import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/network/models/post_report.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/communityFeedback/pages/feedback_view.dart';
import 'package:cctv_app/feature/home/pages/create_reel_page.dart';
import 'package:cctv_app/feature/home/widgets/fullscreen_reel_viewer.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';

class CommunityFeedback extends StatefulWidget {
  const CommunityFeedback({super.key});

  @override
  State<CommunityFeedback> createState() => _CommunityFeedbackState();
}

class _CommunityFeedbackState extends State<CommunityFeedback> {
  int selectedIndex = 0;
  bool _isLoading = false;
  List<ActivePost> _dynamicPosts = [];
  List<ActiveReel> _dynamicReels = [];

  final List<String> _categories = [
    'All',
    'Family Affairs',
    'Divorce',
    'Neighborhood conflicts',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDynamicData();
    });
  }

  Future<void> _loadDynamicData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await FirestoreDataService().getAllActivePostsEnriched();
      final reels = await FirestoreDataService().getAllActiveReels();
      
      if (!mounted) return;
      setState(() {
        _dynamicPosts = posts;
        _dynamicReels = reels;
      });
    } catch (_) {
      try {
        final accessToken = await const AuthStorage().readAccessToken();
        if (accessToken != null) {
          final posts = await CasePostService().getAllRecentPosts(accessToken: accessToken);
          if (!mounted) return;
          setState(() {
            _dynamicPosts = posts;
          });
        }
      } catch (_) {}
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter dynamic posts by category tab selection
  List<ActivePost> _getFilteredPosts() {
    if (selectedIndex == 0) {
      return _dynamicPosts;
    }
    final targetCategory = _categories[selectedIndex].toLowerCase();
    
    // Attempt to match by categoryId or descriptions
    return _dynamicPosts.where((post) {
      final title = post.caseDetail?.caseTitle.toLowerCase() ?? '';
      final description = post.postDescription.toLowerCase();
      return title.contains(targetCategory) || description.contains(targetCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDynamicData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Space.vertical(10),
                // Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CurrentUserAvatar(
                        radius: 22,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        },
                      ),
                      Space.horizontal(10),
                      Expanded(
                        child: CustomTextField(
                          topPadding: 10,
                          bottomPadding: 10,
                          hintText: "Search",
                          prefix: const Icon(Icons.search, color: kDarkGreyColor),
                          hintTextColor: kDarkGreyColor,
                        ),
                      ),
                      Space.horizontal(10),
                      Container(
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: kGreyColor),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          Assets.pngFileImage,
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: kBlackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Space.vertical(14),

                // Category Pills Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: List.generate(_categories.length, (index) {
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimaryColor : kWhiteColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? kPrimaryColor : kGreyColor,
                            ),
                          ),
                          child: Text(
                            _categories[index],
                            style: context.medium.copyWith(
                              fontSize: 13,
                              color: isSelected ? kWhiteColor : kBlackColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Space.vertical(16),

                // Highlights / Reels Row
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      // Card 1: Add Highlight
                      GestureDetector(
                        onTap: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateReelPage()),
                          );
                          if (created == true) {
                            _loadDynamicData();
                          }
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8F3F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: kBlackColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, color: kWhiteColor, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                              Space.vertical(6),
                              Text(
                                "Add highlight",
                                style: context.normal.copyWith(fontSize: 12, color: kBlackColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dynamic Highlights List from Firestore
                      ..._dynamicReels.map((reel) {
                        final coverUrl = reel.applicationMeta?.metaUrl?.trim() ?? '';
                        final avatarUrl = reel.userInfo?.applicationMeta?.metaUrl?.trim() ?? '';
                        final userName = reel.userInfo?.firstName ?? 'User';

                        return GestureDetector(
                          onTap: () async {
                            final deleted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullscreenReelViewer(reel: reel),
                              ),
                            );
                            if (deleted == true) {
                              _loadDynamicData();
                            }
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: coverUrl.isNotEmpty
                                            ? Image.network(
                                                coverUrl,
                                                width: 100,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: kGreyColor,
                                                  child: const Icon(Icons.videocam, color: kWhiteColor),
                                                ),
                                              )
                                            : Container(
                                                color: kGreyColor,
                                                child: const Icon(Icons.videocam, color: kWhiteColor),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: kWhiteColor,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: kGreyColor.withValues(alpha: 0.3),
                                              backgroundImage: avatarUrl.isNotEmpty
                                                  ? NetworkImage(avatarUrl)
                                                  : null,
                                              child: avatarUrl.isEmpty
                                                  ? const Icon(Icons.person, color: kDarkGreyColor, size: 14)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Space.vertical(6),
                                Text(
                                  userName,
                                  style: context.normal.copyWith(fontSize: 12, color: kBlackColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Space.vertical(16),

                // Community Feed Stream
                if (_isLoading && filteredPosts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (filteredPosts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Text(
                      "No cases found in this category",
                      style: context.normal.copyWith(color: kDarkGreyColor, fontSize: 16),
                    ),
                  )
                else
                  ...filteredPosts.map((post) => _buildDynamicPostCard(context, post)),
                Space.vertical(24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicPostCard(BuildContext context, ActivePost post) {
    final caseDetail = post.caseDetail;
    final defendantA = post.defendantDetails.isNotEmpty ? post.defendantDetails[0] : null;
    final defendantB = post.defendantDetails.length > 1 ? post.defendantDetails[1] : null;

    final avatarUrl = post.authorAvatarUrl;
    final authorName = post.authorDisplayName.isEmpty ? "Community User" : post.authorDisplayName;

    // Fetch dynamic cover images for Options A and B
    final coverA = defendantA?.meta?.metaUrl?.trim() ?? '';
    final coverB = defendantB?.meta?.metaUrl?.trim() ?? '';

    // Calculate time left or use default
    final createdAt = post.createdAt != null ? DateTime.tryParse(post.createdAt!) : null;
    final diff = createdAt != null ? DateTime.now().difference(createdAt) : null;
    final remainingHours = diff != null ? (24 - diff.inHours).clamp(1, 24) : 8;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kGreyColor.withValues(alpha: 0.3),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: kDarkGreyColor, size: 20)
                    : null,
              ),
              Space.horizontal(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: context.bold.copyWith(fontSize: 15, color: kBlackColor),
                    ),
                    Text(
                      post.createdAt != null ? "${diff?.inMinutes ?? 2} mints ago" : "2 mints ago",
                      style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: kDarkGreyColor),
            ],
          ),
          Space.vertical(12),

          // Case Title & Time Left
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  caseDetail?.caseTitle ?? post.postDescription,
                  style: context.bold.copyWith(fontSize: 20, color: kBlackColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$remainingHours hours left",
                style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
              ),
            ],
          ),
          Space.vertical(12),

          // Dual Video / Image Comparison Cards
          Row(
            children: [
              // Option A
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: kGreyColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        image: coverA.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(coverA),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: kPrimaryColor,
                          child: const Icon(Icons.play_arrow, color: kWhiteColor, size: 24),
                        ),
                      ),
                    ),
                    Space.vertical(8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kPrimaryColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: kWhiteColor, size: 10),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "A. ${defendantA?.userInfo?.fullName ?? 'Option A'}",
                              style: context.semiBold.copyWith(fontSize: 12, color: kPrimaryColor),
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
              Space.horizontal(12),
              // Option B
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: kGreyColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        image: coverB.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(coverB),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: kPrimaryColor,
                          child: const Icon(Icons.play_arrow, color: kWhiteColor, size: 24),
                        ),
                      ),
                    ),
                    Space.vertical(8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kGreyColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          "B. ${defendantB?.userInfo?.fullName ?? 'Option B'}",
                          style: context.semiBold.copyWith(fontSize: 12, color: kBlackColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Space.vertical(14),

          // Resolutions Action Button
          PrimaryButton(
            text: "Resolutions",
            onPressed: () {
              final dummyReport = PostReport(
                reportId: post.postId,
                postId: post.postId,
                reportReasonTypeId: 1,
                reportStatus: 'P',
                reportAdditionalInformation: post.postDescription,
                createdBy: post.authorUserId ?? 0,
                createdAt: post.createdAt,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedbackView(
                    report: dummyReport,
                    post: post,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
