import 'dart:convert';

import 'package:cctv_app/core/network/models/uploaded_media.dart';

class AppNotificationMeta {
  final int? caseId;
  final String? caseTitle;
  final String? caseDescription;
  final String? category;
  final int? attachedMetaId;
  final String? role;
  final String? oldStatus;
  final String? newStatus;
  final UploadedMedia? applicationMeta;
  final int? userId;
  final String? timestamp;

  const AppNotificationMeta({
    this.caseId,
    this.caseTitle,
    this.caseDescription,
    this.category,
    this.attachedMetaId,
    this.role,
    this.oldStatus,
    this.newStatus,
    this.applicationMeta,
    this.userId,
    this.timestamp,
  });

  String? get mediaUrl => applicationMeta?.metaUrl;

  bool get hasMedia => mediaUrl != null && mediaUrl!.trim().isNotEmpty;

  bool get isImage {
    final metaTypeId = applicationMeta?.metaTypeId;
    if (metaTypeId != null) {
      return metaTypeId == 1;
    }

    final url = mediaUrl?.toLowerCase() ?? '';
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  factory AppNotificationMeta.fromJson(Map<String, dynamic> json) {
    final caseId = json['case_id'];
    final attachedMetaId = json['attached_meta_id'];
    final userId = json['user_id'];
    final applicationMeta = json['application_meta'];

    return AppNotificationMeta(
      caseId: caseId == null ? null : int.tryParse('$caseId'),
      caseTitle: json['case_title'] as String?,
      caseDescription: json['case_description'] as String?,
      category: json['category'] as String?,
      attachedMetaId: attachedMetaId == null
          ? null
          : int.tryParse('$attachedMetaId'),
      role: json['role'] as String?,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      applicationMeta: applicationMeta is Map<String, dynamic>
          ? UploadedMedia.fromJson(applicationMeta)
          : null,
      userId: userId == null ? null : int.tryParse('$userId'),
      timestamp: json['timestamp'] as String?,
    );
  }

  static AppNotificationMeta? tryParse(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      return AppNotificationMeta.fromJson(raw);
    }

    if (raw is! String) return null;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return AppNotificationMeta.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to a normalized JSON-like parse.
    }

    try {
      final normalized = _normalizeJsonLikeString(trimmed);
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        return AppNotificationMeta.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static String _normalizeJsonLikeString(String value) {
    final buffer = StringBuffer();
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var index = 0; index < value.length; index++) {
      final char = value[index];
      final previousChar = index > 0 ? value[index - 1] : '';
      final isEscaped = previousChar == r'\';

      if (char == "'" && !inDoubleQuote && !isEscaped) {
        inSingleQuote = !inSingleQuote;
        buffer.write('"');
        continue;
      }

      if (char == '"' && !inSingleQuote && !isEscaped) {
        inDoubleQuote = !inDoubleQuote;
      }

      buffer.write(char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'\bNone\b'), 'null')
        .replaceAll(RegExp(r'\bTrue\b'), 'true')
        .replaceAll(RegExp(r'\bFalse\b'), 'false');
  }
}
