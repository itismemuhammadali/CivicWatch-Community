import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/services/user_cache_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _profileImageUrl;

  final List<String> cities = ['Vancouver', 'Toronto', 'Montreal', 'Calgary'];
  final List<String> countries = ['Canada', 'USA', 'UK', 'Australia'];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<String> days = List.generate(31, (i) => '${i + 1}');
  final List<String> years = List.generate(
    80,
    (i) => '${DateTime.now().year - i}',
  );
  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
      text: AuthStorage.cachedFirstName ?? 'Alex',
    );
    lastNameController = TextEditingController(
      text: AuthStorage.cachedLastName ?? 'Honnold',
    );
    emailController = TextEditingController(
      text: AuthStorage.cachedEmail ?? 'user@cctv.app',
    );
    phoneController = TextEditingController(text: '(778) 123-4567');
    selectedCity = 'Vancouver';
    selectedCountry = 'Canada';
    selectedMonth = 'April';
    selectedDay = '14';
    selectedYear = '1982';
    selectedGender = 'Male';
    _profileImageUrl = AuthStorage.cachedProfileImageUrl;

    _loadProfileFromFirestore();
  }

  Future<void> _loadProfileFromFirestore() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final storage = const AuthStorage();
      final uid =
          await storage.readFirebaseUid() ?? AuthStorage.cachedFirebaseUid;
      if (uid == null) {
        throw Exception("No firebase user ID found");
      }
      final profile = await FirestoreDataService().getUserProfile(uid);
      if (profile != null) {
        firstNameController.text =
            profile['firstName'] ?? profile['first_name'] ?? '';
        lastNameController.text =
            profile['lastName'] ?? profile['last_name'] ?? '';
        emailController.text = profile['email'] ?? profile['user_email'] ?? '';
        phoneController.text = profile['phone'] ?? '';
        selectedCity = profile['city'];
        selectedCountry = profile['country'];
        selectedGender = profile['gender'];
        isPublic = profile['isPublic'] ?? true;
        _profileImageUrl =
            profile['profileImageUrl'] ?? profile['profile_image_url'];

        final dobStr = profile['dob'] as String?;
        if (dobStr != null && dobStr.isNotEmpty) {
          final parts = dobStr.split('-');
          if (parts.length == 3) {
            selectedYear = parts[0];
            final monthIndex = int.tryParse(parts[1]);
            if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
              selectedMonth = months[monthIndex - 1];
            }
            final dayInt = int.tryParse(parts[2]);
            if (dayInt != null) {
              selectedDay = '$dayInt';
            }
          }
        }
      }
    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final fileBytes = await file.readAsBytes();

      setState(() {
        _isUploadingPhoto = true;
      });

      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';

      const service = ApplicationCloudService();
      final uploadedMedia = await service.uploadImage(
        accessToken: accessToken,
        filePath: file.path,
        fileBytes: fileBytes,
        fileName: file.name,
      );

      setState(() {
        _profileImageUrl = uploadedMedia.metaUrl;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storage = const AuthStorage();
      final uid =
          await storage.readFirebaseUid() ?? AuthStorage.cachedFirebaseUid;
      if (uid == null) {
        throw Exception("No firebase user ID found");
      }

      String? dob;
      if (selectedYear != null &&
          selectedMonth != null &&
          selectedDay != null) {
        final monthIndex = months.indexOf(selectedMonth!) + 1;
        final monthStr = monthIndex.toString().padLeft(2, '0');
        final dayStr = int.parse(selectedDay!).toString().padLeft(2, '0');
        dob = '$selectedYear-$monthStr-$dayStr';
      }

      final updates = {
        'firstName': firstNameController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'user_email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'city': selectedCity,
        'country': selectedCountry,
        'gender': selectedGender,
        'isPublic': isPublic,
        if (dob != null) 'dob': dob,
        if (_profileImageUrl != null) 'profileImageUrl': _profileImageUrl,
        if (_profileImageUrl != null) 'profile_image_url': _profileImageUrl,
        if (_profileImageUrl != null) 'avatar_url': _profileImageUrl,
      };

      await FirestoreDataService().updateUserProfile(uid, updates);

      // Save to AuthStorage
      final userId = await storage.readUserId() ?? 0;
      final roleId = await storage.readRoleId();
      final roleDescription = await storage.readRoleDescription();
      final dashboardType =
          await storage.readDashboardType() ?? DashboardType.user;

      await storage.saveAuth(
        accessToken: await storage.readAccessToken() ?? '',
        userId: userId,
        roleId: roleId,
        roleDescription: roleDescription,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        profileImageUrl: _profileImageUrl,
        dashboardType: dashboardType,
        firebaseUid: uid,
      );

      // Invalidate UserCacheService so post enrichment & connections pull fresh data immediately
      if (userId > 0) UserCacheService().invalidate(userId);
      UserCacheService().invalidateByFirebaseUid(uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: kTextfieldBlueColor,
                          backgroundImage: _buildProfileImage(),
                          onBackgroundImageError: (_, __) {},
                        ),
                        if (_isUploadingPhoto)
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kPrimaryColor,
                            ),
                          ),
                      ],
                    ),
                    Space.horizontal(16),
                    Text(
                      _isUploadingPhoto
                          ? 'Uploading...'
                          : 'Upload Profile Photo',
                      style: context.normal.copyWith(
                        fontSize: 14,
                        color: kBlackColor,
                      ),
                    ),
                  ],
                ),
              ),
              Space.vertical(20),

              // ✅ First Name
              Text(
                'First name',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: kDarkGreyColor,
                  ),
                ),
              ),
              Space.vertical(16),

              // ✅ Last Name
              Text(
                'Last name',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: kDarkGreyColor,
                  ),
                ),
              ),
              Space.vertical(16),

              // ✅ Email
              Text(
                'Email',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: kDarkGreyColor,
                  ),
                ),
              ),
              Space.vertical(16),

              // ✅ Phone Number
              Text(
                'Phone Number',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              Space.vertical(16),

              // ✅ Location
              Text(
                'Location',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedCity = value),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedCountry = value),
                    ),
                  ),
                ],
              ),
              Space.vertical(16),

              // ✅ Birthday
              Text(
                'Birthday',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      items: months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedMonth = value),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      items: days.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedDay = value),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      items: years.map((year) {
                        return DropdownMenuItem(value: year, child: Text(year, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => selectedYear = value),
                    ),
                  ),
                ],
              ),
              Space.vertical(16),

              // ✅ Profile (Public/Private)
              Text(
                'Profile',
                style: context.bold.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
              ),
              Space.vertical(6),
              Row(
                children: [
                  Checkbox(
                    value: isPublic,
                    onChanged: (value) => setState(() => isPublic = true),
                  ),
                  Text('Public', style: context.normal.copyWith(fontSize: 13)),
                  Space.horizontal(20),
                  Checkbox(
                    value: !isPublic,
                    onChanged: (value) => setState(() => isPublic = false),
                  ),
                  Text('Private', style: context.normal.copyWith(fontSize: 13)),
                ],
              ),
              Space.vertical(16),

              // ✅ Gender
              Text(
                'Gender',
                style: context.normal.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: genders.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => selectedGender = value),
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
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kWhiteColor,
                            ),
                          ),
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
    );
  }

  ImageProvider? _buildProfileImage() {
    final profileImageUrl = _profileImageUrl?.trim();
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('assets/')) {
        return AssetImage(profileImageUrl);
      }
      return NetworkImage(profileImageUrl);
    }
    return const AssetImage('assets/images/super_admin_avatar.png');
  }
}
