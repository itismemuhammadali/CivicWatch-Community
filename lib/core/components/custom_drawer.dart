import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/app_bottom_sheet.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/storage/app_settings_storage.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/drawer/pages/post_history.dart';
import 'package:cctv_app/feature/pending/pages/pending_page.dart';
import 'package:cctv_app/feature/profile/pages/help_and_support.dart';
import 'package:cctv_app/feature/profile/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onRunningCaseTap;

  const CustomDrawer({super.key, this.onHomeTap, this.onRunningCaseTap});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  static const Set<String> _countryOptions = {
    'English',
    'German',
    'Chinese',
    'Russian',
  };

  late String selectedLang = _cachedSelectedCountry();
  late String displayName = _cachedDisplayName();
  String? profileImageUrl = AuthStorage.cachedProfileImageUrl?.trim();

  String _cachedSelectedCountry() {
    final userId = AuthStorage.cachedUserId;
    final cachedCountry = userId == null
        ? null
        : AppSettingsStorage.cachedDrawerCountry(userId);
    if (cachedCountry != null && _countryOptions.contains(cachedCountry)) {
      return cachedCountry;
    }
    return 'English';
  }

  String _cachedDisplayName() {
    final first = AuthStorage.cachedFirstName?.trim() ?? '';
    final last = AuthStorage.cachedLastName?.trim() ?? '';
    final name = [
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ].join(' ');
    return name.isEmpty ? 'User' : name;
  }

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final storage = const AuthStorage();
    final settingsStorage = const AppSettingsStorage();
    await storage.hydrateCache();
    final accessToken = await storage.readAccessToken();
    final userId = await storage.readUserId();
    final first = await storage.readFirstName();
    final last = await storage.readLastName();
    final savedCountry = userId == null
        ? null
        : await settingsStorage.readDrawerCountry(userId);
    final name = [
      if (first != null && first.trim().isNotEmpty) first.trim(),
      if (last != null && last.trim().isNotEmpty) last.trim(),
    ].join(' ');
    String? resolvedProfileImageUrl;

    if (accessToken != null &&
        accessToken.trim().isNotEmpty &&
        userId != null) {
      try {
        final profile = await const UserService().getUserById(
          accessToken: accessToken,
          userId: userId,
        );
        resolvedProfileImageUrl = profile.applicationMeta?.metaUrl?.trim();
        final dashboardType = await storage.readDashboardType();
        await storage.saveAuth(
          accessToken: accessToken,
          userId: userId,
          roleId: profile.roleId,
          roleDescription: profile.roleDescription,
          firstName: profile.firstName,
          lastName: profile.lastName,
          email: profile.email,
          profileImageUrl: resolvedProfileImageUrl,
          dashboardType: dashboardType ?? DashboardType.user,
        );
      } catch (_) {
        resolvedProfileImageUrl = null;
      }
    }

    if (!mounted) return;
    setState(() {
      displayName = name.isEmpty ? displayName : name;
      if (savedCountry != null && _countryOptions.contains(savedCountry)) {
        selectedLang = savedCountry;
      }
      profileImageUrl =
          resolvedProfileImageUrl ??
          AuthStorage.cachedProfileImageUrl?.trim() ??
          profileImageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      backgroundColor: kWhiteColor,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Profile Header
            GestureDetector(
              onTap: () {},
              child: Container(
                decoration: const BoxDecoration(color: kTransparentColor),
                padding: const EdgeInsets.fromLTRB(8, 16, 12, 22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: kTextfieldBlueColor,
                      backgroundImage:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      onBackgroundImageError:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? (_, __) {}
                          : null,
                      child:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? null
                          : Text(
                              _buildInitials(displayName),
                              style: context.bold.copyWith(
                                color: kWhiteColor,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    Space.horizontal(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bold.copyWith(fontSize: 13),
                          ),
                          Space.vertical(6),
                          Text(
                            "Online",
                            style: context.normal.copyWith(
                              color: kDarkGreyColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Drawer Items
            _buildDrawerItem(
              leading: Image.asset(Assets.pngHomeImage, width: 20, height: 20),
              text: "Home",
              onTap: () {
                Navigator.pop(context);
                widget.onHomeTap?.call();
              },
            ),
            _buildDrawerItem(
              leading: Image.asset(Assets.pngFileImage, width: 20, height: 20),
              text: "Post History",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostHistory()),
                );
              },
            ),
            _buildLanguageDropdown(context),
            _buildDrawerItem(
              leading: Image.asset(
                Assets.pngRedirectImage,
                width: 20,
                height: 20,
              ),
              text: "Invite Friends",
              onTap: _showInviteFriendsSheet,
            ),
            _buildDrawerItem(
              leading: SvgPicture.asset(
                Assets.svgGroupIcon,
                width: 20,
                height: 20,
              ),
              text: "Running Case",
              onTap: _openRunningCase,
            ),
            _buildDrawerItem(
              leading: Image.asset(Assets.pngInfoImage, width: 20, height: 20),
              text: "Help & Support",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpAndSupport()),
                );
              },
            ),
            _buildDrawerItem(
              leading: Image.asset(
                Assets.pngSettingImage,
                width: 20,
                height: 20,
              ),
              text: "Setting",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),

            // ✅ Logout Button at the End
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0085FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      showLogoutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/logout icon.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              kWhiteColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: context.semiBold.copyWith(
                              fontSize: 14,
                              color: kWhiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRunningCase() {
    final navigator = Navigator.of(context);
    navigator.pop();

    if (widget.onRunningCaseTap != null) {
      widget.onRunningCaseTap!();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.push(MaterialPageRoute(builder: (_) => const PendingPage()));
    });
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
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
                  text: "Yes",
                  onPressed: () async {
                    await AppSessionManager.instance.logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInviteFriendsSheet() {
    AppBottomSheet.show(
      context,
      borderRadius: 28,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Friends',
              style: context.bold.copyWith(fontSize: 20),
            ),
            Space.vertical(6),
            Text(
              'Share Cctv with your friends.',
              style: context.normal.copyWith(color: kDarkGreyColor),
            ),
            Space.vertical(18),
            _buildInviteOption(
              icon: const Icon(Icons.share_outlined, size: 20),
              title: 'More',
              onTap: () => _shareInvite('system'),
            ),
            _buildInviteOption(
              icon: SvgPicture.asset(Assets.svgWhatsappIcon),
              title: 'Whatsapp',
              onTap: () => _shareInvite('whatsapp'),
            ),
            _buildInviteOption(
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              title: 'Instagram',
              onTap: () => _shareInvite('instagram'),
            ),
            _buildInviteOption(
              icon: SvgPicture.asset(Assets.svgTwitterIcon),
              title: 'Twitter/X',
              onTap: () => _shareInvite('twitter'),
            ),
            _buildInviteOption(
              icon: SvgPicture.asset(Assets.svgCopyIcon),
              title: 'Copy Link',
              onTap: () => _shareInvite('copy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteOption({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(width: 28, height: 28, child: Center(child: icon)),
      title: Text(title, style: context.semiBold.copyWith(fontSize: 16)),
      onTap: onTap,
    );
  }

  Future<void> _shareInvite(String target) async {
    final shareText =
        'Join me on Cctv and check out the latest community updates.\n\n'
        '${ApiConfig.baseUrl}';

    Navigator.pop(context);

    try {
      switch (target) {
        case 'copy':
          await Clipboard.setData(
            const ClipboardData(text: ApiConfig.baseUrl),
          );
          if (mounted) {
            AppAlert.showInfo(context, 'Invite link copied to clipboard');
          }
          return;
        case 'whatsapp':
          await _launchWithFallbacks([
            Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareText)}'),
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}'),
          ]);
          return;
        case 'instagram':
          await _launchWithFallbacks([
            Uri.parse('instagram://app'),
            Uri.parse('https://www.instagram.com/'),
          ]);
          return;
        case 'twitter':
          await _launchWithFallbacks([
            Uri.parse(
              'twitter://post?message=${Uri.encodeComponent(shareText)}',
            ),
            Uri.parse('x://post?message=${Uri.encodeComponent(shareText)}'),
            Uri.parse(
              'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}',
            ),
            Uri.parse(
              'https://x.com/intent/post?text=${Uri.encodeComponent(shareText)}',
            ),
          ]);
          return;
        case 'system':
        default:
          await Share.share(shareText, subject: 'Join me on Cctv');
      }
    } catch (_) {
      if (mounted) {
        AppAlert.showError(context, 'Unable to share invite right now');
      }
    }
  }

  Future<void> _launchWithFallbacks(List<Uri> uris) async {
    for (final uri in uris) {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (didLaunch) return;
    }

    throw Exception('Unable to launch share target');
  }

  Future<void> _saveSelectedCountry(String value) async {
    final userId = await const AuthStorage().readUserId();
    if (userId == null) return;

    await const AppSettingsStorage().writeDrawerCountry(userId, value);
  }

  Widget _buildDrawerItem({
    required Widget leading,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 0.7, color: Color(0xFFE9E9E9)),
        SizedBox(
          height: 52,
          child: ListTile(
            dense: true,
            minLeadingWidth: 20,
            horizontalTitleGap: 18,
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            visualDensity: VisualDensity.compact,
            leading: leading,
            title: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF3F3F3F),
              ),
            ),
            onTap: onTap,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 0.7, color: Color(0xFFE9E9E9)),
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLang,
                isExpanded: true,
                dropdownColor: kWhiteColor,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: kBlackColor,
                  size: 20,
                ),
                items: [
                  DropdownMenuItem(
                    value: "English",
                    child: Row(
                      children: [
                        Image.asset(Assets.english, width: 16, height: 16),
                        const SizedBox(width: 18),
                        const Text(
                          "English",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "German",
                    child: Row(
                      children: [
                        Image.asset(Assets.german, width: 16, height: 16),
                        const SizedBox(width: 18),
                        const Text(
                          "German",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Chinese",
                    child: Row(
                      children: [
                        Image.asset(Assets.china, width: 16, height: 16),
                        const SizedBox(width: 18),
                        const Text(
                          "Chinese",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Russian",
                    child: Row(
                      children: [
                        Image.asset(Assets.russia, width: 16, height: 16),
                        const SizedBox(width: 18),
                        const Text(
                          "Russian",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLang = value; // 👈 update karte hain
                    });
                    _saveSelectedCountry(value);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return 'U';
  }
}
