import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/deeplink/post_link_manager.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum PostShareTarget {
  system,
  whatsapp,
  twitter,
  facebook,
  copy,
}

class PostShareHelper {
  PostShareHelper._();

  static String buildPostLink(ActivePost post) {
    return PostLinkManager.buildPostLink(post.postId);
  }

  static String buildShareTitle(ActivePost post) {
    final caseTitle = post.caseDetail?.caseTitle.trim() ?? '';
    if (caseTitle.isNotEmpty) return caseTitle;

    final description = post.postDescription.trim();
    if (description.isEmpty) return 'Check out this post on Cctv';
    if (description.length <= 60) return description;
    return '${description.substring(0, 60).trim()}...';
  }

  static String buildShareText(ActivePost post) {
    final title = buildShareTitle(post);
    final link = buildPostLink(post);
    return '$title\n\n$link';
  }

  static Future<void> sharePost(
    BuildContext context, {
    required ActivePost post,
    required PostShareTarget target,
  }) async {
    try {
      switch (target) {
        case PostShareTarget.copy:
          await Clipboard.setData(ClipboardData(text: buildPostLink(post)));
          if (context.mounted) {
            AppAlert.showInfo(context, 'Post link copied to clipboard');
          }
          return;
        case PostShareTarget.system:
          await Share.share(
            buildShareText(post),
            subject: buildShareTitle(post),
          );
          return;
        case PostShareTarget.whatsapp:
          await _launchWhatsApp(post);
          return;
        case PostShareTarget.twitter:
          await _launchTwitter(post);
          return;
        case PostShareTarget.facebook:
          await _launchFacebook(post);
          return;
      }
    } catch (_) {
      if (context.mounted) {
        AppAlert.showError(context, 'Unable to share this post right now');
      }
    }
  }

  static Future<void> _launchWhatsApp(ActivePost post) async {
    final text = buildShareText(post);
    await _launchWithFallbacks([
      Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}'),
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
    ]);
  }

  static Future<void> _launchTwitter(ActivePost post) async {
    final text = buildShareText(post);
    await _launchWithFallbacks([
      Uri.parse('twitter://post?message=${Uri.encodeComponent(text)}'),
      Uri.parse('x://post?message=${Uri.encodeComponent(text)}'),
      Uri.parse(
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}',
      ),
      Uri.parse(
        'https://x.com/intent/post?text=${Uri.encodeComponent(text)}',
      ),
    ]);
  }

  static Future<void> _launchFacebook(ActivePost post) async {
    final link = buildPostLink(post);
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
    );
    await _launchExternal(uri);
  }

  static Future<void> _launchWithFallbacks(List<Uri> uris) async {
    for (final uri in uris) {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (didLaunch) {
        return;
      }
    }

    throw Exception('Unable to launch share target');
  }

  static Future<void> _launchExternal(Uri uri) async {
    final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!didLaunch) {
      throw Exception('Unable to launch share target');
    }
  }
}
