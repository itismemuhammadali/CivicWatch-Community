import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/notification_icon_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/pages/history_screen.dart';
import 'package:cctv_app/feature/profile/pages/ad_profile_page.dart';
import 'package:flutter/material.dart';

class AdTopHeader extends StatelessWidget {
  const AdTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CurrentUserAvatar(
          radius: 24,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdProfilePage()),
            );
          },
        ),
        Space.horizontal(10),
        Expanded(
          child: CustomTextField(
            topPadding: 10,
            bottomPadding: 10,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
            hintText: "Search",
            prefix: Icon(Icons.search, color: kDarkGreyColor),
            hintTextColor: kDarkGreyColor,
          ),
        ),
        Space.horizontal(10),
        NotificationIconButton(
          decoration: BoxDecoration(
            color: kWhiteColor,
            shape: BoxShape.circle,
            border: Border.all(color: kDarkGreyColor),
          ),
          padding: const EdgeInsets.all(10),
        ),
      ],
    );
  }
}
