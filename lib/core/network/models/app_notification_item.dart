import 'package:cctv_app/core/network/models/app_notification_meta.dart';

class AppNotificationItem {
  final int notificationId;
  final int? userId;
  final String? notificationType;
  final String? notificationStatus;
  final String? viewType;
  final String title;
  final String message;
  final String? notificationMeta;
  final AppNotificationMeta? parsedMeta;
  final String? createdAt;
  final String? userFirstName;
  final String? userLastName;
  final String? userAvatarUrl;

  const AppNotificationItem({
    required this.notificationId,
    this.userId,
    this.notificationType,
    this.notificationStatus,
    this.viewType,
    required this.title,
    required this.message,
    this.notificationMeta,
    this.parsedMeta,
    this.createdAt,
    this.userFirstName,
    this.userLastName,
    this.userAvatarUrl,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final notificationId = json['notification_id'];
    final userId = json['user_id'];
    final detail = (json['notification_detail'] as String?)?.trim();
    final type = (json['notification_type'] as String?)?.trim();
    final status = (json['notification_status'] as String?)?.trim();
    final viewType = (json['view_type'] as String?)?.trim();
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final profileMeta = user?['profile_meta'] is Map<String, dynamic>
        ? user!['profile_meta'] as Map<String, dynamic>
        : null;

    return AppNotificationItem(
      notificationId: notificationId is int
          ? notificationId
          : int.parse('$notificationId'),
      userId: userId == null ? null : int.tryParse('$userId'),
      notificationType: type,
      notificationStatus: status,
      viewType: viewType,
      title: _titleFromType(type),
      message: detail == null || detail.isEmpty
          ? 'No details available'
          : detail,
      notificationMeta: json['notification_meta'] as String?,
      parsedMeta: AppNotificationMeta.tryParse(json['notification_meta']),
      createdAt: json['created_at'] as String?,
      userFirstName: user?['first_name'] as String?,
      userLastName: user?['last_name'] as String?,
      userAvatarUrl: profileMeta?['meta_url'] as String?,
    );
  }

  String get userFullName =>
      '${userFirstName?.trim() ?? ''} ${userLastName?.trim() ?? ''}'.trim();

  bool get isReminder {
    final combined = [
      notificationType,
      title,
      message,
    ].whereType<String>().join(' ').toLowerCase();

    return combined.contains('remind') || combined.contains('reminder');
  }

  bool get opensSimpleNotification => viewType?.toUpperCase() == 'SN';

  bool get opensCaseResponse => viewType?.toUpperCase() == 'RN';

  static String _titleFromType(String? type) {
    return switch (type) {
      'U' => 'Notification',
      'A' => 'Alert',
      'P' => 'Post',
      _ => 'Notification',
    };
  }
}
