class UploadedMedia {
  final int metaId;
  final String? metaUrl;
  final int? metaTypeId;

  const UploadedMedia({
    required this.metaId,
    this.metaUrl,
    this.metaTypeId,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    final metaId = json['meta_id'];
    final metaTypeId = json['meta_type_id'];

    return UploadedMedia(
      metaId: metaId is int ? metaId : int.parse('$metaId'),
      metaUrl: json['meta_url'] as String?,
      metaTypeId: metaTypeId == null ? null : int.tryParse('$metaTypeId'),
    );
  }
}
