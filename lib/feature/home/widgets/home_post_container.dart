import 'dart:io';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/app_bottom_sheet.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/network/services/general_parameter_service.dart';
import 'package:cctv_app/core/share/post_share_helper.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adminHome/pages/report_and_suspend.dart';
import 'package:cctv_app/feature/home/widgets/comment_container.dart';
import 'package:cctv_app/feature/home/widgets/vote_container.dart';
import 'package:cctv_app/core/services/user_cache_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';

class HomePostContainer extends StatefulWidget {
  final bool isAdmin;
  final bool isSavedPost;
  final VoidCallback onClickProfile;
  final VoidCallback onPostUpdated;
  final ActivePost post;
  final ActivePostRepost? repost;
  final VoidCallback? onOpenOriginalPostInFeed;
  final bool highlightPost;
  const HomePostContainer({
    super.key,
    required this.isAdmin,
    this.isSavedPost = false,
    required this.onClickProfile,
    required this.onPostUpdated,
    required this.post,
    this.repost,
    this.onOpenOriginalPostInFeed,
    this.highlightPost = false,
  });

  @override
  State<HomePostContainer> createState() => _HomePostContainerState();
}

class _HomePostContainerState extends State<HomePostContainer> {
  bool areCommentsVisible = true;
  bool isMuted = false;
  bool isWarning = false;
  String? selectedReaction;
  bool isReactionPopupVisible = false;
  OverlayEntry? reactionOverlay;
  bool _isSubmittingVote = false;
  bool _isSubmittingReaction = false;
  bool _isSubmittingComment = false;
  bool _isSubmittingReply = false;
  bool _isSavingPost = false;
  int _reactionCountDelta = 0;
  int _likeCountDelta = 0;
  String? _selectedVote;
  int? _replyingCommentId;
  final Set<int> _expandedReplyCommentIds = <int>{};
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final GlobalKey _commentsSectionKey = GlobalKey();
  late List<ActivePostComment> _comments;
  
  bool _isFollowerOfCreator = false;
  bool _isCheckingFollowerStatus = false;
  int? _currentUserId;

  int get _reactionCount =>
      (widget.post.reactionSummary?.totalReactions ??
          widget.post.reactions.length) +
      _reactionCountDelta;

  int get _likeCount {
    final summary = widget.post.reactionSummary?.byType ?? const {};
    final likeValue =
        summary['Like'] ??
        summary['LIKE'] ??
        summary['like'];
    final parsedLikeCount = int.tryParse('$likeValue');
    if (parsedLikeCount != null) {
      return parsedLikeCount + _likeCountDelta;
    }

    final reactionLikes = widget.post.reactions
        .where(
          (reaction) => _normalizeReactionType(reaction.reactionType) == 'Like',
        )
        .length;
    return reactionLikes + _likeCountDelta;
  }

  @override
  void initState() {
    super.initState();
    _comments = List<ActivePostComment>.from(widget.post.comments);
    _loadCurrentUserReaction();
    _checkJuryFollowerStatus();
  }
  
  Future<void> _checkJuryFollowerStatus() async {
    if (widget.post.caseDetail?.isJuryPost != true) return;
    
    setState(() => _isCheckingFollowerStatus = true);
    try {
      _currentUserId = await const AuthStorage().readUserId();
      if (_currentUserId == null) return;
      
      final authorId = widget.post.authorUserId;
      if (authorId == null || authorId == _currentUserId) {
        _isFollowerOfCreator = true;
        return;
      }
      
      _isFollowerOfCreator = await FirestoreDataService().isFollowing(
        followerId: _currentUserId!,
        followingId: authorId,
      );
    } catch (e) {
      debugPrint('Error checking follower status: $e');
    } finally {
      if (mounted) setState(() => _isCheckingFollowerStatus = false);
    }
  }

  @override
  void didUpdateWidget(covariant HomePostContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNewPost = oldWidget.post.postId != widget.post.postId;
    final hasFreshPostData = !identical(oldWidget.post, widget.post);

    if (isNewPost) {
      _reactionCountDelta = 0;
      _likeCountDelta = 0;
      _comments = List<ActivePostComment>.from(widget.post.comments);
      _commentController.clear();
      _replyController.clear();
      _replyingCommentId = null;
      _expandedReplyCommentIds.clear();
      _loadCurrentUserReaction();
      return;
    }

    if (hasFreshPostData) {
      _reactionCountDelta = 0;
      _likeCountDelta = 0;
      _comments = List<ActivePostComment>.from(widget.post.comments);
      _loadCurrentUserReaction();
    }

    final oldTotal =
        oldWidget.post.reactionSummary?.totalReactions ??
        oldWidget.post.reactions.length;
    final newTotal =
        widget.post.reactionSummary?.totalReactions ??
        widget.post.reactions.length;
    if (oldTotal != newTotal) {
      _reactionCountDelta = 0;
    }

    final oldLikeTotal = oldWidget.post.reactionSummary?.byType['Like'] ??
        oldWidget.post.reactionSummary?.byType['LIKE'] ??
        oldWidget.post.reactionSummary?.byType['like'] ??
        oldWidget.post.reactions
            .where(
              (reaction) =>
                  _normalizeReactionType(reaction.reactionType) == 'Like',
            )
            .length;
    final newLikeTotal = widget.post.reactionSummary?.byType['Like'] ??
        widget.post.reactionSummary?.byType['LIKE'] ??
        widget.post.reactionSummary?.byType['like'] ??
        widget.post.reactions
            .where(
              (reaction) =>
                  _normalizeReactionType(reaction.reactionType) == 'Like',
            )
            .length;
    final normalizedOldLikeTotal = int.tryParse('$oldLikeTotal') ?? 0;
    final normalizedNewLikeTotal = int.tryParse('$newLikeTotal') ?? 0;
    if (normalizedOldLikeTotal != normalizedNewLikeTotal) {
      _likeCountDelta = 0;
    }
  }

  String _timeLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    final now = DateTime.now();
    final diff = now.difference(parsed);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
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
    return '$month ${parsed.day}, ${parsed.year} • $hour:$minute $suffix';
  }

  Widget _buildAuthorAvatar(ActivePost post) {
    String? avatarUrl = post.authorAvatarUrl?.trim();
    final authorId = post.authorUserId;

    if ((avatarUrl == null || avatarUrl.isEmpty) && authorId != null) {
      if (authorId == AuthStorage.cachedUserId) {
        avatarUrl = AuthStorage.cachedProfileImageUrl?.trim();
      } else {
        avatarUrl = UserCacheService().getAvatarSync(authorId)?.trim();
      }
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Handle asset paths
      if (avatarUrl.startsWith('assets/')) {
        return CircleAvatar(
          radius: 30,
          backgroundColor: kLightGreyColor,
          backgroundImage: AssetImage(avatarUrl),
        );
      }

      // Handle network URLs
      return CircleAvatar(
        radius: 30,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final name = post.authorDisplayName.trim();
    final initials = name.isEmpty
        ? 'U'
        : name
              .split(' ')
              .where((part) => part.trim().isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return CircleAvatar(
      radius: 30,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials,
        style: context.semiBold.copyWith(
          color: kPrimaryColor,
          fontSize: 18,
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final initials = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'U' : initials;
  }

  Widget _buildRepostSection(ActivePostRepost repost, ActivePost post) {
    final repostAuthor = repost.repostUserDetail?.fullName.trim() ?? '';
    final repostTime = _timeLabel(repost.createdAt);
    final repostText = repost.description.trim();

    final author = post.authorDisplayName;
    final defendant = post.defendantDetails.isNotEmpty
        ? post.defendantDetails.first
        : null;
    final ownerName = author.trim().isNotEmpty
        ? author.trim()
        : (post.createdByUserInfo?.userEmail?.trim().isNotEmpty == true
            ? post.createdByUserInfo!.userEmail!.trim().split('@').first
            : 'Unknown');
    final defendantName = (defendant?.userInfo?.fullName.trim().isNotEmpty == true)
        ? defendant!.userInfo!.fullName.trim()
        : (defendant?.userInfo?.userEmail?.trim().isNotEmpty == true
            ? defendant!.userInfo!.userEmail!.trim().split('@').first
            : 'Unknown');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGreyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kTextfieldBlueColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      Assets.repostIcon,
                      width: 14,
                      height: 14,
                      color: kPrimaryColor,
                    ),
                    Space.horizontal(6),
                    Text(
                      'Repost',
                      style: context.semiBold.copyWith(
                        color: kPrimaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (repostTime.isNotEmpty) ...[
                Space.horizontal(8),
                Expanded(
                  child: Text(
                    repostTime,
                    style: context.normal.copyWith(
                      fontSize: 12,
                      color: kDarkGreyColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (repostAuthor.isNotEmpty) ...[
            Space.vertical(10),
            Text(
              repostAuthor,
              style: context.semiBold.copyWith(fontSize: 14),
            ),
          ],
          if (repostText.isNotEmpty) ...[
            Space.vertical(10),
            Text(
              repostText,
              style: context.normal.copyWith(
                fontSize: 14,
                color: kBlackColor,
              ),
            ),
          ],
          Space.vertical(12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onOpenOriginalPostInFeed,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGreyColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PostAuthorAvatar(post: post, radius: 18),
                        Space.horizontal(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorDisplayName,
                                style: context.semiBold.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((post.caseDetail?.caseTitle.trim().isNotEmpty ??
                                  false))
                                Text(
                                  post.caseDetail!.caseTitle.trim(),
                                  style: context.normal.copyWith(
                                    fontSize: 12,
                                    color: kDarkGreyColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (post.postDescription.trim().isNotEmpty) ...[
                      Space.vertical(10),
                      Text(
                        post.postDescription.trim(),
                        style: context.normal.copyWith(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((post.caseDetail?.metaList.isNotEmpty ?? false) ||
                        (post.defendantDetails.isNotEmpty &&
                            post.defendantDetails.first.metaList.isNotEmpty)) ...[
                      Space.vertical(12),
                      _PostComparisonPreview(
                        leftMediaList: post.caseDetail?.metaList ?? const [],
                        rightMediaList: post.defendantDetails.isNotEmpty
                            ? post.defendantDetails.first.metaList
                            : const [],
                      ),
                      Space.vertical(12),
                      VotingResultExample(
                        leftLabel: 'A.',
                        leftText: ownerName,
                        rightLabel: 'B.',
                        rightText: defendantName,
                        leftVotes: post.casePollCount?.ownerCount ?? 0,
                        rightVotes: post.casePollCount?.defendantCount ?? 0,
                        totalVotesCount: post.casePollCount?.totalCount ?? 0,
                      ),
                      Space.vertical(12),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: 'Resolutions',
                          buttonColor: kPrimaryColor,
                          textColor: kWhiteColor,
                          showBorder: false,
                          onPressed: () => _showSimpleDialog(context, post),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepostAuthorAvatar(ActivePostRepost repost) {
    String? avatarUrl = repost.repostUserDetail?.avatarUrl?.trim();
    final authorId = repost.userId ?? repost.createdBy;

    if ((avatarUrl == null || avatarUrl.isEmpty) && authorId != null) {
      if (authorId == AuthStorage.cachedUserId) {
        avatarUrl = AuthStorage.cachedProfileImageUrl?.trim();
      } else {
        avatarUrl = UserCacheService().getAvatarSync(authorId)?.trim();
      }
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('assets/')) {
        return CircleAvatar(
          radius: 30,
          backgroundColor: kLightGreyColor,
          backgroundImage: AssetImage(avatarUrl),
        );
      }

      return CircleAvatar(
        radius: 30,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final name = repost.repostUserDetail?.fullName.trim() ?? '';
    final initials = name.isEmpty
        ? 'U'
        : name
              .split(' ')
              .where((part) => part.trim().isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return CircleAvatar(
      radius: 30,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials,
        style: context.semiBold.copyWith(
          color: kPrimaryColor,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStandaloneRepostCard(
    BuildContext context, {
    required ActivePost post,
    required ActivePostRepost repost,
  }) {
    final repostAuthor = repost.repostUserDetail?.fullName.trim() ?? '';
    final authorName = repostAuthor;
    final timeText = _timeLabel(repost.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: widget.highlightPost ? kPrimaryColor : kGreyColor,
          width: widget.highlightPost ? 2 : 1,
        ),
        boxShadow: widget.highlightPost
            ? [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onClickProfile,
                    child: Row(
                      children: [
                        _buildRepostAuthorAvatar(repost),
                        Space.horizontal(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: context.semiBold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                timeText.isEmpty ? 'Just now' : timeText,
                                style: context.normal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Space.vertical(20),
            _buildRepostSection(repost, post),
          ],
        ),
      ),
    );
  }

  Future<void> _savePost() async {
    if (_isSavingPost) return;

    setState(() {
      _isSavingPost = true;
    });

    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      await CasePostService().createSavedPost(
        accessToken: accessToken,
        postId: widget.post.postId,
        userId: userId,
        createdBy: userId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Post saved successfully');
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to save post');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPost = false;
        });
      }
    }
  }

  Future<void> _deleteSavedPost() async {
    if (_isSavingPost) return;

    setState(() {
      _isSavingPost = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final savedPostId =
          widget.post.savedPostMeta?.recordId ?? widget.post.postId;

      await CasePostService().deleteSavedPost(
        accessToken: accessToken,
        savedPostId: savedPostId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Post unsaved successfully');
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to unsave post');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPost = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final repost = widget.repost;

    if (repost != null) {
      return _buildStandaloneRepostCard(
        context,
        post: post,
        repost: repost,
      );
    }

    final author = post.authorDisplayName;
    final timeText = _timeLabel(post.createdAt);
    final defendant = post.defendantDetails.isNotEmpty
        ? post.defendantDetails.first
        : null;
    final ownerName = author.trim().isNotEmpty
        ? author.trim()
        : (post.createdByUserInfo?.userEmail?.trim().isNotEmpty == true
            ? post.createdByUserInfo!.userEmail!.trim().split('@').first
            : 'Unknown');
    final defendantName = (defendant?.userInfo?.fullName.trim().isNotEmpty == true)
        ? defendant!.userInfo!.fullName.trim()
        : (defendant?.userInfo?.userEmail?.trim().isNotEmpty == true
            ? defendant!.userInfo!.userEmail!.trim().split('@').first
            : 'Unknown');

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: kGreyColor),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onClickProfile,
                    child: Container(
                      decoration: BoxDecoration(color: kTransparentColor),
                      child: Row(
                        children: [
                          _buildAuthorAvatar(post),
                          Space.horizontal(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author,
                                  style: context.semiBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Online",
                                  style: context.normal.copyWith(
                                    fontSize: 12,
                                    color: kDarkGreyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                widget.isAdmin
                    ? GestureDetector(
                        onTap: () {
                          isMuted = false;
                          isWarning = false;
                          AppBottomSheet.show(
                            context,
                            body: StatefulBuilder(
                              builder: (context, setStateBottomSheet) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () => Navigator.of(context).pop(),
                                          child: CircleAvatar(
                                            backgroundColor: kLightGreyColor,
                                            child: SvgPicture.asset(
                                              Assets.svgCancelIcon,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Space.vertical(10),
                                      Text(
                                        'Take action against post or Profile. ',
                                        style: context.normal.copyWith(
                                          fontSize: 16,
                                          color: kDarkGreyColor,
                                        ),
                                      ),
                                      Space.vertical(20),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isMuted = true;
                                            isWarning = false;
                                          });
                                          setStateBottomSheet(() {});
                                        },
                                        child: Container(
                                          color: kTransparentColor,
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                Assets.svgMuteIcon,
                                              ),
                                              Space.horizontal(12),
                                              Text(
                                                'Mute conversation',
                                                style: context.normal.copyWith(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Space.vertical(8),
                                      Divider(),
                                      Space.vertical(8),
                                      GestureDetector(
                                        onTap: () async {
                                          final navigator = Navigator.of(
                                            context,
                                          );
                                          final sentWarning =
                                              await navigator.push<bool>(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ReportAndSuspend(
                                                    initialAction:
                                                        ReportAction.warning,
                                                    targetUserId: widget
                                                        .post
                                                        .authorUserId,
                                                    attachedMetaId:
                                                        widget.post.postId,
                                                  ),
                                            ),
                                          );
                                          if (!mounted || !context.mounted) {
                                            return;
                                          }
                                          if (sentWarning == true) {
                                            setState(() {
                                              isWarning = true;
                                              isMuted = false;
                                            });
                                          }
                                          setStateBottomSheet(() {});
                                        },
                                        child: Container(
                                          color: kTransparentColor,
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                Assets.svgWarningIcon,
                                              ),
                                              Space.horizontal(12),
                                              Text(
                                                'Send Warning',
                                                style: context.normal.copyWith(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Space.vertical(8),
                                      Divider(),
                                      Space.vertical(8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ReportAndSuspend(
                                                    initialAction:
                                                        ReportAction.suspend,
                                                    targetUserId: widget
                                                        .post
                                                        .authorUserId,
                                                    attachedMetaId:
                                                        widget.post.postId,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          color: kTransparentColor,
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                Assets.svgBlockIcon,
                                              ),
                                              Space.horizontal(12),
                                              Text(
                                                'Block',
                                                style: context.normal.copyWith(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isWarning) ...[
                                        Space.vertical(16),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              Assets.svgWarningIcon,
                                            ),
                                            Space.horizontal(20),
                                            Text(
                                              'Warning has been sent',
                                              style: context.normal.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (isMuted) ...[
                                        Space.vertical(16),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              Assets.svgWarningIcon,
                                              color: kPrimaryColor,
                                            ),
                                            Space.horizontal(12),
                                            Text(
                                              'Conversation is Muted now',
                                              style: context.normal.copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      Space.vertical(40),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            border: Border.all(color: kDarkGreyColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(5.0),
                          child: Icon(Icons.more_horiz, color: kBlackColor),
                        ),
                      )
                    : PopupMenuButton<String>(
                        color: kWhiteColor,
                        elevation: 22,
                        shadowColor: kBlackColor.withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        offset: const Offset(-12, 40),
                        constraints: const BoxConstraints(
                          minWidth: 160,
                          maxWidth: 180,
                        ),
                        onSelected: (value) {
                          if (value == 'toggleSavedPost') {
                            if (widget.isSavedPost) {
                              _deleteSavedPost();
                            } else {
                              _savePost();
                            }
                            return;
                          }

                          if (value == 'copy') {
                            PostShareHelper.sharePost(
                              context,
                              post: post,
                              target: PostShareTarget.copy,
                            );
                            return;
                          }

                          if (value == 'report') {
                            _showReportBottomSheet(context, post);
                          }
                        },
                        itemBuilder: (context) => [
                          _buildPostMenuItem(
                            value: 'toggleSavedPost',
                            label: 'Save',
                            icon: Icons.bookmark,
                            isSave: true,
                          ),
                          _buildPostMenuItem(
                            value: 'copy',
                            label: 'Copy Link',
                            icon: Icons.copy_all_outlined,
                          ),
                          _buildPostMenuItem(
                            value: 'report',
                            label: 'Report',
                            icon: Icons.report_gmailerrorred_rounded,
                            color: kRedColor,
                          ),
                        ],
                        child: Container(
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            border: Border.all(color: kGreyColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(6.0),
                          child: const Icon(
                            Icons.more_horiz,
                            color: kBlackColor,
                          ),
                        ),
                      ),
              ],
            ),
            Space.vertical(20),
            if (post.caseDetail?.isJuryPost == true)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimaryColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: kPrimaryColor, size: 20),
                    Space.horizontal(8),
                    Expanded(
                      child: Text(
                        'Jury Mode: Only followers of this creator can vote.',
                        style: context.semiBold.copyWith(color: kPrimaryColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if ((post.caseDetail?.metaList.isNotEmpty ?? false) ||
                (defendant?.metaList.isNotEmpty ?? false)) ...[
              _PostComparisonPreview(
                topCaption: post.caseDetail?.caseTitle.isNotEmpty == true
                    ? post.caseDetail!.caseTitle
                    : "Who's Right",
                leftMediaList: post.caseDetail?.metaList ?? const [],
                rightMediaList: defendant?.metaList ?? const [],
              ),
              Space.vertical(15),
            ],
            Builder(
              builder: (context) {
                final pollEndDateString = post.casePollCount?.pollEndDate;
                final pollEndDate = pollEndDateString != null ? DateTime.tryParse(pollEndDateString) : null;
                final isPollEnded = pollEndDate != null && DateTime.now().toUtc().isAfter(pollEndDate.toUtc());
                
                final bool isJuryGated = post.caseDetail?.isJuryPost == true && !_isFollowerOfCreator;
                
                String? countdownText;
                if (pollEndDate != null) {
                  if (isPollEnded) {
                    countdownText = 'Poll Closed';
                  } else {
                    final diff = pollEndDate.toUtc().difference(DateTime.now().toUtc());
                    if (diff.inDays > 0) {
                      countdownText = '${diff.inDays} days left';
                    } else if (diff.inHours > 0) {
                      countdownText = '${diff.inHours} hours left';
                    } else if (diff.inMinutes > 0) {
                      countdownText = '${diff.inMinutes} mins left';
                    } else {
                      countdownText = 'Ending soon';
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (countdownText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPollEnded ? kRedColor.withValues(alpha: 0.1) : kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isPollEnded ? kRedColor : kPrimaryColor, width: 1),
                              ),
                              child: Text(
                                countdownText,
                                style: context.semiBold.copyWith(
                                  fontSize: 12,
                                  color: isPollEnded ? kRedColor : kPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isCheckingFollowerStatus)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      VotingResultExample(
                        leftLabel: 'A.',
                        leftText: ownerName,
                        rightLabel: 'B.',
                        rightText: defendantName,
                        leftVotes: post.casePollCount?.ownerCount ?? 0,
                        rightVotes: post.casePollCount?.defendantCount ?? 0,
                        totalVotesCount: post.casePollCount?.totalCount ?? 0,
                        selectedOption: _selectedVote,
                        isSubmitting: _isSubmittingVote,
                        onLeftTap: (isPollEnded || isJuryGated) ? null : () => _confirmVote(
                          context,
                          post: post,
                          selectedVote: 'owner',
                          selectedName: ownerName,
                        ),
                        onRightTap: (isPollEnded || isJuryGated) ? null : () => _confirmVote(
                          context,
                          post: post,
                          selectedVote: 'defendant',
                          selectedName: defendantName,
                        ),
                      ),
                  ],
                );
              }
            ),
            Space.vertical(15),
            PrimaryButton(
              height: 40,
              text: "Resolutions",
              onPressed: () {
                _showSimpleDialog(context, post);
              },
            ),
            Space.vertical(14),
            _buildPostActionRow(post),
            Space.vertical(20),
            const SizedBox(height: 16),
            if (areCommentsVisible) ...[
              Container(
                key: _commentsSectionKey,
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kGreyColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Comments',
                          style: context.semiBold.copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: kTextfieldBlueColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_comments.length}',
                            style: context.semiBold.copyWith(
                              color: kPrimaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Space.vertical(14),
                    if (_comments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: kLightGreyColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: kTextfieldBlueColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: kPrimaryColor,
                                size: 20,
                              ),
                            ),
                            Space.horizontal(12),
                            Expanded(
                              child: Text(
                                'No comments yet. Start the conversation.',
                                style: context.normal.copyWith(
                                  color: kDarkGreyColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCommentThread(comment),
                        );
                      }),
                    Space.vertical(4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kGreyColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              style: context.normal.copyWith(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Write comment here",
                                hintStyle: context.normal.copyWith(
                                  color: kDarkGreyColor,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitComment(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isSubmittingComment ? null : _submitComment,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: _isSubmittingComment
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kWhiteColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      size: 16,
                                      color: kWhiteColor,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    reactionOverlay?.remove();
    _commentFocusNode.dispose();
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Widget reactionContainer({
    required String text,
    required VoidCallback? onTap,
    required IconData icon,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: kGreyColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: kPrimaryColor),
            Space.horizontal(8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji) {
    return GestureDetector(
      onTap: () {
        _hideReactionPopup();
        _submitReaction(_reactionTypeFromEmoji(emoji));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        child: Text(emoji, style: TextStyle(fontSize: 24)),
      ),
    );
  }

  IconData _getReactionIcon() {
    switch (selectedReaction) {
      case "Love":
        return Icons.favorite;
      case "Haha":
        return Icons.emoji_emotions;
      case "Wow":
        return Icons.sentiment_neutral;
      case "Sad":
        return Icons.sentiment_very_dissatisfied;
      case "Angry":
        return Icons.sentiment_very_dissatisfied;
      case "Like":
        return Icons.thumb_up;
      default:
        return Icons.thumb_up_outlined;
    }
  }

  void _hideReactionPopup() {
    setState(() {
      isReactionPopupVisible = false;
    });
    reactionOverlay?.remove();
    reactionOverlay = null;
  }

  void _showReactionPopup(Offset position) {
    if (reactionOverlay != null || _isSubmittingReaction) return;

    setState(() {
      isReactionPopupVisible = true;
    });

    reactionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Tap outside to close popup
              _hideReactionPopup();
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: position.dx - 50,
            top: position.dy - 80,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReactionButton("❤️"),
                    _buildReactionButton("😂"),
                    _buildReactionButton("😮"),
                    _buildReactionButton("😢"),
                    _buildReactionButton("😡"),
                    _buildReactionButton("👍"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(reactionOverlay!);
  }

  void _showSimpleDialog(BuildContext context, ActivePost post) {
    final caseDetail = post.caseDetail;
    final caseDescription = caseDetail?.caseDescription?.trim();
    final description = caseDescription != null && caseDescription.isNotEmpty
        ? caseDescription
        : post.postDescription.trim();
    final resolution = caseDetail?.caseResolution?.trim().isNotEmpty == true
        ? caseDetail!.caseResolution!.trim()
        : 'No resolution details available.';
    final title = caseDetail?.caseTitle.trim().isNotEmpty == true
        ? caseDetail!.caseTitle.trim()
        : 'Resolution';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(Assets.svgCancelIcon),
                ),
              ),
              Text(title, style: context.bold),
              SizedBox(height: 12),
              Text(
                description.isNotEmpty
                    ? description
                    : 'No case description available.',
                style: context.normal,
              ),
              SizedBox(height: 12),
              Text(
                resolution,
                style: context.normal.copyWith(color: kDarkGreyColor),
              ),
              SizedBox(height: 20),
              PrimaryButton(
                text: "Close",
                isMainAxisSizeMin: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReaction(String reaction) async {
    if (_isSubmittingReaction) return;

    final previousReaction = selectedReaction;
    final nextReaction = previousReaction == reaction ? null : reaction;
    setState(() {
      _isSubmittingReaction = true;
      selectedReaction = nextReaction;
    });

    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      if (nextReaction == null) {
        await CasePostService().deletePostReaction(
          accessToken: accessToken,
          postId: widget.post.postId,
        );
      } else {
        await CasePostService().createPostReaction(
          accessToken: accessToken,
          postId: widget.post.postId,
          userId: userId,
          reactionType: nextReaction,
        );
      }

      if (!mounted) return;
      setState(() {
        if (previousReaction == null && nextReaction != null) {
          _reactionCountDelta += 1;
        } else if (previousReaction != null && nextReaction == null) {
          _reactionCountDelta -= 1;
        }

        if (previousReaction != 'Like' && nextReaction == 'Like') {
          _likeCountDelta += 1;
        } else if (previousReaction == 'Like' && nextReaction != 'Like') {
          _likeCountDelta -= 1;
        }
      });
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        selectedReaction = previousReaction;
      });
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        selectedReaction = previousReaction;
      });
      AppAlert.showError(context, 'Failed to submit reaction');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingReaction = false;
      });
    }
  }

  Future<void> _likeComment(int? commentId) async {
    if (commentId == null) return;
    
    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();

      if (accessToken == null || userId == null) return;

      await CasePostService().likeComment(
        accessToken: accessToken,
        postId: widget.post.postId,
        commentId: commentId,
        userId: userId,
      );
      widget.onPostUpdated();
    } catch (e) {
      debugPrint('Failed to like comment: $e');
    }
  }

  String _reactionLabel(String? reaction) {
    return _normalizeReactionType(reaction);
  }

  String get _reactionButtonText {
    return 'Like $_likeCount';
  }

  Future<void> _loadCurrentUserReaction() async {
    final userId = await const AuthStorage().readUserId();
    if (!mounted) return;

    final userReaction = _findUserReaction(userId);
    setState(() {
      selectedReaction = userReaction;
    });
  }

  String? _findUserReaction(int? userId) {
    if (userId == null) return null;

    for (final reaction in widget.post.reactions.reversed) {
      if (reaction.userId == userId) {
        return _normalizeReactionType(reaction.reactionType);
      }
    }
    return null;
  }

  Widget _buildReactionSummaryIcons() {
    final reactionTypes = _topReactionTypes();
    if (reactionTypes.isEmpty) {
      return const Icon(Icons.thumb_up_alt_outlined, color: kPrimaryColor);
    }

    return SizedBox(
      width: 44,
      height: 20,
      child: Stack(
        children: [
          for (var index = 0; index < reactionTypes.length; index++)
            Positioned(
              left: index * 12,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kWhiteColor, width: 1.5),
                ),
                child: Text(
                  _emojiForReaction(reactionTypes[index]),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLikesSummary() {
    return Row(
      children: [
        _buildReactionSummaryIcons(),
        Space.horizontal(8),
        Text(
          'Total Likes: $_likeCount',
          style: context.semiBold.copyWith(
            fontSize: 13,
            color: kDarkGreyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPostActionRow(ActivePost post) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onLongPressStart: (details) {
              _showReactionPopup(details.globalPosition);
            },
            child: _buildActionButton(
              text: _reactionButtonText,
              onTap: isReactionPopupVisible
                  ? null
                  : () => _submitReaction('Like'),
              icon: _getReactionIcon(),
              isSelected: selectedReaction != null,
            ),
          ),
        ),
        Space.horizontal(10),
        Expanded(
          child: _buildActionButton(
            text: _comments.length.toString(),
            onTap: () {
              _toggleComments();
            },
            icon: Icons.mode_comment_outlined,
          ),
        ),
        Space.horizontal(10),
        Expanded(child: _buildRepostActionButton(post)),
        Space.horizontal(10),
        Expanded(child: _buildShareActionButton()),
      ],
    );
  }

  Widget _buildRepostActionButton(ActivePost post) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _showRepostBottomSheet(context, post);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                Assets.repostIcon,
                width: 18,
                height: 18,
                color: kPrimaryColor,
              ),
              Space.horizontal(6),
              Flexible(
                child: Text(
                  post.repostCount.toString().padLeft(2, '0'),
                  style: context.semiBold.copyWith(
                    color: kDarkGreyColor,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPostMenuItem({
    required String value,
    required String label,
    required IconData icon,
    Color color = kBlackColor,
    bool isSave = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          Space.horizontal(16),
          Text(
            label,
            style: (isSave ? context.bold : context.normal).copyWith(
              color: color,
              fontSize: 16,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleComments() async {
    if (areCommentsVisible) {
      setState(() {
        areCommentsVisible = false;
      });
      _commentFocusNode.unfocus();
      return;
    }

    setState(() {
      areCommentsVisible = true;
    });

    await WidgetsBinding.instance.endOfFrame;
    final commentsContext = _commentsSectionKey.currentContext;
    if (commentsContext != null && mounted) {
      await Scrollable.ensureVisible(
        commentsContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
    if (mounted) {
      _commentFocusNode.requestFocus();
    }
  }

  void _showRepostBottomSheet(BuildContext context, ActivePost post) {
    AppBottomSheet.show(
      context,
      borderRadius: 28,
      body: _RepostBottomSheetContent(
        post: post,
        isAdmin: widget.isAdmin,
        onRepostCreated: widget.onPostUpdated,
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onTap,
    required IconData icon,
    bool isLoading = false,
    bool isSelected = false,
  }) {
    final foregroundColor = isSelected ? kPrimaryColor : kDarkGreyColor;
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreyColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, color: foregroundColor, size: 20),
              Space.horizontal(6),
              Flexible(
                child: Text(
                  text,
                  style: context.semiBold.copyWith(
                    color: foregroundColor,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareActionButton() {
    return PopupMenuButton<String>(
      color: kWhiteColor,
      elevation: 22,
      shadowColor: kBlackColor.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      offset: const Offset(-8, -190),
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 190),
      onSelected: _handleShareSelection,
      itemBuilder: (context) => [
        _buildShareMenuHeader(),
        _buildShareMenuItem(
          value: 'whatsapp',
          label: 'WhatsApp',
          icon: SvgPicture.asset(
            Assets.svgWhatsappIcon,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(kBlackColor, BlendMode.srcIn),
          ),
        ),
        _buildShareMenuItem(
          value: 'twitter',
          label: 'Twitter/X',
          icon: SvgPicture.asset(
            Assets.svgTwitterIcon,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(kBlackColor, BlendMode.srcIn),
          ),
        ),
        _buildShareMenuItem(
          value: 'facebook',
          label: 'Facebook',
          icon: SvgPicture.asset(
            Assets.svgFacebookIcon,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(kBlackColor, BlendMode.srcIn),
          ),
        ),
        _buildShareMenuItem(
          value: 'copy',
          label: 'Copy Link',
          icon: const Icon(Icons.copy_all_outlined, size: 20),
        ),
      ],
      child: _buildActionButton(
        text: 'Share',
        onTap: null,
        icon: Icons.share_outlined,
      ),
    );
  }

  PopupMenuItem<String> _buildShareMenuHeader() {
    return PopupMenuItem<String>(
      enabled: false,
      height: 30,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        'Quick Actions',
        style: context.normal.copyWith(color: kDarkGreyColor, fontSize: 12),
      ),
    );
  }

  PopupMenuItem<String> _buildShareMenuItem({
    required String value,
    required String label,
    required Widget icon,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: icon)),
          Space.horizontal(10),
          Text(label, style: context.normal.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleShareSelection(String value) async {
    switch (value) {
      case 'system':
        await PostShareHelper.sharePost(
          context,
          post: widget.post,
          target: PostShareTarget.system,
        );
        return;
      case 'whatsapp':
        await PostShareHelper.sharePost(
          context,
          post: widget.post,
          target: PostShareTarget.whatsapp,
        );
        return;
      case 'twitter':
        await PostShareHelper.sharePost(
          context,
          post: widget.post,
          target: PostShareTarget.twitter,
        );
        return;
      case 'facebook':
        await PostShareHelper.sharePost(
          context,
          post: widget.post,
          target: PostShareTarget.facebook,
        );
        return;
      case 'copy':
        await PostShareHelper.sharePost(
          context,
          post: widget.post,
          target: PostShareTarget.copy,
        );
        return;
    }
  }

  List<String> _topReactionTypes() {
    final summary = widget.post.reactionSummary?.byType;
    if (summary == null || summary.isEmpty) {
      return widget.post.reactions
          .map((reaction) => _normalizeReactionType(reaction.reactionType))
          .where((reaction) => reaction.isNotEmpty)
          .toSet()
          .take(3)
          .toList();
    }

    final entries = summary.entries.toList()
      ..sort((a, b) {
        final left = int.tryParse('${a.value}') ?? 0;
        final right = int.tryParse('${b.value}') ?? 0;
        return right.compareTo(left);
      });

    return entries
        .map((entry) => _normalizeReactionType(entry.key))
        .where((reaction) => reaction.isNotEmpty)
        .take(3)
        .toList();
  }

  String _normalizeReactionType(String? reaction) {
    final value = (reaction ?? '').trim().toLowerCase();
    switch (value) {
      case '👍':
      case 'like':
        return 'Like';
      case '❤️':
      case 'heart':
      case 'love':
        return 'Love';
      case '😂':
      case 'haha':
      case 'laugh':
      case 'laughing':
        return 'Haha';
      case '😮':
      case 'wow':
        return 'Wow';
      case '😢':
      case 'sad':
        return 'Sad';
      case '😡':
      case 'angry':
        return 'Angry';
      default:
        return reaction?.trim().isNotEmpty == true ? reaction!.trim() : 'Like';
    }
  }

  String _emojiForReaction(String reaction) {
    switch (_normalizeReactionType(reaction)) {
      case 'Love':
        return '❤️';
      case 'Haha':
        return '😂';
      case 'Wow':
        return '😮';
      case 'Sad':
        return '😢';
      case 'Angry':
        return '😡';
      case 'Like':
      default:
        return '👍';
    }
  }

  String _reactionTypeFromEmoji(String emoji) {
    switch (emoji) {
      case '❤️':
        return 'Love';
      case '😂':
        return 'Haha';
      case '😮':
        return 'Wow';
      case '😢':
        return 'Sad';
      case '😡':
        return 'Angry';
      case '👍':
      default:
        return 'Like';
    }
  }

  Future<void> _submitComment() async {
    if (_isSubmittingComment) return;

    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty) {
      AppAlert.showWarning(context, 'Please write a comment');
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();
      final firstName = await authStorage.readFirstName();
      final lastName = await authStorage.readLastName();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      await CasePostService().createPostComment(
        accessToken: accessToken,
        postId: widget.post.postId,
        userId: userId,
        commentContent: commentContent,
      );

      if (!mounted) return;

      setState(() {
        _comments = [
          ..._comments,
          ActivePostComment(
            commentContent: commentContent,
            createdAt: DateTime.now().toIso8601String(),
            userInfo: ActivePostUserInfo(
              firstName: firstName ?? '',
              lastName: lastName ?? '',
            ),
          ),
        ];
        _commentController.clear();
      });
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to add comment');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  Future<void> _submitReply(ActivePostComment comment) async {
    if (_isSubmittingReply) return;

    final replyContent = _replyController.text.trim();
    if (replyContent.isEmpty) {
      AppAlert.showWarning(context, 'Please write a reply');
      return;
    }

    final parentCommentId = comment.commentId;
    if (parentCommentId == null) {
      AppAlert.showWarning(context, 'Comment id not found');
      return;
    }

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();
      final firstName = await authStorage.readFirstName();
      final lastName = await authStorage.readLastName();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      await CasePostService().createPostChildComment(
        accessToken: accessToken,
        postId: widget.post.postId,
        userId: userId,
        parentCommentId: parentCommentId,
        commentContent: replyContent,
      );

      final reply = ActivePostComment(
        postId: widget.post.postId,
        userId: userId,
        parentCommentId: parentCommentId,
        commentContent: replyContent,
        createdAt: DateTime.now().toIso8601String(),
        userInfo: ActivePostUserInfo(
          firstName: firstName ?? '',
          lastName: lastName ?? '',
        ),
      );

      if (!mounted) return;
      setState(() {
        _comments = _appendReplyToComments(_comments, parentCommentId, reply);
        _replyController.clear();
        _replyingCommentId = null;
        _expandedReplyCommentIds.add(parentCommentId);
      });
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to add reply');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingReply = false;
      });
    }
  }

  List<ActivePostComment> _appendReplyToComments(
    List<ActivePostComment> comments,
    int parentCommentId,
    ActivePostComment reply,
  ) {
    return comments.map((comment) {
      if (comment.commentId == parentCommentId) {
        return ActivePostComment(
          commentId: comment.commentId,
          postId: comment.postId,
          userId: comment.userId,
          parentCommentId: comment.parentCommentId,
          commentContent: comment.commentContent,
          isActive: comment.isActive,
          createdAt: comment.createdAt,
          updatedAt: comment.updatedAt,
          userInfo: comment.userInfo,
          childComments: [...comment.childComments, reply],
        );
      }

      if (comment.childComments.isEmpty) {
        return comment;
      }

      return ActivePostComment(
        commentId: comment.commentId,
        postId: comment.postId,
        userId: comment.userId,
        parentCommentId: comment.parentCommentId,
        commentContent: comment.commentContent,
        isActive: comment.isActive,
        createdAt: comment.createdAt,
        updatedAt: comment.updatedAt,
        userInfo: comment.userInfo,
        childComments: _appendReplyToComments(
          comment.childComments,
          parentCommentId,
          reply,
        ),
      );
    }).toList();
  }

  String _commentAuthorName(ActivePostComment comment) {
    final firstName = comment.userInfo?.firstName.trim() ?? '';
    final lastName = comment.userInfo?.lastName.trim() ?? '';
    final fullName = [if (firstName.isNotEmpty) firstName, if (lastName.isNotEmpty) lastName]
        .join(' ')
        .trim();
    return fullName;
  }

  Widget _buildCommentThread(
    ActivePostComment comment, {
    double leftPadding = 0,
    bool isReply = false,
  }) {
    final isReplying = _replyingCommentId == comment.commentId;
    final hasReplies = comment.childComments.isNotEmpty;
    final commentId = comment.commentId;
    final isRepliesExpanded =
        commentId != null && _expandedReplyCommentIds.contains(commentId);

    void toggleReply() {
      setState(() {
        if (_replyingCommentId == comment.commentId) {
          _replyingCommentId = null;
          _replyController.clear();
        } else {
          _replyingCommentId = comment.commentId;
          _replyController.clear();
        }
      });
    }

    void toggleRepliesAccordion() {
      if (commentId == null || !hasReplies) return;
      setState(() {
        if (_expandedReplyCommentIds.contains(commentId)) {
          _expandedReplyCommentIds.remove(commentId);
        } else {
          _expandedReplyCommentIds.add(commentId);
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentContainer.dynamic(
            authorName: _commentAuthorName(comment),
            avatarUrl: comment.userInfo?.avatarUrl,
            comment: comment.commentContent,
            timeText: _timeLabel(comment.createdAt),
            onReplyTap: toggleReply,
            replyLabel: isReplying ? 'Cancel' : 'Reply',
            isReplyActive: isReplying,
            likeCount: comment.likes.length,
            isLiked: comment.likes.contains(AuthStorage.cachedUserId),
            onLikeTap: () => _likeComment(comment.commentId),
            onMenuTap: () {},
            isReply: isReply,
          ),
          if (isReplying) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kLightGreyColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGreyColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _replyController,
                    hintText: 'Write a reply...',
                    hintTextColor: kDarkGreyColor,
                    fieldColor: kWhiteColor,
                    showBorder: false,
                    topPadding: 10,
                    bottomPadding: 10,
                    inputFontSize: 14,
                    borderRadius: 12,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitReply(comment),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      child: PrimaryButton(
                        text: _isSubmittingReply ? '...' : 'Send',
                        isMainAxisSizeMin: true,
                        inactive: _isSubmittingReply,
                        processing: _isSubmittingReply,
                        onPressed: () => _submitReply(comment),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasReplies && !isRepliesExpanded)
            InkWell(
              onTap: toggleRepliesAccordion,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: kTextfieldBlueColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRepliesExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 18,
                      color: kPrimaryColor,
                    ),
                    Text(
                      '${comment.childComments.length} ${comment.childComments.length == 1 ? 'Reply' : 'Replies'}',
                      style: context.semiBold.copyWith(
                        color: kPrimaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasReplies && isRepliesExpanded)
            ...comment.childComments.map(
              (child) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildCommentThread(
                  child,
                  leftPadding: leftPadding + 32,
                  isReply: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmVote(
    BuildContext context, {
    required ActivePost post,
    required String selectedVote,
    required String selectedName,
  }) async {
    if (_isSubmittingVote) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          title: const Text('Confirm Vote'),
          content: Text('Are you sure to cast the vote for $selectedName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final caseId = post.caseDetail?.caseId;
    if (caseId == null) {
      AppAlert.showWarning(context, 'Case id not found for this post');
      return;
    }

    setState(() {
      _isSubmittingVote = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await CasePostService().submitCasePollVote(
        accessToken: accessToken,
        caseId: caseId,
        endPoll: false,
        ownerVote: selectedVote == 'owner' ? 'Y' : 'N',
        defendantVote: selectedVote == 'defendant' ? 'Y' : 'N',
      );

      if (!mounted) return;
      setState(() {
        _selectedVote = selectedVote;
      });
      widget.onPostUpdated();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isPollEndedMessage(e.message)) {
        _showPollEndedDialog(context, e.message);
      } else {
        AppAlert.showError(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to cast vote');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingVote = false;
      });
    }
  }

  bool _isPollEndedMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('poll for case') &&
        normalized.contains('already ended');
  }

  void _showPollEndedDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kLightGreyColor,
                child: const Icon(Icons.info_outline, color: kPrimaryColor),
              ),
              Space.horizontal(10),
              Expanded(
                child: Text(
                  'Poll Closed',
                  style: context.bold.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: context.normal.copyWith(color: kDarkGreyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showReportBottomSheet(BuildContext context, ActivePost post) {
    AppBottomSheet.show(
      context,
      showSheetHandler: true,
      enableScrollView: true,
      borderRadius: 24,
      body: _ReportBottomSheetContent(post: post),
    );
  }

  Widget _buildReportReasonTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kTextfieldBlueColor : kWhiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kPrimaryColor : kGreyColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : kSecondaryGreyColor,
                  width: 1.5,
                ),
                color: isSelected ? kPrimaryColor : kWhiteColor,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: kWhiteColor)
                  : null,
            ),
            Space.horizontal(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.semiBold),
                  if (subtitle.isNotEmpty) ...[
                    Space.vertical(4),
                    Text(
                      subtitle,
                      style: context.normal.copyWith(
                        fontSize: 12,
                        color: kDarkGreyColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBottomSheetContent extends StatefulWidget {
  final ActivePost post;

  const _ReportBottomSheetContent({required this.post});

  @override
  State<_ReportBottomSheetContent> createState() =>
      _ReportBottomSheetContentState();
}

class _ReportBottomSheetContentState extends State<_ReportBottomSheetContent> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmittingReport = false;
  String? _loadError;
  List<GeneralParameterOption> _reasons = const [];
  int? _selectedReasonId;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final reasons = await const GeneralParameterService().getByHeaderName(
        headerName: 'REPORT_REASON_TYPE',
        accessToken: accessToken,
      );

      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        if (reasons.isEmpty) {
          _loadError = 'No report reasons available';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load report reasons';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmittingReport) return;

    final reasonId = _selectedReasonId;
    if (reasonId == null) return;

    setState(() {
      _isSubmittingReport = true;
    });

    try {
      final authStorage = const AuthStorage();
      final accessToken = await authStorage.readAccessToken();
      final userId = await authStorage.readUserId();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      await CasePostService().createPostReport(
        accessToken: accessToken,
        postId: widget.post.postId,
        reportReasonTypeId: reasonId,
        reportAdditionalInformation: _detailsController.text.trim(),
        createdBy: userId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppAlert.showSuccess(context, 'Report submitted successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to submit report');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingReport = false;
      });
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsLength = _detailsController.text.trim().length;
    final caseTitle =
        widget.post.caseDetail?.caseTitle.trim().isNotEmpty == true
        ? widget.post.caseDetail!.caseTitle
        : 'Post #${widget.post.postId}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report', style: context.bold.copyWith(fontSize: 20)),
          Space.vertical(12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kLightOrangeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kLightOrangeColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: kLightOrangeColor,
                ),
                Space.horizontal(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report issue',
                        style: context.bold.copyWith(fontSize: 14),
                      ),
                      Space.vertical(4),
                      Text(
                        'Your report helps us maintain quality and '
                        'safety. False reports may result in account '
                        'restrictions.',
                        style: context.normal.copyWith(
                          color: kDarkGreyColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Space.vertical(14),
          Text('You are reporting:', style: context.normal),
          Space.vertical(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kLightGreyColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreyColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caseTitle, style: context.semiBold),
                Space.vertical(4),
                Text(
                  'Post ID ${widget.post.postId}',
                  style: context.normal.copyWith(
                    color: kDarkGreyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Space.vertical(16),
          Text('Select Reason *', style: context.semiBold),
          Space.vertical(8),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            Column(
              children: [
                Text(
                  _loadError!,
                  style: context.normal.copyWith(color: kRedColor),
                ),
                Space.vertical(8),
                TextButton(onPressed: _loadReasons, child: const Text('Retry')),
              ],
            )
          else
            ...List.generate(_reasons.length, (index) {
              final reason = _reasons[index];
              final isSelected = _selectedReasonId == reason.paramDetailId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildReportReasonTile(
                  title: reason.paramLabel,
                  subtitle: reason.paramValue,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedReasonId = reason.paramDetailId;
                    });
                  },
                ),
              );
            }),
          Space.vertical(6),
          Text('Additional Details (Optional)', style: context.semiBold),
          Space.vertical(8),
          CustomTextField(
            controller: _detailsController,
            hintText:
                'Please provide any additional information that will '
                'help us investigate this issue...',
            hintTextStyle: context.normal.copyWith(
              fontSize: 12,
              color: kDarkGreyColor,
              fontWeight: FontWeight.w400,
            ),
            maxLine: 4,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${detailsLength.clamp(0, 500)}/500 characters',
              style: context.normal.copyWith(
                fontSize: 12,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(12),
          PrimaryButton(
            text: 'Submit Report',
            buttonColor: kRedColor,
            textColor: kWhiteColor,
            inactive: _selectedReasonId == null || _isSubmittingReport,
            processing: _isSubmittingReport,
            onPressed: _submitReport,
          ),
          Space.vertical(8),
          Text(
            'Our support team will review your report and take '
            'appropriate action.',
            textAlign: TextAlign.center,
            style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReportReasonTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? kTextfieldBlueColor : kWhiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kPrimaryColor : kGreyColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : kSecondaryGreyColor,
                  width: 1.5,
                ),
                color: isSelected ? kPrimaryColor : kWhiteColor,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: kWhiteColor)
                  : null,
            ),
            Space.horizontal(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.semiBold),
                  if (subtitle.isNotEmpty) ...[
                    Space.vertical(4),
                    Text(
                      subtitle,
                      style: context.normal.copyWith(
                        fontSize: 12,
                        color: kDarkGreyColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepostBottomSheetContent extends StatefulWidget {
  final ActivePost post;
  final bool isAdmin;
  final VoidCallback onRepostCreated;

  const _RepostBottomSheetContent({
    required this.post,
    required this.isAdmin,
    required this.onRepostCreated,
  });

  @override
  State<_RepostBottomSheetContent> createState() =>
      _RepostBottomSheetContentState();
}

class _RepostBottomSheetContentState extends State<_RepostBottomSheetContent> {
  final TextEditingController _opinionController = TextEditingController();
  bool _isSubmitting = false;

  String _timeLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    final now = DateTime.now();
    final difference = now.difference(parsed);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} mins ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  @override
  void dispose() {
    _opinionController.dispose();
    super.dispose();
  }

  Future<void> _submitRepost() async {
    if (_isSubmitting) return;

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      final userId = await const AuthStorage().readUserId();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      setState(() {
        _isSubmitting = true;
      });

      await CasePostService().createPostRepost(
        accessToken: accessToken,
        postId: widget.post.postId,
        userId: userId,
        postDescription: _opinionController.text.trim(),
        createdBy: userId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onRepostCreated();
      AppAlert.showSuccess(context, 'Post reposted successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to repost post');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.authorDisplayName;
    final defendant = post.defendantDetails.isNotEmpty
        ? post.defendantDetails.first
        : null;
    final ownerName = author.trim().isNotEmpty
        ? author.trim()
        : (post.createdByUserInfo?.userEmail?.trim().isNotEmpty == true
            ? post.createdByUserInfo!.userEmail!.trim().split('@').first
            : 'User A');
    final defendantName = (defendant?.userInfo?.fullName.trim().isNotEmpty == true)
        ? defendant!.userInfo!.fullName.trim()
        : (defendant?.userInfo?.userEmail?.trim().isNotEmpty == true
            ? defendant!.userInfo!.userEmail!.trim().split('@').first
            : 'User B');
    final timeText = _timeLabel(post.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repost', style: context.bold.copyWith(fontSize: 18)),
          Space.vertical(12),
          CustomTextField(
            controller: _opinionController,
            hintText: 'Enter Your opinion',
            maxLine: 7,
            hintTextColor: kDarkGreyColor,
          ),
          Space.vertical(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreyColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PostAuthorAvatar(post: post, radius: 20),
                    Space.horizontal(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: context.semiBold),
                          Text(
                            timeText.isEmpty ? 'Just now' : timeText,
                            style: context.normal.copyWith(
                              color: kDarkGreyColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        border: Border.all(color: kGreyColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.more_horiz,
                        color: kBlackColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Space.vertical(16),
                Text(
                  post.caseDetail?.caseTitle.isNotEmpty == true
                      ? post.caseDetail!.caseTitle
                      : "Who's Right?",
                  style: context.bold.copyWith(fontSize: 20),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Space.vertical(16),
                _PostComparisonPreview(
                  leftMediaList: post.caseDetail?.metaList ?? const [],
                  rightMediaList: defendant?.metaList ?? const [],
                ),
                Space.vertical(14),
                VotingResultExample(
                  leftLabel: 'A.',
                  leftText: ownerName,
                  rightLabel: 'B.',
                  rightText: defendantName,
                  leftVotes: post.casePollCount?.ownerCount ?? 0,
                  rightVotes: post.casePollCount?.defendantCount ?? 0,
                  totalVotesCount: post.casePollCount?.totalCount ?? 0,
                  selectedOption: null,
                ),
              ],
            ),
          ),
          Space.vertical(16),
          PrimaryButton(
            text: 'Repost',
            processing: _isSubmitting,
            inactive: _isSubmitting,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(4.3),
              child: Image.asset(Assets.repostIcon, height: 16),
            ),
            onPressed: _submitRepost,
          ),
        ],
      ),
    );
  }
}

class _PostAuthorAvatar extends StatelessWidget {
  final ActivePost post;
  final double radius;

  const _PostAuthorAvatar({
    required this.post,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    String? avatarUrl = post.authorAvatarUrl?.trim();
    final authorId = post.authorUserId;

    if ((avatarUrl == null || avatarUrl.isEmpty) && authorId != null) {
      if (authorId == AuthStorage.cachedUserId) {
        avatarUrl = AuthStorage.cachedProfileImageUrl?.trim();
      } else {
        avatarUrl = UserCacheService().getAvatarSync(authorId)?.trim();
      }
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Handle asset paths
      if (avatarUrl.startsWith('assets/')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: kLightGreyColor,
          backgroundImage: AssetImage(avatarUrl),
        );
      }

      // Handle network URLs
      return CircleAvatar(
        radius: radius,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final name = post.authorDisplayName.trim();
    final initials = name.isEmpty
        ? 'U'
        : name
              .split(' ')
              .where((part) => part.trim().isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostComparisonPreview extends StatelessWidget {
  final String? topCaption;
  final List<ActivePostMeta> leftMediaList;
  final List<ActivePostMeta> rightMediaList;

  const _PostComparisonPreview({
    this.topCaption,
    required this.leftMediaList,
    required this.rightMediaList,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTiles = <Widget>[
      if (leftMediaList.isNotEmpty)
        Expanded(
          child: _ComparisonMediaTile(
            mediaList: leftMediaList,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
        ),
      if (rightMediaList.isNotEmpty)
        Expanded(
          child: _ComparisonMediaTile(
            mediaList: rightMediaList,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ),
    ];

    if (visibleTiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topCaption != null && topCaption!.isNotEmpty) ...[
          Text(
            topCaption!,
            style: context.semiBold.copyWith(
              color: kBlackColor,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            for (var i = 0; i < visibleTiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              visibleTiles[i],
            ],
          ],
        ),
      ],
    );
  }
}

class _ComparisonMediaTile extends StatefulWidget {
  final List<ActivePostMeta> mediaList;
  final BorderRadius borderRadius;

  const _ComparisonMediaTile({
    required this.mediaList,
    required this.borderRadius,
  });

  @override
  State<_ComparisonMediaTile> createState() => _ComparisonMediaTileState();
}

class _ComparisonMediaTileState extends State<_ComparisonMediaTile> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaList.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _IndividualMediaTile(
                  media: widget.mediaList[index],
                  borderRadius: widget.borderRadius,
                );
              },
            ),
            if (widget.mediaList.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.mediaList.length,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? kPrimaryColor
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IndividualMediaTile extends StatefulWidget {
  final ActivePostMeta? media;
  final BorderRadius borderRadius;

  const _IndividualMediaTile({
    required this.media,
    required this.borderRadius,
  });

  @override
  State<_IndividualMediaTile> createState() => _IndividualMediaTileState();
}

class _IndividualMediaTileState extends State<_IndividualMediaTile> {
  VideoPlayerController? _videoController;
  Future<void>? _videoInitialization;
  VoidCallback? _videoListener;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void didUpdateWidget(covariant _IndividualMediaTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media?.metaUrl != widget.media?.metaUrl) {
      _disposeVideoController();
      _setupVideo();
    }
  }

  void _disposeVideoController() {
    if (_videoListener != null && _videoController != null) {
      _videoController!.removeListener(_videoListener!);
    }
    _videoController?.dispose();
    _videoController = null;
    _videoInitialization = null;
    _videoListener = null;
    _hasVideoError = false;
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  void _setupVideo() {
    final media = widget.media;
    if (media == null || !media.hasMedia || media.isImage) {
      return;
    }

    _hasVideoError = false;
    final url = (media.metaUrl ?? '').trim();
    if (url.isEmpty) return;

    try {
      VideoPlayerController controller;
      if (url.startsWith('assets/')) {
        controller = VideoPlayerController.asset(url);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        controller = VideoPlayerController.file(File(url));
      }

      _videoController = controller;
      _videoListener = () {
        if (!mounted) return;
        setState(() {});
      };
      controller.addListener(_videoListener!);
      _videoInitialization = controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      }).catchError((err) {
        debugPrint('Video init error for $url: $err');
        if (mounted) {
          setState(() {
            _hasVideoError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Video controller setup error for $url: $e');
      _hasVideoError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),
            // Show play icon overlay only for videos
            if (widget.media != null && widget.media!.hasMedia && !widget.media!.isImage && !_hasVideoError)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openMediaFullscreen(context, widget.media!),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    alignment: Alignment.center,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.play_arrow,
                        color: kWhiteColor,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final media = widget.media;
    if (media == null || !media.hasMedia) {
      return const SizedBox.shrink();
    }

    if (!media.isImage) {
      if (_hasVideoError || _videoController == null || _videoInitialization == null) {
        return _buildVideoThumbnailOrFallback(media);
      }

      return FutureBuilder<void>(
        future: _videoInitialization,
        builder: (context, snapshot) {
          if (snapshot.hasError || _hasVideoError) {
            return _buildVideoThumbnailOrFallback(media);
          }

          if (snapshot.connectionState != ConnectionState.done ||
              !_videoController!.value.isInitialized) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildVideoThumbnailOrFallback(media),
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: kWhiteColor),
                ),
              ],
            );
          }

          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width == 0
                  ? 16
                  : _videoController!.value.size.width,
              height: _videoController!.value.size.height == 0
                  ? 9
                  : _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          );
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMediaFullscreen(context, media),
        child: _buildImageWidget(media.metaUrl!),
      ),
    );
  }

  Widget _buildVideoThumbnailOrFallback(ActivePostMeta media) {
    final url = (media.metaUrl ?? '').trim();
    if (url.isNotEmpty) {
      return _buildImageWidget(url);
    }
    return Container(
      color: kLightGreyColor,
      alignment: Alignment.center,
      child: const Icon(Icons.videocam_outlined, color: kDarkGreyColor, size: 40),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: kLightGreyColor,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, color: kDarkGreyColor, size: 40),
          );
        },
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: kLightGreyColor,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, color: kDarkGreyColor, size: 40),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: kLightGreyColor,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }

  void _openMediaFullscreen(BuildContext context, ActivePostMeta media) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenMediaViewer(
            mediaUrl: media.metaUrl!,
            isImage: media.isImage,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }
}

class _FullscreenMediaViewer extends StatefulWidget {
  final String mediaUrl;
  final bool isImage;

  const _FullscreenMediaViewer({
    required this.mediaUrl,
    required this.isImage,
  });

  @override
  State<_FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<_FullscreenMediaViewer> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    if (!widget.isImage) {
      final url = widget.mediaUrl.trim();
      if (url.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(url);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.file(File(url));
      }
      _initialization = _controller!.initialize().then((_) {
        _controller!.play();
        if (mounted) {
          setState(() {});
        }
      }).catchError((err) {
        debugPrint('Fullscreen video load error: $err');
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.isImage ? _buildImage() : _buildVideo(),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: kWhiteColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: widget.mediaUrl.startsWith('assets/')
            ? Image.asset(
                widget.mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 60),
                      SizedBox(height: 16),
                      Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                    ],
                  );
                },
              )
            : Image.network(
                widget.mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 60),
                      SizedBox(height: 16),
                      Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_controller == null || _initialization == null) {
      return const Center(
        child: CircularProgressIndicator(color: kWhiteColor),
      );
    }

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !_controller!.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: kWhiteColor),
          );
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
              AnimatedOpacity(
                opacity: _controller!.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Icon(
                    Icons.play_arrow,
                    color: kWhiteColor,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
