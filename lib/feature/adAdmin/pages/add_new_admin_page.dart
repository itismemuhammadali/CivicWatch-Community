import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:cctv_app/core/network/models/user_role.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddNewAdminPage extends StatefulWidget {
  const AddNewAdminPage({super.key});

  @override
  State<AddNewAdminPage> createState() => _AddNewAdminPageState();
}

class _AddNewAdminPageState extends State<AddNewAdminPage> {
  static const List<String> _months = [
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApplicationCloudService _applicationCloudService =
      const ApplicationCloudService();

  String? _selectedDay = '21';
  String? _selectedMonth = 'September';
  String? _selectedYear = '1994';
  UserRole? _selectedRole;
  bool _isLoadingRoles = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _rolesError;
  List<UserRole> _roles = const [];
  UploadedMedia? _uploadedProfileImage;

  int _resolveRoleId(UserRole role) {
    final normalizedDescription = role.roleDescription.trim().toLowerCase();
    if (normalizedDescription == 'admin') {
      return 2;
    }
    if (normalizedDescription == 'super admin') {
      return 3;
    }
    if (normalizedDescription == 'user') {
      return 1;
    }
    return role.roleId;
  }

  String? _buildDob() {
    final day = _selectedDay;
    final month = _selectedMonth;
    final year = _selectedYear;
    if (day == null || month == null || year == null) {
      return null;
    }

    final monthIndex = _months.indexOf(month);
    if (monthIndex < 0) return null;

    final parsedDay = int.tryParse(day);
    final parsedYear = int.tryParse(year);
    if (parsedDay == null || parsedYear == null) return null;

    final date = DateTime(parsedYear, monthIndex + 1, parsedDay);
    if (date.year != parsedYear ||
        date.month != monthIndex + 1 ||
        date.day != parsedDay) {
      return null;
    }

    final twoDigitMonth = (monthIndex + 1).toString().padLeft(2, '0');
    final twoDigitDay = parsedDay.toString().padLeft(2, '0');
    return '$parsedYear-$twoDigitMonth-$twoDigitDay';
  }

  List<String> get _days =>
      List<String>.generate(31, (index) => '${index + 1}');

  List<String> get _years {
    final currentYear = DateTime.now().year;
    return List<String>.generate(
      91,
      (index) => '${currentYear - index}',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: kWhiteColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kGreyColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
    );
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedDay = null;
      _selectedMonth = null;
      _selectedYear = null;
      _selectedRole = null;
      _uploadedProfileImage = null;
    });
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
      _rolesError = null;
    });

    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      final roles = await const UserService().getRoles(accessToken: token);
      
      if (!mounted) return;
      setState(() {
        _roles = roles;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rolesError = 'Failed to load roles';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isUploadingImage) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      setState(() {
        _isUploadingImage = true;
      });

      final fileBytes = await file.readAsBytes();
      final uploadedMedia = await _applicationCloudService.uploadImage(
        accessToken: accessToken,
        filePath: file.path,
        fileBytes: fileBytes,
        fileName: file.name,
      );

      if (!mounted) return;
      setState(() {
        _uploadedProfileImage = uploadedMedia;
      });

      AppAlert.showSuccess(context, 'Profile image uploaded successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to upload profile image: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedRole == null) {
      AppAlert.showError(context, 'Please select a role');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      final createdBy = await const AuthStorage().readUserId();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (createdBy == null || createdBy <= 0) {
        throw const ApiException('Creator user id not found');
      }

      await const UserService().createUser(
        accessToken: accessToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? '-'
            : _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleId: _resolveRoleId(_selectedRole!),
        createdBy: createdBy,
        dob: _buildDob(),
        metaId: _uploadedProfileImage?.metaId ?? 0,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Profile created successfully');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to create profile: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildDateDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: kWhiteColor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: _dropdownDecoration(),
        hint: Text(
          hint,
          overflow: TextOverflow.ellipsis,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        title: const Text('New Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final dateItemWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: kLightGreyColor,
                          backgroundImage:
                              _uploadedProfileImage?.metaUrl != null &&
                                  _uploadedProfileImage!.metaUrl!.trim().isNotEmpty
                              ? NetworkImage(_uploadedProfileImage!.metaUrl!)
                              : const AssetImage(
                                      Assets.pngHighlight1Image,
                                    )
                                    as ImageProvider,
                          onBackgroundImageError: (_, __) {},
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: GestureDetector(
                            onTap: _isUploadingImage
                                ? null
                                : _pickAndUploadProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kWhiteColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      color: kWhiteColor,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Space.vertical(20),
                  const Text('Name'),
                  Space.vertical(10),
                  CustomTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                    prefix: const Icon(Icons.person_2_outlined),
                    validator: Validators.firstName,
                  ),
                  Space.vertical(10),
                  CustomTextField(
                    controller: _lastNameController,
                    hintText: 'Last Name',
                    prefix: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  Space.vertical(20),
                  const Text('Email'),
                  Space.vertical(10),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter Email',
                    prefix: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                  ),
                  Space.vertical(20),
                  const Text('Password'),
                  Space.vertical(10),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Set Password',
                    prefix: const Icon(Icons.lock_outline),
                    validator: Validators.password,
                  ),
                  Space.vertical(20),
                  const Text('Birth Date (Optional)'),
                  Space.vertical(10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildDateDropdown(
                        width: dateItemWidth,
                        value: _selectedDay,
                        items: _days,
                        hint: 'Day',
                        onChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                          });
                        },
                      ),
                      _buildDateDropdown(
                        width: dateItemWidth,
                        value: _selectedMonth,
                        items: _months,
                        hint: 'Month',
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                      ),
                      _buildDateDropdown(
                        width: dateItemWidth,
                        value: _selectedYear,
                        items: _years,
                        hint: 'Year',
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ],
                  ),
                  Space.vertical(20),
                  const Text('Assign Role'),
                  Space.vertical(6),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: kWhiteColor,
                    decoration: _dropdownDecoration(),
                    hint: Text(
                      _isLoadingRoles ? 'Loading roles...' : 'Select Role',
                    ),
                    items: _roles
                        .map(
                          (role) => DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.roleDescription),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoadingRoles
                        ? null
                        : (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  if (_rolesError != null) ...[
                    Space.vertical(8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _rolesError!,
                            style: const TextStyle(
                              color: kDarkGreyColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadRoles,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                  Space.vertical(16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _clearForm,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(color: kDarkGreyColor),
                      ),
                    ),
                  ),
                  Space.vertical(20),
                  isCompact
                      ? Column(
                          children: [
                            PrimaryButton(
                              text: 'Cancel',
                              textColor: kBlackColor,
                              borderColor: kPrimaryColor,
                              buttonColor: kWhiteColor,
                              showBorder: true,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            Space.vertical(10),
                            PrimaryButton(
                              text: 'Add Profile',
                              processing: _isSubmitting,
                              inactive: _isSubmitting,
                              onPressed: _submit,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Cancel',
                                textColor: kBlackColor,
                                borderColor: kPrimaryColor,
                                buttonColor: kWhiteColor,
                                showBorder: true,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Space.horizontal(10),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Add Profile',
                                processing: _isSubmitting,
                                inactive: _isSubmitting,
                                onPressed: _submit,
                              ),
                            ),
                          ],
                        ),
                ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
