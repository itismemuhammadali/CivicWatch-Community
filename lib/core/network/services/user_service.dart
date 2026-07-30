import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/models/user_role.dart';
import 'package:cctv_app/core/network/models/user_option.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/firebase/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  const UserService();

  Future<String?> _getFirebaseUid(int userId) async {
    final query = await FirebaseFirestore.instance.collection('users').where('user_id', isEqualTo: userId).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    final query2 = await FirebaseFirestore.instance.collection('users').where('userId', isEqualTo: userId).get();
    if (query2.docs.isNotEmpty) {
      return query2.docs.first.id;
    }
    return null;
  }

  Future<Map<String, dynamic>> createUser({
    required String accessToken,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int roleId,
    required int createdBy,
    int countryId = 0,
    int stateId = 0,
    int cityId = 0,
    String? dob,
    int genderId = 0,
    int profileTypeId = 0,
    int metaId = 0,
  }) async {
    final roleStr = roleId == 2 || roleId == 3 ? 'admin' : 'user';
    final result = await FirebaseAuthService().signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: roleStr,
    );
    
    if (result['success'] == true) {
      return {'CONTENT': true};
    } else {
      throw Exception(result['error']);
    }
  }

  Future<List<UserOption>> getAllUsers({
    required String accessToken,
  }) async {
    return FirestoreDataService().getAllUsers();
  }

  Future<UserProfile> getUserById({
    required String accessToken,
    required int userId,
  }) async {
    final uid = await _getFirebaseUid(userId);
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final role = data['role'] ?? 'user';
        final roleId = (role == 'admin' || role == 'super admin') ? 2 : 1;
        
        final profileImageUrl = data['profileImageUrl'] ?? data['profile_image_url'];
        UploadedMedia? meta;
        if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
          meta = UploadedMedia(
            metaId: 0,
            metaTypeId: 1,
            metaUrl: profileImageUrl.toString(),
          );
        }

        return UserProfile(
          userId: userId,
          firstName: data['first_name'] ?? data['firstName'] ?? '',
          lastName: data['last_name'] ?? data['lastName'] ?? '',
          email: data['user_email'] ?? data['email'] ?? '',
          roleId: roleId,
          roleDescription: role,
          applicationMeta: meta,
        );
      }
    }
    return UserProfile(userId: userId, firstName: '', lastName: '', email: '');
  }

  Future<List<UserProfile>> getAllRecentAdminsWithProfiles({
    required String accessToken,
    int skip = 0,
    int limit = 3,
  }) async {
    return getAllAdminsWithProfiles(accessToken: accessToken, skip: skip, limit: limit);
  }

  Future<List<UserProfile>> getAllRecentAdmins({
    required String accessToken,
    int skip = 0,
    int limit = 3,
  }) async {
    return getAllAdminsWithProfiles(accessToken: accessToken, skip: skip, limit: limit);
  }

  Future<List<UserProfile>> getAllAdminsWithProfiles({
    required String accessToken,
    int skip = 0,
    int limit = 100,
  }) async {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'super admin', 'Admin', 'Super Admin'])
          .get();
      docs = query.docs;
    } catch (_) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        docs = query.docs;
      } catch (_) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .get();
        docs = query.docs.where((doc) {
          final r = (doc.data()['role'] ?? '').toString().toLowerCase();
          return r == 'admin' || r == 'super admin';
        }).toList();
      }
    }
        
    final list = docs.map((doc) {
      final data = doc.data();
      final userIdVal = data['user_id'] ?? data['userId'];
      final userId = userIdVal is int ? userIdVal : int.tryParse('$userIdVal') ?? doc.id.hashCode;

      String? createdAtStr;
      final createdAtVal = data['createdAt'] ?? data['created_at'];
      if (createdAtVal is Timestamp) {
        createdAtStr = createdAtVal.toDate().toIso8601String();
      } else if (createdAtVal != null) {
        createdAtStr = createdAtVal.toString();
      }

      final profileImageUrl = data['profileImageUrl'] ?? data['profile_image_url'];

      return UserProfile(
        userId: userId,
        firstName: data['first_name'] ?? data['firstName'] ?? '',
        lastName: data['last_name'] ?? data['lastName'] ?? '',
        email: data['user_email'] ?? data['email'] ?? '',
        roleId: 2,
        roleDescription: data['role']?.toString() ?? 'admin',
        isActive: data['is_active'] != 'N' ? 'Y' : 'N',
        createdAt: createdAtStr,
        applicationMeta: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
            ? UploadedMedia(
                metaId: 0,
                metaUrl: profileImageUrl.toString(),
              )
            : null,
      );
    }).toList();

    list.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return list.take(limit).toList();
  }

  Future<List<UserProfile>> getAllUsersWithProfiles({
    required String accessToken,
    int skip = 0,
    int limit = 100,
  }) async {
    final query = await FirebaseFirestore.instance.collection('users')
        .where('role', isEqualTo: 'user')
        .limit(limit)
        .get();
        
    return query.docs.map((doc) {
      final data = doc.data();
      final userIdVal = data['user_id'] ?? data['userId'];
      final userId = userIdVal is int ? userIdVal : int.tryParse('$userIdVal') ?? doc.id.hashCode;
      return UserProfile(
        userId: userId,
        firstName: data['first_name'] ?? data['firstName'] ?? '',
        lastName: data['last_name'] ?? data['lastName'] ?? '',
        email: data['user_email'] ?? data['email'] ?? '',
        roleId: 1,
        roleDescription: 'user',
        isActive: data['is_active'] != 'N' ? 'Y' : 'N',
      );
    }).toList();
  }

  Future<List<UserRole>> getRoles({
    required String accessToken,
    bool onlyActive = true,
  }) async {
    return [
      UserRole(roleId: 1, roleDescription: 'User', isActive: true),
      UserRole(roleId: 2, roleDescription: 'Admin', isActive: true),
      UserRole(roleId: 3, roleDescription: 'Super Admin', isActive: true),
    ];
  }

  Future<void> updateUser({
    required String accessToken,
    required int userId,
    required Map<String, dynamic> body,
  }) async {
    final uid = await _getFirebaseUid(userId);
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(body);
    }
  }

  Future<void> deleteUser({
    required String accessToken,
    required int userId,
  }) async {
    final uid = await _getFirebaseUid(userId);
    if (uid != null) {
      await FirestoreDataService().blockUser(uid, 'Deleted by admin');
    }
  }
}
