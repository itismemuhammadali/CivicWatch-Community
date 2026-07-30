import 'package:cctv_app/core/network/models/active_reel.dart';
import 'package:cctv_app/core/network/models/pending_case.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';

class UserCaseService {
  UserCaseService({client});

  Future<Map<String, dynamic>> createUserCase({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    await FirestoreDataService().createCase(body);
    return {'CONTENT': true};
  }

  Future<Map<String, dynamic>> createUserReel({
    required String accessToken,
    required int reelMetaId,
    required String reelDescription,
  }) async {
    final storage = AuthStorage();
    final userId = await storage.readUserId();
    if (userId == null) throw Exception('User not logged in');
    
    await FirestoreDataService().createReel(
      userId: userId,
      reelMetaId: reelMetaId,
      description: reelDescription,
    );
    return {'CONTENT': true};
  }

  Future<List<ActiveReel>> getAllActiveReels({
    required String accessToken,
  }) async {
    return FirestoreDataService().getAllActiveReels();
  }

  Future<ActiveReel?> getUserReel({
    required String accessToken,
    required int userId,
  }) async {
    return FirestoreDataService().getUserReel(userId);
  }

  Future<Map<String, dynamic>> deleteUserReel({
    required String accessToken,
    required int reelId,
  }) async {
    await FirestoreDataService().deleteUserReel(reelId);
    return {'CONTENT': true};
  }

  Future<List<PendingCase>> getPendingCases({
    required String accessToken,
    required int userId,
  }) async {
    return FirestoreDataService().getPendingCasesByUserId(userId);
  }

  Future<Map<String, dynamic>> deleteUserCase({
    required String accessToken,
    required int caseId,
  }) async {
    await FirestoreDataService().deleteCase(caseId);
    return {'CONTENT': true};
  }
}
