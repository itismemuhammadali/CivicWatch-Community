class ApplicationAd {
  final int id;
  final String title;
  final String note;
  final String status;
  final int? categoryId;
  final String categoryName;
  final String destinationUrl;
  final int? coverMetaId;
  final String coverImageUrl;
  final int? rotationOrder;
  final int? displayIntervalSeconds;
  final bool isGlobal;
  final String? startAt;
  final String? endAt;
  final String? createdAt;
  final int? runDays;

  const ApplicationAd({
    required this.id,
    required this.title,
    required this.note,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.destinationUrl,
    required this.coverMetaId,
    required this.coverImageUrl,
    required this.rotationOrder,
    required this.displayIntervalSeconds,
    required this.isGlobal,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.runDays,
  });

  factory ApplicationAd.fromJson(Map<String, dynamic> json) {
    return ApplicationAd(
      id: _toInt(json['id']),
      title: (json['title'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      categoryId: _tryInt(json['category_id']),
      categoryName: (json['category_name'] as String?)?.trim() ?? '',
      destinationUrl: (json['destination_url'] as String?)?.trim() ?? '',
      coverMetaId: _tryInt(json['cover_meta_id']),
      coverImageUrl: (json['cover_image_url'] as String?)?.trim() ?? '',
      rotationOrder: _tryInt(json['rotation_order']),
      displayIntervalSeconds: _tryInt(json['display_interval_seconds']),
      isGlobal: json['is_global'] == true,
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      createdAt: json['created_at'] as String?,
      runDays: _tryInt(json['run_days']),
    );
  }

  static int _toInt(dynamic value) => _tryInt(value) ?? 0;

  static int? _tryInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
