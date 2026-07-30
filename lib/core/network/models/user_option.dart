class UserOption {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;

  const UserOption({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  factory UserOption.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];

    return UserOption(
      userId: userId is int ? userId : int.parse('$userId'),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['user_email'] as String? ?? '',
    );
  }
}
