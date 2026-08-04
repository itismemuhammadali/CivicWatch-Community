import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/notification_icon_button.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';

class SuperAdminTopHeader extends StatelessWidget {
  const SuperAdminTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CurrentUserAvatar(
          radius: 24,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomTextField(
            topPadding: 10,
            bottomPadding: 10,
            readOnly: true,
            hintText: "Search",
            prefix: Icon(Icons.search, color: kDarkGreyColor),
            hintTextColor: kDarkGreyColor,
          ),
        ),
        const SizedBox(width: 10),
        NotificationIconButton(
          decoration: BoxDecoration(
            color: kWhiteColor,
            shape: BoxShape.circle,
            border: Border.all(color: kGreyColor),
          ),
          padding: const EdgeInsets.all(10),
        ),
      ],
    );
  }
}
