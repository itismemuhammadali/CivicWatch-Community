import 'package:cctv_app/core/components/custom_drawer.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/utils.dart';
import 'package:cctv_app/feature/case/pages/create_case_page.dart';
import 'package:cctv_app/feature/home/pages/home_page.dart';
import 'package:cctv_app/feature/pending/pages/pending_page.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserBottomNavBar extends StatefulWidget {
  final int initialIndex;
  const UserBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<UserBottomNavBar> createState() => _UserBottomNavBarState();
}

class _UserBottomNavBarState extends State<UserBottomNavBar> {
  late int selectedIndex;
  int _homeRefreshKey = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = _buildPages();
    selectedIndex = widget.initialIndex.clamp(0, pages.length - 1);
  }

  List<Widget> _buildPages() {
    return [
      HomePage(key: ValueKey('home-$_homeRefreshKey'), isAdmin: false, onViewAllPending: () => onItemTapped(2)),
      CreateCasePage(onCaseCreated: _returnToHomeAfterCaseCreated),
      PendingPage(),
      ProfilePage(),
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    const AuthStorage().saveLastTabIndex(DashboardType.user, index);
  }

  void _returnToHomeAfterCaseCreated() {
    setState(() {
      _homeRefreshKey++;
      pages = _buildPages();
      selectedIndex = 0;
    });
    const AuthStorage().saveLastTabIndex(DashboardType.user, 0);
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String iconPath,
    String label,
  ) {
    final bool isSelected = selectedIndex == index;
    final color = isSelected ? kPrimaryColor : kDarkGreyColor;
    
    // Truncate long words to 3-4 chars + "."
    final truncatedLabel = label.length > 4 ? '${label.substring(0, 4)}.' : label;

    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: colorFilter(color: color),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                truncatedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        onHomeTap: () => onItemTapped(0),
        onRunningCaseTap: () => onItemTapped(2),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: pages[selectedIndex]),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: kBlackColor.withValues(alpha: 0.08),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        _buildNavItem(context, 0, Assets.svgHomeIcon, 'Home'),
                        _buildNavItem(context, 1, Assets.svgCreateIcon, 'Create'),
                        _buildNavItem(context, 2, Assets.svgPendingIcon, 'Pending'),
                        _buildNavItem(context, 3, Assets.svgProfileIcon, 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: kWhiteColor,
    );
  }
}
