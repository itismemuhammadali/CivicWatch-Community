class CountryOption {
  final int countryId;
  final String countryShortCode;
  final String countryName;
  final String countryPhoneCode;

  const CountryOption({
    required this.countryId,
    required this.countryShortCode,
    required this.countryName,
    required this.countryPhoneCode,
  });

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      countryId: int.tryParse('${json['country_id']}') ?? 0,
      countryShortCode: json['country_short_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      countryPhoneCode: json['country_phone_code'] as String? ?? '',
    );
  }
}
