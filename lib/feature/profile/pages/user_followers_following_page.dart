import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/pages/public_profile_page.dart';
import 'package:flutter/material.dart';

class UserFollowersFollowingPage extends StatefulWidget {
  final int userId;
  final int initialTabIndex; // 0 for Followers, 1 for Following

  const UserFollowersFollowingPage({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<UserFollowersFollowingPage> createState() => _UserFollowersFollowingPageState();
}

class _UserFollowersFollowingPageState extends State<UserFollowersFollowingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
    ]);
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;
    setState(() => _isLoadingFollowers = true);
    try {
      final followers = await FirestoreDataService().getFollowersList(widget.userId);
      if (!mounted) return;
      setState(() {
        _followers = followers;
      });
    } catch (e) {
      debugPrint('Error loading followers: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    if (!mounted) return;
    setState(() => _isLoadingFollowing = true);
    try {
      final following = await FirestoreDataService().getFollowingList(widget.userId);
      if (!mounted) return;
      setState(() {
        _following = following;
      });
    } catch (e) {
      debugPrint('Error loading following: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBlackColor),
        title: Text(
          'Connections',
          style: context.bold.copyWith(fontSize: 18, color: kBlackColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: kDarkGreyColor,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, _isLoadingFollowers, _loadFollowers),
          _buildUserList(_following, _isLoadingFollowing, _loadFollowing),
        ],
      ),
    );
  }
  
  Widget _buildUserList(List<Map<String, dynamic>> users, bool isLoading, Future<void> Function() onRefresh) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimaryColor,
      child: users.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Text(
                      'No users found',
                      style: context.normal.copyWith(color: kDarkGreyColor),
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kLightGreyColor),
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserTile(user);
              },
            ),
    );
  }
  
  Widget _buildUserTile(Map<String, dynamic> user) {
    final int userId = user['user_id'] is int ? user['user_id'] : (int.tryParse('${user['user_id']}') ?? 0);
    final String firstName = user['first_name'] ?? '';
    final String lastName = user['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String avatarUrl = user['avatar_url'] ?? '';
    final String email = user['user_email'] ?? '';
    final String displayName = fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : 'User $userId');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildAvatar(avatarUrl, displayName),
      title: Text(
        displayName,
        style: context.semiBold.copyWith(fontSize: 14),
      ),
      subtitle: (fullName.isNotEmpty && email.isNotEmpty)
          ? Text(
              email,
              style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
            )
          : null,
      onTap: () {
        if (userId <= 0) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfilePage(
              userId: userId,
              userName: displayName,
              avatarUrl: avatarUrl,
            ),
          ),
        ).then((_) {
          // Refresh list when returning, in case follow status changed
          _loadData();
        });
      },
    );
  }
  
  Widget _buildAvatar(String avatarUrl, String fullName) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    
    final initials = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
        
    return CircleAvatar(
      radius: 20,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: context.bold.copyWith(color: kPrimaryColor, fontSize: 14),
      ),
    );
  }
}
