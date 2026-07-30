class UserRole {
  final int roleId;
  final String roleDescription;
  final bool isActive;

  const UserRole({
    required this.roleId,
    required this.roleDescription,
    required this.isActive,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    final roleId = json['role_id'];

    return UserRole(
      roleId: roleId is int ? roleId : int.parse('$roleId'),
      roleDescription: json['role_description'] as String? ?? '',
      isActive: json['is_active'] == true,
    );
  }
}
