import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class CommentContainer extends StatelessWidget {
  final String authorName;
  final String comment;
  final String timeText;
  final String? avatarUrl;
  final VoidCallback? onReplyTap;
  final String replyLabel;
  final bool isReplyActive;
  final int likeCount;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMenuTap;
  final bool isReply;

  const CommentContainer({
    super.key,
    this.authorName = '',
    this.comment = '',
    this.timeText = '',
    this.avatarUrl,
    this.onReplyTap,
    this.replyLabel = 'Reply',
    this.isReplyActive = false,
    this.likeCount = 0,
    this.onLikeTap,
    this.onMenuTap,
    this.isReply = false,
  });

  const CommentContainer.dynamic({
    super.key,
    required this.authorName,
    required this.comment,
    required this.timeText,
    this.avatarUrl,
    this.onReplyTap,
    this.replyLabel = 'Reply',
    this.isReplyActive = false,
    this.likeCount = 0,
    this.onLikeTap,
    this.onMenuTap,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAuthor = authorName;
    final resolvedComment = comment.isEmpty
        ? "That's a fantastic new app feature. You and your team did an excellent job of incorporating user testing feedback."
        : comment;
    final resolvedTime = timeText.isEmpty ? "14 min" : timeText;
    final normalizedAvatarUrl = avatarUrl?.trim();
    final hasAvatar =
        normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty;
    final avatarText = _buildAvatarText(resolvedAuthor);

    // Parse time to show number and "min" separately
    final timeParts = _parseTime(resolvedTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: kTextfieldBlueColor,
              backgroundImage: hasAvatar
                  ? (normalizedAvatarUrl.startsWith('assets/')
                      ? AssetImage(normalizedAvatarUrl)
                      : NetworkImage(normalizedAvatarUrl))
                  : null,
              child: hasAvatar
                  ? null
                  : Text(
                      avatarText,
                      style: context.bold.copyWith(
                        color: kPrimaryColor,
                        fontSize: 10,
                      ),
                    ),
            ),
            Space.horizontal(10),
            // Name and time
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: resolvedAuthor,
                      style: context.bold.copyWith(
                        fontSize: 13,
                        color: kBlackColor,
                      ),
                    ),
                    TextSpan(
                      text: '  ',
                      style: context.normal.copyWith(fontSize: 13),
                    ),
                    TextSpan(
                      text: timeParts['number'] ?? '14',
                      style: context.normal.copyWith(
                        fontSize: 11,
                        color: kDarkGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Three dot menu (horizontal)
            GestureDetector(
              onTap: onMenuTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kDarkGreyColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kDarkGreyColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kDarkGreyColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // "min" text below name
        Padding(
          padding: const EdgeInsets.only(left: 42, top: 0),
          child: Text(
            timeParts['suffix'] ?? 'min',
            style: context.normal.copyWith(
              fontSize: 11,
              color: kDarkGreyColor,
            ),
          ),
        ),
        Space.vertical(4),
        // Comment text
        Text(
          resolvedComment,
          style: context.normal.copyWith(
            height: 1.4,
            color: kBlackColor,
            fontSize: 13,
          ),
        ),
        Space.vertical(8),
        // Likes, Reply, and thumbs up
        Row(
          children: [
            Text(
              '$likeCount ${likeCount == 1 ? 'Like' : 'Likes'}',
              style: context.normal.copyWith(
                fontSize: 12,
                color: kDarkGreyColor,
              ),
            ),
            Space.horizontal(16),
            GestureDetector(
              onTap: onReplyTap,
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 14,
                    color: kDarkGreyColor,
                  ),
                  Space.horizontal(4),
                  Text(
                    replyLabel,
                    style: context.normal.copyWith(
                      fontSize: 12,
                      color: kDarkGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onLikeTap,
              child: Icon(
                Icons.thumb_up_outlined,
                size: 18,
                color: kDarkGreyColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, String> _parseTime(String time) {
    final parts = time.split(' ');
    if (parts.length >= 2) {
      return {
        'number': parts[0],
        'suffix': parts.sublist(1).join(' '),
      };
    }
    return {'number': '14', 'suffix': 'min'};
  }

  String _buildAvatarText(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return 'U';
  }
}
