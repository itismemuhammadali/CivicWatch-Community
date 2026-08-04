import 'package:cctv_app/core/components/super_admin_top_header.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adAdmin/pages/add_new_admin_page.dart';
import 'package:cctv_app/feature/adAdmin/pages/admin_profile_page.dart';
import 'package:cctv_app/feature/adAdmin/pages/view_all_admin_page.dart';
import 'package:cctv_app/feature/adAdmin/widget/admin_container_widget.dart';
import 'package:cctv_app/feature/adAdmin/widget/view_all_widget.dart';
import 'package:flutter/material.dart';

class AdAdminPage extends StatefulWidget {
  const AdAdminPage({super.key});

  @override
  State<AdAdminPage> createState() => _AdAdminPageState();
}

class _AdAdminPageState extends State<AdAdminPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserProfile> _recentAdmins = const [];
  List<UserProfile> _allAdmins = const [];

  List<UserProfile> get _activeAdmins {
    return _allAdmins
        .where((admin) => (admin.isActive ?? '').toUpperCase() == 'Y')
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      final currentUserId = await const AuthStorage().readUserId();
      var admins = await const UserService().getAllAdminsWithProfiles(
        accessToken: token,
      );

      if (currentUserId != null) {
        admins = admins
            .where((admin) => admin.userId != currentUserId)
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _recentAdmins = admins.take(4).toList();
        _allAdmins = admins;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load admins';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openViewAll({
    required String title,
    required List<UserProfile> admins,
    bool showOnlineStatus = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllAdminPage(
          title: title,
          admins: admins,
          showOnlineStatus: showOnlineStatus,
        ),
      ),
    );
  }

  Widget _buildAdminRow(
    List<UserProfile> admins, {
    bool showOnlineStatus = false,
  }) {
    if (admins.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No admins found',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(admins.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == admins.length - 1 ? 0 : 12,
            ),
            child: AdminContainerWidget(
              admin: admins[index],
              showOnlineStatus: showOnlineStatus,
              onAdminDeleted: _loadAdmins,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAdminList(List<UserProfile> admins) {
    if (admins.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No admins found',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return Column(
      children: List.generate(admins.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == admins.length - 1 ? 0 : 10),
          child: AdminListTile(
            admin: admins[index],
            onAdminDeleted: _loadAdmins,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SuperAdminTopHeader(),
            Space.vertical(16),
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                height: 34,
                isMainAxisSizeMin: true,
                text: "Add new Admin",
                postfixIcon: const Icon(Icons.person, color: kWhiteColor),
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewAdminPage(),
                    ),
                  );

                  if (created == true) {
                    _loadAdmins();
                  }
                },
              ),
            ),
            Space.vertical(8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: context.normal.copyWith(color: kDarkGreyColor),
                      textAlign: TextAlign.center,
                    ),
                    Space.vertical(12),
                    PrimaryButton(
                      height: 38,
                      isMainAxisSizeMin: true,
                      text: 'Retry',
                      onPressed: _loadAdmins,
                    ),
                  ],
                ),
              )
            else ...[
              ViewAllWidget(
                text: "Recent add",
                onClickViewAll: () {
                  _openViewAll(title: 'Recent add', admins: _recentAdmins);
                },
              ),
              _buildAdminRow(_recentAdmins),
              Space.vertical(8),
              ViewAllWidget(
                text: "Active admin",
                onClickViewAll: () {
                  _openViewAll(
                    title: 'Active admin',
                    admins: _activeAdmins,
                    showOnlineStatus: true,
                  );
                },
              ),
              _buildAdminRow(_activeAdmins, showOnlineStatus: true),
              Space.vertical(8),
              ViewAllWidget(
                text: "Admin",
                onClickViewAll: () {
                  _openViewAll(title: 'Admin', admins: _allAdmins);
                },
              ),
              _buildAdminList(_allAdmins),
            ],
            Space.vertical(20),
          ],
        ),
      ),
    );
  }
}

class AdminListTile extends StatelessWidget {
  final UserProfile admin;
  final VoidCallback? onAdminDeleted;

  const AdminListTile({super.key, required this.admin, this.onAdminDeleted});

  String get _displayName {
    final fullName = '${admin.firstName} ${admin.lastName}'.trim();
    if (fullName.isNotEmpty && fullName != '-') {
      return fullName;
    }
    return admin.email;
  }

  String _buildTimeLabel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Recently added';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'pm' : 'am';
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year} $hour:$minute $suffix';
  }

  String _buildInitials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = admin.applicationMeta?.metaUrl?.trim();
    final status = (admin.isActive ?? '').toUpperCase() == 'Y'
        ? 'Online'
        : 'Offline';

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kGreyColor),
      ),
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () async {
          final deleted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProfilePage(admin: admin),
            ),
          );
          if (deleted == true) {
            onAdminDeleted?.call();
          }
        },
        child: Row(
          children: [
            avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      avatarUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _FallbackAvatar(
                        initials: _buildInitials(_displayName),
                      ),
                    ),
                  )
                : _FallbackAvatar(initials: _buildInitials(_displayName)),
            Space.horizontal(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: context.bold.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Space.vertical(8),
                  Text(
                    '$status - ${_buildTimeLabel(admin.createdAt)}',
                    overflow: TextOverflow.ellipsis,
                    style: context.normal.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'email') {
                  AppAlert.showSuccess(
                    context,
                    admin.email.trim().isEmpty
                        ? 'No email available'
                        : admin.email,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'email',
                  child: Text('Show email'),
                ),
              ],
              child: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initials;

  const _FallbackAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: kTextfieldBlueColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: context.bold.copyWith(color: kPrimaryColor, fontSize: 24),
      ),
    );
  }
}
