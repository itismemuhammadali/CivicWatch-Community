import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firebase_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:cctv_app/feature/bottomNavBar/ad_bottom_nav_bar.dart';
import 'package:cctv_app/feature/bottomNavBar/admin_bottom_nav_bar.dart';
import 'package:cctv_app/feature/bottomNavBar/simple_admin_bottom_nav_bar.dart';
import 'package:cctv_app/feature/bottomNavBar/user_bottom_nav_bar.dart';
import 'package:cctv_app/feature/forgotPassword/pages/forgot_pasword.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:cctv_app/feature/profile/pages/terms_and_policies.dart';

class SigninView extends StatefulWidget {
  final int selectedRoleIndex; // 0: Super Admin, 1: Admin, 2: User
  final bool? isAdminTab; // optional backward compatibility

  const SigninView({
    super.key,
    this.selectedRoleIndex = 2,
    this.isAdminTab,
  });

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isSubmitting = false;

  int get _effectiveRoleIndex {
    if (widget.isAdminTab != null) {
      return widget.isAdminTab! ? 0 : 2;
    }
    return widget.selectedRoleIndex;
  }

  DashboardType _dashboardTypeFromRoleString(String role) {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'super admin') {
      return DashboardType.superAdmin;
    }
    if (normalizedRole == 'admin') {
      return DashboardType.admin;
    }
    if (normalizedRole == 'ad') return DashboardType.ad;
    return DashboardType.user;
  }

  int _roleIdFromRoleString(String role) {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'super admin') return 3;
    if (normalizedRole == 'admin') return 2;
    if (normalizedRole == 'ad') return 3;
    return 1;
  }

  Widget _dashboardFromType(DashboardType type) {
    return switch (type) {
      DashboardType.superAdmin => const AdminBottomNavBar(),
      DashboardType.admin => const SimpleAdminBottomNavBar(),
      DashboardType.user => const UserBottomNavBar(),
      DashboardType.ad => const AdBottomNavBar(),
    };
  }

  bool _matchesSelectedLoginType(DashboardType dashboardType) {
    final roleIndex = _effectiveRoleIndex;
    if (roleIndex == 0) {
      // Super Admin tab selected
      return dashboardType == DashboardType.superAdmin || dashboardType == DashboardType.admin;
    }
    if (roleIndex == 1) {
      // Admin tab selected
      return dashboardType == DashboardType.admin || dashboardType == DashboardType.superAdmin;
    }
    // User tab selected
    return dashboardType == DashboardType.user;
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    if (formKey.currentState?.validate() != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      final authService = FirebaseAuthService();
      final response = await authService.signIn(
        email: email,
        password: password,
      );

      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'Login failed');
      }

      final user = response['user'];
      final role = response['role'] as String? ?? 'user';
      final token = response['token'] as String?;

      if (user == null || token == null) {
        throw Exception('Login succeeded but auth data is missing');
      }

      if (!user.emailVerified) {
        await FirebaseAuth.instance.currentUser?.reload();
        final isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        
        if (!isEmailVerified) {
          await user.sendEmailVerification();
          throw Exception('Please verify your email address before logging in. A new verification link has been sent to your inbox.');
        }
      }

      final dashboardType = _dashboardTypeFromRoleString(role);
      if (!_matchesSelectedLoginType(dashboardType)) {
        throw Exception(
          'Please select the correct login tab for your account role ($role)',
        );
      }

      // Read the full user document so we get the real user_id integer, name, and avatar
      int firestoreUserId = user.uid.hashCode; // fallback
      String firstName = '';
      String lastName = '';
      String? profileImageUrl;
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          profileImageUrl = data['profileImageUrl'] ?? data['profile_image_url'];
          // Prefer the integer user_id stored in Firestore
          final rawId = data['user_id'] ?? data['userId'];
          firestoreUserId = rawId is int
              ? rawId
              : (int.tryParse('$rawId') ?? user.uid.hashCode);
          // Prefer Firestore first_name/lastName over displayName
          firstName = (data['first_name'] ?? data['firstName'] ?? '').toString().trim();
          lastName  = (data['last_name']  ?? data['lastName']  ?? '').toString().trim();
          if (firstName.isEmpty) {
            // Fall back to Firebase Auth displayName
            final displayName = user.displayName ?? '';
            final nameParts = displayName.split(' ');
            firstName = nameParts.isNotEmpty ? nameParts.first : '';
            lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          }
        } else {
          final displayName = user.displayName ?? '';
          final nameParts = displayName.split(' ');
          firstName = nameParts.isNotEmpty ? nameParts.first : '';
          lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        }
      } catch (e) {
        debugPrint('Failed to fetch user profile on login: $e');
        final displayName = user.displayName ?? '';
        final nameParts = displayName.split(' ');
        firstName = nameParts.isNotEmpty ? nameParts.first : '';
        lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }

      await AuthStorage().saveAuth(
        accessToken: token,
        userId: firestoreUserId,
        roleId: _roleIdFromRoleString(role),
        roleDescription: role,
        firstName: firstName,
        lastName: lastName,
        email: user.email ?? email,
        dashboardType: dashboardType,
        firebaseUid: user.uid,
        profileImageUrl: profileImageUrl,
      );

      if (!mounted) return;
      final dashboard = _dashboardFromType(dashboardType);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Login failed: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            hintText: "Email",
            labelText: "Email",
            controller: emailController,
            hintTextColor: kDarkGreyColor,
            topPadding: 24,
            bottomPadding: 12,
            validator: (value) {
              return Validators.email(value);
            },
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 10),
              onPressed: null,
              child: SvgPicture.asset(
                Assets.svgNameIcon,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(kDarkGreyColor, BlendMode.srcIn),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Space.vertical(16),
          CustomTextField(
            hintText: "Password",
            labelText: "Password",
            controller: passwordController,
            obscureText: obscurePassword,
            hintTextColor: kDarkGreyColor,
            topPadding: 24,
            bottomPadding: 12,
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
          ),
          Space.vertical(16),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              child: Text(
                "Forget password",
                style: context.medium.copyWith(
                  color: kDarkGreyColor,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasword(),
                  ),
                );
              },
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
                  const TextSpan(text: 'By logging in, you agree to our '),
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
            text: "Log in",
            isMainAxisSizeMin: true,
            padding: const EdgeInsets.symmetric(horizontal: 50),
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
