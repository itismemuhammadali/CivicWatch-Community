import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/feature/home/pages/shared_post_page.dart';
import 'package:flutter/material.dart';

class PostLinkManager {
  PostLinkManager._();

  static final PostLinkManager instance = PostLinkManager._();
  static const String _scheme = 'cctvapp';
  static const String _postHost = 'post';
  static const String _postPathSegment = 'post';

  AppLinks? _appLinks;
  int? _pendingPostId;
  bool _isInitialized = false;
  bool _isOpeningPost = false;

  static String buildPostLink(int postId) {
    return Uri(
      scheme: _scheme,
      host: _postHost,
      pathSegments: ['$postId'],
    ).toString();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _appLinks = AppLinks();

    final initialUri = await _appLinks!.getInitialLink();
    _handleUri(initialUri);

    _appLinks!.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
  }

  void _handleUri(Uri? uri) {
    final postId = _postIdFromUri(uri);
    if (postId == null) return;
    _pendingPostId = postId;
    unawaited(tryOpenPendingPost());
  }

  int? _postIdFromUri(Uri? uri) {
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();

    if (scheme == _scheme) {
      if (uri.host.toLowerCase() != _postHost) return null;
      if (uri.pathSegments.isEmpty) return null;
      return int.tryParse(uri.pathSegments.first);
    }

    if (scheme == 'http' || scheme == 'https') {
      final pathPostId = _postIdFromSegments(
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList(),
      );
      if (pathPostId != null) return pathPostId;

      final fragment = uri.fragment.startsWith('/')
          ? uri.fragment.substring(1)
          : uri.fragment;
      return _postIdFromSegments(
        fragment
            .split('/')
            .where((segment) => segment.trim().isNotEmpty)
            .toList(),
      );
    }

    return null;
  }

  int? _postIdFromSegments(List<String> segments) {
    if (segments.length < 2) return null;
    if (segments[segments.length - 2].toLowerCase() != _postPathSegment) {
      return null;
    }
    return int.tryParse(segments.last);
  }

  Future<void> tryOpenPendingPost() async {
    if (_isOpeningPost || _pendingPostId == null) return;

    final hasSession = await const AuthStorage().hasSession();
    if (!hasSession) return;

    final navigator = AppSessionManager.instance.navigatorKey.currentState;
    if (navigator == null) return;

    final postId = _pendingPostId!;
    _pendingPostId = null;
    _isOpeningPost = true;

    try {
      await navigator.push(
        MaterialPageRoute(builder: (_) => SharedPostPage(postId: postId)),
      );
    } finally {
      _isOpeningPost = false;
      if (_pendingPostId != null) {
        unawaited(tryOpenPendingPost());
      }
    }
  }
}
