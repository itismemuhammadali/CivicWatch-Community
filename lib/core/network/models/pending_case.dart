import 'package:cctv_app/core/network/models/uploaded_media.dart';

class PendingCase {
  final int caseId;
  final int? userId;
  final String caseTitle;
  final String caseDescription;
  final String? caseStatus;
  final int? caseCategoryId;
  final String? caseIsActive;
  final String? caseCreatedAt;
  final UploadedMedia? applicationMeta;
  final PendingCaseDefendant? defendant;
  final List<UploadedMedia> metaList;
  final int? tagDefendentUserId;
  final String? creatorFirstName;
  final String? creatorLastName;
  final String? creatorAvatarUrl;

  const PendingCase({
    required this.caseId,
    this.userId,
    required this.caseTitle,
    required this.caseDescription,
    this.caseStatus,
    this.caseCategoryId,
    this.caseIsActive,
    this.caseCreatedAt,
    this.applicationMeta,
    this.defendant,
    this.metaList = const [],
    this.tagDefendentUserId,
    this.creatorFirstName,
    this.creatorLastName,
    this.creatorAvatarUrl,
  });

  String get creatorDisplayName =>
      '$creatorFirstName $creatorLastName'.trim();

  bool get hasMedia => (applicationMeta?.metaUrl ?? '').trim().isNotEmpty;

  bool get isImage {
    final metaTypeId = applicationMeta?.metaTypeId;
    if (metaTypeId != null) {
      return metaTypeId == 1;
    }

    final url = applicationMeta?.metaUrl?.toLowerCase() ?? '';
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  factory PendingCase.fromJson(Map<String, dynamic> json) {
    final caseId = json['case_id'];

    return PendingCase(
      caseId: caseId is int ? caseId : int.parse('$caseId'),
      userId: int.tryParse('${json['user_id']}'),
      caseTitle: json['case_title'] as String? ?? '',
      caseDescription: json['case_description'] as String? ?? '',
      caseStatus: json['case_status'] as String?,
      caseCategoryId: int.tryParse('${json['case_category_id']}'),
      caseIsActive: json['case_is_active'] as String?,
      caseCreatedAt: json['case_created_at'] as String?,
      applicationMeta: json['application_meta'] is Map<String, dynamic>
          ? UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)
          : (json['meta_url'] != null
              ? UploadedMedia(
                  metaId: json['meta_id'],
                  metaTypeId: json['meta_type_id'],
                  metaUrl: json['meta_url'] as String,
                )
              : null),
      defendant: json['defendant'] is Map<String, dynamic>
          ? PendingCaseDefendant.fromJson(json['defendant'] as Map<String, dynamic>)
          : null,
      metaList: json['meta_list'] is List && (json['meta_list'] as List).isNotEmpty
          ? (json['meta_list'] as List)
              .whereType<Map<String, dynamic>>()
              .map(UploadedMedia.fromJson)
              .toList()
          : (json['application_meta'] is Map<String, dynamic>
              ? [UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)]
              : (json['meta_url'] != null
                  ? [
                      UploadedMedia(
                        metaId: json['meta_id'],
                        metaTypeId: json['meta_type_id'],
                        metaUrl: json['meta_url'] as String,
                      )
                    ]
                  : const [])),
      tagDefendentUserId: int.tryParse('${json['tag_defendent_user_id']}'),
      creatorFirstName: json['creator_first_name'] as String? ??
          json['created_by_user_info']?['first_name'] as String?,
      creatorLastName: json['creator_last_name'] as String? ??
          json['created_by_user_info']?['last_name'] as String?,
      creatorAvatarUrl: json['creator_avatar_url'] as String? ??
          json['created_by_user_info']?['avatar_url'] as String?,
    );
  }

  PendingCase copyWith({
    String? creatorFirstName,
    String? creatorLastName,
    String? creatorAvatarUrl,
  }) {
    return PendingCase(
      caseId: caseId,
      userId: userId,
      caseTitle: caseTitle,
      caseDescription: caseDescription,
      caseStatus: caseStatus,
      caseCategoryId: caseCategoryId,
      caseIsActive: caseIsActive,
      caseCreatedAt: caseCreatedAt,
      applicationMeta: applicationMeta,
      defendant: defendant,
      metaList: metaList,
      tagDefendentUserId: tagDefendentUserId,
      creatorFirstName: creatorFirstName ?? this.creatorFirstName,
      creatorLastName: creatorLastName ?? this.creatorLastName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
    );
  }
}

class PendingCaseDefendant {
  final int? defendantCaseId;
  final int? defendentId;
  final bool? isAcceptTerms;
  final String? caseResolution;
  final bool? isActive;
  final String? createdAt;
  final UploadedMedia? applicationMeta;

  const PendingCaseDefendant({
    this.defendantCaseId,
    this.defendentId,
    this.isAcceptTerms,
    this.caseResolution,
    this.isActive,
    this.createdAt,
    this.applicationMeta,
  });

  factory PendingCaseDefendant.fromJson(Map<String, dynamic> json) {
    return PendingCaseDefendant(
      defendantCaseId: int.tryParse('${json['defendant_case_id']}'),
      defendentId: int.tryParse('${json['defendent_id']}'),
      isAcceptTerms: json['is_accept_terms'] as bool?,
      caseResolution: json['case_resolution'] as String?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] as String?,
      applicationMeta: json['application_meta'] is Map<String, dynamic>
          ? UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)
          : null,
    );
  }
}
