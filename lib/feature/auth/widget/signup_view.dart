import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/firebase/firebase_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:cctv_app/feature/bottomNavBar/user_bottom_nav_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cctv_app/feature/profile/pages/terms_and_policies.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isSubmitting = false;

  XFile? _pickedProfileImage;
  Uint8List? _profileImageBytes;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedProfileImage = file;
        _profileImageBytes = bytes;
      });
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    if (formKey.currentState?.validate() != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final authService = FirebaseAuthService();
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();
      final email = emailController.text.trim();
      
      final response = await authService.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: passwordController.text,
        role: 'user',
      );

      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'Sign up failed');
      }

      final user = response['user'];
      final token = response['token'] as String?;

      if (user == null || token == null) {
        throw const ApiException('Signup succeeded but auth data is missing');
      }

      String? uploadedProfileUrl;
      if (_pickedProfileImage != null && _profileImageBytes != null) {
        final service = const ApplicationCloudService();
        final uploaded = await service.uploadImage(
          accessToken: token,
          filePath: _pickedProfileImage!.path,
          fileBytes: _profileImageBytes!,
          fileName: _pickedProfileImage!.name,
        );
        uploadedProfileUrl = uploaded.metaUrl;
        
        // Update user doc with avatar
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'profileImageUrl': uploadedProfileUrl,
          });
        } catch (_) {}
      }

      // Read the Firestore user_id that firebase_service.dart wrote (millisecondsSinceEpoch)
      int firestoreUserId = user.uid.hashCode; // safe fallback
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final rawId = userDoc.data()?['user_id'] ?? userDoc.data()?['userId'];
          firestoreUserId = rawId is int
              ? rawId
              : (int.tryParse('$rawId') ?? user.uid.hashCode);
        }
      } catch (_) {}

      await const AuthStorage().saveAuth(
        accessToken: token,
        userId: firestoreUserId,
        roleId: 1,
        roleDescription: 'user',
        firstName: firstName,
        lastName: lastName,
        email: user.email ?? email,
        profileImageUrl: uploadedProfileUrl,
        dashboardType: DashboardType.user,
        firebaseUid: user.uid,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserBottomNavBar()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Signup failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Avatar Picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kTextfieldBlueColor,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.person, size: 40, color: kPrimaryColor)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: kWhiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Space.vertical(20),

          // First Name
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "First name",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          CustomTextField(
            hintText: "First Name",
            controller: firstNameController,
            hintTextColor: kDarkGreyColor,
            validator: (value) {
              return Validators.firstName(value);
            },
            suffix: const Icon(Icons.person_outline, color: kDarkGreyColor),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          Space.vertical(14),

          // Last Name
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Last name",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          CustomTextField(
            hintText: "Last Name",
            controller: lastNameController,
            hintTextColor: kDarkGreyColor,
            validator: (value) {
              return Validators.lastName(value);
            },
            suffix: const Icon(Icons.person_outline, color: kDarkGreyColor),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          Space.vertical(14),

          // Email
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Email",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          CustomTextField(
            hintText: "Email",
            controller: emailController,
            hintTextColor: kDarkGreyColor,
            validator: (value) {
              return Validators.email(value);
            },
            suffix: const Icon(Icons.email_outlined, color: kDarkGreyColor),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          Space.vertical(14),

          // Password
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Passwords",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          CustomTextField(
            hintText: "Password",
            controller: passwordController,
            obscureText: obscurePassword,
            hintTextColor: kDarkGreyColor,
            validator: (value) {
              return Validators.password(value);
            },
            suffix: CupertinoButton(
              child: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.remove_red_eye_outlined,
                color: kDarkGreyColor,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          Space.vertical(14),

          // Confirm Password
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Confirm Passwords",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          CustomTextField(
            hintText: "Confirm Password",
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            hintTextColor: kDarkGreyColor,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Required";
              }
              if (passwordController.text != confirmPasswordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
            suffix: CupertinoButton(
              child: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.remove_red_eye_outlined,
                color: kDarkGreyColor,
              ),
              onPressed: () {
                setState(() {
                  obscureConfirmPassword = !obscureConfirmPassword;
                });
              },
            ),
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kBlackColor,
            ),
          ),
          Space.vertical(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: kDarkGreyColor,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'By signing up, you agree to our '),
                  TextSpan(
                    text: 'End User License Agreement',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndPolicies(),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndPolicies(),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          Space.vertical(20),
          PrimaryButton(
            text: "Sign Up",
            isMainAxisSizeMin: true,
            padding: EdgeInsets.symmetric(horizontal: 50),
            processing: isSubmitting,
            inactive: isSubmitting,
            onPressed: () {
              _submit();
            },
          ),
        ],
      ),
    );
  }
}
