import 'dart:async';

import 'package:cctv_app/core/components/ad_top_header.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adHome/widget/ad_post_container.dart';
import 'package:cctv_app/feature/adHome/widget/horizontal_graph_list.dart';
import 'package:cctv_app/feature/adHome/widget/revenue_card.dart';
import 'package:flutter/material.dart';

class AdHomePage extends StatefulWidget {
  const AdHomePage({super.key});

  @override
  State<AdHomePage> createState() => _AdHomePageState();
}

class _AdHomePageState extends State<AdHomePage> {
  int selectedYear = 2025;
  bool _isLoadingPosts = true;
  String? _postsError;
  List<ActivePost> _posts = const [];
  StreamSubscription<AppWebSocketEvent>? _postsEventSubscription;
  bool _refreshQueued = false;

  @override
  void initState() {
    super.initState();
    _bindWebSocketEvents();
    _loadPosts();
  }

  @override
  void dispose() {
    _postsEventSubscription?.cancel();
    super.dispose();
  }

  void _bindWebSocketEvents() {
    _postsEventSubscription?.cancel();
    _postsEventSubscription = AppWebSocketService.instance
        .eventsFor(postRefreshEventTypes)
        .listen((_) => _schedulePostsRefresh());
  }

  void _schedulePostsRefresh() {
    if (!mounted) return;
    if (_isLoadingPosts) {
      _refreshQueued = true;
      return;
    }
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final posts = await CasePostService().getAllActivePosts(
        accessToken: accessToken,
      );

      if (!mounted) return;
      setState(() {
        _posts = posts;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postsError = 'Failed to load active posts';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
      });
      if (_refreshQueued) {
        _refreshQueued = false;
        _loadPosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdTopHeader(),
            Space.vertical(20),
            RevenueCard(
              amount: "\$5,44,370",
              year: selectedYear,
              onYearChanged: (y) => setState(() => selectedYear = y),
            ),
            Space.vertical(20),
            Text(
              "User Growth",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kBlackColor,
              ),
            ),
            Space.vertical(10),
            HorizontalGraphList(),
            Space.vertical(20),
            Text(
              "Active posts",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kBlackColor,
              ),
            ),
            Space.vertical(10),
            if (_isLoadingPosts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_postsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _postsError!,
                      style: context.normal.copyWith(color: kRedColor),
                    ),
                    Space.vertical(8),
                    TextButton(
                      onPressed: _loadPosts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No active posts yet',
                  style: context.normal.copyWith(color: kDarkGreyColor),
                ),
              )
            else
              ..._posts.take(4).map((post) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdPostContainer(post: post),
                );
              }),
            Space.vertical(10),
          ],
        ),
      ),
    );
  }
}
