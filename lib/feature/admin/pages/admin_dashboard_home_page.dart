import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/services/dashboard_service.dart';
import 'package:cctv_app/core/network/services/general_parameter_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adminHome/pages/admin_post_detail_page.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:flutter/material.dart';

class AdminDashboardHomePage extends StatefulWidget {
  const AdminDashboardHomePage({super.key});

  @override
  State<AdminDashboardHomePage> createState() => _AdminDashboardHomePageState();
}

class _AdminDashboardHomePageState extends State<AdminDashboardHomePage> {
  int _selectedGrowthFilterIndex = 3; // 'Year' selected by default
  final List<String> _growthFilters = ['Daily', 'Weekly', 'Monthly', 'Year'];

  int _selectedCategoryIndex = 0; // 'All' selected by default
  final List<String> _postCategories = [
    'All',
    'Family Affairs',
    'Divorce',
    'Neighborhood conflicts',
  ];

  // Dynamic values
  bool _isLoading = false;
  int _totalUsers = 0;
  int _activeUsers = 0;
  List<ActivePost> _posts = [];
  List<DashboardUserAnalysisEntry> _growthEntries = [];
  Map<int, String> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final token = await const AuthStorage().readAccessToken() ?? 'demo_token';

    // 1. Fetch stats
    try {
      final total = await DashboardService().getLatestRegistrationCount(accessToken: token);
      final active = await DashboardService().getActiveUserCount(accessToken: token);
      if (mounted) {
        setState(() {
          _totalUsers = total;
          _activeUsers = active;
        });
      }
    } catch (e) {
      debugPrint('Error loading registration counts: $e');
    }

    // 2. Fetch growth entries
    try {
      final entries = await DashboardService().getUserAnalysis(accessToken: token);
      if (mounted) {
        setState(() {
          _growthEntries = entries;
        });
      }
    } catch (e) {
      debugPrint('Error loading user growth analysis: $e');
    }

    // 3. Fetch categories
    try {
      final categoryParams = await const GeneralParameterService().getByHeaderName(
        headerName: 'CASE_CATEGORY',
        accessToken: token,
      );
      if (mounted) {
        setState(() {
          _categoryMap = {
            for (var c in categoryParams) c.paramDetailId: c.paramLabel.trim()
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading case categories: $e');
    }

    // 4. Fetch posts
    try {
      final allPosts = await FirestoreDataService().getAllActivePostsEnriched();
      if (mounted) {
        setState(() {
          _posts = allPosts;
        });
      }
    } catch (e) {
      debugPrint('Error loading active posts: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter recent posts based on selected category tab
  List<ActivePost> _getFilteredPosts() {
    if (_selectedCategoryIndex == 0) {
      return _posts;
    }
    final targetLabel = _postCategories[_selectedCategoryIndex].toLowerCase();
    return _posts.where((post) {
      final catId = post.caseDetail?.caseCategoryId;
      if (catId != null) {
        final label = _categoryMap[catId]?.toLowerCase() ?? '';
        if (label.contains(targetLabel) || targetLabel.contains(label)) return true;
      }
      final description = post.postDescription.toLowerCase();
      return description.contains(targetLabel);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Space.vertical(10),
                  // Header
                  Row(
                    children: [
                      CurrentUserAvatar(
                        radius: 24,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
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
                  Space.vertical(16),
                  // Top overview mini charts
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CustomPaint(
                                  painter: _MiniAreaChartPainter(),
                                  size: const Size(double.infinity, 60),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                top: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Total Users",
                                      style: TextStyle(fontSize: 10, color: kWhiteColor, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "$_totalUsers",
                                      style: const TextStyle(fontSize: 16, color: kWhiteColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Space.horizontal(12),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10, top: 22, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(12, (index) {
                                    final heights = [12.0, 22.0, 8.0, 18.0, 10.0, 15.0, 9.0, 20.0, 6.0, 14.0, 18.0, 20.0];
                                    final colors = [
                                      kGreyColor,
                                      kGreyColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kGreyColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                      kPrimaryColor,
                                    ];
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 4,
                                        height: heights[index % heights.length],
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                top: 4,
                                child: Row(
                                  children: [
                                    Text(
                                      "Active: $_activeUsers",
                                      style: const TextStyle(fontSize: 10, color: kBlackColor, fontWeight: FontWeight.bold),
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
                  // User Growth Section
                  Text(
                    "User Growth",
                    style: context.bold.copyWith(fontSize: 22, color: kBlackColor),
                  ),
                  Space.vertical(12),
                  // Time filters
                  Container(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: List.generate(_growthFilters.length, (index) {
                        final isSelected = _selectedGrowthFilterIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGrowthFilterIndex = index;
                              });
                            },
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _growthFilters[index],
                                style: context.medium.copyWith(
                                  fontSize: 13,
                                  color: isSelected ? kWhiteColor : kDarkGreyColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Space.vertical(12),
                  // User Growth Chart Card (Fully Dynamic & Accurate)
                  _buildDynamicUserGrowthChart(),
                  Space.vertical(20),
                  // Recent post Section
                  Text(
                    "Recent post",
                    style: context.bold.copyWith(fontSize: 22, color: kBlackColor),
                  ),
                  Space.vertical(12),
                  // Category Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_postCategories.length, (index) {
                        final isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
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
                              _postCategories[index],
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
                  // Post List
                  filteredPosts.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Text(
                            "No active posts in this category",
                            style: context.normal.copyWith(color: kDarkGreyColor),
                          ),
                        )
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredPosts.length,
                          separatorBuilder: (_, __) => Space.vertical(12),
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            final imageUrl = post.caseDetail?.meta?.metaUrl?.trim() ?? '';
                            final defImageUrl = post.defendantDetails.isNotEmpty
                                ? post.defendantDetails.first.meta?.metaUrl?.trim() ?? ''
                                : '';
                            final authorAvatar = post.authorAvatarUrl?.trim() ?? '';
                            final displayImage = imageUrl.isNotEmpty
                                ? imageUrl
                                : (defImageUrl.isNotEmpty ? defImageUrl : authorAvatar);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminPostDetailPage(
                                      post: post,
                                      onPostUpdated: _loadDashboardData,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kWhiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: displayImage.isNotEmpty
                                          ? Image.network(
                                              displayImage,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 70,
                                                height: 70,
                                                color: kGreyColor.withValues(alpha: 0.3),
                                                child: const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: kDarkGreyColor,
                                                  size: 24,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 70,
                                              height: 70,
                                              color: kGreyColor.withValues(alpha: 0.3),
                                              child: const Icon(
                                                Icons.image_outlined,
                                                color: kDarkGreyColor,
                                                size: 24,
                                              ),
                                            ),
                                    ),
                                    Space.horizontal(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.caseDetail?.caseTitle ?? post.postDescription,
                                            style: context.bold.copyWith(
                                              fontSize: 14,
                                              color: kBlackColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Space.vertical(6),
                                          Text(
                                            post.createdAt != null
                                                ? post.createdAt!.split('T').first
                                                : 'Active Post',
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
                            );
                          },
                        ),
                  Space.vertical(24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicUserGrowthChart() {
    final now = DateTime.now();

    // 1. Determine period X-labels and counts from _growthEntries
    List<String> xLabels = [];
    List<int> periodCounts = [];

    if (_selectedGrowthFilterIndex == 3) {
      // Year (Last 5 Years)
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        xLabels.add('$year');
        final count = _growthEntries
            .where((e) => e.date.year == year)
            .fold(0, (sum, e) => sum + e.count);
        periodCounts.add(count);
      }
    } else if (_selectedGrowthFilterIndex == 2) {
      // Monthly (Last 6 Months)
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final monthIdx = (d.month - 1) % 12;
        xLabels.add(monthNames[monthIdx < 0 ? monthIdx + 12 : monthIdx]);
        final count = _growthEntries
            .where((e) => e.date.year == d.year && e.date.month == d.month)
            .fold(0, (sum, e) => sum + e.count);
        periodCounts.add(count);
      }
    } else if (_selectedGrowthFilterIndex == 1) {
      // Weekly (Last 4 Weeks)
      for (int i = 3; i >= 0; i--) {
        xLabels.add('Wk ${4 - i}');
        final start = now.subtract(Duration(days: (i + 1) * 7));
        final end = now.subtract(Duration(days: i * 7));
        final count = _growthEntries
            .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
            .fold(0, (sum, e) => sum + e.count);
        periodCounts.add(count);
      }
    } else {
      // Daily (Last 7 Days)
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 6; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        xLabels.add(dayNames[(targetDate.weekday - 1) % 7]);
        final count = _growthEntries
            .where((e) =>
                e.date.year == targetDate.year &&
                e.date.month == targetDate.month &&
                e.date.day == targetDate.day)
            .fold(0, (sum, e) => sum + e.count);
        periodCounts.add(count);
      }
    }

    // 2. Compute dynamic Y-Axis scale
    final maxRaw = periodCounts.fold<int>(0, (max, c) => c > max ? c : max);
    final maxVal = maxRaw == 0 ? 5 : maxRaw;
    
    final yTicks = [
      maxVal,
      (maxVal * 0.75).round(),
      (maxVal * 0.50).round(),
      (maxVal * 0.25).round(),
      0,
    ];

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Y-Axis Labels Column
              SizedBox(
                width: 32,
                height: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: yTicks.map((val) {
                    return Text(
                      '$val',
                      style: const TextStyle(fontSize: 10, color: kDarkGreyColor, fontWeight: FontWeight.w500),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Dynamic Bars Row
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(periodCounts.length, (index) {
                      final count = periodCounts[index];
                      final ratio = count == 0 ? 0.04 : (count / maxVal).clamp(0.04, 1.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text(
                              '$count',
                              style: const TextStyle(fontSize: 10, color: kPrimaryColor, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            width: 18,
                            height: 135 * ratio,
                            decoration: BoxDecoration(
                              color: count > 0 ? kPrimaryColor : kGreyColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dynamic X-Axis Labels Row
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: xLabels.map((lbl) {
                    return Text(
                      lbl,
                      style: const TextStyle(fontSize: 11, color: kDarkGreyColor, fontWeight: FontWeight.w500),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kPrimaryColor.withValues(alpha: 0.8),
          kPrimaryColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.45,
      size.height * 0.2,
      size.width * 0.65,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.1,
      size.width * 0.9,
      size.height * 0.3,
      size.width,
      0,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
