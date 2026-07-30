enum AppWebSocketEventType {
  interaction('INTERACTION_EVENT'),
  reel('REEL_EVENT'),
  notification('NOTIFICATION_EVENT'),
  post('POST_EVENT'),
  comment('COMMENT_EVENT'),
  poll('POLL_EVENT'),
  userStatus('USER_STATUS_EVENT'),
  unknown('');

  final String value;

  const AppWebSocketEventType(this.value);

  static AppWebSocketEventType fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final type in AppWebSocketEventType.values) {
      if (type.value == normalized) {
        return type;
      }
    }
    return AppWebSocketEventType.unknown;
  }
}

class AppWebSocketEvent {
  final String id;
  final String scope;
  final AppWebSocketEventType type;
  final int? userId;
  final Map<String, dynamic> data;
  final Map<String, dynamic> meta;

  const AppWebSocketEvent({
    required this.id,
    required this.scope,
    required this.type,
    required this.userId,
    required this.data,
    required this.meta,
  });

  factory AppWebSocketEvent.fromJson(Map<String, dynamic> json) {
    return AppWebSocketEvent(
      id: json['id'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      type: AppWebSocketEventType.fromValue(json['type'] as String?),
      userId: int.tryParse('${json['user_id']}'),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map<String, dynamic>)
          : const {},
      meta: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
          : const {},
    );
  }

  int? get postId => int.tryParse('${data['post_id']}');
}

const Set<AppWebSocketEventType> postRefreshEventTypes = {
  AppWebSocketEventType.interaction,
  AppWebSocketEventType.post,
  AppWebSocketEventType.comment,
  AppWebSocketEventType.poll,
};

const Set<AppWebSocketEventType> reelRefreshEventTypes = {
  AppWebSocketEventType.reel,
};

const Set<AppWebSocketEventType> notificationRefreshEventTypes = {
  AppWebSocketEventType.notification,
};

const Set<AppWebSocketEventType> userStatusEventTypes = {
  AppWebSocketEventType.userStatus,
};
