import 'package:cctv_app/core/components/custom_drawer.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/utils.dart';
import 'package:cctv_app/feature/adAdmin/pages/ad_admin_page.dart';
import 'package:cctv_app/feature/adminHome/pages/admin_home_page.dart';
import 'package:cctv_app/feature/ads/pages/ads_page.dart';
import 'package:cctv_app/feature/announcement/pages/announcement_page.dart';
import 'package:cctv_app/feature/home/pages/home_page.dart';
import 'package:cctv_app/feature/profile/pages/notification_page.dart';
import 'package:cctv_app/feature/communityFeedback/pages/community_feedback.dart';
import 'package:cctv_app/feature/superAdmin/pages/super_admin_home_page.dart';
import 'package:cctv_app/feature/adHome/pages/ad_home_page.dart';
import 'package:cctv_app/feature/superAdmin/pages/super_admin_ads_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AdminBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const AdminBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<AdminBottomNavBar> createState() => _AdminBottomNavBarState();
}

class _AdminBottomNavBarState extends State<AdminBottomNavBar> {
  late int selectedIndex;
  bool _isSuperAdmin = false;
  bool _isRoleResolved = false;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _loadRoleAccess();
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    const AuthStorage().saveLastTabIndex(DashboardType.admin, index);
  }

  Future<void> _loadRoleAccess() async {
    final storage = const AuthStorage();
    final roleDescription = (await storage.readRoleDescription() ?? '')
        .trim()
        .toLowerCase();
    final roleId = await storage.readRoleId();
    final isSuperAdmin =
        roleDescription.contains('super') ||
        roleDescription == 'admin' ||
        roleId == 2 ||
        roleId == 3;

    if (!mounted) return;
    setState(() {
      _isSuperAdmin = isSuperAdmin;
      _isRoleResolved = true;
      selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    });
  }

  List<Widget> get _pages => [
    SuperAdminHomePage(),
    SuperAdminAdsPage(),
    AdAdminPage(),
    AnnouncementPage(),
  ];

  List<BottomNavigationBarItem> _buildItems() => [
    BottomNavigationBarItem(
      icon: SvgPicture.asset(
        Assets.svgHomeIcon,
        colorFilter: colorFilter(
          color: selectedIndex == 0 ? kPrimaryColor : kDarkGreyColor,
        ),
      ),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(
        Assets.svgAdsIcon,
        colorFilter: colorFilter(
          color: selectedIndex == 1 ? kPrimaryColor : kDarkGreyColor,
        ),
      ),
      label: 'Ads',
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(
        Assets.svgAdminIcon,
        colorFilter: colorFilter(
          color: selectedIndex == 2 ? kPrimaryColor : kDarkGreyColor,
        ),
      ),
      label: 'Admin',
    ),
    BottomNavigationBarItem(
      icon: SvgPicture.asset(
        Assets.svgAnnouncementIcon,
        colorFilter: colorFilter(
          color: selectedIndex == 3 ? kPrimaryColor : kDarkGreyColor,
        ),
      ),
      label: 'Announce',
    ),
  ];

  Widget _buildCustomBottomNav() {
    final items = [
      {'icon': Assets.svgHomeIcon, 'label': 'Home'},
      {'icon': Assets.svgAdsIcon, 'label': 'Ads'},
      {'icon': Assets.svgAdminIcon, 'label': 'Admins'},
      {'icon': Assets.svgAnnouncementIcon, 'label': 'Announce'},
    ];

    return Container(
      color: kWhiteColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;
              final iconColor = isSelected ? kPrimaryColor : kDarkGreyColor;
              final textColor = isSelected ? kPrimaryColor : kDarkGreyColor;
              final label = item['label'] as String;
              return GestureDetector(
                onTap: () => onItemTapped(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        item['icon'] as String,
                        colorFilter: colorFilter(
                          color: isSelected ? kWhiteColor : kDarkGreyColor,
                        ),
                        width: 24,
                        height: 24,
                      ),
                      if (isSelected) const SizedBox(width: 6),
                      if (isSelected)
                        Text(
                          label,
                          style: context.normal.copyWith(
                            color: isSelected ? kWhiteColor : kDarkGreyColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoleResolved) {
      return const Scaffold(
        backgroundColor: kWhiteColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: CustomDrawer(onHomeTap: () => onItemTapped(0)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _pages[selectedIndex],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: kBlackColor.withValues(alpha: 0.05),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: _buildCustomBottomNav(),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: kWhiteColor,
    );
  }
}
