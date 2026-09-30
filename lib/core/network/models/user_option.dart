class UserOption {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;

  const UserOption({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0].toUpperCase() : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : '';
    final combined = '$f$l';
    if (combined.isNotEmpty) return combined;
    if (email.trim().isNotEmpty) return email.trim()[0].toUpperCase();
    return '?';
  }

  factory UserOption.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] ?? json['userId'];
    final profileImg = json['profileImageUrl'] ??
        json['profile_image_url'] ??
        json['avatar_url'] ??
        json['avatarUrl'] ??
        json['photoUrl'];

    return UserOption(
      userId: userId is int ? userId : int.parse('$userId'),
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      email: json['user_email'] as String? ?? json['email'] as String? ?? '',
      profileImageUrl: profileImg is String && profileImg.isNotEmpty ? profileImg : null,
    );
  }
}
