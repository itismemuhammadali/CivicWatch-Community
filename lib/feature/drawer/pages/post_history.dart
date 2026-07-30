import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/drawer/widget/custom_post_history_container.dart';
import 'package:flutter/material.dart';

class PostHistory extends StatefulWidget {
  const PostHistory({super.key});

  @override
  State<PostHistory> createState() => _PostHistoryState();
}

class _PostHistoryState extends State<PostHistory> {
  bool _isLoading = true;
  String? _error;
  List<ActivePost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _loadPostHistory();
  }

  Future<void> _loadPostHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken();
      final userId = await storage.readUserId();

      if (accessToken == null || accessToken.trim().isEmpty || userId == null) {
        throw const ApiException('Session not found');
      }

      final posts = await CasePostService().getPostsByUserId(
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
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load post history';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
        title: Text(
          "Post History",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kBlackColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          const SizedBox(height: 10),
          Expanded(child: _buildBody(context)),
        ]),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(color: kRedColor),
            ),
            Space.vertical(8),
            TextButton(onPressed: _loadPostHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Text(
          'No posts found',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (context, index) => Space.vertical(6),
      itemBuilder: (context, index) {
        return CustomPostHistoryContainer(post: _posts[index]);
      },
    );
  }
}
