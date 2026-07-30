import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/post_report.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';

class CasePostService {
  CasePostService({client});

  Future<List<ActivePost>> getAllActivePosts({
    required String accessToken,
  }) async {
    return FirestoreDataService().getAllActivePostsEnriched();
  }

  Future<List<ActivePost>> getAllRecentPosts({
    required String accessToken,
  }) async {
    return FirestoreDataService().getAllActivePostsEnriched();
  }

  Future<List<ActivePost>> getPostsByUserId({
    required String accessToken,
    required int userId,
  }) async {
    return FirestoreDataService().getPostsByIntUserIdEnriched(userId);
  }

  Future<List<ActivePost>> getSavedPostByUserId({
    required String accessToken,
    required int userId,
  }) async {
    return FirestoreDataService().getSavedPostsByUserIdEnriched(userId);
  }

  Future<void> submitCasePollVote({
    required String accessToken,
    required int caseId,
    required bool endPoll,
    required String ownerVote,
    required String defendantVote,
  }) async {
    final userId = AuthStorage.cachedUserId;
    if (userId != null) {
      await FirestoreDataService().submitPollVote(
        caseId,
        userId,
        ownerVote == 'Y' ? 'owner' : 'defendant'
      );
    }
  }

  Future<void> createPostReaction({
    required String accessToken,
    required int postId,
    required int userId,
    required String reactionType,
  }) async {
    await FirestoreDataService().createPostReaction(postId, userId, reactionType);
  }

  Future<void> deletePostReaction({
    required String accessToken,
    required int postId,
  }) async {
    final userId = AuthStorage.cachedUserId;
    if (userId != null) {
      await FirestoreDataService().deletePostReaction(postId, userId);
    }
  }

  Future<void> createPostComment({
    required String accessToken,
    required int postId,
    required int userId,
    required String commentContent,
  }) async {
    await FirestoreDataService().createPostComment(postId, userId, commentContent);
  }

  Future<void> createSavedPost({
    required String accessToken,
    required int postId,
    required int userId,
    required int createdBy,
  }) async {
    await FirestoreDataService().createSavedPost(postId, userId, createdBy);
  }

  Future<void> deleteSavedPost({
    required String accessToken,
    required int savedPostId,
  }) async {
    await FirestoreDataService().deleteSavedPost(savedPostId);
  }

  Future<void> createPostRepost({
    required String accessToken,
    required int postId,
    required int userId,
    required String postDescription,
    required int createdBy,
  }) async {
    final userInfo = {
      'first_name': AuthStorage.cachedFirstName ?? '',
      'last_name': AuthStorage.cachedLastName ?? '',
      'user_email': AuthStorage.cachedEmail ?? '',
      'avatar_url': AuthStorage.cachedProfileImageUrl ?? '',
    };
    await FirestoreDataService().createPostRepost(
      postId,
      userId,
      postDescription,
      createdBy,
      userInfo: userInfo,
    );
  }

  Future<void> createPostChildComment({
    required String accessToken,
    required int postId,
    required int userId,
    required int parentCommentId,
    required String commentContent,
  }) async {
    await FirestoreDataService().createChildComment(postId, parentCommentId, userId, commentContent);
  }

  Future<void> likeComment({
    required String accessToken,
    required int postId,
    required int commentId,
    required int userId,
  }) async {
    await FirestoreDataService().likeComment(postId, commentId, userId);
  }

  Future<void> createPostReport({
    required String accessToken,
    required int postId,
    required int reportReasonTypeId,
    required String reportAdditionalInformation,
    required int createdBy,
    String reportStatus = 'P',
  }) async {
    await FirestoreDataService().createPostReport(
      postId: postId,
      reportReasonTypeId: reportReasonTypeId,
      reportAdditionalInformation: reportAdditionalInformation,
      createdBy: createdBy,
      reportStatus: reportStatus,
    );
  }

  Future<void> remindCasePending({
    required String accessToken,
    required int caseId,
  }) async {
    // Reminder logic
  }

  Future<List<Map<String, dynamic>>> getPostReportsRaw({
    required String accessToken,
  }) async {
    return FirestoreDataService().getPostReports();
  }

  Future<void> deletePost({
    required String accessToken,
    required int postId,
  }) async {
    await FirestoreDataService().deletePost(postId);
  }

  Future<void> hidePost({
    required String accessToken,
    required int postId,
    required bool hidden,
  }) async {
    await FirestoreDataService().hidePost(postId, hidden);
  }

  Future<void> hideVotingResults({
    required String accessToken,
    required int postId,
    required bool hidden,
  }) async {
    await FirestoreDataService().hideVotingResults(postId, hidden);
  }

  Future<List<PostReport>> getPostReports({
    required String accessToken,
    String status = 'P',
  }) async {
    final reports = await FirestoreDataService().getPostReports();
    return reports.map((doc) => PostReport(
      reportId: doc['report_id'] ?? 0,
      postId: doc['post_id'] ?? 0,
      reportReasonTypeId: doc['report_reason_type_id'] ?? 0,
      reportAdditionalInformation: doc['report_additional_information'] ?? '',
      createdBy: doc['created_by'] ?? 0,
      reportStatus: doc['report_status'] ?? '',
      createdAt: doc['created_at'] ?? '',
    )).toList();
  }
}
