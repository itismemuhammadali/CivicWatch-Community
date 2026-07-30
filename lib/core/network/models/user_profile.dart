import 'package:cctv_app/core/network/models/uploaded_media.dart';

class UserProfile {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? userPassword;
  final int? countryId;
  final int? stateId;
  final int? cityId;
  final String? dob;
  final int? genderId;
  final int? profileTypeId;
  final int? metaId;
  final int? roleId;
  final String? roleDescription;
  final String? isActive;
  final String? createdAt;
  final UploadedMedia? applicationMeta;

  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.userPassword,
    this.countryId,
    this.stateId,
    this.cityId,
    this.dob,
    this.genderId,
    this.profileTypeId,
    this.metaId,
    this.roleId,
    this.roleDescription,
    this.isActive,
    this.createdAt,
    this.applicationMeta,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];

    return UserProfile(
      userId: userId is int ? userId : int.parse('$userId'),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['user_email'] as String? ?? '',
      userPassword: json['user_password'] as String?,
      countryId: int.tryParse('${json['country_id']}'),
      stateId: int.tryParse('${json['state_id']}'),
      cityId: int.tryParse('${json['city_id']}'),
      dob: json['dob'] as String?,
      genderId: int.tryParse('${json['gender_id']}'),
      profileTypeId: int.tryParse('${json['profile_type_id']}'),
      metaId: int.tryParse('${json['meta_id']}'),
      roleId: int.tryParse('${json['role_id']}'),
      roleDescription: json['role_description'] as String?,
      isActive: json['is_active'] as String?,
      createdAt: json['created_at'] as String?,
      applicationMeta: json['application_meta'] is Map<String, dynamic>
          ? UploadedMedia.fromJson(json['application_meta'] as Map<String, dynamic>)
          : null,
    );
  }
}
