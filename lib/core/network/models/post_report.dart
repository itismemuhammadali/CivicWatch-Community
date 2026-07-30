class PostReport {
  final int reportId;
  final int postId;
  final int reportReasonTypeId;
  final String reportStatus;
  final String reportAdditionalInformation;
  final int createdBy;
  final String? createdAt;

  const PostReport({
    required this.reportId,
    required this.postId,
    required this.reportReasonTypeId,
    required this.reportStatus,
    required this.reportAdditionalInformation,
    required this.createdBy,
    this.createdAt,
  });

  factory PostReport.fromJson(Map<String, dynamic> json) {
    final reportId = json['report_id'];
    final postId = json['post_id'];
    final reportReasonTypeId = json['report_reason_type_id'];
    final createdBy = json['created_by'];

    return PostReport(
      reportId: reportId is int ? reportId : int.parse('$reportId'),
      postId: postId is int ? postId : int.parse('$postId'),
      reportReasonTypeId: reportReasonTypeId is int
          ? reportReasonTypeId
          : int.parse('$reportReasonTypeId'),
      reportStatus: json['report_status'] as String? ?? '',
      reportAdditionalInformation:
          json['report_additional_information'] as String? ?? '',
      createdBy: createdBy is int ? createdBy : int.parse('$createdBy'),
      createdAt: json['created_at'] as String?,
    );
  }
}
