import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_config.dart';

class UserDefendentService {
  final ApiClient _client;

  UserDefendentService({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  String _normalizeBearerToken(String accessToken) {
    final trimmedToken = accessToken.trim();
    if (trimmedToken.toLowerCase().startsWith('bearer ')) {
      return trimmedToken.substring(7).trim();
    }
    return trimmedToken;
  }

  Future<Map<String, dynamic>> createUserDefendent({
    required String accessToken,
    required int caseId,
    required int defendentId,
    required String caseResolution,
    required bool isAcceptTerms,
    int? metaId,
  }) {
    final normalizedToken = _normalizeBearerToken(accessToken);
    final queryParameters = <String, String>{
      'case_id': '$caseId',
      'defendent_id': '$defendentId',
      'case_resolution': caseResolution,
      'is_accept_terms': '$isAcceptTerms',
      if (metaId != null) 'meta_id': '$metaId',
    };

    final query = Uri(queryParameters: queryParameters).query;
    return _client.postJson(
      '/api/v1/user_case/createUserDefendent?$query',
      body: const {},
      headers: {
        'Authorization': 'Bearer $normalizedToken',
      },
    );
  }
}
