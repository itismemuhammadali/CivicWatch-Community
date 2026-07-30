import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/network/models/application_ad.dart';
import 'package:cctv_app/core/network/models/ads_category.dart';

class AdsService {
  final ApiClient _client;

  AdsService({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  String _normalizeBearerToken(String accessToken) {
    final trimmedToken = accessToken.trim();
    if (trimmedToken.toLowerCase().startsWith('bearer ')) {
      return trimmedToken.substring(7).trim();
    }
    return trimmedToken;
  }

  Future<List<AdsCategory>> getAdsCategory({
    required String accessToken,
  }) async {
    final normalizedToken = _normalizeBearerToken(accessToken);
    final json = await _client.get(
      '/api/v1/application_ads/getAdsCategory',
      headers: {'Authorization': 'Bearer $normalizedToken'},
    );

    final content = json['CONTENT'];
    if (content is! List) {
      return const [];
    }

    return content
        .whereType<Map<String, dynamic>>()
        .map(AdsCategory.fromJson)
        .toList();
  }

  Future<List<ApplicationAd>> getAdsByStatus({
    required String accessToken,
    required String status,
    int page = 1,
    int limit = 20,
  }) async {
    final normalizedToken = _normalizeBearerToken(accessToken);
    final uri = Uri(
      path: '/api/v1/application_ads/getAdsByStatus',
      queryParameters: {
        'status': status,
        'page': '$page',
        'limit': '$limit',
      },
    );

    final json = await _client.get(
      uri.toString(),
      headers: {'Authorization': 'Bearer $normalizedToken'},
    );

    final content = json['CONTENT'];
    if (content is! Map<String, dynamic>) {
      return const [];
    }

    final items = content['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(ApplicationAd.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> resumeAd({
    required String accessToken,
    required int adId,
  }) {
    final normalizedToken = _normalizeBearerToken(accessToken);
    return _client.postJson(
      '/api/v1/application_ads/resumeAd/$adId',
      headers: {'Authorization': 'Bearer $normalizedToken'},
      body: const {},
    );
  }

  Future<Map<String, dynamic>> submitAd({
    required String accessToken,
    required int adId,
    String? startAt,
  }) {
    final normalizedToken = _normalizeBearerToken(accessToken);
    return _client.postJson(
      '/api/v1/application_ads/submitAd/$adId',
      headers: {'Authorization': 'Bearer $normalizedToken'},
      body: {
        if (startAt != null && startAt.trim().isNotEmpty) 'start_at': startAt,
      },
    );
  }

  Future<Map<String, dynamic>> createAd({
    required String accessToken,
    required int businessId,
    required int categoryId,
    required String title,
    required String note,
    required String destinationUrl,
    required int coverMetaId,
    String status = 'draft',
    int rotationOrder = 1,
    int displayIntervalSeconds = 30,
    bool isGlobal = true,
  }) {
    final normalizedToken = _normalizeBearerToken(accessToken);
    return _client.postJson(
      '/api/v1/application_ads/createAd',
      headers: {'Authorization': 'Bearer $normalizedToken'},
      body: {
        'business_id': businessId,
        'category_id': categoryId,
        'title': title,
        'note': note,
        'destination_url': destinationUrl,
        'cover_meta_id': coverMetaId,
        'status': status,
        'rotation_order': rotationOrder,
        'display_interval_seconds': displayIntervalSeconds,
        'is_global': isGlobal,
      },
    );
  }
}
