import 'dart:async';

import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:flutter/material.dart';

class SharedPostPage extends StatefulWidget {
  final int postId;

  const SharedPostPage({super.key, required this.postId});

  @override
  State<SharedPostPage> createState() => _SharedPostPageState();
}

class _SharedPostPageState extends State<SharedPostPage> {
  bool _isLoading = true;
  String? _errorMessage;
  ActivePost? _post;
  StreamSubscription<AppWebSocketEvent>? _postEventSubscription;
  bool _refreshQueued = false;

  @override
  void initState() {
    super.initState();
    _bindWebSocketEvents();
    _loadPost();
  }

  @override
  void dispose() {
    _postEventSubscription?.cancel();
    super.dispose();
  }

  void _bindWebSocketEvents() {
    _postEventSubscription?.cancel();
    _postEventSubscription = AppWebSocketService.instance
        .eventsFor(postRefreshEventTypes)
        .listen((event) {
          if (event.postId != null && event.postId != widget.postId) {
            return;
          }
          _schedulePostRefresh();
        });
  }

  void _schedulePostRefresh() {
    if (!mounted) return;
    if (_isLoading) {
      _refreshQueued = true;
      return;
    }
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Please log in to view this shared post');
      }

      final posts = await CasePostService().getAllActivePosts(
        accessToken: accessToken,
      );

      ActivePost? matchedPost;
      for (final post in posts) {
        if (post.postId == widget.postId) {
          matchedPost = post;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _post = matchedPost;
        if (matchedPost == null) {
          _errorMessage = 'This post is no longer available';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to open shared post';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_refreshQueued) {
          _refreshQueued = false;
          _loadPost();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: const Text('Shared Post'),
        backgroundColor: kWhiteColor,
        foregroundColor: kBlackColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPost,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: context.normal.copyWith(color: kRedColor),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadPost,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            else if (_post != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Opened from shared link',
                  style: context.semiBold.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              HomePostContainer(
                isAdmin: false,
                post: _post!,
                onClickProfile: () {},
                onPostUpdated: _loadPost,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
