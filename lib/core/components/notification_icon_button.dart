import 'dart:async';

import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/network/services/notification_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/app_settings_storage.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/profile/pages/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationIconButton extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final BoxDecoration decoration;
  final double iconSize;

  const NotificationIconButton({
    super.key,
    required this.padding,
    required this.decoration,
    this.iconSize = 24,
  });

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  static const String _lastSeenKeyPrefix = 'last_seen_notification_id';

  final AppSettingsStorage _settingsStorage = const AppSettingsStorage();
  StreamSubscription<AppWebSocketEvent>? _subscription;
  bool _showDot = false;
  int? _latestNotificationId;

  @override
  void initState() {
    super.initState();
    _bindWebSocketEvents();
    unawaited(_loadInitialBadgeState());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _bindWebSocketEvents() {
    _subscription = AppWebSocketService.instance
        .eventsFor(notificationRefreshEventTypes)
        .listen((_) {
          if (!mounted) return;
          setState(() {
            _showDot = true;
          });
          unawaited(_loadInitialBadgeState(markExistingAsSeen: false));
        });
  }

  Future<void> _loadInitialBadgeState({bool markExistingAsSeen = true}) async {
    final storage = const AuthStorage();
    final userId = await storage.readUserId();
    final accessToken = await storage.readAccessToken();
    if (userId == null || accessToken == null || accessToken.trim().isEmpty) {
      return;
    }

    try {
      final notificationService = NotificationService();
      final notifications = await notificationService
          .getAppNotificationsByUserId(
        userId: userId,
        accessToken: accessToken,
        limit: 1,
      );
      if (notifications.isEmpty) return;

      final latest = notifications.first;
      final latestId = latest.notificationId;
      final key = _lastSeenKey(userId);
      final lastSeenId = await _settingsStorage.readInt(key);
      final hasUnreadStatus = _isUnread(latest);
      final isAfterLastSeen = latestId > (lastSeenId ?? 0);
      final isNew = lastSeenId != null && isAfterLastSeen;

      if (lastSeenId == null && markExistingAsSeen && !hasUnreadStatus) {
        await _settingsStorage.writeInt(key, latestId);
      }

      if (!mounted) return;
      setState(() {
        _latestNotificationId = latestId;
        _showDot =
            (hasUnreadStatus && isAfterLastSeen) ||
            isNew ||
            (!markExistingAsSeen && isAfterLastSeen);
      });
    } catch (_) {
      // Badge state should never block rendering the home header.
    }
  }

  bool _isUnread(AppNotificationItem notification) {
    final status = notification.notificationStatus?.trim().toUpperCase() ?? '';
    if (status.isEmpty) return false;
    return !{'R', 'READ', 'SEEN', 'VIEWED', 'V'}.contains(status);
  }

  String _lastSeenKey(int userId) => '${_lastSeenKeyPrefix}_$userId';

  Future<void> _openNotifications() async {
    setState(() {
      _showDot = false;
    });

    final userId = await const AuthStorage().readUserId();
    final latestId = _latestNotificationId;
    if (userId != null && latestId != null) {
      await _settingsStorage.writeInt(_lastSeenKey(userId), latestId);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
    unawaited(_loadInitialBadgeState());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: widget.decoration,
            padding: widget.padding,
            child: SvgPicture.asset(
              Assets.svgNotificationIcon,
              width: widget.iconSize,
              height: widget.iconSize,
            ),
          ),
          if (_showDot)
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: kRedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kWhiteColor, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
