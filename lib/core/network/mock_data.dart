/// Mock data generator for testing without backend
class MockDataGenerator {
  static const String mockImageUrl = 'https://via.placeholder.com/500x500?text=CCTV+Image';
  static const String mockVideoThumbnail = 'https://via.placeholder.com/500x300?text=CCTV+Video';
  static const String mockAvatarUrl = 'https://via.placeholder.com/200x200?text=User+Avatar';

  /// Generate mock user data
  static Map<String, dynamic> generateMockUser({
    int userId = 1,
    String firstName = 'Test',
    String lastName = 'User',
    String email = 'test@cctv.app',
    int roleId = 1,
    String roleDescription = 'user',
  }) {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'user_email': email,
      'role_id': roleId,
      'role_description': roleDescription,
      'dob': '1990-01-15',
      'gender_id': 1,
      'country_id': 1,
      'state_id': 1,
      'city_id': 1,
      'is_active': 'Y',
    };
  }

  /// Generate mock admin user
  static Map<String, dynamic> generateMockAdminUser({
    int userId = 2,
  }) {
    return generateMockUser(
      userId: userId,
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@cctv.app',
      roleId: 2,
      roleDescription: 'admin',
    );
  }

  /// Generate mock super admin user
  static Map<String, dynamic> generateMockSuperAdminUser({
    int userId = 3,
  }) {
    return generateMockUser(
      userId: userId,
      firstName: 'Super',
      lastName: 'Admin',
      email: 'superadmin@cctv.app',
      roleId: 3,
      roleDescription: 'super admin',
    );
  }

  /// Generate mock case
  static Map<String, dynamic> generateMockCase({
    int caseId = 1,
    int userId = 1,
    String title = 'CCTV Footage Case',
    String description = 'This is a test case with CCTV footage for investigation',
    String status = 'pending',
  }) {
    return {
      'case_id': caseId,
      'user_id': userId,
      'case_title': title,
      'case_description': description,
      'case_status': status,
      'case_category_id': 1,
      'case_is_active': 'Y',
      'case_created_at': DateTime.now().toIso8601String(),
      'application_meta': {
        'meta_id': caseId,
        'meta_type_id': 1,
        'meta_url': mockImageUrl,
        'is_active': 'Y',
      },
      'defendant': {
        'defendant_case_id': caseId,
        'defendent_id': 2,
        'is_accept_terms': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Generate multiple mock cases
  static List<Map<String, dynamic>> generateMockCases({int count = 5}) {
    return List.generate(
      count,
      (index) => generateMockCase(
        caseId: index + 1,
        userId: 1,
        title: 'Case #${index + 1}: CCTV Evidence',
        description: 'Mock case #${index + 1} for testing purposes',
        status: ['pending', 'approved', 'rejected'][index % 3],
      ),
    );
  }

  /// Generate mock post
  static Map<String, dynamic> generateMockPost({
    int postId = 1,
    int caseId = 1,
    int createdBy = 1,
    String description = 'This is a test post about the case',
  }) {
    final now = DateTime.now();
    return {
      'post_id': postId,
      'case_id': caseId,
      'post_description': description,
      'created_by': createdBy,
      'created_at': now.subtract(Duration(hours: 2)).toIso8601String(),
      'created_by_user_info': {
        'user_id': createdBy,
        'first_name': 'Test',
        'last_name': 'User',
        'user_email': 'test@cctv.app',
        'avatar_url': mockAvatarUrl,
      },
      'case_detail': generateMockCase(caseId: caseId),
      'defendant_details': [
        {
          'defendent_id': 2,
          'defendent_name': 'Defendant Name',
          'is_accept_terms': false,
        }
      ],
      'comments': generateMockPostComments(postId),
      'reactions': generateMockPostReactions(postId),
      'reaction_summary': {
        'like_count': 5,
        'dislike_count': 1,
        'heart_count': 3,
      },
      'case_poll_count': {
        'owner_count': 10,
        'defendant_count': 8,
      },
      'repost_count': 2,
      'reposts': [],
      'saved_post_meta': null,
    };
  }

  /// Generate mock posts
  static List<Map<String, dynamic>> generateMockPosts({
    int count = 10,
    int caseId = 1,
  }) {
    return List.generate(
      count,
      (index) => generateMockPost(
        postId: index + 1,
        caseId: caseId,
        createdBy: index % 2 == 0 ? 1 : 2,
        description:
            'Test post #${index + 1}: This is a mock post for testing the CCTV app UI',
      ),
    );
  }

  /// Generate mock post comments
  static List<Map<String, dynamic>> generateMockPostComments(int postId) {
    return [
      {
        'comment_id': 1,
        'post_id': postId,
        'comment_text': 'This is a test comment',
        'created_by': 1,
        'created_by_user_info': {
          'user_id': 1,
          'first_name': 'Test',
          'last_name': 'User',
          'user_email': 'test@cctv.app',
          'avatar_url': mockAvatarUrl,
        },
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'comment_id': 2,
        'post_id': postId,
        'comment_text': 'Another test comment',
        'created_by': 2,
        'created_by_user_info': {
          'user_id': 2,
          'first_name': 'Admin',
          'last_name': 'User',
          'user_email': 'admin@cctv.app',
          'avatar_url': mockAvatarUrl,
        },
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  /// Generate mock post reactions
  static List<Map<String, dynamic>> generateMockPostReactions(int postId) {
    return [
      {
        'reaction_id': 1,
        'post_id': postId,
        'reaction_type': 'like',
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'reaction_id': 2,
        'post_id': postId,
        'reaction_type': 'heart',
        'created_by': 2,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  /// Generate mock reel
  static Map<String, dynamic> generateMockReel({
    int reelId = 1,
    int userId = 1,
    String description = 'Test reel video',
  }) {
    return {
      'reel_id': reelId,
      'user_id': userId,
      'reel_description': description,
      'reel_video_url': mockVideoThumbnail,
      'thumbnail_url': mockVideoThumbnail,
      'duration': 30,
      'view_count': 150,
      'like_count': 25,
      'created_at': DateTime.now().toIso8601String(),
      'user_info': {
        'user_id': userId,
        'first_name': 'Test',
        'last_name': 'User',
        'avatar_url': mockAvatarUrl,
      },
    };
  }

  /// Generate mock reels
  static List<Map<String, dynamic>> generateMockReels({int count = 5}) {
    return List.generate(
      count,
      (index) => generateMockReel(
        reelId: index + 1,
        userId: 1,
        description: 'Test reel #${index + 1}',
      ),
    );
  }

  /// Generate mock application alert
  static Map<String, dynamic> generateMockAlert({
    int alertId = 1,
    String category = 'A',
    String message = 'Important system alert',
  }) {
    return {
      'alert_id': alertId,
      'category': category,
      'alert_note': message,
      'attached_meta_id': 1,
      'is_active': 'Y',
      'created_by': 2,
      'created_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate mock alerts
  static List<Map<String, dynamic>> generateMockAlerts({int count = 3}) {
    return List.generate(
      count,
      (index) => generateMockAlert(
        alertId: index + 1,
        message: 'System alert #${index + 1}: Important notification',
      ),
    );
  }

  /// Generate mock advertisement
  static Map<String, dynamic> generateMockAd({
    int adId = 1,
    String title = 'Test Advertisement',
    String status = 'active',
  }) {
    return {
      'ad_id': adId,
      'ad_title': title,
      'ad_description': 'This is a test advertisement',
      'ad_status': status,
      'ad_category_id': 1,
      'ad_image_url': mockImageUrl,
      'is_active': 'Y',
      'created_at': DateTime.now().toIso8601String(),
      'created_by': 1,
    };
  }

  /// Generate mock ads
  static List<Map<String, dynamic>> generateMockAds({int count = 5}) {
    return List.generate(
      count,
      (index) => generateMockAd(
        adId: index + 1,
        title: 'Ad #${index + 1}',
        status: ['active', 'pending', 'archived'][index % 3],
      ),
    );
  }

  /// Generate mock notification
  static Map<String, dynamic> generateMockNotification({
    int notificationId = 1,
    String message = 'Test notification',
    String type = 'info',
  }) {
    return {
      'notification_id': notificationId,
      'user_id': 1,
      'notification_message': message,
      'notification_type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'notification_meta': {
        'meta_id': 1,
        'meta_value': 'value',
      },
    };
  }

  /// Generate mock notifications
  static List<Map<String, dynamic>> generateMockNotifications({int count = 5}) {
    return List.generate(
      count,
      (index) => generateMockNotification(
        notificationId: index + 1,
        message: 'Notification #${index + 1}: Test message',
        type: ['info', 'warning', 'success'][index % 3],
      ),
    );
  }

  /// Generate mock role
  static Map<String, dynamic> generateMockRole({
    int roleId = 1,
    String description = 'User',
  }) {
    return {
      'role_id': roleId,
      'role_description': description,
      'is_active': true,
    };
  }

  /// Generate all available roles
  static List<Map<String, dynamic>> generateMockRoles() {
    return [
      generateMockRole(roleId: 1, description: 'User'),
      generateMockRole(roleId: 2, description: 'admin'),
      generateMockRole(roleId: 3, description: 'manager'),
      generateMockRole(roleId: 4, description: 'operator'),
    ];
  }

  /// Generate mock dashboard stats
  static Map<String, dynamic> generateMockDashboardStats() {
    return {
      'total_cases': 15,
      'pending_cases': 5,
      'approved_cases': 8,
      'rejected_cases': 2,
      'total_posts': 45,
      'total_users': 23,
      'total_alerts': 7,
      'new_notifications': 3,
      'cases_this_week': 4,
      'posts_this_week': 12,
    };
  }

  /// Generate mock country options
  static List<Map<String, dynamic>> generateMockCountries() {
    return [
      {'country_id': 1, 'country_name': 'United States'},
      {'country_id': 2, 'country_name': 'Canada'},
      {'country_id': 3, 'country_name': 'United Kingdom'},
      {'country_id': 4, 'country_name': 'Pakistan'},
      {'country_id': 5, 'country_name': 'India'},
    ];
  }

  /// Generate mock state/province options
  static List<Map<String, dynamic>> generateMockStates() {
    return [
      {'state_id': 1, 'state_name': 'California'},
      {'state_id': 2, 'state_name': 'Texas'},
      {'state_id': 3, 'state_name': 'New York'},
      {'state_id': 4, 'state_name': 'Punjab'},
      {'state_id': 5, 'state_name': 'Sindh'},
    ];
  }

  /// Generate mock gender options
  static List<Map<String, dynamic>> generateMockGenders() {
    return [
      {'gender_id': 1, 'gender_name': 'Male'},
      {'gender_id': 2, 'gender_name': 'Female'},
      {'gender_id': 3, 'gender_name': 'Other'},
    ];
  }
}
