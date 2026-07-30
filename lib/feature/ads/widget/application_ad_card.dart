import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/network/models/application_ad.dart';
import 'package:cctv_app/core/utils/app_date_time.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class AdsListCard extends StatelessWidget {
  final ApplicationAd ad;
  final AdCardAction? primaryAction;
  final AdCardAction? secondaryAction;
  final AdCardAction? tertiaryAction;

  const AdsListCard({
    super.key,
    required this.ad,
    this.primaryAction,
    this.secondaryAction,
    this.tertiaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = ad.title.isEmpty ? 'Untitled ad' : ad.title;
    final linkedPage = ad.destinationUrl.isEmpty ? '-' : ad.destinationUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(),
          Space.horizontal(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Space.vertical(2),
                Text(
                  'Linked Page ${_buildLinkedPageLabel(linkedPage)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: kDarkGreyColor,
                  ),
                ),
                Space.vertical(8),
                _InfoRow(
                  label: 'Create Date',
                  value: AppDateTime.formatShortDateTime(
                    ad.createdAt,
                    fallback: '-',
                  ),
                ),
                Space.vertical(4),
                _InfoRow(
                  label: 'End Date',
                  value: AppDateTime.formatShortDateTime(
                    ad.endAt,
                    fallback: '-',
                  ),
                ),
                if (ad.note.isNotEmpty) ...[
                  Space.vertical(4),
                  Text(
                    ad.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: kDarkGreyColor),
                  ),
                ],
                Space.vertical(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (primaryAction != null) _buildActionButton(primaryAction!),
                    if (secondaryAction != null) _buildActionButton(secondaryAction!),
                    if (tertiaryAction != null) _buildActionButton(tertiaryAction!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (ad.coverImageUrl.isEmpty) {
      return Container(
        width: 104,
        height: 112,
        decoration: BoxDecoration(
          color: kGreyColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: kDarkGreyColor),
      );
    }

    if (ad.coverImageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          ad.coverImageUrl,
          width: 104,
          height: 112,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 104,
              height: 112,
              color: kGreyColor.withValues(alpha: 0.2),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, color: kDarkGreyColor),
            );
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        ad.coverImageUrl,
        width: 104,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 104,
            height: 112,
            color: kGreyColor.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: kDarkGreyColor),
          );
        },
      ),
    );
  }

  String _buildLinkedPageLabel(String linkedPage) {
    if (linkedPage == '-') return ': -';
    return ': $linkedPage';
  }

  Widget _buildActionButton(AdCardAction action) {
    return PrimaryButton(
      text: action.label,
      height: 28,
      isMainAxisSizeMin: true,
      textFontSize: 11,
      padding: action.padding,
      processing: action.processing,
      showBorder: action.showBorder,
      buttonColor: action.buttonColor,
      borderColor: action.borderColor,
      textColor: action.textColor,
      onPressed: action.onPressed,
    );
  }
}

class AdCardAction {
  final String label;
  final VoidCallback onPressed;
  final Color buttonColor;
  final Color textColor;
  final bool showBorder;
  final Color borderColor;
  final bool processing;
  final EdgeInsets padding;

  const AdCardAction({
    required this.label,
    required this.onPressed,
    required this.buttonColor,
    required this.textColor,
    this.showBorder = false,
    this.borderColor = kTransparentColor,
    this.processing = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: kDarkGreyColor),
          ),
        ),
      ],
    );
  }
}
