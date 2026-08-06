import 'package:cctv_app/core/components/app_bottom_sheet.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/drawer/pages/user_profile_page.dart';
import 'package:cctv_app/feature/profile/pages/help_and_support.dart';
import 'package:cctv_app/feature/profile/pages/terms_and_policies.dart';
import 'package:cctv_app/feature/profile/widget/profile_tile.dart';
import 'package:flutter/material.dart';

class AdProfilePage extends StatefulWidget {
  const AdProfilePage({super.key});

  @override
  State<AdProfilePage> createState() => _AdProfilePageState();
}

class _AdProfilePageState extends State<AdProfilePage> {
  late String _name = _cachedName();
  late String _email = _cachedEmail();

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
    });
  }

  Future<UserProfile?> _loadUserProfile() async {
    final storage = const AuthStorage();
    final accessToken = await storage.readAccessToken();
    final userId = await storage.readUserId();

    if (accessToken == null || accessToken.trim().isEmpty || userId == null) {
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
    final profile = await _loadUserProfile();
    if (profile == null) return;

    final name = [
      if (profile.firstName.trim().isNotEmpty) profile.firstName.trim(),
      if (profile.lastName.trim().isNotEmpty) profile.lastName.trim(),
    ].join(' ').trim();
    final email = profile.email.trim();

    final storage = const AuthStorage();
    final dashboardType = await storage.readDashboardType();
    await storage.saveAuth(
      accessToken: (await storage.readAccessToken()) ?? '',
      userId: profile.userId,
      roleId: profile.roleId,
      roleDescription: profile.roleDescription,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: email,
      profileImageUrl: profile.applicationMeta?.metaUrl?.trim(),
      dashboardType: dashboardType ?? DashboardType.user,
    );

    if (!mounted) return;
    setState(() {
      _name = name.isEmpty ? 'User' : name;
      _email = email.isEmpty ? 'No username' : email;
    });
  }

  Future<Map<String, String>> _loadFallbackProfileInfo() async {
    final storage = const AuthStorage();
    final first = (await storage.readFirstName() ?? '').trim();
    final last = (await storage.readLastName() ?? '').trim();
    final email = (await storage.readEmail() ?? '').trim();
    final name = [if (first.isNotEmpty) first, if (last.isNotEmpty) last]
        .join(' ')
        .trim();

    return {
      'name': name.isEmpty ? 'User' : name,
      'email': email.isEmpty ? 'No username' : email,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("My Profile", style: context.bold.copyWith(fontSize: 20)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Space.vertical(20),
                      Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: kLightGreyColor,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: kDarkGreyColor,
                            ),
                          ),
                          Space.vertical(15),
                          Text(
                            _name,
                            style: context.bold.copyWith(fontSize: 20),
                          ),
                          Text(
                            _email,
                            style: context.normal.copyWith(
                              fontSize: 16,
                              color: kDarkGreyColor,
                            ),
                          ),
                        ],
                      ),
                      Space.vertical(20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Account Settings",
                          style: context.normal.copyWith(fontSize: 22),
                        ),
                      ),
                      Space.vertical(20),
                      ProfileTile(
                        text: "Edit profile",
                        icon: Assets.svgEditProfileIcon,
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfilePage(),
                            ),
                          );
                          if (updated == true) {
                            await _loadCachedProfileInfo();
                            await _refreshUserProfile();
                          }
                        },
                      ),
                      Space.vertical(8),
                      ProfileTile(
                        text: "Help & Support",
                        icon: Assets.svgHelpAndSupportIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpAndSupport(),
                            ),
                          );
                        },
                      ),
                      Space.vertical(8),
                      ProfileTile(
                        text: "Terms and Policies",
                        icon: Assets.svgTermAndPoliciesIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsAndPolicies(),
                            ),
                          );
                        },
                      ),
                      Space.vertical(8),
                      ProfileTile(
                        text: "Logout",
                        icon: Assets.svgLogoutIcon,
                        onTap: () {
                          showLogoutDialog(context);
                        },
                      ),
                      Space.vertical(8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
