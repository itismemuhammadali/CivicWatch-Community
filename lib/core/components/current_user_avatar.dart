import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class CurrentUserAvatar extends StatefulWidget {
  final double radius;
  final VoidCallback? onTap;

  const CurrentUserAvatar({
    super.key,
    this.radius = 24,
    this.onTap,
  });

  @override
  State<CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<CurrentUserAvatar> {
  late String _name = _cachedName();
  String? _imageUrl = AuthStorage.cachedProfileImageUrl;

  String _cachedName() {
    final first = AuthStorage.cachedFirstName?.trim() ?? '';
    final last = AuthStorage.cachedLastName?.trim() ?? '';
    final name = [
      if (first.isNotEmpty) first,
      if (last.isNotEmpty) last,
    ].join(' ');
    return name;
  }

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _refreshUserProfile();
  }

  Future<void> _loadCachedProfile() async {
    final name = await _loadFallbackName();
    final imageUrl = (await const AuthStorage().readProfileImageUrl())?.trim();
    if (!mounted) return;
    setState(() {
      _name = name;
      _imageUrl = imageUrl;
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
      return await const UserService().getUserById(
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
    final imageUrl = profile.applicationMeta?.metaUrl?.trim();

    final storage = const AuthStorage();
    final dashboardType = await storage.readDashboardType();
    await storage.saveAuth(
      accessToken: (await storage.readAccessToken()) ?? '',
      userId: profile.userId,
      roleId: profile.roleId,
      roleDescription: profile.roleDescription,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      profileImageUrl: imageUrl,
      dashboardType: dashboardType ?? DashboardType.user,
    );

    if (!mounted) return;
    setState(() {
      _name = name;
      _imageUrl = imageUrl;
    });
  }

  Future<String> _loadFallbackName() async {
    final storage = const AuthStorage();
    final first = (await storage.readFirstName() ?? '').trim();
    final last = (await storage.readLastName() ?? '').trim();
    final name = [if (first.isNotEmpty) first, if (last.isNotEmpty) last]
        .join(' ')
        .trim();
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl?.trim() ?? '';
    final isNetwork = imageUrl.isNotEmpty && !imageUrl.startsWith('assets/');
    final avatar = imageUrl.isNotEmpty
        ? CircleAvatar(
            radius: widget.radius,
            backgroundColor: kTextfieldBlueColor,
            backgroundImage: imageUrl.startsWith('assets/')
                ? AssetImage(imageUrl)
                : NetworkImage(imageUrl),
            onBackgroundImageError: isNetwork
                ? (_, __) {
                    if (!mounted) return;
                    setState(() {
                      _imageUrl = null;
                    });
                  }
                : null,
            child: isNetwork ? null : null,
          )
        : _InitialAvatar(radius: widget.radius, name: _name);

    if (widget.onTap == null) {
      return avatar;
    }

    return GestureDetector(onTap: widget.onTap, child: avatar);
  }
}

class _InitialAvatar extends StatelessWidget {
  final double radius;
  final String name;

  const _InitialAvatar({
    required this.radius,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        _buildInitials(name),
        style: TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.42,
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.length == 1) {
      final part = parts.first;
      return part.substring(0, part.length >= 2 ? 2 : 1).toUpperCase();
    }

    return 'U';
  }
}
