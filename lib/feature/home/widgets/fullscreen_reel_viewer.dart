import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullscreenReelViewer extends StatefulWidget {
  final ActiveReel reel;

  const FullscreenReelViewer({super.key, required this.reel});

  @override
  State<FullscreenReelViewer> createState() => _FullscreenReelViewerState();
}

class _FullscreenReelViewerState extends State<FullscreenReelViewer> {
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
                      _ReelAvatar(reel: widget.reel, radius: 20),
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

  Widget _buildImage() {
    final mediaUrl = widget.reel.mediaUrl;
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: kWhiteColor, size: 64),
      );
    }

    return Image.network(
      mediaUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, color: kWhiteColor, size: 64),
      ),
    );
  }

  Widget _buildVideo() {
    if (_controller == null || _initialization == null) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: kWhiteColor, size: 64),
      );
    }

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _controller!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: kWhiteColor, size: 48),
                  Space.vertical(12),
                  Text(
                    'Failed to play video.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kWhiteColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator(color: kWhiteColor));
      },
    );
  }

  Future<void> _confirmDeleteReel() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          title: const Text('Delete reel?'),
          content: const Text('This reel will be removed.'),
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

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final token = await const AuthStorage().readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('Not authenticated');
      }

      await UserCaseService().deleteUserReel(
        accessToken: token,
        reelId: widget.reel.reelId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Reel deleted');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to delete reel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}

class _ReelAvatar extends StatelessWidget {
  final ActiveReel reel;
  final double radius;

  const _ReelAvatar({required this.reel, required this.radius});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = reel.userAvatarUrl;
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
      backgroundColor: kPrimaryColor.withValues(alpha: 0.2),
      child: Text(
        reel.displayName.isNotEmpty ? reel.displayName[0].toUpperCase() : 'U',
        style: TextStyle(
          color: kWhiteColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
