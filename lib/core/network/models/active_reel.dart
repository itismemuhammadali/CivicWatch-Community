import 'package:cctv_app/core/network/models/uploaded_media.dart';

class ActiveReel {
  final int reelId;
  final int? userId;
  final int? reelMetaId;
  final String reelDescription;
  final String? isActive;
  final String? reelStartDate;
  final String? reelExpireDate;
  final int? createdBy;
  final String? createdAt;
  final UploadedMedia? applicationMeta;
  final ActiveReelUserInfo? userInfo;

  const ActiveReel({
    required this.reelId,
    this.userId,
    this.reelMetaId,
    required this.reelDescription,
    this.isActive,
    this.reelStartDate,
    this.reelExpireDate,
    this.createdBy,
    this.createdAt,
    this.applicationMeta,
    this.userInfo,
  });

  String? get mediaUrl => applicationMeta?.metaUrl;
  String get displayName {
    final fullName = userInfo?.fullName ?? '';
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    return 'User ${userId ?? createdBy ?? '-'}';
  }

  String? get userAvatarUrl => userInfo?.applicationMeta?.metaUrl;

  bool get hasMedia => (mediaUrl ?? '').trim().isNotEmpty;

  bool get isImage {
    final metaTypeId = applicationMeta?.metaTypeId;
    if (metaTypeId != null) {
      return metaTypeId == 1;
    }

    final url = mediaUrl?.toLowerCase() ?? '';
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  factory ActiveReel.fromJson(Map<String, dynamic> json) {
    final reelId = json['reel_id'];

    return ActiveReel(
      reelId: reelId is int ? reelId : int.parse('$reelId'),
      userId: int.tryParse('${json['user_id']}'),
      reelMetaId: int.tryParse('${json['reel_meta_id']}'),
      reelDescription: json['reel_description'] as String? ?? '',
      isActive: json['is_active'] as String?,
      reelStartDate: json['reel_start_date'] as String?,
      reelExpireDate: json['reel_expire_date'] as String?,
      createdBy: int.tryParse('${json['created_by']}'),
      createdAt: json['created_at'] as String?,
      applicationMeta: json['application_meta'] is Map<String, dynamic>
          ? UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)
          : null,
      userInfo: json['user_info'] is Map<String, dynamic>
          ? ActiveReelUserInfo.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActiveReelUserInfo {
  final int? userId;
  final String firstName;
  final String lastName;
  final String? userEmail;
  final UploadedMedia? applicationMeta;

  const ActiveReelUserInfo({
    this.userId,
    required this.firstName,
    required this.lastName,
    this.userEmail,
    this.applicationMeta,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ActiveReelUserInfo.fromJson(Map<String, dynamic> json) {
    return ActiveReelUserInfo(
      userId: int.tryParse('${json['user_id']}'),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      userEmail: json['user_email'] as String?,
      applicationMeta: json['application_meta'] is Map<String, dynamic>
          ? UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)
          : null,
    );
  }
}
