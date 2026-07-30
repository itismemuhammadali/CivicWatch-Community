import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final AppNotificationItem notification;

  const NotificationDetailPage({super.key, required this.notification});

  String _formatTimestamp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$month ${parsed.day}, ${parsed.year} - $hour:$minute $suffix';
  }

  String _categoryLabel(String category) {
    return switch (category.toUpperCase()) {
      'W' => 'Warning',
      _ => category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final meta = notification.parsedMeta;
    final createdAt = _formatTimestamp(
      notification.createdAt ?? meta?.timestamp,
    );
    final mediaUrl = meta?.mediaUrl?.trim() ?? '';
    final rawMeta = notification.notificationMeta?.trim() ?? '';
    final metaRows = <_MetaRow>[
      if (meta?.caseTitle?.trim().isNotEmpty == true)
        _MetaRow('Case Title', meta!.caseTitle!.trim()),
      if (meta?.caseDescription?.trim().isNotEmpty == true)
        _MetaRow('Case Description', meta!.caseDescription!.trim()),
      if (meta?.category?.trim().isNotEmpty == true)
        _MetaRow('Category', _categoryLabel(meta!.category!.trim())),
      if (meta?.role?.trim().isNotEmpty == true)
        _MetaRow('Role', meta!.role!.trim()),
      if (meta?.oldStatus?.trim().isNotEmpty == true)
        _MetaRow('Old Status', meta!.oldStatus!.trim()),
      if (meta?.newStatus?.trim().isNotEmpty == true)
        _MetaRow('New Status', meta!.newStatus!.trim()),
    ];

    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        title: Text(
          'Notification',
          style: context.bold.copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta?.caseTitle?.trim().isNotEmpty == true
                  ? meta!.caseTitle!.trim()
                  : notification.title,
              style: context.bold.copyWith(fontSize: 20),
            ),
            Space.vertical(10),
            Text(
              notification.message,
              style: context.normal.copyWith(
                fontSize: 15,
                color: kDarkGreyColor,
              ),
            ),
            if (createdAt.isNotEmpty) ...[
              Space.vertical(8),
              Text(
                createdAt,
                style: context.normal.copyWith(
                  fontSize: 12,
                  color: kDarkGreyColor,
                ),
              ),
            ],
            if (mediaUrl.isNotEmpty) ...[
              Space.vertical(20),
              Text(
                'Attached File',
                style: context.bold.copyWith(fontSize: 16),
              ),
              Space.vertical(10),
              _NotificationMetaMedia(
                mediaUrl: mediaUrl,
                isImage: meta?.isImage ?? false,
              ),
            ],
            if (metaRows.isNotEmpty) ...[
              Space.vertical(20),
              Text(
                'Details',
                style: context.bold.copyWith(fontSize: 16),
              ),
              Space.vertical(8),
              ...metaRows.map((row) => _MetaRowTile(row: row)),
            ],
            if (metaRows.isEmpty && mediaUrl.isEmpty && rawMeta.isNotEmpty) ...[
              Space.vertical(20),
              Text(
                'Meta',
                style: context.bold.copyWith(fontSize: 16),
              ),
              Space.vertical(8),
              Text(
                rawMeta,
                style: context.normal.copyWith(color: kDarkGreyColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationMetaMedia extends StatelessWidget {
  final String mediaUrl;
  final bool isImage;

  const _NotificationMetaMedia({
    required this.mediaUrl,
    required this.isImage,
  });

  @override
  Widget build(BuildContext context) {
    if (!isImage) {
      return Text(
        mediaUrl,
        style: context.normal.copyWith(color: kPrimaryColor),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 220,
        color: kBlackColor.withValues(alpha: 0.06),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _MetaRow {
  final String label;
  final String value;

  const _MetaRow(this.label, this.value);
}

class _MetaRowTile extends StatelessWidget {
  final _MetaRow row;

  const _MetaRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: context.bold.copyWith(fontSize: 13),
          ),
          Space.vertical(3),
          Text(
            row.value,
            style: context.normal.copyWith(color: kDarkGreyColor),
          ),
        ],
      ),
    );
  }
}
