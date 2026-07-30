import 'package:cctv_app/core/components/custom_drawer.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/utils.dart';
import 'package:cctv_app/feature/admin/pages/admin_dashboard_home_page.dart';
import 'package:cctv_app/feature/announcement/pages/announcement_page.dart';
import 'package:cctv_app/feature/communityFeedback/pages/community_feedback.dart';
import 'package:cctv_app/feature/profile/pages/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SimpleAdminBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const SimpleAdminBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<SimpleAdminBottomNavBar> createState() => _SimpleAdminBottomNavBarState();
}

class _SimpleAdminBottomNavBarState extends State<SimpleAdminBottomNavBar> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  List<Widget> get _pages => const [
        AdminDashboardHomePage(),
        CommunityFeedback(),
        AnnouncementPage(),
        NotificationPage(),
      ];

  void onItemTapped(int index) {
    if (index == selectedIndex) return;
    setState(() {
      selectedIndex = index;
    });
    const AuthStorage().saveLastTabIndex(DashboardType.admin, index);
  }

  Widget _buildCustomBottomNav() {
    final items = [
      {'icon': Assets.svgHomeIcon, 'label': 'Home'},
      {'icon': Assets.svgCommunityIcon, 'label': 'Community'},
      {'icon': Assets.svgAnnouncementIcon, 'label': 'Announce'},
      {'icon': Assets.svgNotifyIcon, 'label': 'Notify'},
    ];

    return Container(
      color: kWhiteColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;
          final label = item['label'] as String;

          return GestureDetector(
            onTap: () => onItemTapped(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    item['icon'] as String,
                    colorFilter: colorFilter(color: isSelected ? kWhiteColor : kDarkGreyColor),
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: context.normal.copyWith(
                      color: isSelected ? kWhiteColor : kDarkGreyColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }
}
