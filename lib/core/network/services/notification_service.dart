import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';

class NotificationService {
  NotificationService({client});

  Future<List<AppNotificationItem>> getAppNotificationsByUserId({
    required int userId,
    required String accessToken,
    int limit = 50,
    int offset = 0,
  }) async {
    return FirestoreDataService().getNotificationsByUserId(userId);
  }
}
