import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  String? selectedCity;
  String? selectedCountry;
  String? selectedMonth;
  String? selectedDay;
  String? selectedYear;
  String? selectedGender;
  bool isPublic = true;

  final List<String> cities = ['Vancouver', 'Toronto', 'Montreal', 'Calgary'];
  final List<String> countries = ['Canada', 'USA', 'UK', 'Australia'];
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> days = List.generate(31, (i) => '${i + 1}');
  final List<String> years = List.generate(80, (i) => '${DateTime.now().year - i}');
  final List<String> genders = ['Male', 'Female', 'Other'];

  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: AuthStorage.cachedFirstName ?? 'Alex');
    lastNameController = TextEditingController(text: AuthStorage.cachedLastName ?? 'Honnold');
    emailController = TextEditingController(text: 'user@cctv.app');
    phoneController = TextEditingController(text: '(778) 123-4567');
    selectedCity = 'Vancouver';
    selectedCountry = 'Canada';
    selectedMonth = 'April';
    selectedDay = '14';
    selectedYear = '1982';
    selectedGender = 'Male';
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageFile = file;
        _pickedImageBytes = bytes;
      });
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => _isUploadingPhoto = true);

    try {
      String? newAvatarUrl;
      final storage = const AuthStorage();
      final uid = await storage.readUserId();
      final accessToken = await storage.readAccessToken();

      if (_pickedImageFile != null && _pickedImageBytes != null && uid != null && accessToken != null) {
        final service = const ApplicationCloudService();
        final uploaded = await service.uploadImage(
          accessToken: accessToken,
          filePath: _pickedImageFile!.path,
          fileBytes: _pickedImageBytes!,
          fileName: _pickedImageFile!.name,
        );
        newAvatarUrl = uploaded.metaUrl;
        await FirestoreDataService().updateUserProfile(uid.toString(), {
          'profileImageUrl': newAvatarUrl,
          'profile_image_url': newAvatarUrl,
          'avatar_url': newAvatarUrl,
        });
      }

      final currentAvatar = AuthStorage.cachedProfileImageUrl;
      final roleDescription = await storage.readRoleDescription();
      await storage.saveAuth(
        accessToken: accessToken ?? '',
        userId: uid ?? 0,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        profileImageUrl: newAvatarUrl ?? currentAvatar,
        roleDescription: roleDescription ?? 'user',
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppAlert.showError(context, 'Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlackColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Edit profile",
          style: context.semiBold.copyWith(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Upload Profile Photo
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: kTextfieldBlueColor,
                          backgroundImage: _pickedImageBytes != null
                              ? MemoryImage(_pickedImageBytes!)
                              : (AuthStorage.cachedProfileImageUrl != null && AuthStorage.cachedProfileImageUrl!.isNotEmpty
                                  ? NetworkImage(AuthStorage.cachedProfileImageUrl!)
                                  : const AssetImage('assets/images/super_admin_avatar.png')) as ImageProvider,
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
                Space.vertical(8),
                Center(
                  child: Text(
                    'Upload Profile Photo',
                    style: context.normal.copyWith(
                      fontSize: 12,
                      color: kDarkGreyColor,
                    ),
                  ),
                ),
                Space.vertical(20),

                // ✅ First Name
                Text(
                  'First name',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Alex',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                Space.vertical(16),

                // ✅ Last Name
                Text(
                  'Last name',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Honnold',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                Space.vertical(16),

                // ✅ Email
                Text(
                  'Email',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'user@cctv.app',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: const Icon(Icons.email, size: 20, color: kDarkGreyColor),
                  ),
                ),
                Space.vertical(16),

                // ✅ Phone Number
                Text(
                  'Phone Number',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    hintText: '(778) 123-4567',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                Space.vertical(16),

                // ✅ Location (City and Country)
                Text(
                  'Location',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: cities.map((city) {
                          return DropdownMenuItem(value: city, child: Text(city));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCity = value);
                        },
                      ),
                    ),
                    Space.horizontal(12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCountry,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: countries.map((country) {
                          return DropdownMenuItem(value: country, child: Text(country));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCountry = value);
                        },
                      ),
                    ),
                  ],
                ),
                Space.vertical(16),

                // ✅ Birthday
                Text(
                  'Birthday',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedMonth,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        items: months.map((month) {
                          return DropdownMenuItem(value: month, child: Text(month, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedMonth = value);
                        },
                      ),
                    ),
                    Space.horizontal(8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedDay,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        items: days.map((day) {
                          return DropdownMenuItem(value: day, child: Text(day, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDay = value);
                        },
                      ),
                    ),
                    Space.horizontal(8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedYear,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: kLightGreyColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedYear = value);
                        },
                      ),
                    ),
                  ],
                ),
                Space.vertical(16),

                // ✅ Profile (Public/Private)
                Text(
                  'Profile',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                Row(
                  children: [
                    Checkbox(
                      value: isPublic,
                      onChanged: (value) {
                        setState(() => isPublic = true);
                      },
                    ),
                    Text(
                      'Public',
                      style: context.normal.copyWith(fontSize: 13),
                    ),
                    Space.horizontal(20),
                    Checkbox(
                      value: !isPublic,
                      onChanged: (value) {
                        setState(() => isPublic = false);
                      },
                    ),
                    Text(
                      'Private',
                      style: context.normal.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                Space.vertical(16),

                // ✅ Gender
                Text(
                  'Gender',
                  style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                ),
                Space.vertical(6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedGender,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kLightGreyColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: genders.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedGender = value);
                  },
                ),
                Space.vertical(30),

                // ✅ Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0085FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isUploadingPhoto ? null : _saveProfile,
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: kWhiteColor, strokeWidth: 2),
                          )
                        : Text(
                            'Save',
                            style: context.semiBold.copyWith(
                              fontSize: 14,
                              color: kWhiteColor,
                            ),
                          ),
                  ),
                ),
                Space.vertical(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
