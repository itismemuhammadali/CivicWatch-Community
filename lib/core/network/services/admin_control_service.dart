import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/network/models/application_alert.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminControlService {
  final ApiClient _client;

  AdminControlService({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<String?> _getFirebaseUid(int userId) async {
    final query = await FirebaseFirestore.instance.collection('users').where('user_id', isEqualTo: userId).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    // Try lowercase 'userId' as well
    final query2 = await FirebaseFirestore.instance.collection('users').where('userId', isEqualTo: userId).get();
    if (query2.docs.isNotEmpty) {
      return query2.docs.first.id;
    }
    return null;
  }

  Future<Map<String, dynamic>> createApplicationAlert({
    required String accessToken,
    required int createdBy,
    required String category,
    required String alertNote,
    int attachedMetaId = 0,
    String? mediaUrl,
  }) async {
    await FirestoreDataService().createAnnouncement(
      category: category,
      alertNote: alertNote,
      attachedMetaId: attachedMetaId,
      createdBy: createdBy,
      mediaUrl: mediaUrl,
    );
    return {'success': true, 'message': 'Alert created successfully'};
  }

  Future<Map<String, dynamic>> sendWarningToUser({
    required String accessToken,
    required int userId,
    required String alertNote,
    required int attachedMetaId,
    String isActive = 'Y',
  }) async {
    await FirestoreDataService().sendWarningToUser(userId, alertNote, attachedMetaId);
    return {'success': true, 'message': 'Warning sent successfully'};
  }

  Future<Map<String, dynamic>> blockUser({
    required String accessToken,
    required int userId,
    required String reason,
  }) async {
    final uid = await _getFirebaseUid(userId);
    if (uid != null) {
      await FirestoreDataService().blockUser(uid, reason);
      return {'success': true, 'message': 'User blocked successfully'};
    }
    return {'success': false, 'message': 'User not found'};
  }

  Future<List<ApplicationAlert>> getAllApplicationAlerts({
    required String accessToken,
    bool onlyActive = true,
  }) async {
    final docs = await FirestoreDataService().getAnnouncements();
    return docs.map((doc) => ApplicationAlert(
      alertId: doc['announcement_id'] ?? 0,
      category: doc['category'] ?? '',
      alertNote: doc['alert_note'] ?? '',
      attachedMetaId: doc['attached_meta_id'] ?? 0,
      isActive: 'Y',
      createdBy: doc['created_by'] ?? 0,
      createdAt: doc['created_at'] ?? '',
    )).toList();
  }
}
