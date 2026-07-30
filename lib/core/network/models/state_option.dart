class StateOption {
  final int stateId;
  final String stateName;
  final int countryId;

  const StateOption({
    required this.stateId,
    required this.stateName,
    required this.countryId,
  });

  factory StateOption.fromJson(Map<String, dynamic> json) {
    return StateOption(
      stateId: int.tryParse('${json['state_id']}') ?? 0,
      stateName: json['state_name'] as String? ?? '',
      countryId: int.tryParse('${json['country_id']}') ?? 0,
    );
  }
}
