import 'package:cctv_app/core/components/app_bottom_sheet.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/drawer/pages/user_profile_page.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/feature/profile/pages/help_and_support.dart';
import 'package:cctv_app/feature/profile/pages/saved_posts_page.dart';
import 'package:cctv_app/feature/profile/pages/settings_page.dart';
import 'package:cctv_app/feature/profile/pages/terms_and_policies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:cctv_app/feature/profile/pages/user_followers_following_page.dart';
import 'package:cctv_app/core/ads/admob_banner_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name = _cachedName();
  late String _email = _cachedEmail();
  String? _profileImageUrl = AuthStorage.cachedProfileImageUrl;

  String _cachedName() {
    final first = AuthStorage.cachedFirstName?.trim() ?? '';
    final last = AuthStorage.cachedLastName?.trim() ?? '';
    final name = [
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ].join(' ');
    return name.isEmpty ? 'User' : name;
  }

  String _cachedEmail() {
    final email = AuthStorage.cachedEmail?.trim() ?? '';
    return email.isEmpty ? 'No username' : email;
  }

  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCachedProfileInfo();
    _refreshUserProfile();
  }

  Future<void> _loadCachedProfileInfo() async {
    final info = await _loadFallbackProfileInfo();
    if (!mounted) return;
    setState(() {
      _name = info['name'] ?? '';
      _email = info['email'] ?? 'No username';
      _profileImageUrl = info['profileImageUrl'];
    });
  }

  Future<UserProfile?> _loadUserProfile() async {
    final storage = const AuthStorage();
    final accessToken = await storage.readAccessToken();
    final userId = await storage.readUserId();

    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        userId == null) {
      return null;
    }

    try {
      return const UserService().getUserById(
        accessToken: accessToken,
        userId: userId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshUserProfile() async {
    try {
      final storage = const AuthStorage();
      final uid = await storage.readFirebaseUid() ?? AuthStorage.cachedFirebaseUid;
      if (uid == null) return;

      final profileMap = await FirestoreDataService().getUserProfile(uid);
      if (profileMap == null) return;

      final firstName = profileMap['firstName'] ?? profileMap['first_name'] ?? '';
      final lastName = profileMap['lastName'] ?? profileMap['last_name'] ?? '';
      final email = profileMap['email'] ?? profileMap['user_email'] ?? '';
      final profileImageUrl = profileMap['profileImageUrl'] ?? profileMap['profile_image_url'] ?? '';

      final name = [
        if (firstName.trim().isNotEmpty) firstName.trim(),
        if (lastName.trim().isNotEmpty) lastName.trim(),
      ].join(' ');

      final currentDashboardType = await storage.readDashboardType();
      final profileUserId = profileMap['user_id'] ?? profileMap['userId'];
      final userId = profileUserId is int
          ? profileUserId
          : (int.tryParse('$profileUserId') ?? (await storage.readUserId()) ?? uid.hashCode);
      final roleId = await storage.readRoleId() ?? 1;
      final roleDescription = profileMap['role'] ?? 'user';
      
      final followStats = await FirestoreDataService().getFollowStats(userId);

      await storage.saveAuth(
        accessToken: (await storage.readAccessToken()) ?? '',
        userId: userId,
        roleId: roleId,
        roleDescription: roleDescription,
        firstName: firstName,
        lastName: lastName,
        email: email,
        profileImageUrl: profileImageUrl,
        dashboardType: currentDashboardType ?? DashboardType.user,
        firebaseUid: uid,
      );

      if (!mounted) return;
      setState(() {
        _name = name.isEmpty ? 'User' : name;
        _email = email.isEmpty ? 'No username' : email;
        _profileImageUrl = profileImageUrl;
        _followersCount = followStats['followersCount'] ?? 0;
        _followingCount = followStats['followingCount'] ?? 0;
      });
    } catch (e) {
      print("Error refreshing profile: $e");
    }
  }

  Future<Map<String, String>> _loadFallbackProfileInfo() async {
    final storage = const AuthStorage();
    final first = (await storage.readFirstName() ?? '').trim();
    final last = (await storage.readLastName() ?? '').trim();
    final email = (await storage.readEmail() ?? '').trim();
    final profileImageUrl = (await storage.readProfileImageUrl() ?? '').trim();
    final name = [
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ].join(' ');
    return {
      'name': name.isEmpty ? 'User' : name,
      'email': email.isEmpty ? 'No username' : email,
      'profileImageUrl': profileImageUrl,
    };
  }

  Widget _buildProfileHeader(BuildContext context) {
    final imageUrl = _profileImageUrl?.trim() ?? '';

    final defaultAvatar = Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        color: kLightGreyColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 38,
        color: kDarkGreyColor,
      ),
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => defaultAvatar,
                )
              : defaultAvatar,
        ),
        Space.vertical(8),
        Text(
          _name,
          style: context.bold.copyWith(fontSize: 18),
        ),
        Text(
          _email,
          style: context.normal.copyWith(
            fontSize: 13,
            color: kDarkGreyColor,
          ),
        ),
        Space.vertical(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                final userId = await const AuthStorage().readUserId();
                if (userId != null && mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFollowersFollowingPage(
                        userId: userId,
                        initialTabIndex: 0, // Followers
                      ),
                    ),
                  );
                  _refreshUserProfile();
                }
              },
              child: Column(
                children: [
                  Text(
                    '$_followersCount',
                    style: context.bold.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Followers',
                    style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                  ),
                ],
              ),
            ),
            Space.horizontal(32),
            GestureDetector(
              onTap: () async {
                final userId = await const AuthStorage().readUserId();
                if (userId != null && mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFollowersFollowingPage(
                        userId: userId,
                        initialTabIndex: 1, // Following
                      ),
                    ),
                  );
                  _refreshUserProfile();
                }
              },
              child: Column(
                children: [
                  Text(
                    '$_followingCount',
                    style: context.bold.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Following',
                    style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      bottomNavigationBar: AdMobBannerWidget(),
      body: Container(
        color: kWhiteColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Space.vertical(40),
                  SizedBox(
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            "My Profile",
                            style: context.bold.copyWith(fontSize: 18),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: _buildTopIconButton(
                            icon: Icons.settings_outlined,
                            iconSize: 22,
                            iconColor: kDarkGreyColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Space.vertical(8),
                  Center(child: _buildProfileHeader(context)),
                  Space.vertical(16),
                  Text(
                    "Account setting",
                    style: context.bold.copyWith(fontSize: 22),
                  ),
                  Space.vertical(12),
                  _buildSettingRow(
                    icon: Icons.person_outline,
                    text: "Edit profile",
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfilePage(),
                        ),
                      );
                      if (updated == true) {
                        await _loadCachedProfileInfo();
                      }
                    },
                  ),
                  _buildSettingRow(
                    icon: Icons.help_outline,
                    text: "Help & Support",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpAndSupport(),
                        ),
                      );
                    },
                  ),
                  _buildSettingRow(
                    icon: Icons.bookmark_border_outlined,
                    text: "Saved Posts",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedPostsPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingRow(
                    icon: Assets.svgTermAndPoliciesIcon,
                    text: "Terms and Policies",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndPolicies(),
                        ),
                      );
                    },
                  ),
                  _buildSettingRow(
                    icon: Assets.svgLogoutIcon,
                    text: "Log out",
                    onTap: () {
                      showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 24,
    Color iconColor = kBlackColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  Widget _buildSettingRow({
    required dynamic icon, // Can be IconData or String (SVG path)
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                if (icon is IconData)
                  Icon(icon, color: kPrimaryColor, size: 23)
                else if (icon is String)
                  SvgPicture.asset(
                    icon,
                    width: 23,
                    height: 23,
                    colorFilter: const ColorFilter.mode(
                      kPrimaryColor,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  Icon(Icons.help_outline, color: kPrimaryColor, size: 23),
                Space.horizontal(20),
                Text(
                  text,
                  style: context.normal.copyWith(
                    fontSize: 14,
                    color: kBlackColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void showLogoutDialog(BuildContext context) {
    AppBottomSheet.show(
      context,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔴 Title Text
            const Text(
              "Are you sure you want\nto logout?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ❌ Cancel Button
            PrimaryButton(
              text: "Cancel",
              borderColor: kGreyColor,
              textColor: kBlackColor,
              buttonColor: kWhiteColor,
              showBorder: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Space.vertical(12),

            // ✅ Yes Button
            PrimaryButton(
              text: "Logout",
              onPressed: () async {
                await AppSessionManager.instance.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
