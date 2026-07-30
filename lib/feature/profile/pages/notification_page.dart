import 'dart:async';

import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/network/services/notification_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/pending/pages/pending_case_response_page.dart';
import 'package:cctv_app/feature/profile/pages/notification_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static List<AppNotificationItem> _notificationCache = const [];

  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotificationItem> _notifications = const [];
  StreamSubscription<AppWebSocketEvent>? _notificationEventSubscription;
  bool _refreshQueued = false;

  String _notificationThumbnailUrl(AppNotificationItem notification) {
    if (notification.isReminder) {
      return '';
    }
    return notification.parsedMeta?.mediaUrl?.trim() ?? '';
  }

  String _formatNotificationTimestamp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
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

    final month = months[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$month ${parsed.day}, ${parsed.year} - $hour:$minute $suffix';
  }

  @override
  void initState() {
    super.initState();
    _notifications = _notificationCache;
    _isLoading = _notifications.isEmpty;
    _bindWebSocketEvents();
    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationEventSubscription?.cancel();
    super.dispose();
  }

  void _bindWebSocketEvents() {
    _notificationEventSubscription?.cancel();
    _notificationEventSubscription = AppWebSocketService.instance
        .eventsFor(notificationRefreshEventTypes)
        .listen((_) => _scheduleNotificationsRefresh());
  }

  void _scheduleNotificationsRefresh() {
    if (!mounted) return;
    if (_isLoading) {
      _refreshQueued = true;
      return;
    }
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = _notifications.isEmpty;
      _errorMessage = null;
    });

    try {
      final userId = await const AuthStorage().readUserId();
      final accessToken = await const AuthStorage().readAccessToken();
      if (userId == null || accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session user not found');
      }

      final service = NotificationService();
      final notifications = await service.getAppNotificationsByUserId(
        userId: userId,
        accessToken: accessToken,
        limit: 50,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _notificationCache = notifications;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load notifications';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (_refreshQueued) {
        _refreshQueued = false;
        _loadNotifications();
      }
    }
  }

  void _openNotification(AppNotificationItem notification) {
    final Widget destination;
    if (notification.opensSimpleNotification) {
      destination = NotificationDetailPage(notification: notification);
    } else if (notification.opensCaseResponse) {
      destination = PendingCaseResponsePage(
        caseId: notification.parsedMeta?.caseId ?? 0,
      );
    } else {
      destination = NotificationDetailPage(notification: notification);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        title: Text("Notifications"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SvgPicture.asset(Assets.svgDoubleTickIcon),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(color: kRedColor),
            ),
            Space.vertical(12),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return emptyNotification(context);
    }

    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: kGreyColor, thickness: 1),
      ),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final createdAt = _formatNotificationTimestamp(notification.createdAt);
        final isReminder = notification.isReminder;
        final thumbnailUrl = _notificationThumbnailUrl(notification);
        return GestureDetector(
          onTap: () => _openNotification(notification),
          child: Container(
            color: kTransparentColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationUserAvatar(notification: notification),
                Space.horizontal(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: context.bold.copyWith(fontSize: 16),
                      ),
                      Text(notification.message),
                      if (createdAt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            createdAt,
                            style: context.normal.copyWith(
                              fontSize: 12,
                              color: kDarkGreyColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isReminder && thumbnailUrl.isNotEmpty) ...[
                  Space.horizontal(12),
                  _NotificationThumbnail(
                    imageUrl: thumbnailUrl,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget emptyNotification(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: SvgPicture.asset(Assets.svgNotificationImage)),
        Space.vertical(20),
        Text(
          "No Notification yet",
          style: context.normal.copyWith(fontSize: 20),
        ),
      ],
    );
  }
}

class _NotificationThumbnail extends StatelessWidget {
  final String imageUrl;

  const _NotificationThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _NotificationUserAvatar extends StatelessWidget {
  final AppNotificationItem notification;

  const _NotificationUserAvatar({required this.notification});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = notification.userAvatarUrl?.trim() ?? '';
    final name = notification.userFullName;
    final initials = _buildInitials(name);

    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: context.bold.copyWith(
          fontSize: 13,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
