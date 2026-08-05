import 'dart:async';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/admin_top_header.dart';
import 'package:cctv_app/core/components/custom_horizontal_listview_widget.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/components/search_bar_header.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/network/services/general_parameter_service.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/ads/admob_banner_widget.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/pages/create_reel_page.dart';
import 'package:cctv_app/feature/home/pages/public_profile_page.dart';
import 'package:cctv_app/feature/home/widgets/fullscreen_reel_viewer.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:cctv_app/feature/pending/pages/pending_case_response_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback? onViewAllPending;
  const HomePage({super.key, required this.isAdmin, this.onViewAllPending});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _CategoryTabItem {
  final String label;
  final int? categoryId;

  const _CategoryTabItem({required this.label, this.categoryId});
}

class _FeedPostItem {
  final ActivePost post;
  final ActivePostRepost? repost;

  const _FeedPostItem({
    required this.post,
    this.repost,
  });
}

class _HomePageState extends State<HomePage> {
  static const List<_CategoryTabItem> _defaultCategoryTabs = [
    _CategoryTabItem(label: 'All'),
    _CategoryTabItem(label: 'Family Affairs', categoryId: 1),
    _CategoryTabItem(label: 'Divorce', categoryId: 2),
    _CategoryTabItem(label: 'Neighborhood conflicts', categoryId: 3),
    _CategoryTabItem(label: 'Property disputes', categoryId: 4),
    _CategoryTabItem(label: 'Custody', categoryId: 5),
  ];

  static List<ActivePost> _postsCache = const [];
  static List<ActiveReel> _reelsCache = const [];
  static List<_CategoryTabItem> _categoryTabsCache = _defaultCategoryTabs;

  int selectedIndex = 0;
  bool _isLoadingPosts = true;
  bool _isLoadingReels = true;
  String? _postsError;
  String? _reelsError;
  List<ActivePost> _posts = const [];
  List<ActiveReel> _reels = const [];
  List<_CategoryTabItem> _categoryTabs = _defaultCategoryTabs;
  List<Map<String, String>> _pendingCases = const [];
  List<Map<String, dynamic>> _activeFeedAds = const [];
  StreamSubscription<AppWebSocketEvent>? _postsEventSubscription;
  StreamSubscription<AppWebSocketEvent>? _reelsEventSubscription;
  bool _postsRefreshQueued = false;
  bool _reelsRefreshQueued = false;
  final Map<int, GlobalKey> _postKeys = <int, GlobalKey>{};
  final ScrollController _feedScrollController = ScrollController();
  int? _highlightedPostId;

  List<String> get _categoryItems =>
      _categoryTabs.map((tab) => tab.label).toList();

  List<_FeedPostItem> get _filteredPosts {
    if (selectedIndex < 0 || selectedIndex >= _categoryTabs.length) {
      return _expandPosts(_posts);
    }

    final selectedCategory = _categoryTabs[selectedIndex];
    if (selectedCategory.label.toLowerCase() == 'all') {
      return _expandPosts(_posts);
    }

    final selectedCategoryId = selectedCategory.categoryId;
    final selectedCategoryLabel = selectedCategory.label.toLowerCase().trim();

    final filteredPosts = _posts.where((post) {
      if (selectedCategoryId != null && post.caseDetail?.caseCategoryId == selectedCategoryId) {
        return true;
      }
      final title = (post.caseDetail?.caseTitle ?? '').toLowerCase();
      final desc = post.postDescription.toLowerCase();
      return title.contains(selectedCategoryLabel) || desc.contains(selectedCategoryLabel);
    }).toList();

    return _expandPosts(filteredPosts.isEmpty ? _posts : filteredPosts);
  }

  List<_FeedPostItem> _expandPosts(List<ActivePost> posts) {
    final items = <_FeedPostItem>[];
    for (final post in posts) {
      for (final repost in post.reposts) {
        items.add(_FeedPostItem(post: post, repost: repost));
      }
      items.add(_FeedPostItem(post: post));
    }
    return items;
  }

  Future<void> _focusPostInFeed(int postId) async {
    if (!mounted) return;

    if (_filteredPosts.every((item) => item.post.postId != postId)) {
      return;
    }

    setState(() {
      _highlightedPostId = postId;
    });

    await WidgetsBinding.instance.endOfFrame;
    final targetContext = _postKeys[postId]?.currentContext;
    if (targetContext != null && mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        alignment: 0.12,
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _highlightedPostId != postId) return;
      setState(() {
        _highlightedPostId = null;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _posts = _postsCache;
    _reels = _reelsCache;
    _categoryTabs = _categoryTabsCache;
    _isLoadingPosts = _posts.isEmpty;
    _isLoadingReels = _reels.isEmpty;
    _bindWebSocketEvents();
    _loadPostsAndCategories();
    _loadReels();
    _loadPendingCases();
    _loadFeedAds();
  }

  Future<void> _loadFeedAds() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('ads').get();
      final active = snapshot.docs.map((doc) => doc.data()).where((data) {
        final st = (data['status'] ?? 'active').toString().toLowerCase();
        return st == 'active' || st == 'draft';
      }).toList();
      if (!mounted) return;
      setState(() {
        _activeFeedAds = active;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _postsEventSubscription?.cancel();
    _reelsEventSubscription?.cancel();
    _feedScrollController.dispose();
    super.dispose();
  }

  void _scrollFeedToTop() {
    if (!_feedScrollController.hasClients) return;
    _feedScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadPendingCases() async {
    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken();
      final userId = await storage.readUserId();

      if (accessToken == null || userId == null) return;

      final cases = await UserCaseService().getPendingCases(
        accessToken: accessToken,
        userId: userId,
      );

      final mapped = cases.map((c) => {
        'image': c.applicationMeta?.metaUrl ?? '',
        'title': c.caseTitle,
        'description': c.caseDescription,
        'date': c.caseCreatedAt ?? '',
        'case_id': '${c.caseId}',
      }).toList();

      if (mounted) {
        setState(() {
          _pendingCases = mapped;
        });
      }
    } catch (_) {}
  }

  void _bindWebSocketEvents() {
    // To be implemented using firestore snapshots if needed
  }

  void _schedulePostsRefresh() {
    if (!mounted) return;
    if (_isLoadingPosts) {
      _postsRefreshQueued = true;
      return;
    }
    _loadPostsAndCategories();
  }

  void _scheduleReelsRefresh() {
    if (!mounted) return;
    if (_isLoadingReels) {
      _reelsRefreshQueued = true;
      return;
    }
    _loadReels();
  }

  Future<void> _loadPostsAndCategories() async {
    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';

      final categoriesTask = const GeneralParameterService().getByHeaderName(
        headerName: 'CASE_CATEGORY',
        accessToken: accessToken,
      );
      final postsTask = CasePostService().getAllActivePosts(
        accessToken: accessToken,
      );

      final results = await Future.wait([categoriesTask, postsTask]);
      final params = results[0] as List<GeneralParameterOption>;
      final currentUserId = await storage.readUserId();
      final allPosts = results[1] as List<ActivePost>;
      final posts = currentUserId != null
          ? allPosts.where((p) => p.authorUserId != currentUserId).toList()
          : allPosts;

      final tabs = params.isNotEmpty
          ? [
              const _CategoryTabItem(label: 'All'),
              ...params.map(
                (p) => _CategoryTabItem(
                  label: p.paramLabel,
                  categoryId: p.paramDetailId,
                ),
              ),
            ]
          : _defaultCategoryTabs;

      if (!mounted) return;
      setState(() {
        _categoryTabs = tabs;
        _posts = posts;
        _postsCache = _posts;
        _categoryTabsCache = _categoryTabs;
      });
      _loadFeedAds();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postsError = 'Failed to load feed';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
        if (_postsRefreshQueued) {
          _postsRefreshQueued = false;
          _loadPostsAndCategories();
        }
      });
    }
  }

  Future<void> _loadReels() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReels = true;
      _reelsError = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';
      
      final reels = await UserCaseService().getAllActiveReels(
        accessToken: accessToken,
      );

      if (!mounted) return;
      setState(() {
        _reels = reels;
        _reelsCache = _reels;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _reelsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reelsError = 'Failed to load reels';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReels = false;
        if (_reelsRefreshQueued) {
          _reelsRefreshQueued = false;
          _loadReels();
        }
      });
    }
  }

  Widget _buildReelsSection() {
    if (_isLoadingReels && _reels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reelsError != null && _reels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _reelsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kRedColor),
            ),
            TextButton(onPressed: _loadReels, child: const Text('Retry reels')),
          ],
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _reels.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      padding: const EdgeInsets.only(left: 16, right: 16),
      itemBuilder: (context, index) {
        // Add Highlight button first
        if (index == 0) {
          return _AddReelCard(
            onTap: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const CreateReelPage()),
              );
              if (created == true) {
                _loadReels();
              }
            },
          );
        }

        final reel = _reels[index - 1];
        return _ActiveReelCard(
          reel: reel,
          onDeleted: _loadReels,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              widget.isAdmin
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AdminTopHeader(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SearchBarHeader(),
                    ),
              Space.vertical(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomHorizontalListViewWidget(
                  items: _categoryItems,
                  selectedItem: selectedIndex,
                  onTap: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                    _scrollFeedToTop();
                  },
                ),
              ),
              Space.vertical(20),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadPostsAndCategories();
            },
            child: SingleChildScrollView(
              controller: _feedScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 4),
                  Container(
                    height: 172,
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(
                            alpha: 0.5,
                          ), // Shadow color
                          spreadRadius: 2, // Kitna wide shadow ho
                          blurRadius: 7, // Shadow blur
                          offset: Offset(
                            0,
                            3,
                          ), // X aur Y direction mein shadow ka move
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: _buildReelsSection(),
                  ),
                  Space.vertical(20),
                  if (!widget.isAdmin) ...[
                    // Pending Cases Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending cases',
                            style: context.bold.copyWith(fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: widget.onViewAllPending,
                            child: Text(
                              'View all',
                              style: context.normal.copyWith(
                                fontSize: 14,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Space.vertical(12),
                    ..._pendingCases.map((pendingCase) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PendingCaseCard(
                        pendingCase: pendingCase,
                        onOpenResponse: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PendingCaseResponsePage(
                                caseId: int.tryParse(pendingCase['case_id'] ?? ''),
                                caseTitle: pendingCase['title'],
                                mediaUrl: pendingCase['image'],
                                isMediaImage: (pendingCase['image'] ?? '').isNotEmpty,
                                createdAt: pendingCase['date'],
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                    Space.vertical(8),
                  ],
                  if (_isLoadingPosts && _filteredPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_postsError != null && _filteredPosts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            _postsError!,
                            style: context.normal.copyWith(color: kRedColor),
                          ),
                          Space.vertical(8),
                          TextButton(
                            onPressed: _loadPostsAndCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_filteredPosts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        selectedIndex == 0
                            ? 'No active posts yet'
                            : 'No posts found for this category',
                        style: context.normal.copyWith(color: kDarkGreyColor),
                      ),
                    )
                  else
                    ..._buildFeedWithAds(_filteredPosts),
                  Space.vertical(20),
                ],
              ),
            ),
          ),
        ),
        const AdMobBannerWidget(),
      ],
    );
  }

  List<Widget> _buildFeedWithAds(List<_FeedPostItem> postItems) {
    final List<Widget> list = [];
    if (postItems.isEmpty) return list;

    if (_activeFeedAds.isEmpty) {
      return postItems.map((item) => _buildPostWidget(item)).toList();
    }

    int adIndex = 0;
    final pattern = [1, 2, 1, 2];
    int patternIndex = 0;
    int postsProcessedCount = 0;
    int currentTarget = pattern[patternIndex];

    for (int i = 0; i < postItems.length; i++) {
      list.add(_buildPostWidget(postItems[i]));
      postsProcessedCount++;

      if (postsProcessedCount == currentTarget) {
        final ad = _activeFeedAds[adIndex % _activeFeedAds.length];
        list.add(_HomeFeedAdContainer(ad: ad));
        adIndex++;
        postsProcessedCount = 0;
        patternIndex = (patternIndex + 1) % pattern.length;
        currentTarget = pattern[patternIndex];
      }
    }

    return list;
  }

  Widget _buildPostWidget(_FeedPostItem item) {
    final post = item.post;
    final postKey = _postKeys.putIfAbsent(
      post.postId,
      () => GlobalKey(),
    );
    return Padding(
      key: item.repost == null ? postKey : null,
      padding: const EdgeInsets.only(bottom: 20),
      child: HomePostContainer(
        isAdmin: widget.isAdmin,
        post: post,
        repost: item.repost,
        onOpenOriginalPostInFeed: item.repost != null
            ? () => _focusPostInFeed(post.postId)
            : null,
        highlightPost:
            item.repost == null &&
            _highlightedPostId == post.postId,
        onClickProfile: () {
          final repostUserId = item.repost?.userId;
          final authorUserId = repostUserId ?? post.authorUserId;
          if (authorUserId == null) {
            return;
          }

          final repostName =
              item.repost?.repostUserDetail?.fullName.trim() ??
              '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfilePage(
                userId: authorUserId,
                userName: repostName.isNotEmpty
                    ? repostName
                    : post.authorDisplayName,
                avatarUrl: post.authorAvatarUrl,
              ),
            ),
          );
        },
        onPostUpdated: _loadPostsAndCategories,
      ),
    );
  }
}

class _HomeFeedAdContainer extends StatelessWidget {
  final Map<String, dynamic> ad;

  const _HomeFeedAdContainer({required this.ad});

  @override
  Widget build(BuildContext context) {
    final title = ad['title']?.toString() ?? 'Featured Promotion';
    final note = ad['note']?.toString() ?? '';
    final categoryName = ad['categoryName']?.toString() ?? 'Sponsored';
    final coverUrl = ad['coverImageUrl']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign, size: 16, color: kPrimaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Sponsored • $categoryName',
                        style: context.semiBold.copyWith(fontSize: 12, color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                coverUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: const Color(0xFFFACC46),
                  alignment: Alignment.center,
                  child: const Icon(Icons.campaign, size: 48, color: kWhiteColor),
                ),
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withValues(alpha: 0.8), kPrimaryColor],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.campaign, size: 48, color: kWhiteColor),
            ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bold.copyWith(fontSize: 16, color: kBlackColor),
                ),
                if (note.isNotEmpty) ...[
                  Space.vertical(6),
                  Text(
                    note,
                    style: context.normal.copyWith(fontSize: 13, color: kDarkGreyColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReelCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddReelCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = AuthStorage.cachedProfileImageUrl?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 100,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kBlackColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profileImageUrl.isNotEmpty
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: kGreyColor.withValues(alpha: 0.3),
                            child: const Icon(Icons.person, color: kDarkGreyColor, size: 36),
                          ),
                        )
                      : Container(
                          color: kGreyColor.withValues(alpha: 0.3),
                          child: const Icon(Icons.person, color: kDarkGreyColor, size: 36),
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: kWhiteColor,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: kDeepBlackColor,
                      child: const Icon(Icons.add, color: kWhiteColor, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 100,
            child: Text(
              'Add highlight',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveReelCard extends StatelessWidget {
  final ActiveReel reel;
  final VoidCallback onDeleted;

  const _ActiveReelCard({required this.reel, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => FullscreenReelViewer(reel: reel)),
        );
        if (deleted == true) {
          onDeleted();
        }
      },
      child: SizedBox(
        width: 100,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: kBlackColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _ReelMediaPreview(reel: reel),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 8,
              child: Row(
                children: [
                  _ReelUserAvatar(reel: reel, radius: 13),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      reel.displayName,
                      style: context.normal.copyWith(
                        color: kWhiteColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelUserAvatar extends StatelessWidget {
  final ActiveReel reel;
  final double radius;

  const _ReelUserAvatar({required this.reel, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cachedAvatarUrl = AuthStorage.cachedProfileImageUrl?.trim();
    final avatarUrl =
        _isCurrentUserReel &&
            cachedAvatarUrl != null &&
            cachedAvatarUrl.isNotEmpty
        ? cachedAvatarUrl
        : reel.userAvatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: kPrimaryColor.withValues(alpha: 0.12),
      child: Text(
        _buildInitials(reel.displayName),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool get _isCurrentUserReel {
    final currentUserId = AuthStorage.cachedUserId;
    if (currentUserId == null) return false;

    return reel.userInfo?.userId == currentUserId ||
        reel.userId == currentUserId ||
        reel.createdBy == currentUserId;
  }

  String _buildInitials(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _FullscreenReelViewer extends StatefulWidget {
  final ActiveReel reel;

  const _FullscreenReelViewer({required this.reel});

  @override
  State<_FullscreenReelViewer> createState() => _FullscreenReelViewerState();
}

class _FullscreenReelViewerState extends State<_FullscreenReelViewer> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  bool _isDeleting = false;

  bool get _isImage => widget.reel.isImage;
  bool get _isCurrentUserReel {
    final currentUserId = AuthStorage.cachedUserId;
    if (currentUserId == null) return false;

    return widget.reel.userInfo?.userId == currentUserId ||
        widget.reel.userId == currentUserId ||
        widget.reel.createdBy == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    if (!_isImage && widget.reel.mediaUrl != null) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.mediaUrl!),
      );
      _initialization = _controller!.initialize().then((_) {
        _controller!
          ..setLooping(true)
          ..play();
        if (mounted) {
          setState(() {});
        }
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
      backgroundColor: kBlackColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _isImage ? _buildImage() : _buildVideo()),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (_isCurrentUserReel)
                    PopupMenuButton<String>(
                      color: kWhiteColor,
                      elevation: 18,
                      shadowColor: kBlackColor.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      offset: const Offset(-8, 42),
                      enabled: !_isDeleting,
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDeleteReel();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'delete',
                          height: 46,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                color: kRedColor,
                              ),
                              Space.horizontal(10),
                              Text(
                                _isDeleting ? 'Deleting...' : 'Delete',
                                style: const TextStyle(color: kRedColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.more_horiz,
                            color: kWhiteColor,
                          ),
                        ),
                      ),
                    ),
                  if (_isCurrentUserReel) Space.horizontal(8),
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: kWhiteColor),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _ReelUserAvatar(reel: widget.reel, radius: 20),
                      Space.horizontal(10),
                      Expanded(
                        child: Text(
                          widget.reel.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: kWhiteColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  Space.vertical(10),
                  Text(
                    widget.reel.reelDescription.trim().isEmpty
                        ? 'No description'
                        : widget.reel.reelDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kWhiteColor,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReel() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          title: const Text('Delete reel?'),
          content: const Text('This reel will be removed from your story.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: kRedColor)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteReel();
    }
  }

  Future<void> _deleteReel() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await UserCaseService().deleteUserReel(
        accessToken: accessToken,
        reelId: widget.reel.reelId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Reel deleted successfully');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to delete reel: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
    }
  }

  Widget _buildImage() {
    final mediaUrl = widget.reel.mediaUrl;
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: kWhiteColor, size: 48),
      );
    }

    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.network(
          mediaUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            color: kWhiteColor,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_controller == null || _initialization == null) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: kWhiteColor, size: 48),
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
                      ? 9 / 16
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

class _ReelMediaPreview extends StatelessWidget {
  final ActiveReel reel;

  const _ReelMediaPreview({required this.reel});

  @override
  Widget build(BuildContext context) {
    final mediaUrl = reel.mediaUrl;
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      return _buildFallback(icon: Icons.hide_image_outlined, label: 'No media');
    }

    if (reel.isImage) {
      return SizedBox.expand(
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildFallback(
              icon: Icons.image_outlined,
              label: 'Loading image',
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, _, _) => _buildFallback(
            icon: Icons.broken_image_outlined,
            label: 'Image failed',
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: kBlackColor),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kPrimaryColor.withValues(alpha: 0.2),
                kBlackColor.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: kWhiteColor,
            size: 36,
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Text(
            reel.reelDescription.trim().isEmpty
                ? 'Video reel'
                : reel.reelDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.normal.copyWith(color: kWhiteColor, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback({
    required IconData icon,
    required String label,
    Widget? child,
  }) {
    return Container(
      color: kLightGreyColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child ?? Icon(icon, color: kDarkGreyColor, size: 28),
          Space.vertical(6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kDarkGreyColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PendingCaseCard extends StatelessWidget {
  final Map<String, String> pendingCase;
  final VoidCallback? onOpenResponse;

  const _PendingCaseCard({required this.pendingCase, this.onOpenResponse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCaseImage(pendingCase['image']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pendingCase['title']!,
                    style: context.bold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pendingCase['description']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.normal.copyWith(
                      fontSize: 11,
                      color: kDarkGreyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pendingCase['date']!,
                    style: context.normal.copyWith(
                      fontSize: 10,
                      color: kDarkGreyColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onOpenResponse,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Open and response',
                        style: context.semiBold.copyWith(
                          fontSize: 12,
                          color: kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 90,
        color: kLightGreyColor,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          color: kLightGreyColor,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return Image.asset(
      imagePath,
      width: 90,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 90,
        color: kLightGreyColor,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
