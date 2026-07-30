import 'dart:async';

import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/feature/profile/pages/user_followers_following_page.dart';

class PublicProfilePage extends StatefulWidget {
  final int userId;
  final String userName;
  final String? avatarUrl;

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ActivePost> _posts = const [];
  bool _isLoadingReel = true;
  ActiveReel? _userReel;
  String _userStatus = 'Offline';
  StreamSubscription<AppWebSocketEvent>? _userStatusSubscription;

  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowingCurrent = false;
  bool _isFollowLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _bindUserStatusEvents();
    _loadPosts();
    _loadUserReel();
    _loadFollowData();
  }

  Future<void> _loadFollowData() async {
    setState(() => _isFollowLoading = true);
    _currentUserId = await const AuthStorage().readUserId();
    
    try {
      final stats = await FirestoreDataService().getFollowStats(widget.userId, currentUserId: _currentUserId);
      if (!mounted) return;
      setState(() {
        _followersCount = stats['followersCount'] ?? 0;
        _followingCount = stats['followingCount'] ?? 0;
        _isFollowingCurrent = stats['isFollowingCurrent'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loading follow stats: $e');
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    
    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowingCurrent) {
        await FirestoreDataService().unfollowUser(followerId: _currentUserId!, followingId: widget.userId);
        setState(() {
          _isFollowingCurrent = false;
          _followersCount--;
        });
      } else {
        await FirestoreDataService().followUser(followerId: _currentUserId!, followingId: widget.userId);
        setState(() {
          _isFollowingCurrent = true;
          _followersCount++;
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    super.dispose();
  }

  void _bindUserStatusEvents() {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = AppWebSocketService.instance
        .eventsFor(userStatusEventTypes)
        .listen(_handleUserStatusEvent);
  }

  void _handleUserStatusEvent(AppWebSocketEvent event) {
    final users = event.data['users'];
    if (users is! List) return;

    for (final user in users) {
      if (user is! Map) continue;

      final userId = int.tryParse('${user['user_id']}');
      if (userId != widget.userId) continue;

      final status = '${user['status'] ?? ''}'.trim().toUpperCase();
      if (status != 'ONLINE' && status != 'OFFLINE') return;
      if (!mounted) return;

      setState(() {
        _userStatus = status == 'ONLINE' ? 'Online' : 'Offline';
      });
      return;
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final posts = await CasePostService().getPostsByUserId(
        accessToken: accessToken,
        userId: widget.userId,
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
        _errorMessage = 'Failed to load profile posts';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserReel() async {
    setState(() {
      _isLoadingReel = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final reel = await UserCaseService().getUserReel(
        accessToken: accessToken,
        userId: widget.userId,
      );

      if (!mounted) return;
      setState(() {
        _userReel = reel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userReel = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingReel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kBlackColor),
        title: Text('Profile', style: context.bold.copyWith(fontSize: 18, color: kBlackColor)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadPosts(), _loadUserReel(), _loadFollowData()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProfileAvatar(
                    avatarUrl: widget.avatarUrl,
                    userName: widget.userName,
                    radius: 28,
                  ),
                  Space.horizontal(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: context.bold.copyWith(fontSize: 16),
                        ),
                        Text(
                          _userStatus,
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
              Space.vertical(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: context.bold.copyWith(fontSize: 18),
                      ),
                      Text(
                        'The description of my profile',
                        style: context.normal.copyWith(color: kDarkGreyColor),
                      ),
                    ],
                  ),
                  if (_currentUserId == null || _currentUserId != widget.userId)
                    PrimaryButton(
                      text: _isFollowingCurrent ? 'Unfollow' : 'Follow',
                      onPressed: () {
                        if (!_isFollowLoading) _toggleFollow();
                      },
                      height: 36,
                      buttonColor: _isFollowingCurrent ? kWhiteColor : kPrimaryColor,
                      textColor: _isFollowingCurrent ? kBlackColor : kWhiteColor,
                      showBorder: _isFollowingCurrent,
                      borderColor: _isFollowingCurrent ? kGreyColor : kTransparentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: kContainerGreyColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Your Profile',
                        style: context.semiBold.copyWith(color: kDarkGreyColor, fontSize: 13),
                      ),
                    ),
                ],
              ),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFollowersFollowingPage(
                            userId: widget.userId,
                            initialTabIndex: 0, // Followers
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          '$_followersCount',
                          style: context.bold.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Followers',
                          style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                        ),
                      ],
                    ),
                  ),
                  Space.horizontal(32),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFollowersFollowingPage(
                            userId: widget.userId,
                            initialTabIndex: 1, // Following
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          '$_followingCount',
                          style: context.bold.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Following',
                          style: context.normal.copyWith(fontSize: 12, color: kDarkGreyColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Space.vertical(16),
              if (_isLoadingReel)
                const Center(child: CircularProgressIndicator())
              else if (_userReel != null) ...[
                Text(
                  'Reels',
                  style: context.semiBold.copyWith(fontSize: 14),
                ),
                Space.vertical(10),
                _ProfileReelCard(reel: _userReel!),
              ],
              Space.vertical(16),
              Text(
                'Total post',
                style: context.semiBold.copyWith(fontSize: 14),
              ),
              Space.vertical(10),
              _buildBody(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(color: kRedColor),
            ),
            Space.vertical(8),
            TextButton(onPressed: _loadPosts, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No posts found',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _ProfilePostCard(post: _posts[index]);
      },
    );
  }
}

class _ProfileReelCard extends StatelessWidget {
  final ActiveReel reel;

  const _ProfileReelCard({required this.reel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _ProfileFullscreenReelViewer(reel: reel)),
        );
      },
      child: SizedBox(
        width: 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor,
                    kPrimaryColor.withValues(alpha: 0.35),
                  ],
                ),
              ),
              child: ClipOval(child: _ProfileReelMediaPreview(reel: reel)),
            ),
            Space.vertical(8),
            Text(
              reel.reelDescription.trim().isEmpty ? 'Reel' : reel.reelDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileReelMediaPreview extends StatelessWidget {
  final ActiveReel reel;

  const _ProfileReelMediaPreview({required this.reel});

  @override
  Widget build(BuildContext context) {
    final mediaUrl = reel.mediaUrl;
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      return Container(
        color: kLightGreyColor,
        alignment: Alignment.center,
        child: const Icon(Icons.hide_image_outlined, color: kDarkGreyColor),
      );
    }

    if (reel.isImage) {
      return Image.network(
        mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: kLightGreyColor,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: kDarkGreyColor),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: kBlackColor),
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: kWhiteColor,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _ProfileFullscreenReelViewer extends StatefulWidget {
  final ActiveReel reel;

  const _ProfileFullscreenReelViewer({required this.reel});

  @override
  State<_ProfileFullscreenReelViewer> createState() =>
      _ProfileFullscreenReelViewerState();
}

class _ProfileFullscreenReelViewerState
    extends State<_ProfileFullscreenReelViewer> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;

  bool get _isImage => widget.reel.isImage;

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
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: kWhiteColor),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Text(
                widget.reel.reelDescription.trim().isEmpty
                    ? 'No description'
                    : widget.reel.reelDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kWhiteColor,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio == 0
                  ? 9 / 16
                  : _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String userName;
  final double radius;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.userName,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl?.trim();
    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: kLightGreyColor,
        backgroundImage: NetworkImage(normalizedUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initials = userName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: kTextfieldBlueColor,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  final ActivePost post;

  const _ProfilePostCard({required this.post});

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
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
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'pm' : 'am';
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    return '$month ${parsed.day}, $hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final media = post.caseDetail?.meta;
    final title = post.caseDetail?.caseTitle.trim().isNotEmpty == true
        ? post.caseDetail!.caseTitle
        : 'Untitled';
    final description = post.postDescription.trim().isNotEmpty
        ? post.postDescription
        : (post.caseDetail?.caseDescription ?? '');

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: _ProfilePostMedia(media: media),
            ),
          ),
          Space.vertical(6),
          Text(
            title,
            style: context.bold.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Space.vertical(4),
          Expanded(
            child: Text(
              description,
              style: context.normal.copyWith(
                overflow: TextOverflow.ellipsis,
                fontSize: 12,
                color: kDarkGreyColor,
              ),
              maxLines: 3,
            ),
          ),
          Space.vertical(6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatDate(post.createdAt),
              style: context.normal.copyWith(
                overflow: TextOverflow.ellipsis,
                fontSize: 12,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          PrimaryButton(
            height: 42,
            text: 'View Post',
            padding: const EdgeInsets.symmetric(horizontal: 2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: kWhiteColor,
                    appBar: AppBar(
                      backgroundColor: kWhiteColor,
                      foregroundColor: kBlackColor,
                      title: const Text('View Post'),
                    ),
                    body: ListView(
                      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 16),
                      children: [
                        HomePostContainer(
                          isAdmin: false,
                          post: post,
                          onClickProfile: () {},
                          onPostUpdated: () {},
                        ),
                      ],
                    ),
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

class _ProfilePostMedia extends StatelessWidget {
  final ActivePostMeta? media;

  const _ProfilePostMedia({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media == null || !media!.hasMedia) {
      return Container(
        color: kLightGreyColor,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: kDarkGreyColor),
      );
    }

    if (!media!.isImage) {
      return Container(
        color: kBlackColor,
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_fill_rounded,
          color: kWhiteColor,
          size: 34,
        ),
      );
    }

    return Image.network(
      media!.metaUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: kLightGreyColor,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: kDarkGreyColor),
      ),
    );
  }
}
