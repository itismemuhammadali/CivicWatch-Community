import 'package:cctv_app/core/network/api_client.dart';
import 'package:cctv_app/core/network/api_response.dart';
import 'package:cctv_app/core/network/endpoints.dart';
import 'package:cctv_app/core/network/models/user_content.dart';

class AuthService {
  final ApiClient _client;
  final int signUpRoleId;

  AuthService(this._client, {this.signUpRoleId = 1});

  Future<ApiResponse<UserContent>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    int? metaId,
  }) async {
    final json = await _client.postJson(
      Endpoints.signUp,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'user_email': email,
        'user_password': password,
        'role_id': signUpRoleId,
        if (metaId != null) 'meta_id': metaId,
      },
      treatUnauthorizedAsSessionExpired: false,
    );

    return ApiResponse<UserContent>.fromJson(
      json,
      contentParser: (contentJson) =>
          UserContent.fromJson(contentJson as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<UserContent>> login({
    required String username,
    required String password,
  }) async {
    final json = await _client.postForm(
      Endpoints.login,
      body: {
        'username': username,
        'password': password,
      },
      treatUnauthorizedAsSessionExpired: false,
    );

    return ApiResponse<UserContent>.fromJson(
      json,
      contentParser: (contentJson) =>
          UserContent.fromJson(contentJson as Map<String, dynamic>),
    );
  }
}
