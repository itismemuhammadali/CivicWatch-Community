import 'package:cctv_app/core/components/custom_drawer.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/utils.dart';
import 'package:cctv_app/feature/adAdmin/pages/ad_admin_page.dart';
import 'package:cctv_app/feature/adHome/pages/ad_home_page.dart';
import 'package:cctv_app/feature/ads/pages/ads_page.dart';
import 'package:cctv_app/feature/announcement/pages/announcement_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AdBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const AdBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<AdBottomNavBar> createState() => _AdBottomNavBarState();
}

class _AdBottomNavBarState extends State<AdBottomNavBar> {
  late int selectedIndex;

  final List<Widget> pages = [
    AdHomePage(),
    AdsPage(),
    AdAdminPage(),
    AnnouncementPage(),
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex.clamp(0, pages.length - 1);
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    const AuthStorage().saveLastTabIndex(DashboardType.ad, index);
  }

  Widget _buildCustomBottomNav() {
    final items = [
      {'icon': Assets.svgHomeIcon, 'label': 'Home'},
      {'icon': Assets.svgAdsIcon, 'label': 'Ads'},
      {'icon': Assets.svgAdminIcon, 'label': 'Admins'},
      {'icon': Assets.svgAnnouncementIcon, 'label': 'Announce'},
    ];

    return Container(
      color: kWhiteColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;
          final iconColor = isSelected ? kPrimaryColor : kDarkGreyColor;
          final textColor = isSelected ? kPrimaryColor : kDarkGreyColor;
          final label = item['label'] as String;
          
          // Truncate long words to 3-4 chars + "."
          final truncatedLabel = label.length > 4 ? '${label.substring(0, 4)}.' : label;

          return GestureDetector(
            onTap: () => onItemTapped(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    item['icon'] as String,
                    colorFilter: colorFilter(color: iconColor),
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      truncatedLabel,
                      style: context.normal.copyWith(
                        color: textColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      drawer: CustomDrawer(onHomeTap: () => onItemTapped(0)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: pages[selectedIndex]),
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
