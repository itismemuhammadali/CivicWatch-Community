import 'dart:async';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/services/user_cache_service.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/pages/public_profile_page.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;

  bool _isLoading = false;
  String _query = '';
  List<ActivePost> _posts = [];
  List<CachedUserInfo> _users = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
    _performSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _query = query;
      });
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final postsResult = await FirestoreDataService().searchPosts(_query);
      final usersResult = await FirestoreDataService().searchUsers(_query);

      if (!mounted) return;
      setState(() {
        _posts = postsResult;
        _users = usersResult;
      });
    } catch (e) {
      debugPrint('Error searching: $e');
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
      body: SafeArea(
        child: Column(
          children: [
            // Header Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kDarkGreyColor),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Space.horizontal(12),
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      topPadding: 10,
                      bottomPadding: 10,
                      hintText: "Search posts, people...",
                      prefix: const Icon(Icons.search, color: kDarkGreyColor),
                      hintTextColor: kDarkGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: kPrimaryColor,
              unselectedLabelColor: kDarkGreyColor,
              indicatorColor: kPrimaryColor,
              tabs: const [
                Tab(text: "Posts"),
                Tab(text: "Users"),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(),
                        _buildUsersTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Text(
          "No posts found.",
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => Space.vertical(16),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return HomePostContainer(
          isAdmin: false,
          onClickProfile: () {
            final authorId = post.authorUserId;
            if (authorId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(
                    userId: authorId,
                    userName: post.authorDisplayName,
                    avatarUrl: post.authorAvatarUrl,
                  ),
                ),
              );
            }
          },
          post: post,
          onPostUpdated: _performSearch,
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          "No users found.",
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(color: kContainerGreyColor),
      itemBuilder: (context, index) {
        final user = _users[index];
        final displayName = '${user.firstName} ${user.lastName}'.trim();
        
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicProfilePage(
                  userId: user.userId,
                  userName: displayName.isEmpty ? user.email : displayName,
                  avatarUrl: user.avatarUrl,
                ),
              ),
            );
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.hardEdge,
            child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: kPrimaryColor.withOpacity(0.2),
                      child: Center(
                        child: Text(
                          (displayName.isNotEmpty ? displayName[0] : (user.email.isNotEmpty ? user.email[0] : 'U')).toUpperCase(),
                          style: context.bold.copyWith(color: kPrimaryColor),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: kPrimaryColor.withOpacity(0.2),
                    child: Center(
                      child: Text(
                        (displayName.isNotEmpty ? displayName[0] : (user.email.isNotEmpty ? user.email[0] : 'U')).toUpperCase(),
                        style: context.bold.copyWith(color: kPrimaryColor),
                      ),
                    ),
                  ),
          ),
          title: Text(
            displayName.isEmpty ? user.email : displayName,
            style: context.normal.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.email,
            style: context.normal.copyWith(color: kDarkGreyColor, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: kGreyColor),
        );
      },
    );
  }
}
