import 'package:flutter_svg/svg.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/app_date_time.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class AdminProfilePage extends StatefulWidget {
  final UserProfile admin;

  const AdminProfilePage({super.key, required this.admin});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _isDeleting = false;

  String get _displayName {
    final fullName = '${widget.admin.firstName} ${widget.admin.lastName}'.trim();
    if (fullName.isNotEmpty && fullName != '-') {
      return fullName;
    }
    return widget.admin.email;
  }

  String get _statusLabel {
    return (widget.admin.isActive ?? '').toUpperCase() == 'Y' ? 'Active' : 'Inactive';
  }

  String get _avatarUrl => widget.admin.applicationMeta?.metaUrl?.trim() ?? '';

  String get _locationLabel {
    final parts =
        [
              widget.admin.cityId?.toString(),
              widget.admin.stateId?.toString(),
              widget.admin.countryId?.toString(),
            ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .cast<String>()
            .toList();

    if (parts.isEmpty) {
      return widget.admin.roleDescription?.trim().isNotEmpty == true
          ? widget.admin.roleDescription!.trim()
          : 'Admin';
    }

    return parts.join(', ');
  }

  Future<void> _deleteAdmin() async {
    final userId = widget.admin.userId;
    if (userId == null || userId <= 0) {
      AppAlert.showError(context, 'Invalid user id');
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await const UserService().deleteUser(
        accessToken: accessToken,
        userId: userId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Admin deleted successfully');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to delete admin: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        title: Text(""),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      _avatarUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundColor: kLightGreyColor,
                              backgroundImage: NetworkImage(_avatarUrl),
                              onBackgroundImageError: (_, __) {},
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: kTextfieldBlueColor,
                              child: Text(
                                _buildInitials(_displayName),
                                style: context.bold.copyWith(
                                  fontSize: 24,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: kWhiteColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kBlackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: kDarkGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Space.vertical(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Admin profile",
                    style: context.semiBold.copyWith(fontSize: 20),
                  ),
                  PrimaryButton(
                    text: "Delete Profile",
                    isMainAxisSizeMin: true,
                    height: 40,
                    buttonColor: kRedColor,
                    processing: _isDeleting,
                    inactive: _isDeleting,
                    prefixIcon: const Icon(Icons.delete, color: kWhiteColor),
                    onPressed: () {
                      if (_isDeleting) return;
                      showDeleteDialog(context);
                    },
                  ),
                ],
              ),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Email Address", style: context.semiBold),
                  Text(
                    widget.admin.email.isEmpty ? '-' : widget.admin.email,
                    style: context.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Account Status", style: context.semiBold),
                  Text(
                    _statusLabel,
                    style: context.normal.copyWith(
                      color: _statusLabel == 'Active'
                          ? Colors.green
                          : kDarkGreyColor,
                    ),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Date Joined", style: context.semiBold),
                  Text(
                    AppDateTime.formatDateTime(
                      widget.admin.createdAt,
                      fallback: 'Unknown date',
                    ),
                    style: context.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Last Login Date & Time", style: context.semiBold),
                  Text(
                    AppDateTime.formatDateTime(
                      widget.admin.createdAt,
                      fallback: 'Unknown',
                    ),
                    style: context.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tasks or Projects Done", style: context.semiBold),
                  Text(
                    "${widget.admin.userId}",
                    style: context.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Share profile", style: context.semiBold),
                  GestureDetector(
                    onTap: () {
                      AppAlert.showInfo(
                        context,
                        widget.admin.email.isEmpty ? _displayName : widget.admin.email,
                      );
                    },
                    child: SvgPicture.asset(
                      Assets.svgSolarCopyBoldIcon,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(kDarkGreyColor, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
              Space.vertical(10),
              Divider(thickness: 1),
              Space.vertical(20),
              Text("Important note", style: context.semiBold),
              Space.vertical(10),
              CustomTextField(
                maxLine: 5,
                hintText:
                    "Role: ${widget.admin.roleDescription ?? 'Admin'}\nDOB: ${widget.admin.dob ?? '-'}\nUser ID: ${widget.admin.userId}",
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Space.vertical(10),
              const Text(
                "Want to delete admin profile?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              Space.vertical(20),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Container(
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          border: Border.all(color: kRedColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "No",
                          style: context.normal.copyWith(color: kBlackColor),
                        ),
                      ),
                    ),
                  ),
                  Space.horizontal(10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting ? null : () async {
                        Navigator.pop(dialogContext);
                        await _deleteAdmin();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: kRedColor,
                          border: Border.all(color: kRedColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Yes",
                          style: context.normal.copyWith(color: kWhiteColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
