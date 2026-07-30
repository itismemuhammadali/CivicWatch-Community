import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class CommunityFeedbackWidget extends StatelessWidget {
  final String title;
  final String? categoryLabel;
  final String createdAt;
  final String? imageUrl;
  final VoidCallback? onView;

  const CommunityFeedbackWidget({
    super.key,
    required this.title,
    required this.createdAt,
    this.categoryLabel,
    this.imageUrl,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGreyColor),
      ),
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 104,
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: kBlackColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _FeedbackImage(imageUrl: imageUrl),
          ),
          Space.horizontal(8),
          Expanded(
            child: SizedBox(
              height: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.semiBold.copyWith(
                        fontSize: 17,
                        height: 1.18,
                        color: kBlackColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            createdAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.normal.copyWith(
                              fontSize: 10,
                              color: kDarkGreyColor,
                            ),
                          ),
                        ),
                      ),
                      Space.horizontal(10),
                      SizedBox(
                        width: 54,
                        height: 44,
                        child: Material(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(5),
                          child: InkWell(
                            onTap: onView,
                            borderRadius: BorderRadius.circular(5),
                            child: Center(
                              child: Text(
                                "View",
                                style: context.semiBold.copyWith(
                                  fontSize: 12,
                                  color: kWhiteColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackImage extends StatelessWidget {
  final String? imageUrl;

  const _FeedbackImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isEmpty) {
      return Container(
        color: kGreyColor.withValues(alpha: 0.3),
        child: const Icon(Icons.image_outlined, color: kDarkGreyColor),
      );
    }

    if (trimmedUrl.startsWith('assets/')) {
      return Image.asset(trimmedUrl, fit: BoxFit.cover);
    }

    return Image.network(
      trimmedUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: kGreyColor.withValues(alpha: 0.3),
        child: const Icon(Icons.image_not_supported_outlined, color: kDarkGreyColor),
      ),
    );
  }
}
