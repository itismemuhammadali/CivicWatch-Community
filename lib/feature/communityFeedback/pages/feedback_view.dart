import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/network/models/post_report.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adminHome/pages/admin_post_detail_page.dart';
import 'package:flutter/material.dart';

class FeedbackView extends StatelessWidget {
  final PostReport report;
  final ActivePost? post;
  final String? categoryLabel;
  final String? imageUrl;

  const FeedbackView({
    super.key,
    required this.report,
    required this.post,
    this.categoryLabel,
    this.imageUrl,
  });

  String get _title {
    final caseTitle = post?.caseDetail?.caseTitle.trim() ?? '';
    if (caseTitle.isNotEmpty) {
      return caseTitle;
    }

    final postDescription = post?.postDescription.trim() ?? '';
    if (postDescription.isNotEmpty) {
      return postDescription;
    }

    final reportText = report.reportAdditionalInformation.trim();
    if (reportText.isNotEmpty) {
      return reportText;
    }

    return 'Report #${report.reportId}';
  }

  String get _noteTitle {
    final label = categoryLabel?.trim() ?? '';
    return label.isEmpty ? 'Important note' : label;
  }

  String get _noteBody {
    final reportText = report.reportAdditionalInformation.trim();
    if (reportText.isNotEmpty) {
      return reportText;
    }

    final postDescription = post?.postDescription.trim() ?? '';
    if (postDescription.isNotEmpty) {
      return postDescription;
    }

    final caseDescription = post?.caseDetail?.caseDescription.trim() ?? '';
    if (caseDescription.isNotEmpty) {
      return caseDescription;
    }

    return 'No additional information available.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(backgroundColor: kWhiteColor),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(
                  text: 'View Post',
                  height: 40,
                  isMainAxisSizeMin: true,
                  inactive: post == null,
                  onPressed: () {
                    if (post == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPostDetailPage(
                          post: post!,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Space.vertical(20),
              Text(
                _title,
                style: context.semiBold.copyWith(fontSize: 18),
              ),
              Space.vertical(20),
              _FeedbackMedia(
                imageUrl: imageUrl,
                media: post?.caseDetail?.meta,
              ),
              Space.vertical(12),
              Text(
                _noteTitle,
                style: context.semiBold.copyWith(fontSize: 18),
              ),
              Space.vertical(10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kGreyColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(14),
                child: Text(
                  _noteBody,
                  style: context.normal.copyWith(
                    fontSize: 15,
                    color: kBlackColor,
                    height: 1.45,
                  ),
                ),
              ),
              Space.vertical(24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackMedia extends StatelessWidget {
  final String? imageUrl;
  final ActivePostMeta? media;

  const _FeedbackMedia({
    this.imageUrl,
    required this.media,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = (imageUrl?.trim().isNotEmpty == true
            ? imageUrl
            : media?.metaUrl)
        ?.trim() ??
        '';
    final hasMedia = mediaUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: !hasMedia
            ? Container(
                color: kGreyColor.withValues(alpha: 0.3),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: kDarkGreyColor,
                  size: 48,
                ),
              )
            : (media?.isImage ?? true)
            ? Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: kGreyColor.withValues(alpha: 0.3),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: kDarkGreyColor,
                    size: 48,
                  ),
                ),
              )
            : Container(
                color: kBlackColor,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: kWhiteColor,
                  size: 56,
                ),
              ),
      ),
    );
  }
}
