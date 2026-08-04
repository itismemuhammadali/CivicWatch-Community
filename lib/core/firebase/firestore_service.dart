import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/network/models/pending_case.dart';
import 'package:cctv_app/core/network/models/user_option.dart';
import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/services/user_cache_service.dart';

class FirestoreDataService {
  static final FirestoreDataService _instance =
      FirestoreDataService._internal();
  factory FirestoreDataService() => _instance;
  FirestoreDataService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  int _generateId() => DateTime.now().millisecondsSinceEpoch;

  // --- Posts ---
  Future<List<ActivePost>> getAllActivePosts() async {
    final query = await _db
        .collection('posts')
        .orderBy('created_at', descending: true)
        .get();
    return query.docs.map((doc) => ActivePost.fromJson(doc.data())).toList();
  }

  Future<List<ActivePost>> getPostsByUserId(String uid) async {
    // We assume the user ID stored in posts is an integer, so we might need to query by string if we changed it, or int.
    // For now, let's query where created_by is the user's integer ID. But wait, uid is string!
    // If uid is string, we need to handle it. Assuming created_by is stored as int.
    // We will pass the integer userId to this method instead of string uid for posts.
    throw UnimplementedError('Pass integer userId instead');
  }

  Future<Set<int>> getAllMatchingUserIds(int inputUserId) async {
    final ids = <int>{inputUserId, inputUserId.abs()};
    try {
      final userData = await _getUserDataById(inputUserId);
      if (userData != null) {
        final raw1 = userData['user_id'];
        final raw2 = userData['userId'];
        final int1 = raw1 is int ? raw1 : int.tryParse('$raw1');
        final int2 = raw2 is int ? raw2 : int.tryParse('$raw2');
        if (int1 != null) {
          ids.add(int1);
          ids.add(int1.abs());
        }
        if (int2 != null) {
          ids.add(int2);
          ids.add(int2.abs());
        }
        final fbUid = userData['firebase_uid'];
        if (fbUid is String) {
          ids.add(fbUid.hashCode);
          ids.add(fbUid.hashCode.abs());
        }
      }
    } catch (_) {}
    return ids;
  }

  Future<List<ActivePost>> getPostsByIntUserId(int userId) async {
    try {
      final matchingIds = await getAllMatchingUserIds(userId);
      final allPosts = await getAllActivePostsEnriched();
      final posts = allPosts.where((post) {
        final authorId = post.authorUserId;
        final createdBy = post.createdBy;
        return (authorId != null && matchingIds.contains(authorId)) ||
            (createdBy != null && matchingIds.contains(createdBy));
      }).toList();
      posts.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      return posts;
    } catch (e) {
      debugPrint('Error getting posts by user id: $e');
      return [];
    }
  }

  Future<List<ActivePost>> getPostsByFirebaseUid(String firebaseUid) async {
    // 1. Get int userId from users collection
    final userDoc = await _db.collection('users').doc(firebaseUid).get();
    if (!userDoc.exists) return [];

    final data = userDoc.data()!;
    final userIdVal = data['user_id'] ?? data['userId'];
    final userId = userIdVal is int
        ? userIdVal
        : int.tryParse('$userIdVal') ?? userDoc.id.hashCode;

    // 2. Fetch posts by int userId
    return getPostsByIntUserId(userId);
  }

  Future<List<ActivePost>> getSavedPostsByUserId(int userId) async {
    final savedQuery = await _db
        .collection('saved_posts')
        .where('user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .get();
    List<ActivePost> savedPosts = [];
    for (var doc in savedQuery.docs) {
      final postId = doc.data()['post_id'];
      final postDoc = await _db.collection('posts').doc('$postId').get();
      if (postDoc.exists) {
        savedPosts.add(ActivePost.fromJson(postDoc.data()!));
      }
    }
    return savedPosts;
  }

  Future<void> createPost(Map<String, dynamic> data) async {
    final postId = _generateId();
    data['post_id'] = postId;
    data['created_at'] = DateTime.now().toUtc().toIso8601String();
    await _db.collection('posts').doc('$postId').set(data);
  }

  // --- Enriched Post Fetching (read-time user data overlay) ---

  Future<List<ActivePost>> getAllActivePostsEnriched() async {
    final posts = await getAllActivePosts();
    return _enrichPosts(posts);
  }

  Future<List<ActivePost>> getPostsByIntUserIdEnriched(int userId) async {
    final posts = await getPostsByIntUserId(userId);
    return _enrichPosts(posts);
  }

  Future<List<ActivePost>> getSavedPostsByUserIdEnriched(int userId) async {
    final posts = await getSavedPostsByUserId(userId);
    return _enrichPosts(posts);
  }

  Future<List<ActivePost>> _enrichPosts(List<ActivePost> posts) async {
    try {
      final userIds = <int>{};
      for (final post in posts) {
        final authorId = post.authorUserId;
        if (authorId != null) userIds.add(authorId);
        for (final r in post.reposts) {
          final rUserId = r.userId ?? r.createdBy;
          if (rUserId != null) userIds.add(rUserId);
        }
        for (final d in post.defendantDetails) {
          if (d.defendentId != null) userIds.add(d.defendentId!);
        }
        for (final c in post.comments) {
          if (c.userId != null && c.userId! > 0) userIds.add(c.userId!);
        }
      }

      if (userIds.isEmpty) return posts;

      final users = await UserCacheService().batchGetUsers(userIds.toList());
      return posts.map((post) => _enrichPost(post, users)).toList();
    } catch (e) {
      debugPrint('Error enriching posts: $e');
      return posts;
    }
  }

  // --- Search Methods ---

  Future<List<CachedUserInfo>> searchUsers(String query) async {
    final lowercaseQuery = query.toLowerCase().trim();
    final Map<int, CachedUserInfo> userMap = {};

    try {
      final snapshot = await _db.collection('users').get();
      for (final doc in snapshot.docs) {
        final u = CachedUserInfo.fromFirestoreData(doc.data(), docId: doc.id);
        if (u != null) userMap[u.userId] = u;
      }
    } catch (_) {}

    try {
      final posts = await getAllActivePostsEnriched();
      for (final post in posts) {
        final creatorId = post.authorUserId;
        final name = post.authorDisplayName;
        if (creatorId != null &&
            creatorId > 0 &&
            !userMap.containsKey(creatorId)) {
          final avatar = post.authorAvatarUrl ?? '';
          final parts = name.split(' ');
          final first = parts.isNotEmpty ? parts.first : 'User';
          final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          userMap[creatorId] = CachedUserInfo(
            userId: creatorId,
            firstName: first,
            lastName: last,
            email: '',
            avatarUrl: avatar,
          );
        }
      }
    } catch (_) {}

    final users = userMap.values.where((user) {
      if (lowercaseQuery.isEmpty) return true;
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      return fullName.contains(lowercaseQuery) ||
          user.email.toLowerCase().contains(lowercaseQuery);
    }).toList();

    return users;
  }

  Future<List<ActivePost>> searchPosts(String query) async {
    final lowercaseQuery = query.toLowerCase().trim();
    final posts = await getAllActivePostsEnriched();

    if (lowercaseQuery.isEmpty) return posts;

    return posts.where((post) {
      final text = (post.postDescription).toLowerCase();
      final author = (post.authorDisplayName).toLowerCase();
      return text.contains(lowercaseQuery) || author.contains(lowercaseQuery);
    }).toList();
  }

  ActivePost _enrichPost(ActivePost post, Map<int, CachedUserInfo> users) {
    // Enrich creator info
    final creatorId = post.authorUserId;
    final creatorInfo = creatorId != null ? users[creatorId] : null;
    final enrichedCreator = _buildEnrichedUserInfo(
      post.createdByUserInfo,
      creatorInfo,
    );

    // Enrich reposts list info
    final enrichedReposts = post.reposts.map((r) {
      final rUserId = r.userId ?? r.createdBy;
      final repostUser = rUserId != null ? users[rUserId] : null;
      if (repostUser == null) return r;

      final existingDetail = r.repostUserDetail;
      final fName = repostUser.firstName.isNotEmpty
          ? repostUser.firstName
          : (existingDetail?.firstName ?? '');
      final lName = repostUser.lastName.isNotEmpty
          ? repostUser.lastName
          : (existingDetail?.lastName ?? '');
      final email = repostUser.email.isNotEmpty
          ? repostUser.email
          : (existingDetail?.userEmail ?? '');
      final avatar = repostUser.avatarUrl.isNotEmpty
          ? repostUser.avatarUrl
          : (existingDetail?.avatarUrl ?? '');

      final enrichedDetail = ActivePostRepostUserDetail(
        firstName: fName,
        lastName: lName,
        userEmail: email,
        avatarUrl: avatar,
      );

      return ActivePostRepost(
        repostId: r.repostId,
        postId: r.postId,
        userId: r.userId,
        description: r.description,
        isActive: r.isActive,
        createdBy: r.createdBy,
        createdAt: r.createdAt,
        repostUserDetail: enrichedDetail,
      );
    }).toList();

    // Enrich defendant details
    final enrichedDefendants = post.defendantDetails.map((d) {
      if (d.defendentId == null) return d;
      final defInfo = users[d.defendentId!];
      if (defInfo == null) return d;
      final enrichedUserInfo = _buildEnrichedUserInfo(d.userInfo, defInfo);
      if (identical(enrichedUserInfo, d.userInfo)) return d;
      return ActivePostDefendantDetail(
        defendantCaseId: d.defendantCaseId,
        defendentId: d.defendentId,
        caseResolution: d.caseResolution,
        userInfo: enrichedUserInfo,
        meta: d.meta,
        metaList: d.metaList,
      );
    }).toList();

    // Enrich comments
    final enrichedComments = post.comments.map((c) {
      if (c.userId == null || c.userId! <= 0) return c;
      final commentUser = users[c.userId!];
      if (commentUser == null) return c;
      final enrichedUserInfo = _buildEnrichedUserInfo(c.userInfo, commentUser);
      if (identical(enrichedUserInfo, c.userInfo)) return c;
      return ActivePostComment(
        commentId: c.commentId,
        postId: c.postId,
        userId: c.userId,
        parentCommentId: c.parentCommentId,
        commentContent: c.commentContent,
        isActive: c.isActive,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        userInfo: enrichedUserInfo,
        childComments: c.childComments,
        likes: c.likes,
      );
    }).toList();

    return _buildEnrichedPost(
      post,
      enrichedCreator,
      enrichedDefendants,
      enrichedComments,
      reposts: enrichedReposts,
    );
  }

  ActivePostUserInfo _buildEnrichedUserInfo(
    ActivePostUserInfo? existing,
    CachedUserInfo? fresh,
  ) {
    final existingAvatarUrl = (existing?.avatarUrl?.trim().isNotEmpty == true)
        ? existing!.avatarUrl!.trim()
        : (existing?.applicationMeta?.metaUrl?.trim() ?? '');

    if (fresh == null) {
      if (existing != null && (existing.avatarUrl ?? '') != existingAvatarUrl) {
        return ActivePostUserInfo(
          firstName: existing.firstName,
          lastName: existing.lastName,
          userEmail: existing.userEmail,
          avatarUrl: existingAvatarUrl,
          applicationMeta: existing.applicationMeta,
        );
      }
      return existing ?? const ActivePostUserInfo(firstName: '', lastName: '');
    }

    final firstName = fresh.firstName.isNotEmpty
        ? fresh.firstName
        : (existing?.firstName ?? '');
    final lastName = fresh.lastName.isNotEmpty
        ? fresh.lastName
        : (existing?.lastName ?? '');
    final email = fresh.email.isNotEmpty
        ? fresh.email
        : (existing?.userEmail ?? '');
    final avatar = fresh.avatarUrl.isNotEmpty
        ? fresh.avatarUrl
        : existingAvatarUrl;

    if (firstName == existing?.firstName &&
        lastName == existing?.lastName &&
        email == (existing?.userEmail ?? '') &&
        avatar == (existing?.avatarUrl ?? '')) {
      return existing!;
    }

    return ActivePostUserInfo(
      firstName: firstName,
      lastName: lastName,
      userEmail: email,
      avatarUrl: avatar,
      applicationMeta: existing?.applicationMeta,
    );
  }

  ActivePost _buildEnrichedPost(
    ActivePost post,
    ActivePostUserInfo creator,
    List<ActivePostDefendantDetail> defendants,
    List<ActivePostComment> comments, {
    List<ActivePostRepost>? reposts,
  }) {
    return ActivePost(
      postId: post.postId,
      postDescription: post.postDescription,
      createdBy: post.createdBy,
      createdAt: post.createdAt,
      createdByUserInfo: creator,
      caseDetail: post.caseDetail,
      defendantDetails: defendants,
      comments: comments,
      reactions: post.reactions,
      reactionSummary: post.reactionSummary,
      casePollCount: post.casePollCount,
      repostCount: post.repostCount,
      reposts: reposts ?? post.reposts,
      savedPostMeta: post.savedPostMeta,
    );
  }

  Future<void> createPostReaction(
    int postId,
    int userId,
    String reactionType,
  ) async {
    final postRef = _db.collection('posts').doc('$postId');
    final reactionId = _generateId();
    final reaction = {
      'reaction_id': reactionId,
      'post_id': postId,
      'user_id': userId,
      'reaction_type': reactionType,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List reactions = List.from(snapshot.data()?['reactions'] ?? []);

      // Remove existing reaction if any
      final existingIndex = reactions.indexWhere((r) => r['user_id'] == userId);
      String? oldType;
      if (existingIndex >= 0) {
        oldType = reactions[existingIndex]['reaction_type'];
        reactions.removeAt(existingIndex);
      }
      reactions.add(reaction);

      Map<String, dynamic> summary = Map<String, dynamic>.from(
        snapshot.data()?['reaction_summary'] ??
            {'like_count': 0, 'dislike_count': 0, 'heart_count': 0},
      );

      if (oldType == 'Like') {
        summary['like_count'] = (summary['like_count'] as int) - 1;
      }
      if (reactionType == 'Like') {
        summary['like_count'] = (summary['like_count'] as int) + 1;
      }

      transaction.update(postRef, {
        'reactions': reactions,
        'reaction_summary': summary,
      });
    });
  }

  Future<void> deletePostReaction(int postId, int userId) async {
    final postRef = _db.collection('posts').doc('$postId');
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List reactions = List.from(snapshot.data()?['reactions'] ?? []);

      final existingIndex = reactions.indexWhere((r) => r['user_id'] == userId);
      if (existingIndex < 0) return;

      final oldType = reactions[existingIndex]['reaction_type'];
      reactions.removeAt(existingIndex);

      Map<String, dynamic> summary = Map<String, dynamic>.from(
        snapshot.data()?['reaction_summary'] ??
            {'like_count': 0, 'dislike_count': 0, 'heart_count': 0},
      );

      if (oldType == 'Like') {
        summary['like_count'] = (summary['like_count'] as int) - 1;
      }

      transaction.update(postRef, {
        'reactions': reactions,
        'reaction_summary': summary,
      });
    });
  }

  Future<void> createPostComment(int postId, int userId, String content) async {
    final postRef = _db.collection('posts').doc('$postId');
    final commentId = _generateId();

    // Fetch user name at write-time so comments display correctly immediately
    Map<String, dynamic>? userInfo;
    try {
      final userData = await _getUserDataById(userId);
      if (userData != null) {
        final avatar =
            userData['profileImageUrl'] ??
            userData['profile_image_url'] ??
            userData['avatar_url'] ??
            '';
        userInfo = {
          'first_name': userData['first_name'] ?? userData['firstName'] ?? '',
          'last_name': userData['last_name'] ?? userData['lastName'] ?? '',
          'user_email': userData['user_email'] ?? userData['email'] ?? '',
          'avatar_url': avatar,
        };
      }
    } catch (_) {}

    final comment = {
      'comment_id': commentId,
      'post_id': postId,
      'user_id': userId,
      'comment_content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (userInfo != null) 'user_info': userInfo,
    };

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List comments = snapshot.data()?['comments'] ?? [];
      comments.add(comment);
      transaction.update(postRef, {'comments': comments});
    });
  }

  Future<void> createChildComment(
    int postId,
    int parentCommentId,
    int userId,
    String content,
  ) async {
    final postRef = _db.collection('posts').doc('$postId');
    final commentId = _generateId();

    // Fetch user name at write-time so replies display correctly immediately
    Map<String, dynamic>? userInfo;
    try {
      final userData = await _getUserDataById(userId);
      if (userData != null) {
        final avatar =
            userData['profileImageUrl'] ??
            userData['profile_image_url'] ??
            userData['avatar_url'] ??
            '';
        userInfo = {
          'first_name': userData['first_name'] ?? userData['firstName'] ?? '',
          'last_name': userData['last_name'] ?? userData['lastName'] ?? '',
          'user_email': userData['user_email'] ?? userData['email'] ?? '',
          'avatar_url': avatar,
        };
      }
    } catch (_) {}

    final comment = {
      'comment_id': commentId,
      'post_id': postId,
      'user_id': userId,
      'parent_comment_id': parentCommentId,
      'comment_content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (userInfo != null) 'user_info': userInfo,
    };

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List comments = snapshot.data()?['comments'] ?? [];

      // If backend nests comments directly in the json, we would find parent and append to childComments.
      // But standard relation just adds to root with parent_comment_id.
      // The UI mapping doesn't auto nest unless we nest it here or ActivePostComment.fromJson does it (it doesn't, it looks for 'child_comments').
      // Let's nest it inside the parent comment's 'child_comments' array for correct UI rendering from ActivePostComment.fromJson.
      bool added = false;
      for (var i = 0; i < comments.length; i++) {
        if (comments[i]['comment_id'] == parentCommentId) {
          List childComments = comments[i]['child_comments'] ?? [];
          childComments.add(comment);
          comments[i]['child_comments'] = childComments;
          added = true;
          break;
        }
      }

      if (!added) {
        // Fallback to top level if parent not found
        comments.add(comment);
      }

      transaction.update(postRef, {'comments': comments});
    });
  }

  Future<void> likeComment(int postId, int commentId, int userId) async {
    final postRef = _db.collection('posts').doc('$postId');

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List comments = List.from(snapshot.data()?['comments'] ?? []);

      bool updated = false;
      for (var i = 0; i < comments.length; i++) {
        Map<String, dynamic> comment = Map<String, dynamic>.from(comments[i]);

        if (comment['comment_id'] == commentId) {
          List likes = List.from(comment['likes'] ?? []);
          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
          }
          comment['likes'] = likes;
          comments[i] = comment;
          updated = true;
          break;
        }

        // Also check children
        List childComments = List.from(comment['child_comments'] ?? []);
        bool childUpdated = false;
        for (var j = 0; j < childComments.length; j++) {
          Map<String, dynamic> child = Map<String, dynamic>.from(
            childComments[j],
          );
          if (child['comment_id'] == commentId) {
            List likes = List.from(child['likes'] ?? []);
            if (likes.contains(userId)) {
              likes.remove(userId);
            } else {
              likes.add(userId);
            }
            child['likes'] = likes;
            childComments[j] = child;
            childUpdated = true;
            break;
          }
        }

        if (childUpdated) {
          comment['child_comments'] = childComments;
          comments[i] = comment;
          updated = true;
          break;
        }
      }

      if (updated) {
        transaction.update(postRef, {'comments': comments});
      }
    });
  }

  Future<void> createSavedPost(int postId, int userId, int createdBy) async {
    final recordId = _generateId();
    final data = {
      'record_id': recordId,
      'post_id': postId,
      'user_id': userId,
      'created_by': createdBy,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': true,
    };
    await _db.collection('saved_posts').doc('$recordId').set(data);
  }

  Future<void> deleteSavedPost(int recordId) async {
    await _db.collection('saved_posts').doc('$recordId').delete();
  }

  Future<void> createPostRepost(
    int postId,
    int userId,
    String description,
    int createdBy, {
    Map<String, dynamic>? userInfo,
  }) async {
    final postRef = _db.collection('posts').doc('$postId');
    final repostId = _generateId();
    final repost = {
      'repost_id': repostId,
      'post_id': postId,
      'user_id': userId,
      'description': description,
      'created_by': createdBy,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (userInfo != null) 'repost_user_detail': userInfo,
    };

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List reposts = snapshot.data()?['reposts'] ?? [];
      reposts.add(repost);

      int repostCount = snapshot.data()?['repost_count'] ?? 0;

      transaction.update(postRef, {
        'reposts': reposts,
        'repost_count': repostCount + 1,
      });
    });
  }

  // --- Cases ---
  Future<void> submitPollVote(int caseId, int userId, String side) async {
    final postRef = _db.collection('posts').doc('$caseId');
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final pollCount =
          data['case_poll_count'] ??
          {'owner_count': 0, 'defendant_count': 0, 'total_count': 0};

      if (side == 'Y' || side == 'owner') {
        pollCount['owner_count'] = (pollCount['owner_count'] as int) + 1;
      } else {
        pollCount['defendant_count'] =
            (pollCount['defendant_count'] as int) + 1;
      }
      pollCount['total_count'] = (pollCount['total_count'] as int) + 1;

      transaction.update(postRef, {'case_poll_count': pollCount});
    });
  }

  Future<List<PendingCase>> getPendingCasesByUserId(int userId) async {
    final query = await _db
        .collection('pending_cases')
        .where('tag_defendent_user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING_DEFENDANT_APPROVAL')
        .get();

    final casesList = query.docs
        .map((doc) => PendingCase.fromJson(doc.data()))
        .toList();
    casesList.sort(
      (a, b) => (b.caseCreatedAt ?? '').compareTo(a.caseCreatedAt ?? ''),
    );

    // Enrich with creator user info if not already present
    final creatorIds = <int>{};
    for (final c in casesList) {
      if (c.creatorFirstName == null && c.userId != null) {
        creatorIds.add(c.userId!);
      }
    }

    if (creatorIds.isNotEmpty) {
      final users = await UserCacheService().batchGetUsers(creatorIds.toList());
      for (var i = 0; i < casesList.length; i++) {
        final c = casesList[i];
        if (c.creatorFirstName == null && c.userId != null) {
          final userInfo = users[c.userId!];
          if (userInfo != null) {
            casesList[i] = c.copyWith(
              creatorFirstName: userInfo.firstName,
              creatorLastName: userInfo.lastName,
              creatorAvatarUrl: userInfo.avatarUrl,
            );
          }
        }
      }
    }

    return casesList;
  }

  Future<PendingCase?> getPendingCaseById(int caseId) async {
    final doc = await _db.collection('pending_cases').doc('$caseId').get();
    if (doc.exists && doc.data() != null) {
      return PendingCase.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> createCase(Map<String, dynamic> data) async {
    final caseId = _generateId();
    data['case_id'] = caseId;
    data['case_created_at'] = DateTime.now().toUtc().toIso8601String();

    bool isTagged = data['tag_defendent_user_id'] != null;
    data['status'] = isTagged ? 'PENDING_DEFENDANT_APPROVAL' : 'ACTIVE';

    // Write to cases
    await _db.collection('cases').doc('$caseId').set(data);

    // Also write to pending_cases so it shows up there (with creator info embedded)
    final pendingData = Map<String, dynamic>.from(data);
    if (data['user_id'] != null) {
      final creatorInfo = await UserCacheService().getUser(
        data['user_id'] is int
            ? data['user_id']
            : int.tryParse('${data['user_id']}') ?? 0,
      );
      if (creatorInfo != null) {
        pendingData['creator_first_name'] = creatorInfo.firstName;
        pendingData['creator_last_name'] = creatorInfo.lastName;
        pendingData['creator_avatar_url'] = creatorInfo.avatarUrl;
      }
    }
    await _db.collection('pending_cases').doc('$caseId').set(pendingData);

    if (isTagged) {
      // Send notification to tagged user
      final notificationId = _generateId();
      await _db.collection('notifications').doc('$notificationId').set({
        'notification_id': notificationId,
        'user_id': data['tag_defendent_user_id'],
        'notification_type': 'P',
        'view_type': 'RN',
        'notification_detail':
            'You have been invited to contribute to a post. Tap to add your opinion.',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'notification_meta': '{"case_id": $caseId}',
        'is_read': 0,
      });
      return; // Stop here, do not publish to posts yet
    }

    // If case is public, publish as a post!
    if (data['case_view_status_id'] == 6) {
      final userData = await _getUserDataById(data['user_id']);
      Map<String, dynamic>? userInfo;
      if (userData != null) {
        final avatar =
            userData['profileImageUrl'] ??
            userData['profile_image_url'] ??
            userData['avatar_url'] ??
            '';
        userInfo = {
          'first_name': userData['firstName'] ?? userData['first_name'] ?? '',
          'last_name': userData['lastName'] ?? userData['last_name'] ?? '',
          'user_email': userData['email'] ?? userData['user_email'] ?? '',
          'avatar_url': avatar,
          'application_meta': {
            'meta_id': 0,
            'meta_type_id': 1,
            'meta_url': avatar,
            'is_active': 'Y',
          },
        };
      }

      List<Map<String, dynamic>> defendantDetails = [];
      if (data['tag_defendent_user_id'] != null) {
        final defData = await _getUserDataById(data['tag_defendent_user_id']);
        if (defData != null) {
          final defAvatar =
              defData['profileImageUrl'] ??
              defData['profile_image_url'] ??
              defData['avatar_url'] ??
              '';
          defendantDetails.add({
            'defendent_id': data['tag_defendent_user_id'],
            'user_info': {
              'first_name': defData['firstName'] ?? defData['first_name'] ?? '',
              'last_name': defData['lastName'] ?? defData['last_name'] ?? '',
              'user_email': defData['email'] ?? defData['user_email'] ?? '',
              'avatar_url': defAvatar,
            },
          });
        }
      }

      final postData = {
        'post_id': caseId,
        'case_id': caseId,
        'post_description': data['case_description'] ?? '',
        'created_by': data['user_id'],
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (userInfo != null) 'created_by_user_info': userInfo,
        'case_detail': {
          'case_id': caseId,
          'case_title': data['case_title'] ?? '',
          'case_description': data['case_description'] ?? '',
          'case_category_id': data['case_category_id'],
          'meta': {
            'meta_id': data['meta_id'] ?? caseId,
            'meta_type_id': data['meta_type_id'] ?? 1,
            'meta_url': data['meta_url'] ?? '',
            'is_active': 'Y',
          },
          'application_meta': {
            'meta_id': data['meta_id'] ?? caseId,
            'meta_type_id': data['meta_type_id'] ?? 1,
            'meta_url': data['meta_url'] ?? '',
            'is_active': 'Y',
          },
          'meta_list': data['meta_list'] ?? [],
        },
        'defendant_details': defendantDetails,
        'comments': [],
        'reactions': [],
        'reaction_summary': {
          'like_count': 0,
          'dislike_count': 0,
          'heart_count': 0,
        },
        'case_poll_count': {
          'owner_count': 0,
          'defendant_count': 0,
          'total_count': 0,
        },
        'repost_count': 0,
        'reposts': [],
      };

      await _db.collection('posts').doc('$caseId').set(postData);
    }
  }

  Future<Map<String, dynamic>?> _getUserDataById(dynamic userId) async {
    if (userId == null) return null;
    final intId = userId is int ? userId : int.tryParse('$userId');

    if (intId != null) {
      final q1 = await _db
          .collection('users')
          .where('user_id', isEqualTo: intId)
          .get();
      if (q1.docs.isNotEmpty) return q1.docs.first.data();

      final q1Camel = await _db
          .collection('users')
          .where('userId', isEqualTo: intId)
          .get();
      if (q1Camel.docs.isNotEmpty) return q1Camel.docs.first.data();
    }

    final q2 = await _db
        .collection('users')
        .where('user_id', isEqualTo: '$userId')
        .get();
    if (q2.docs.isNotEmpty) return q2.docs.first.data();

    final q2Camel = await _db
        .collection('users')
        .where('userId', isEqualTo: '$userId')
        .get();
    if (q2Camel.docs.isNotEmpty) return q2Camel.docs.first.data();

    final q4 = await _db
        .collection('users')
        .where('firebase_uid', isEqualTo: '$userId')
        .get();
    if (q4.docs.isNotEmpty) return q4.docs.first.data();

    final doc = await _db.collection('users').doc('$userId').get();
    if (doc.exists && doc.data() != null) return doc.data();

    // Fallback collection scan — also handles legacy uid.hashCode stored as created_by
    try {
      final all = await _db.collection('users').get();
      for (final d in all.docs) {
        final data = d.data();
        final raw = data['userId'] ?? data['user_id'];
        final docId = raw is int ? raw : int.tryParse('$raw');
        if (docId != null && intId != null && docId == intId) return data;
        // Also check if firebase_uid.hashCode matches (legacy uid.hashCode stored as created_by)
        final firebaseUid = data['firebase_uid'] ?? d.id;
        if (intId != null &&
            firebaseUid is String &&
            firebaseUid.hashCode == intId) {
          return data;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> approveAndPublishCase({
    required int caseId,
    required int defendentId,
    required String caseResolution,
    int? metaId,
    String? metaUrl,
  }) async {
    final caseDoc = await _db.collection('cases').doc('$caseId').get();
    final data = caseDoc.exists ? caseDoc.data()! : <String, dynamic>{};

    data['status'] = 'ACTIVE';
    data['defendant_resolution'] = caseResolution;

    await _db.collection('cases').doc('$caseId').update({
      'status': 'ACTIVE',
      'defendant_resolution': caseResolution,
    });
    await _db.collection('pending_cases').doc('$caseId').update({
      'status': 'ACTIVE',
      'defendant_resolution': caseResolution,
    });

    final notifs = await _db
        .collection('notifications')
        .where('case_id', isEqualTo: caseId)
        .get();
    for (var doc in notifs.docs) {
      await doc.reference.update({'is_read': 1});
    }

    final creatorId = data['user_id'];
    final userData = await _getUserDataById(creatorId);
    final creatorFirstName =
        userData?['firstName'] ?? userData?['first_name'] ?? '';
    final creatorLastName =
        userData?['lastName'] ?? userData?['last_name'] ?? '';
    final creatorAvatar =
        userData?['profileImageUrl'] ?? userData?['profile_image_url'] ?? '';

    final userInfo = {
      'first_name': creatorFirstName,
      'last_name': creatorLastName,
      'user_email': userData?['email'] ?? userData?['user_email'] ?? '',
      'avatar_url': creatorAvatar,
      'application_meta': {
        'meta_id': 0,
        'meta_type_id': 1,
        'meta_url': creatorAvatar,
        'is_active': 'Y',
      },
    };

    final defData = await _getUserDataById(defendentId);
    final defFirstName = defData?['firstName'] ?? defData?['first_name'] ?? '';
    final defLastName = defData?['lastName'] ?? defData?['last_name'] ?? '';
    final defAvatar =
        defData?['profileImageUrl'] ?? defData?['profile_image_url'] ?? '';

    final Map<String, dynamic> defMeta = {
      'meta_id': metaId ?? caseId,
      'meta_type_id': 1,
      'meta_url': metaUrl ?? '',
      'is_active': 'Y',
    };

    List<Map<String, dynamic>> defendantDetails = [
      {
        'defendent_id': defendentId,
        'case_resolution': caseResolution,
        'user_info': {
          'first_name': defFirstName,
          'last_name': defLastName,
          'user_email': defData?['email'] ?? defData?['user_email'] ?? '',
          'avatar_url': defAvatar,
        },
        if (metaUrl != null && metaUrl.isNotEmpty) 'meta': defMeta,
        if (metaUrl != null && metaUrl.isNotEmpty) 'meta_list': [defMeta],
        if (metaUrl != null && metaUrl.isNotEmpty) 'application_meta': defMeta,
      },
    ];

    final primaryMetaUrl =
        data['meta_url'] ??
        (data['application_meta'] is Map
            ? data['application_meta']['meta_url']
            : '');
    final Map<String, dynamic> primaryMeta = {
      'meta_id': data['meta_id'] ?? caseId,
      'meta_type_id': data['meta_type_id'] ?? 1,
      'meta_url': primaryMetaUrl ?? '',
      'is_active': 'Y',
    };

    final postData = {
      'post_id': caseId,
      'case_id': caseId,
      'post_description': data['case_description'] ?? '',
      'created_by': creatorId ?? 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'created_by_user_info': userInfo,
      'case_detail': {
        'case_id': caseId,
        'case_title': data['case_title'] ?? "Who's Right?",
        'case_description': data['case_description'] ?? '',
        'case_category_id': data['case_category_id'],
        'meta': primaryMeta,
        'application_meta': primaryMeta,
        'meta_list': [primaryMeta],
      },
      'defendant_details': defendantDetails,
      'comments': [],
      'reactions': [],
      'reaction_summary': {
        'like_count': 0,
        'dislike_count': 0,
        'heart_count': 0,
      },
      'case_poll_count': {
        'owner_count': 0,
        'defendant_count': 0,
        'total_count': 0,
      },
      'repost_count': 0,
      'reposts': [],
    };

    await _db.collection('posts').doc('$caseId').set(postData);
  }

  Future<void> deleteCase(int caseId) async {
    await _db.collection('cases').doc('$caseId').delete();
    await _db.collection('pending_cases').doc('$caseId').delete();
  }

  // --- User Profile ---
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
    if (payload.containsKey('firstName') &&
        !payload.containsKey('first_name')) {
      payload['first_name'] = payload['firstName'];
    }
    if (payload.containsKey('lastName') && !payload.containsKey('last_name')) {
      payload['last_name'] = payload['lastName'];
    }
    if (payload.containsKey('email') && !payload.containsKey('user_email')) {
      payload['user_email'] = payload['email'];
    }
    if (payload.containsKey('profileImageUrl')) {
      payload['profile_image_url'] ??= payload['profileImageUrl'];
      payload['avatar_url'] ??= payload['profileImageUrl'];
    }
    await _db.collection('users').doc(uid).update(payload);
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final rawId = doc.data()?['user_id'] ?? doc.data()?['userId'];
        final intId = rawId is int ? rawId : int.tryParse('$rawId');
        if (intId != null) {
          UserCacheService().invalidate(intId);
        }
      }
    } catch (_) {}
    UserCacheService().invalidateByFirebaseUid(uid);
  }

  Future<List<UserOption>> getAllUsers() async {
    final query = await _db.collection('users').get();
    // We map them to UserOption. We need to handle userId (int vs string).
    // Let's assume user document has an integer user_id.
    return query.docs.map((doc) {
      final data = doc.data();
      final userIdVal = data['user_id'] ?? data['userId'];
      final userId = userIdVal is int
          ? userIdVal
          : int.tryParse('$userIdVal') ?? doc.id.hashCode;
      return UserOption(
        userId: userId,
        firstName: data['first_name'] ?? data['firstName'] ?? '',
        lastName: data['last_name'] ?? data['lastName'] ?? '',
        email: data['user_email'] ?? data['email'],
      );
    }).toList();
  }

  // --- Notifications & Announcements ---
  Future<List<AppNotificationItem>> getNotificationsByUserId(int userId) async {
    try {
      final query = await _db.collection('notifications').get();
      final docs = query.docs.where((doc) {
        final data = doc.data();
        final targetUid = data['user_id'];
        final isBroadcast = data['is_broadcast'] == true;
        return isBroadcast || targetUid == 0 || targetUid == userId;
      }).toList();
      final notifications = docs
          .map((doc) => AppNotificationItem.fromJson(doc.data()))
          .toList();
      notifications.sort(
        (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
      );
      return notifications;
    } catch (_) {
      return [];
    }
  }

  Future<void> createAnnouncement({
    required String category,
    required String alertNote,
    required int attachedMetaId,
    required int createdBy,
    String? mediaUrl,
  }) async {
    final id = _generateId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _db.collection('announcements').doc('$id').set({
      'announcement_id': id,
      'category': category,
      'alert_note': alertNote,
      'attached_meta_id': attachedMetaId,
      'created_by': createdBy,
      'created_at': nowIso,
      'media_url': mediaUrl ?? '',
    });

    final notificationMetaJson = jsonEncode({
      'case_title': 'Announcement: $category',
      'case_description': alertNote,
      'category': category,
      'timestamp': nowIso,
      'application_meta': {
        'meta_id': attachedMetaId,
        'meta_type_id': 1,
        'meta_url': mediaUrl ?? '',
        'is_active': 'Y',
      },
    });

    await _db.collection('notifications').doc('$id').set({
      'notification_id': id,
      'user_id': 0,
      'is_broadcast': true,
      'notification_type': 'A',
      'notification_status': 'unread',
      'view_type': 'SN',
      'notification_detail': alertNote,
      'notification_meta': notificationMetaJson,
      'created_at': nowIso,
    });
  }

  Future<void> sendWarningToUser(
    int userId,
    String alertNote,
    int attachedMetaId,
  ) async {
    final id = _generateId();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final notificationMetaJson = jsonEncode({
      'case_title': 'Warning Notice',
      'case_description': alertNote,
      'category': 'Warning',
      'timestamp': nowIso,
      'application_meta': {
        'meta_id': attachedMetaId,
        'meta_type_id': 1,
        'meta_url': '',
        'is_active': 'Y',
      },
    });

    await _db.collection('notifications').doc('$id').set({
      'notification_id': id,
      'user_id': userId,
      'is_broadcast': false,
      'notification_type': 'W',
      'notification_status': 'unread',
      'view_type': 'SN',
      'notification_detail': alertNote,
      'notification_meta': notificationMetaJson,
      'created_at': nowIso,
    });
  }

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final query = await _db
          .collection('announcements')
          .orderBy('created_at', descending: true)
          .get();
      return query.docs.map((doc) => doc.data()).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Parameters ---
  Future<List<GeneralParameterOption>> getParametersByHeader(
    String header,
  ) async {
    final query = await _db
        .collection('parameters')
        .where('param_header', isEqualTo: header)
        .get();
    return query.docs
        .map((doc) => GeneralParameterOption.fromJson(doc.data()))
        .toList();
  }

  // --- Reels (Highlights) ---
  Future<void> createReel({
    required int userId,
    required int reelMetaId,
    required String description,
  }) async {
    final reelId = _generateId();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final expireIso = DateTime.now()
        .add(const Duration(hours: 24))
        .toUtc()
        .toIso8601String();

    // Fetch media details
    Map<String, dynamic>? applicationMeta;
    final mediaDoc = await _db.collection('media').doc('$reelMetaId').get();
    if (mediaDoc.exists) {
      applicationMeta = mediaDoc.data();
    } else {
      applicationMeta = {
        'meta_id': reelMetaId,
        'meta_type_id': 1,
        'meta_url': '',
        'is_active': 'Y',
      };
    }

    // Fetch creator details using full fallback strategy (handles uid.hashCode, all field aliases)
    Map<String, dynamic>? creatorInfo;
    final userData = await _getUserDataById(userId);
    if (userData != null) {
      creatorInfo = {
        'user_id': userId,
        'first_name': userData['first_name'] ?? userData['firstName'] ?? '',
        'last_name': userData['last_name'] ?? userData['lastName'] ?? '',
        'user_email': userData['user_email'] ?? userData['email'] ?? '',
        'application_meta': {
          'meta_id': 0,
          'meta_type_id': 1,
          'meta_url':
              userData['profileImageUrl'] ??
              userData['profile_image_url'] ??
              userData['avatar_url'] ??
              '',
          'is_active': 'Y',
        },
      };
    }

    final reelData = {
      'reel_id': reelId,
      'user_id': userId,
      'reel_meta_id': reelMetaId,
      'reel_description': description,
      'is_active': 'Y',
      'reel_start_date': nowIso,
      'reel_expire_date': expireIso,
      'created_by': userId,
      'created_at': nowIso,
      'application_meta': applicationMeta,
      'user_info': creatorInfo,
    };

    await _db.collection('reels').doc('$reelId').set(reelData);
  }

  Future<List<ActiveReel>> getAllActiveReels() async {
    final query = await _db
        .collection('reels')
        .where('is_active', isEqualTo: 'Y')
        .get();

    final now = DateTime.now().toUtc();
    final reels = <ActiveReel>[];

    for (var doc in query.docs) {
      final data = doc.data();
      final expireStr = data['reel_expire_date'] as String?;
      if (expireStr != null) {
        final expire = DateTime.tryParse(expireStr);
        if (expire != null && now.isAfter(expire)) {
          await doc.reference.update({'is_active': 'N'});
          continue;
        }
      }
      // Enrich missing/empty user_info at read-time
      final enrichedData = await _enrichReelData(data);
      reels.add(ActiveReel.fromJson(enrichedData));
    }

    reels.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    return reels;
  }

  /// Fills in missing user_info on a reel's raw Firestore map.
  Future<Map<String, dynamic>> _enrichReelData(
    Map<String, dynamic> data,
  ) async {
    final existingUserInfo = data['user_info'];
    final existingFirstName =
        (existingUserInfo is Map
            ? existingUserInfo['first_name'] ?? existingUserInfo['firstName']
            : null) ??
        '';
    if (existingFirstName.toString().trim().isNotEmpty)
      return data; // already has a name

    final rawUserId = data['user_id'] ?? data['created_by'];
    if (rawUserId == null) return data;

    try {
      final userData = await _getUserDataById(rawUserId);
      if (userData == null) return data;
      final avatar =
          userData['profileImageUrl'] ??
          userData['profile_image_url'] ??
          userData['avatar_url'] ??
          '';
      final enriched = Map<String, dynamic>.from(data);
      enriched['user_info'] = {
        'user_id': rawUserId,
        'first_name': userData['first_name'] ?? userData['firstName'] ?? '',
        'last_name': userData['last_name'] ?? userData['lastName'] ?? '',
        'user_email': userData['user_email'] ?? userData['email'] ?? '',
        'application_meta': {
          'meta_id': 0,
          'meta_type_id': 1,
          'meta_url': avatar,
          'is_active': 'Y',
        },
      };
      return enriched;
    } catch (_) {
      return data;
    }
  }

  Future<ActiveReel?> getUserReel(int userId) async {
    try {
      final matchingIds = await getAllMatchingUserIds(userId);
      final allReels = await getAllActiveReels();
      for (final reel in allReels) {
        if ((reel.userId != null && matchingIds.contains(reel.userId)) ||
            (reel.createdBy != null && matchingIds.contains(reel.createdBy))) {
          return reel;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteUserReel(int reelId) async {
    await _db.collection('reels').doc('$reelId').delete();
  }

  // --- Admin Functions ---

  Future<List<UserOption>> getUsersByRole(String role) async {
    final query = await _db
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      final userIdVal = data['user_id'] ?? data['userId'];
      final userId = userIdVal is int
          ? userIdVal
          : int.tryParse('$userIdVal') ?? doc.id.hashCode;
      return UserOption(
        userId: userId,
        firstName: data['first_name'] ?? data['firstName'] ?? '',
        lastName: data['last_name'] ?? data['lastName'] ?? '',
        email: data['user_email'] ?? data['email'],
      );
    }).toList();
  }

  Future<void> blockUser(String firebaseUid, String reason) async {
    await _db.collection('users').doc(firebaseUid).update({
      'is_active': 'N',
      'block_reason': reason,
      'blocked_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Also record in blocked_users collection
    final recordId = _generateId();
    await _db.collection('blocked_users').doc('$recordId').set({
      'record_id': recordId,
      'user_firebase_uid': firebaseUid,
      'reason': reason,
      'blocked_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> unblockUser(String firebaseUid) async {
    await _db.collection('users').doc(firebaseUid).update({
      'is_active': 'Y',
      'block_reason': FieldValue.delete(),
      'blocked_at': FieldValue.delete(),
    });
  }

  Future<void> deletePost(int postId) async {
    // Soft delete or hard delete? Let's do hard delete or soft delete. We'll do soft delete by is_active for safety.
    // Or hard delete. Let's hard delete from posts, and also cases.
    await _db.collection('posts').doc('$postId').delete();
    await _db.collection('cases').doc('$postId').delete();
    await _db.collection('pending_cases').doc('$postId').delete();
  }

  Future<void> hidePost(int postId, bool hidden) async {
    await _db.collection('posts').doc('$postId').update({'is_hidden': hidden});
  }

  Future<void> hideVotingResults(int postId, bool hidden) async {
    await _db.collection('posts').doc('$postId').update({
      'vote_results_hidden': hidden,
    });
  }

  Future<void> deleteComment(int postId, int commentId) async {
    final postRef = _db.collection('posts').doc('$postId');
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List comments = List.from(snapshot.data()?['comments'] ?? []);

      comments.removeWhere((c) => c['comment_id'] == commentId);
      for (var c in comments) {
        if (c['child_comments'] != null) {
          List childComments = List.from(c['child_comments']);
          childComments.removeWhere(
            (child) => child['comment_id'] == commentId,
          );
          c['child_comments'] = childComments;
        }
      }

      transaction.update(postRef, {'comments': comments});
    });
  }

  Future<List<Map<String, dynamic>>> getPostReports() async {
    final query = await _db
        .collection('post_reports')
        .orderBy('created_at', descending: true)
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<void> createPostReport({
    required int postId,
    required int reportReasonTypeId,
    required String reportAdditionalInformation,
    required int createdBy,
    String reportStatus = 'P',
  }) async {
    final reportId = _generateId();
    await _db.collection('post_reports').doc('$reportId').set({
      'report_id': reportId,
      'post_id': postId,
      'report_reason_type_id': reportReasonTypeId,
      'report_additional_information': reportAdditionalInformation,
      'created_by': createdBy,
      'report_status': reportStatus,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Also increment report_count on post
    final postRef = _db.collection('posts').doc('$postId');
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final currentCount = snapshot.data()?['report_count'] ?? 0;
      transaction.update(postRef, {'report_count': currentCount + 1});
    });
  }

  Future<Map<String, int>> getDashboardStats() async {
    int activeUsers = 0;
    int totalUsers = 0;

    final usersQuery = await _db
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    totalUsers = usersQuery.docs.length;
    for (var doc in usersQuery.docs) {
      final data = doc.data();
      if (data['is_active'] != 'N') {
        // default is active if missing
        activeUsers++;
      }
    }

    return {'total_users': totalUsers, 'active_users': activeUsers};
  }

  Future<List<Map<String, dynamic>>> getUserGrowth() async {
    final usersQuery = await _db
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    List<Map<String, dynamic>> users = usersQuery.docs
        .map((doc) => doc.data())
        .toList();
    return users;
  }

  // --- Follow System & Jury Gating ---
  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
  _queryFollowDocsByFollowingId(int userId) async {
    final matches = await getAllMatchingUserIds(userId);
    final List<DocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    final Set<String> seenDocIds = {};

    for (final mId in matches) {
      try {
        final qInt = await _db
            .collection('follows')
            .where('following_id', isEqualTo: mId)
            .get();
        for (final doc in qInt.docs) {
          if (seenDocIds.add(doc.id)) allDocs.add(doc);
        }
        final qStr = await _db
            .collection('follows')
            .where('following_id', isEqualTo: '$mId')
            .get();
        for (final doc in qStr.docs) {
          if (seenDocIds.add(doc.id)) allDocs.add(doc);
        }
      } catch (e) {
        debugPrint('Error querying follows for following_id $mId: $e');
      }
    }

    if (allDocs.isEmpty) {
      try {
        final qAll = await _db.collection('follows').get();
        for (final doc in qAll.docs) {
          final data = doc.data();
          final rawFg = data['following_id'];
          final fgId = rawFg is int ? rawFg : int.tryParse('$rawFg');
          final bool matchesTarget =
              (fgId != null && matches.contains(fgId)) ||
              (rawFg != null &&
                  (matches.contains(rawFg.toString().hashCode) ||
                      matches.contains(rawFg.toString().hashCode.abs())));
          if (matchesTarget && seenDocIds.add(doc.id)) {
            allDocs.add(doc);
          }
        }
      } catch (e) {
        debugPrint('Fallback follows collection scan failed: $e');
      }
    }

    return allDocs;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
  _queryFollowDocsByFollowerId(int userId) async {
    final matches = await getAllMatchingUserIds(userId);
    final List<DocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    final Set<String> seenDocIds = {};

    for (final mId in matches) {
      try {
        final qInt = await _db
            .collection('follows')
            .where('follower_id', isEqualTo: mId)
            .get();
        for (final doc in qInt.docs) {
          if (seenDocIds.add(doc.id)) allDocs.add(doc);
        }
        final qStr = await _db
            .collection('follows')
            .where('follower_id', isEqualTo: '$mId')
            .get();
        for (final doc in qStr.docs) {
          if (seenDocIds.add(doc.id)) allDocs.add(doc);
        }
      } catch (e) {
        debugPrint('Error querying follows for follower_id $mId: $e');
      }
    }

    if (allDocs.isEmpty) {
      try {
        final qAll = await _db.collection('follows').get();
        for (final doc in qAll.docs) {
          final data = doc.data();
          final rawF = data['follower_id'];
          final fId = rawF is int ? rawF : int.tryParse('$rawF');
          final bool matchesTarget =
              (fId != null && matches.contains(fId)) ||
              (rawF != null &&
                  (matches.contains(rawF.toString().hashCode) ||
                      matches.contains(rawF.toString().hashCode.abs())));
          if (matchesTarget && seenDocIds.add(doc.id)) {
            allDocs.add(doc);
          }
        }
      } catch (e) {
        debugPrint('Fallback follows collection scan failed: $e');
      }
    }

    return allDocs;
  }

  Future<bool> isFollowing({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final docs = await _queryFollowDocsByFollowerId(followerId);
      final targetMatches = await getAllMatchingUserIds(followingId);

      for (var doc in docs) {
        final data = doc.data();
        if (data == null) continue;
        final rawFg = data['following_id'];
        final fgId = rawFg is int ? rawFg : int.tryParse('$rawFg');

        final fgMatch =
            (fgId != null && targetMatches.contains(fgId)) ||
            (rawFg != null &&
                (targetMatches.contains(rawFg.toString().hashCode) ||
                    targetMatches.contains(rawFg.toString().hashCode.abs())));

        if (fgMatch) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error in isFollowing: $e');
    }
    return false;
  }

  Future<void> followUser({
    required int followerId,
    required int followingId,
  }) async {
    if (followerId == followingId) return;
    final exists = await isFollowing(
      followerId: followerId,
      followingId: followingId,
    );
    if (exists) return;

    final followId = _generateId();
    await _db.collection('follows').doc('$followId').set({
      'follow_id': followId,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> unfollowUser({
    required int followerId,
    required int followingId,
  }) async {
    try {
      final docs = await _queryFollowDocsByFollowerId(followerId);
      final targetMatches = await getAllMatchingUserIds(followingId);

      for (var doc in docs) {
        final data = doc.data();
        if (data == null) continue;
        final rawFg = data['following_id'];
        final fgId = rawFg is int ? rawFg : int.tryParse('$rawFg');

        final fgMatch =
            (fgId != null && targetMatches.contains(fgId)) ||
            (rawFg != null &&
                (targetMatches.contains(rawFg.toString().hashCode) ||
                    targetMatches.contains(rawFg.toString().hashCode.abs())));

        if (fgMatch) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Error in unfollowUser: $e');
    }
  }

  Future<Map<String, dynamic>> getFollowStats(
    int userId, {
    int? currentUserId,
  }) async {
    try {
      final followersList = await getFollowersList(userId);
      final followingList = await getFollowingList(userId);

      bool isFollowingCurrent = false;
      if (currentUserId != null) {
        isFollowingCurrent = await isFollowing(
          followerId: currentUserId,
          followingId: userId,
        );
      }

      return {
        'followersCount': followersList.length,
        'followingCount': followingList.length,
        'isFollowingCurrent': isFollowingCurrent,
      };
    } catch (e, stack) {
      debugPrint('Error getting follow stats for $userId: $e\n$stack');
      return {
        'followersCount': 0,
        'followingCount': 0,
        'isFollowingCurrent': false,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getFollowersList(int userId) async {
    try {
      final docs = await _queryFollowDocsByFollowingId(userId);
      final followerRawValues = <dynamic>[];

      for (var doc in docs) {
        final data = doc.data();
        if (data != null) {
          final rawF = data['follower_id'];
          if (rawF != null) {
            followerRawValues.add(rawF);
          }
        }
      }

      if (followerRawValues.isEmpty) return [];

      final List<Map<String, dynamic>> resultList = [];
      final Set<dynamic> addedDedupKeys = {};

      for (final rawF in followerRawValues) {
        final userInfo = await UserCacheService().getUserDynamic(rawF);

        final dedupKey = rawF is int ? rawF : '$rawF';
        if (!addedDedupKeys.contains(dedupKey)) {
          addedDedupKeys.add(dedupKey);

          if (userInfo != null) {
            final displayId = userInfo.userId > 0
                ? userInfo.userId
                : (rawF is int
                      ? rawF
                      : (int.tryParse('$rawF') ??
                            rawF.toString().hashCode.abs()));
            resultList.add({
              'user_id': displayId,
              'first_name': userInfo.firstName,
              'last_name': userInfo.lastName,
              'user_email': userInfo.email,
              'avatar_url': userInfo.avatarUrl,
            });
          } else {
            final fallbackId = rawF is int
                ? rawF
                : (int.tryParse('$rawF') ?? rawF.toString().hashCode.abs());
            resultList.add({
              'user_id': fallbackId,
              'first_name': 'Unknown',
              'last_name': 'User',
              'user_email': '',
              'avatar_url': '',
            });
          }
        }
      }

      return resultList;
    } catch (e, stack) {
      debugPrint('Error getting followers list for user $userId: $e\n$stack');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFollowingList(int userId) async {
    try {
      final docs = await _queryFollowDocsByFollowerId(userId);
      final followingRawValues = <dynamic>[];

      for (var doc in docs) {
        final data = doc.data();
        if (data != null) {
          final rawFg = data['following_id'];
          if (rawFg != null) {
            followingRawValues.add(rawFg);
          }
        }
      }

      if (followingRawValues.isEmpty) return [];

      final List<Map<String, dynamic>> resultList = [];
      final Set<dynamic> addedDedupKeys = {};

      for (final rawFg in followingRawValues) {
        final userInfo = await UserCacheService().getUserDynamic(rawFg);

        final dedupKey = rawFg is int ? rawFg : '$rawFg';
        if (!addedDedupKeys.contains(dedupKey)) {
          addedDedupKeys.add(dedupKey);

          if (userInfo != null) {
            final displayId = userInfo.userId > 0
                ? userInfo.userId
                : (rawFg is int
                      ? rawFg
                      : (int.tryParse('$rawFg') ??
                            rawFg.toString().hashCode.abs()));
            resultList.add({
              'user_id': displayId,
              'first_name': userInfo.firstName,
              'last_name': userInfo.lastName,
              'user_email': userInfo.email,
              'avatar_url': userInfo.avatarUrl,
            });
          } else {
            final fallbackId = rawFg is int
                ? rawFg
                : (int.tryParse('$rawFg') ?? rawFg.toString().hashCode.abs());
            resultList.add({
              'user_id': fallbackId,
              'first_name': 'Unknown',
              'last_name': 'User',
              'user_email': '',
              'avatar_url': '',
            });
          }
        }
      }

      return resultList;
    } catch (e, stack) {
      debugPrint('Error getting following list for user $userId: $e\n$stack');
      return [];
    }
  }
}
