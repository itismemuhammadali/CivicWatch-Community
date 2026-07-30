class GeneralParameterOption {
  final int paramDetailId;
  final String? paramHeader;
  final String paramLabel;
  final String paramValue;

  const GeneralParameterOption({
    required this.paramDetailId,
    this.paramHeader,
    required this.paramLabel,
    required this.paramValue,
  });

  factory GeneralParameterOption.fromJson(Map<String, dynamic> json) {
    final paramDetailId = json['param_detail_id'];

    return GeneralParameterOption(
      paramDetailId: paramDetailId is int
          ? paramDetailId
          : int.parse('$paramDetailId'),
      paramHeader: json['param_header'] as String?,
      paramLabel: json['param_label'] as String? ?? '',
      paramValue: json['param_value'] as String? ?? '',
    );
  }
}
