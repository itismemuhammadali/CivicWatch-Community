class ApplicationAlert {
  final int alertId;
  final String category;
  final String alertNote;
  final int? attachedMetaId;
  final String? isActive;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  const ApplicationAlert({
    required this.alertId,
    required this.category,
    required this.alertNote,
    this.attachedMetaId,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ApplicationAlert.fromJson(Map<String, dynamic> json) {
    final alertId = json['alert_id'];

    return ApplicationAlert(
      alertId: alertId is int ? alertId : int.parse('$alertId'),
      category: json['category'] as String? ?? '',
      alertNote: json['alert_note'] as String? ?? '',
      attachedMetaId: int.tryParse('${json['attached_meta_id']}'),
      isActive: json['is_active'] as String?,
      createdBy: int.tryParse('${json['created_by']}'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
