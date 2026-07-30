class UserContent {
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? userEmail;
  final int? roleId;
  final String? roleDescription;

  const UserContent({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.userEmail,
    required this.roleId,
    required this.roleDescription,
  });

  factory UserContent.fromJson(Map<String, dynamic> json) {
    final userIdDynamic = json['user_id'];
    return UserContent(
      userId: userIdDynamic is int ? userIdDynamic : int.parse('$userIdDynamic'),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      userEmail: json['user_email'] as String?,
      roleId: json['role_id'] == null ? null : int.tryParse('${json['role_id']}'),
      roleDescription: json['role_description'] as String?,
    );
  }
}
