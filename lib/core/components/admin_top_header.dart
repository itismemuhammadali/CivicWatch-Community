import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/app_constants.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/communityFeedback/pages/community_feedback.dart';
import 'package:cctv_app/feature/home/pages/history_screen.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AdminTopHeader extends StatelessWidget {
  const AdminTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CurrentUserAvatar(
          radius: 18,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        const SizedBox(width: 17),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xffE6E6E6),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Color(0xff292929),
                    size: 23,
                  ),
                  SizedBox(width: 13),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Color(0xff292929),
                      fontFamily: kPrimaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityFeedback()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kWhiteColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xffE6E6E6),
                width: 1,
              ),
            ),
            child: SvgPicture.asset(
              Assets.svgNoteBookIcon,
              width: 23,
              height: 23,
              colorFilter: const ColorFilter.mode(
                kBlackColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
