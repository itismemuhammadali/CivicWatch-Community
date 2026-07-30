import 'dart:convert';

import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/network/mock_data.dart';
import 'package:cctv_app/core/network/network_response_handler.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Validate mock credentials
  /// Returns null if valid, error message if invalid
  static String? _validateMockCredentials(String email, String password) {
    // Password requirements for mock mode
    const userPassword = 'user@123';
    const adminPassword = 'admin@123';
    const superAdminPassword = 'superadmin@123';

    email = email.toLowerCase().trim();
    password = password.trim();

    // Validate email format
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!email.contains('@')) {
      return 'Invalid email format';
    }

    // Validate password
    if (password.isEmpty) {
      return 'Password is required';
    }

    // Check credentials match
    if (email.contains('superadmin')) {
      if (password != superAdminPassword) {
        return 'Invalid credentials for SuperAdmin account';
      }
    } else if (email.contains('admin')) {
      if (password != adminPassword) {
        return 'Invalid credentials for Admin account';
      }
    } else {
      // Regular user
      if (password != userPassword) {
        return 'Invalid credentials for User account';
      }
    }

    // All validations passed
    return null;
  }

  // Mock response data for testing without backend
  static Map<String, dynamic> _getMockResponse(String path, {Map<String, dynamic>? requestBody}) {
    // Authentication endpoints
    if (path.contains('/login') || path.contains('userLogin')) {
      // Check email and password for mock login
      final email = requestBody?['username']?.toString().toLowerCase() ?? '';
      final password = requestBody?['password']?.toString() ?? '';
      
      // Validate credentials
      String? errorMessage = _validateMockCredentials(email, password);
      if (errorMessage != null) {
        return {
          'SUCCESS': false,
          'STATUS_CODE': 401,
          'MESSAGE': errorMessage,
          'access_token': null,
          'CONTENT': null,
        };
      }
      
      // Mock credentials for different roles
      if (email.contains('superadmin')) {
        return {
          'SUCCESS': true,
          'STATUS_CODE': 200,
          'MESSAGE': 'Login successful',
          'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'token_type': 'Bearer',
          'CONTENT': MockDataGenerator.generateMockSuperAdminUser(),
        };
      } else if (email.contains('admin')) {
        return {
          'SUCCESS': true,
          'STATUS_CODE': 200,
          'MESSAGE': 'Login successful',
          'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'token_type': 'Bearer',
          'CONTENT': MockDataGenerator.generateMockAdminUser(),
        };
      } else {
        // Default to regular user
        return {
          'SUCCESS': true,
          'STATUS_CODE': 200,
          'MESSAGE': 'Login successful',
          'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'token_type': 'Bearer',
          'CONTENT': MockDataGenerator.generateMockUser(
            email: email.isEmpty ? 'user@cctv.app' : email,
          ),
        };
      }
    }

    // SignUp endpoint
    if (path.contains('/createUser') || path.contains('/signUp')) {
      final firstName = requestBody?['first_name'] ?? 'Test';
      final lastName = requestBody?['last_name'] ?? 'User';
      final email = requestBody?['user_email'] ?? 'test@cctv.app';
      
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'User created successfully',
        'access_token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        'token_type': 'Bearer',
        'CONTENT': MockDataGenerator.generateMockUser(
          firstName: firstName,
          lastName: lastName,
          email: email,
          roleId: 1,
          roleDescription: 'user',
        ),
      };
    }

    // User endpoints
    if (path.contains('/getAllUsers')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Users retrieved',
        'CONTENT': [
          MockDataGenerator.generateMockUser(),
          MockDataGenerator.generateMockAdminUser(),
        ],
      };
    }

    if (path.contains('/getUserById')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'User retrieved',
        'CONTENT': MockDataGenerator.generateMockUser(),
      };
    }

    if (path.contains('/getRoles')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Roles retrieved',
        'CONTENT': MockDataGenerator.generateMockRoles(),
      };
    }

    // Case endpoints
    if (path.contains('/getPendingCases') || path.contains('/getPendingCasesByUserId')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Pending cases retrieved',
        'CONTENT': MockDataGenerator.generateMockCases(count: 5),
      };
    }

    if (path.contains('/getApprovedCases')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Approved cases retrieved',
        'CONTENT': MockDataGenerator.generateMockCases(count: 3),
      };
    }

    if (path.contains('/createUserCase')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Case created successfully',
        'CONTENT': MockDataGenerator.generateMockCase(),
      };
    }

    if (path.contains('/delete_user_case') || path.contains('/deleteUserCase')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Case deleted successfully',
        'CONTENT': {'deleted': true},
      };
    }

    // Post endpoints
    if (path.contains('/get_all_active_posts') || path.contains('/getAllActivePosts')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Active posts retrieved',
        'CONTENT': MockDataGenerator.generateMockPosts(count: 8),
      };
    }

    if (path.contains('/getAllRecentPosts')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Recent posts retrieved',
        'CONTENT': MockDataGenerator.generateMockPosts(count: 10),
      };
    }

    if (path.contains('/getPostsByUserId')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'User posts retrieved',
        'CONTENT': MockDataGenerator.generateMockPosts(count: 5),
      };
    }

    if (path.contains('/getSavedPostByUserId')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Saved posts retrieved',
        'CONTENT': MockDataGenerator.generateMockPosts(count: 3),
      };
    }

    if (path.contains('/createSavedPost')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Post saved successfully',
        'CONTENT': {'saved': true},
      };
    }

    if (path.contains('/deleteSavedPost')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Saved post deleted',
        'CONTENT': {'deleted': true},
      };
    }

    // Reel endpoints
    if (path.contains('/get_all_active_reels') || path.contains('/getAllActiveReels')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Active reels retrieved',
        'CONTENT': MockDataGenerator.generateMockReels(count: 5),
      };
    }

    if (path.contains('/get_user_reel') || path.contains('/getUserReel')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'User reel retrieved',
        'CONTENT': MockDataGenerator.generateMockReel(),
      };
    }

    if (path.contains('/create_user_reel')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Reel created successfully',
        'CONTENT': MockDataGenerator.generateMockReel(),
      };
    }

    if (path.contains('/delete_user_reel') || path.contains('/deleteUserReel')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Reel deleted successfully',
        'CONTENT': {'deleted': true},
      };
    }

    // Alert endpoints
    if (path.contains('/getAllApplicationAlerts')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Application alerts retrieved',
        'CONTENT': MockDataGenerator.generateMockAlerts(count: 5),
      };
    }

    if (path.contains('/createApplicationAlert')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Application alert created successfully',
        'CONTENT': MockDataGenerator.generateMockAlert(),
      };
    }

    // Advertisement endpoints
    if (path.contains('/getAds') || path.contains('/getAllAds')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Advertisements retrieved',
        'CONTENT': MockDataGenerator.generateMockAds(count: 5),
      };
    }

    if (path.contains('/getAdsByCategory')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Ads by category retrieved',
        'CONTENT': MockDataGenerator.generateMockAds(count: 3),
      };
    }

    if (path.contains('/createAd')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Advertisement created successfully',
        'CONTENT': MockDataGenerator.generateMockAd(),
      };
    }

    // Notification endpoints
    if (path.contains('/getNotifications') || path.contains('/getAllNotifications')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Notifications retrieved',
        'CONTENT': MockDataGenerator.generateMockNotifications(count: 5),
      };
    }

    if (path.contains('/markNotificationAsRead')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Notification marked as read',
        'CONTENT': {'marked': true},
      };
    }

    // Dashboard endpoints
    if (path.contains('/getDashboardStats') || path.contains('/getStats')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Dashboard stats retrieved',
        'CONTENT': MockDataGenerator.generateMockDashboardStats(),
      };
    }

    // Common parameter endpoints
    if (path.contains('/getCountries')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Countries retrieved',
        'CONTENT': MockDataGenerator.generateMockCountries(),
      };
    }

    if (path.contains('/getStates')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'States retrieved',
        'CONTENT': MockDataGenerator.generateMockStates(),
      };
    }

    if (path.contains('/getGenders')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Genders retrieved',
        'CONTENT': MockDataGenerator.generateMockGenders(),
      };
    }

    // Post reactions
    if (path.contains('/createPostReaction') || path.contains('/submit_case_poll_vote')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'Reaction created successfully',
        'CONTENT': {'created': true},
      };
    }

    if (path.contains('/removePostReaction')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 200,
        'MESSAGE': 'Reaction removed successfully',
        'CONTENT': {'removed': true},
      };
    }

    // File upload endpoints
    if (path.contains('/upload_image') || path.contains('/upload_video') || path.contains('/upload')) {
      return {
        'SUCCESS': true,
        'STATUS_CODE': 201,
        'MESSAGE': 'File uploaded successfully',
        'CONTENT': {
          'meta_id': 1,
          'meta_type_id': 1,
          'meta_url': MockDataGenerator.mockImageUrl,
          'is_active': 'Y',
        },
      };
    }

    // Default mock response
    return {
      'SUCCESS': true,
      'STATUS_CODE': 200,
      'MESSAGE': 'Mock response - backend disabled for testing',
      'CONTENT': {},
    };
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool treatUnauthorizedAsSessionExpired = true,
  }) async {
    // Return mock data in mock mode
    if (ApiConfig.MOCK_MODE) {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      return _getMockResponse(path);
    }

    final uri = Uri.parse('$baseUrl$path');
    print('=======================================');
    print('API GET Request: $uri');
    print('Headers: ${{'Accept': 'application/json', ...?headers}}');

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json', ...?headers},
    );

    print('API GET Response [${response.statusCode}]: ${response.body}');
    print('=======================================');

    return NetworkResponseHandler.parseJsonResponse(
      response,
      treatUnauthorizedAsSessionExpired: treatUnauthorizedAsSessionExpired,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool treatUnauthorizedAsSessionExpired = true,
  }) async {
    // Return mock success in mock mode
    if (ApiConfig.MOCK_MODE) {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      return _getMockResponse(path, requestBody: body);
    }

    final uri = Uri.parse('$baseUrl$path');
    final headersMap = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
    
    print('=======================================');
    print('API POST (JSON) Request: $uri');
    print('Headers: $headersMap');
    print('Body: ${jsonEncode(body)}');

    final response = await _client.post(
      uri,
      headers: headersMap,
      body: jsonEncode(body),
    );

    print('API POST Response [${response.statusCode}]: ${response.body}');
    print('=======================================');

    return NetworkResponseHandler.parseJsonResponse(
      response,
      treatUnauthorizedAsSessionExpired: treatUnauthorizedAsSessionExpired,
    );
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    required Map<String, String> body,
    Map<String, String>? headers,
    bool treatUnauthorizedAsSessionExpired = true,
  }) async {
    // Return mock success in mock mode
    if (ApiConfig.MOCK_MODE) {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      final bodyMap = body.cast<String, dynamic>();
      return _getMockResponse(path, requestBody: bodyMap);
    }

    final uri = Uri.parse('$baseUrl$path');
    final headersMap = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      ...?headers,
    };

    print('=======================================');
    print('API POST (Form) Request: $uri');
    print('Headers: $headersMap');
    print('Body: $body');

    final response = await _client.post(
      uri,
      headers: headersMap,
      body: body,
    );

    print('API POST Response [${response.statusCode}]: ${response.body}');
    print('=======================================');

    return NetworkResponseHandler.parseJsonResponse(
      response,
      treatUnauthorizedAsSessionExpired: treatUnauthorizedAsSessionExpired,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    bool treatUnauthorizedAsSessionExpired = true,
  }) async {
    // Return mock success in mock mode
    if (ApiConfig.MOCK_MODE) {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      return _getMockResponse(path);
    }

    final uri = Uri.parse('$baseUrl$path');
    print('=======================================');
    print('API DELETE Request: $uri');
    print('Headers: ${{'Accept': 'application/json', ...?headers}}');

    final response = await _client.delete(
      uri,
      headers: {'Accept': 'application/json', ...?headers},
    );

    print('API DELETE Response [${response.statusCode}]: ${response.body}');
    print('=======================================');

    return NetworkResponseHandler.parseJsonResponse(
      response,
      treatUnauthorizedAsSessionExpired: treatUnauthorizedAsSessionExpired,
    );
  }
}
