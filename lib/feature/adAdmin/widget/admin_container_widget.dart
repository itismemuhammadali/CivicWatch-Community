import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adAdmin/pages/admin_profile_page.dart';
import 'package:flutter/material.dart';

class AdminContainerWidget extends StatelessWidget {
  final UserProfile admin;
  final bool showOnlineStatus;
  final double width;
  final VoidCallback? onAdminDeleted;

  const AdminContainerWidget({
    super.key,
    required this.admin,
    this.showOnlineStatus = false,
    this.width = 138,
    this.onAdminDeleted,
  });

  String get _displayName {
    final fullName = '${admin.firstName} ${admin.lastName}'.trim();
    if (fullName.isNotEmpty && fullName != '-') {
      return fullName;
    }
    return admin.email;
  }

  String get _subtitle {
    final email = admin.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return (admin.roleDescription ?? 'Admin').trim();
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

  @override
  Widget build(BuildContext context) {
    final avatarUrl = admin.applicationMeta?.metaUrl?.trim();

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AdminProfilePage(admin: admin),
          ),
        );
        if (deleted == true) {
          onAdminDeleted?.call();
        }
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: kWhiteColor,
          border: Border.all(color: kGreyColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Stack(
              children: [
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 40,
                        backgroundColor: kTextfieldBlueColor,
                        backgroundImage: NetworkImage(avatarUrl),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 40,
                        backgroundColor: kTextfieldBlueColor,
                        child: Text(
                          _buildInitials(_displayName),
                          style: context.bold.copyWith(
                            color: kPrimaryColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                if (showOnlineStatus)
                  Positioned(
                    bottom: 0,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: kWhiteColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            Space.vertical(6),
            Text(
              _displayName,
              style: context.semiBold.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Space.vertical(2),
            Text(
              _subtitle,
              style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
