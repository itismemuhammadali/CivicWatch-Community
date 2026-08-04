class ActivePost {
  final int postId;
  final String postDescription;
  final int? createdBy;
  final String? createdAt;
  final ActivePostUserInfo? createdByUserInfo;
  final ActivePostCaseDetail? caseDetail;
  final List<ActivePostDefendantDetail> defendantDetails;
  final List<ActivePostComment> comments;
  final List<ActivePostReaction> reactions;
  final ActivePostReactionSummary? reactionSummary;
  final ActivePostPollCount? casePollCount;
  final int repostCount;
  final List<ActivePostRepost> reposts;
  final ActiveSavedPostMeta? savedPostMeta;

  const ActivePost({
    required this.postId,
    required this.postDescription,
    this.createdBy,
    this.createdAt,
    this.createdByUserInfo,
    this.caseDetail,
    required this.defendantDetails,
    required this.comments,
    required this.reactions,
    this.reactionSummary,
    this.casePollCount,
    this.repostCount = 0,
    this.reposts = const [],
    this.savedPostMeta,
  });

  String? get authorAvatarUrl {
    final directAvatar = createdByUserInfo?.avatarUrl?.trim();
    if (directAvatar != null && directAvatar.isNotEmpty) {
      return directAvatar;
    }

    final caseProfileAvatar =
        caseDetail?.caseUserProfile?.profileMeta?.metaUrl?.trim();
    if (caseProfileAvatar != null && caseProfileAvatar.isNotEmpty) {
      return caseProfileAvatar;
    }

    return null;
  }

  String get authorDisplayName {
    final directName = createdByUserInfo?.fullName.trim() ?? '';
    if (directName.isNotEmpty) {
      return directName;
    }

    final caseProfileName = caseDetail?.caseUserProfile?.fullName.trim() ?? '';
    if (caseProfileName.isNotEmpty) {
      return caseProfileName;
    }

    final email = createdByUserInfo?.userEmail?.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Unknown';
  }

  int? get authorUserId {
    if (createdBy != null && createdBy! > 0) {
      return createdBy;
    }

    final caseProfileUserId = caseDetail?.caseUserProfile?.userId;
    if (caseProfileUserId != null && caseProfileUserId > 0) {
      return caseProfileUserId;
    }

    return null;
  }

  factory ActivePost.fromJson(Map<String, dynamic> json) {
    final postId = json['post_id'];

    return ActivePost(
      postId: postId is int ? postId : int.parse('$postId'),
      postDescription: json['post_description'] as String? ?? '',
      createdBy: int.tryParse('${json['created_by']}'),
      createdAt: json['created_at'] as String?,
      createdByUserInfo:
          json['created_by_user_info'] is Map<String, dynamic>
          ? ActivePostUserInfo.fromJson(
              json['created_by_user_info'] as Map<String, dynamic>,
            )
          : null,
      caseDetail: json['case_detail'] is Map<String, dynamic>
          ? ActivePostCaseDetail.fromJson(
              json['case_detail'] as Map<String, dynamic>,
            )
          : null,
      defendantDetails: (json['defendant_details'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivePostDefendantDetail.fromJson)
          .toList(),
      comments: (json['comments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivePostComment.fromJson)
          .toList(),
      reactions: (json['reactions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivePostReaction.fromJson)
          .toList(),
      reactionSummary:
          json['reaction_summary'] is Map<String, dynamic>
          ? ActivePostReactionSummary.fromJson(
              json['reaction_summary'] as Map<String, dynamic>,
            )
          : null,
      casePollCount: json['case_poll_count'] is Map<String, dynamic>
          ? ActivePostPollCount.fromJson(
              json['case_poll_count'] as Map<String, dynamic>,
            )
          : null,
      repostCount: int.tryParse('${json['repost_count']}') ?? 0,
      reposts: (json['reposts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivePostRepost.fromJson)
          .toList(),
      savedPostMeta: json['saved_post_meta'] is Map<String, dynamic>
          ? ActiveSavedPostMeta.fromJson(
              json['saved_post_meta'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ActiveSavedPostMeta {
  final int? recordId;
  final String? savedAt;
  final int? savedBy;
  final bool isActive;

  const ActiveSavedPostMeta({
    this.recordId,
    this.savedAt,
    this.savedBy,
    required this.isActive,
  });

  factory ActiveSavedPostMeta.fromJson(Map<String, dynamic> json) {
    final rawIsActive = json['is_active'];
    return ActiveSavedPostMeta(
      recordId: int.tryParse('${json['record_id']}'),
      savedAt: json['saved_at'] as String?,
      savedBy: int.tryParse('${json['saved_by']}'),
      isActive: rawIsActive == true || '$rawIsActive'.toLowerCase() == 'true',
    );
  }
}

class ActivePostRepost {
  final int? repostId;
  final int? postId;
  final int? userId;
  final String description;
  final String? isActive;
  final int? createdBy;
  final String? createdAt;
  final ActivePostRepostUserDetail? repostUserDetail;

  const ActivePostRepost({
    this.repostId,
    this.postId,
    this.userId,
    required this.description,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.repostUserDetail,
  });

  factory ActivePostRepost.fromJson(Map<String, dynamic> json) {
    return ActivePostRepost(
      repostId: int.tryParse('${json['repost_id']}'),
      postId: int.tryParse('${json['post_id']}'),
      userId: int.tryParse('${json['user_id']}'),
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as String?,
      createdBy: int.tryParse('${json['created_by']}'),
      createdAt: json['created_at'] as String?,
      repostUserDetail:
          json['repost_user_detail'] is Map<String, dynamic>
          ? ActivePostRepostUserDetail.fromJson(
              json['repost_user_detail'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ActivePostRepostUserDetail {
  final String firstName;
  final String lastName;
  final String? userEmail;
  final String? avatarUrl;

  const ActivePostRepostUserDetail({
    required this.firstName,
    required this.lastName,
    this.userEmail,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ActivePostRepostUserDetail.fromJson(Map<String, dynamic> json) {
    return ActivePostRepostUserDetail(
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? json['email'] as String?,
      avatarUrl:
          json['avatar_url'] as String? ??
          json['profileImageUrl'] as String? ??
          json['profile_image_url'] as String? ??
          json['profile_meta_url'] as String? ??
          json['meta_url'] as String?,
    );
  }
}

class ActivePostUserInfo {
  final String firstName;
  final String lastName;
  final String? userEmail;
  final ActivePostMeta? applicationMeta;
  final String? avatarUrl;

  const ActivePostUserInfo({
    required this.firstName,
    required this.lastName,
    this.userEmail,
    this.applicationMeta,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ActivePostUserInfo.fromJson(Map<String, dynamic> json) {
    final applicationMeta =
        json['application_meta'] is Map<String, dynamic>
        ? ActivePostMeta.fromJson(json['application_meta'] as Map<String, dynamic>)
        : null;

    return ActivePostUserInfo(
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? json['email'] as String?,
      applicationMeta: applicationMeta,
      avatarUrl:
          applicationMeta?.metaUrl ??
          json['profileImageUrl'] as String? ??
          json['profile_image_url'] as String? ??
          json['profile_meta_url'] as String? ??
          json['meta_url'] as String? ??
          json['image_url'] as String? ??
          json['profile_image'] as String? ??
          json['profile_picture'] as String? ??
          json['avatar_url'] as String? ??
          json['user_image'] as String?,
    );
  }
}

class ActivePostMeta {
  final String? metaUrl;
  final String? metaTypeId;

  const ActivePostMeta({
    this.metaUrl,
    this.metaTypeId,
  });

  bool get hasMedia => (metaUrl ?? '').trim().isNotEmpty;

  bool get isImage {
    final normalizedType = metaTypeId?.trim();
    if (normalizedType == '1') return true;
    if (normalizedType == '2') return false;

    final url = (metaUrl ?? '').toLowerCase();
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  factory ActivePostMeta.fromJson(Map<String, dynamic> json) {
    return ActivePostMeta(
      metaUrl: json['meta_url'] as String?,
      metaTypeId: json['meta_type_id']?.toString(),
    );
  }
}

class ActivePostCaseDetail {
  final int caseId;
  final String caseTitle;
  final String caseDescription;
  final int? caseCategoryId;
  final int? caseViewStatusId;
  final String? caseResolution;
  final ActivePostMeta? meta;
  final List<ActivePostMeta> metaList;
  final ActivePostCaseUserProfile? caseUserProfile;

  bool get isJuryPost => caseViewStatusId == 7;

  const ActivePostCaseDetail({
    required this.caseId,
    required this.caseTitle,
    required this.caseDescription,
    this.caseCategoryId,
    this.caseViewStatusId,
    this.caseResolution,
    this.meta,
    this.metaList = const [],
    this.caseUserProfile,
  });

  factory ActivePostCaseDetail.fromJson(Map<String, dynamic> json) {
    final caseId = json['case_id'];

    return ActivePostCaseDetail(
      caseId: caseId is int ? caseId : int.parse('$caseId'),
      caseTitle: json['case_title'] as String? ?? '',
      caseDescription: json['case_description'] as String? ?? '',
      caseCategoryId: int.tryParse('${json['case_category_id']}'),
      caseViewStatusId: int.tryParse('${json['case_view_status_id']}'),
      caseResolution: json['case_resolution'] as String?,
      meta: json['meta'] is Map<String, dynamic>
          ? ActivePostMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : json['application_meta'] is Map<String, dynamic>
              ? ActivePostMeta.fromJson(json['application_meta'] as Map<String, dynamic>)
              : null,
      metaList: json['meta_list'] is List
          ? (json['meta_list'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ActivePostMeta.fromJson)
              .toList()
          : (json['meta'] is Map<String, dynamic>
              ? [ActivePostMeta.fromJson(json['meta'] as Map<String, dynamic>)]
              : (json['application_meta'] is Map<String, dynamic>
                  ? [ActivePostMeta.fromJson(json['application_meta'] as Map<String, dynamic>)]
                  : const [])),
      caseUserProfile: json['case_user_profile'] is Map<String, dynamic>
          ? ActivePostCaseUserProfile.fromJson(
              json['case_user_profile'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ActivePostCaseUserProfile {
  final int? userId;
  final String firstName;
  final String lastName;
  final String? userEmail;
  final ActivePostMeta? profileMeta;

  const ActivePostCaseUserProfile({
    this.userId,
    required this.firstName,
    required this.lastName,
    this.userEmail,
    this.profileMeta,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ActivePostCaseUserProfile.fromJson(Map<String, dynamic> json) {
    return ActivePostCaseUserProfile(
      userId: int.tryParse('${json['user_id']}'),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      userEmail: json['user_email'] as String?,
      profileMeta: json['profile_meta'] is Map<String, dynamic>
          ? ActivePostMeta.fromJson(json['profile_meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActivePostDefendantDetail {
  final int? defendantCaseId;
  final int? defendentId;
  final String? caseResolution;
  final ActivePostUserInfo? userInfo;
  final ActivePostMeta? meta;
  final List<ActivePostMeta> metaList;

  const ActivePostDefendantDetail({
    this.defendantCaseId,
    this.defendentId,
    this.caseResolution,
    this.userInfo,
    this.meta,
    this.metaList = const [],
  });

  factory ActivePostDefendantDetail.fromJson(Map<String, dynamic> json) {
    return ActivePostDefendantDetail(
      defendantCaseId: int.tryParse('${json['defendant_case_id']}'),
      defendentId: int.tryParse('${json['defendent_id']}'),
      caseResolution: json['case_resolution'] as String?,
      userInfo: json['user_info'] is Map<String, dynamic>
          ? ActivePostUserInfo.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] is Map<String, dynamic>
          ? ActivePostMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      metaList: json['meta_list'] is List
          ? (json['meta_list'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ActivePostMeta.fromJson)
              .toList()
          : (json['meta'] is Map<String, dynamic>
              ? [ActivePostMeta.fromJson(json['meta'] as Map<String, dynamic>)]
              : const []),
    );
  }
}

class ActivePostComment {
  final int? commentId;
  final int? postId;
  final int? userId;
  final int? parentCommentId;
  final String commentContent;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final ActivePostUserInfo? userInfo;
  final List<ActivePostComment> childComments;
  final List<int> likes;

  const ActivePostComment({
    this.commentId,
    this.postId,
    this.userId,
    this.parentCommentId,
    required this.commentContent,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.userInfo,
    this.childComments = const [],
    this.likes = const [],
  });

  factory ActivePostComment.fromJson(Map<String, dynamic> json) {
    return ActivePostComment(
      commentId: int.tryParse('${json['comment_id']}'),
      postId: int.tryParse('${json['post_id']}'),
      userId: int.tryParse('${json['user_id']}'),
      parentCommentId: int.tryParse('${json['parent_comment_id']}'),
      commentContent: json['comment_content'] as String? ?? '',
      isActive: json['is_active'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      userInfo: json['user_info'] is Map<String, dynamic>
          ? ActivePostUserInfo.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
      childComments: (json['child_comments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ActivePostComment.fromJson)
          .toList(),
      likes: (json['likes'] as List? ?? const []).map((e) => int.tryParse('$e') ?? 0).toList(),
    );
  }
}

class ActivePostReaction {
  final int? reactionId;
  final int? postId;
  final int? userId;
  final String reactionType;
  final String? createdAt;
  final ActivePostUserInfo? userInfo;

  const ActivePostReaction({
    this.reactionId,
    this.postId,
    this.userId,
    required this.reactionType,
    this.createdAt,
    this.userInfo,
  });

  factory ActivePostReaction.fromJson(Map<String, dynamic> json) {
    return ActivePostReaction(
      reactionId: int.tryParse('${json['reaction_id']}'),
      postId: int.tryParse('${json['post_id']}'),
      userId: int.tryParse('${json['user_id']}'),
      reactionType: json['reaction_type'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      userInfo: json['user_info'] is Map<String, dynamic>
          ? ActivePostUserInfo.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActivePostReactionSummary {
  final int totalReactions;
  final Map<String, dynamic> byType;

  const ActivePostReactionSummary({
    required this.totalReactions,
    required this.byType,
  });

  factory ActivePostReactionSummary.fromJson(Map<String, dynamic> json) {
    final byType = json['by_type'] is Map<String, dynamic>
        ? json['by_type'] as Map<String, dynamic>
        : {
            'Like': json['like_count'] ?? 0,
            'Dislike': json['dislike_count'] ?? 0,
            'Heart': json['heart_count'] ?? 0,
          };
    final total = int.tryParse('${json['total_reactions']}') ??
        byType.values.fold<int>(0, (sum, v) => sum + (int.tryParse('$v') ?? 0));
    return ActivePostReactionSummary(
      totalReactions: total,
      byType: byType,
    );
  }
}

class ActivePostPollCount {
  final int ownerCount;
  final int defendantCount;
  final int totalCount;
  final String? pollStartDate;
  final String? pollEndDate;
  final String? lastVoteAt;

  const ActivePostPollCount({
    required this.ownerCount,
    required this.defendantCount,
    required this.totalCount,
    this.pollStartDate,
    this.pollEndDate,
    this.lastVoteAt,
  });

  factory ActivePostPollCount.fromJson(Map<String, dynamic> json) {
    return ActivePostPollCount(
      ownerCount: int.tryParse('${json['owner_count']}') ?? 0,
      defendantCount: int.tryParse('${json['defendant_count']}') ?? 0,
      totalCount: int.tryParse('${json['total_count']}') ?? 0,
      pollStartDate: json['poll_start_date'] as String?,
      pollEndDate: json['poll_end_date'] as String?,
      lastVoteAt: json['last_vote_at'] as String?,
    );
  }
}
