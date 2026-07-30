import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<int> getLatestRegistrationCount({required String accessToken}) async {
    final stats = await FirestoreDataService().getDashboardStats();
    return stats['total_users'] ?? 0;
  }

  Future<int> getActiveUserCount({required String accessToken}) async {
    final stats = await FirestoreDataService().getDashboardStats();
    return stats['active_users'] ?? 0;
  }

  Future<List<DashboardUserAnalysisEntry>> getUserAnalysis({
    required String accessToken,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final users = await FirestoreDataService().getUserGrowth();
    
    // Group by date string (YYYY-MM-DD)
    final Map<String, int> countsByDate = {};
    
    for (var u in users) {
      final rawDate = u['createdAt'] ?? u['created_at'] ?? u['timestamp'] ?? u['createdDate'];
      DateTime? parsed;
      if (rawDate is String) {
        parsed = DateTime.tryParse(rawDate);
      } else if (rawDate is int) {
        parsed = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else if (rawDate != null) {
        try {
          parsed = (rawDate as dynamic).toDate();
        } catch (_) {}
      }

      if (parsed != null) {
        if (dateFrom != null && parsed.isBefore(dateFrom)) continue;
        if (dateTo != null && parsed.isAfter(dateTo.add(const Duration(days: 1)))) continue;
        
        final dateKey = _formatDate(parsed);
        countsByDate[dateKey] = (countsByDate[dateKey] ?? 0) + 1;
      }
    }
    
    final entries = countsByDate.entries.map((e) {
      return DashboardUserAnalysisEntry(
        date: DateTime.parse(e.key),
        count: e.value,
      );
    }).toList();
    
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}

class DashboardUserAnalysisEntry {
  final DateTime date;
  final int count;

  const DashboardUserAnalysisEntry({required this.date, required this.count});
}
