import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:flutter/material.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ActivePost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  void _loadMockPosts() {
    _posts = [
      ActivePost(
        postId: 101,
        postDescription: "Family relations - Check out this amazing content about family bonds and relationships!",
        createdAt: "2025-07-14T08:00:00",
        createdByUserInfo: const ActivePostUserInfo(
          firstName: "Hannah",
          lastName: "Flores",
          avatarUrl: "assets/images/user1.png",
        ),
        caseDetail: const ActivePostCaseDetail(
          caseId: 101,
          caseTitle: "Who's Right?",
          caseDescription: "Family relations case",
          meta: ActivePostMeta(
            metaUrl: "assets/images/post1.png",
            metaTypeId: "1",
          ),
        ),
        defendantDetails: [
          const ActivePostDefendantDetail(
            defendantCaseId: 1,
            defendentId: 1,
            userInfo: ActivePostUserInfo(
              firstName: "Dennis",
              lastName: "Collins",
              avatarUrl: "assets/images/man.png",
            ),
            meta: ActivePostMeta(
              metaUrl: "assets/images/recent_post_1.jpg",
              metaTypeId: "1",
            ),
          ),
          const ActivePostDefendantDetail(
            defendantCaseId: 2,
            defendentId: 2,
            userInfo: ActivePostUserInfo(
              firstName: "Katie",
              lastName: "Sims",
              avatarUrl: "assets/images/user2.png",
            ),
            meta: ActivePostMeta(
              metaUrl: "assets/images/recent_post_2.jpg",
              metaTypeId: "1",
            ),
          ),
        ],
        comments: const [],
        reactions: const [],
      ),
      ActivePost(
        postId: 102,
        postDescription: "Beautiful moments captured today! #photography #nature",
        createdAt: "2025-07-13T15:30:00",
        createdByUserInfo: const ActivePostUserInfo(
          firstName: "Alex",
          lastName: "Buckmaster",
          avatarUrl: "assets/images/user2.png",
        ),
        caseDetail: const ActivePostCaseDetail(
          caseId: 102,
          caseTitle: "Family relations",
          caseDescription: "Discussion about family relationships",
          meta: ActivePostMeta(
            metaUrl: "assets/images/1.jpg",
            metaTypeId: "1",
          ),
        ),
        defendantDetails: [
          const ActivePostDefendantDetail(
            defendantCaseId: 3,
            defendentId: 3,
            userInfo: ActivePostUserInfo(
              firstName: "Eddie",
              lastName: "Lake",
              avatarUrl: "assets/images/man_2.png",
            ),
            meta: ActivePostMeta(
              metaUrl: "assets/images/2.jpg",
              metaTypeId: "1",
            ),
          ),
          const ActivePostDefendantDetail(
            defendantCaseId: 4,
            defendentId: 4,
            userInfo: ActivePostUserInfo(
              firstName: "David",
              lastName: "Elson",
              avatarUrl: "assets/images/dennis.png",
            ),
            meta: ActivePostMeta(
              metaUrl: "assets/images/3.jpg",
              metaTypeId: "1",
            ),
          ),
        ],
        comments: const [],
        reactions: const [],
      ),
      ActivePost(
        postId: 103,
        postDescription: "Latest updates on the project progress. Great work team!",
        createdAt: "2025-07-12T10:15:00",
        createdByUserInfo: const ActivePostUserInfo(
          firstName: "Michael",
          lastName: "Chen",
          avatarUrl: "assets/images/man.png",
        ),
        caseDetail: const ActivePostCaseDetail(
          caseId: 103,
          caseTitle: "Project Updates",
          caseDescription: "Latest project progress",
          meta: ActivePostMeta(
            metaUrl: "assets/images/recent_post_3.jpg",
            metaTypeId: "1",
          ),
        ),
        defendantDetails: const [],
        comments: const [],
        reactions: const [],
      ),
    ];
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Real data call instead of mock

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken();
      final userId = await storage.readUserId();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('User id not found');
      }

      final posts = await CasePostService().getSavedPostByUserId(
        accessToken: accessToken,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _posts = posts;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load saved posts';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        foregroundColor: kBlackColor,
        leadingWidth: 96,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              'Back',
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: context.normal.copyWith(fontSize: 14, color: kBlackColor),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Saved posts',
          style: context.bold.copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSavedPosts,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: context.normal.copyWith(color: kRedColor),
          ),
          Space.vertical(8),
          TextButton(onPressed: _loadSavedPosts, child: const Text('Retry')),
        ],
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'No saved posts yet',
            textAlign: TextAlign.center,
            style: context.normal.copyWith(color: kDarkGreyColor),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return HomePostContainer(
          isAdmin: false,
          isSavedPost: true,
          post: post,
          onClickProfile: () {},
          onPostUpdated: _loadSavedPosts,
        );
      },
    );
  }
}
