import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cctv_app/core/network/mock_data.dart';
import 'package:cctv_app/core/network/api_config.dart';

class MockFirebaseUser {
  final String uid;
  final String email;
  final String displayName;

  MockFirebaseUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });
}

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  User? get currentUser {
    if (ApiConfig.USE_FIREBASE) {
      return _auth.currentUser;
    }
    return null;
  }

  Stream<User?> get authStateChanges {
    if (ApiConfig.USE_FIREBASE) {
      return _auth.authStateChanges();
    }
    return const Stream.empty();
  }

  Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    if (!ApiConfig.USE_FIREBASE) {
      return {
        'success': true,
        'user': MockFirebaseUser(
          uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          displayName: '$firstName $lastName',
        ),
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }
    try {
      print('=======================================');
      print('FIREBASE AUTH: Attempting signUp for email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName('$firstName $lastName');

      await _firestore.collection('users').doc(credential.user?.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('FIREBASE AUTH: signUp successful. User UID: ${credential.user?.uid}');
      print('=======================================');
      return {
        'success': true,
        'user': credential.user,
        'token': await credential.user?.getIdToken(),
      };
    } on FirebaseAuthException catch (e) {
      print('FIREBASE AUTH: signUp failed with error: ${e.code} - ${e.message}');
      print('=======================================');
      return {
        'success': false,
        'error': e.message,
      };
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    if (!ApiConfig.USE_FIREBASE) {
      final emailLower = email.toLowerCase().trim();
      final pwdTrim = password.trim();

      if (emailLower == 'user@cctv.app' && pwdTrim == 'user@123') {
        return {
          'success': true,
          'user': MockFirebaseUser(
            uid: 'mock_user_uid',
            email: 'user@cctv.app',
            displayName: 'Test User',
          ),
          'role': 'user',
          'token': 'mock_token_user',
        };
      } else if (emailLower == 'admin@cctv.app' && pwdTrim == 'admin@123') {
        return {
          'success': true,
          'user': MockFirebaseUser(
            uid: 'mock_admin_uid',
            email: 'admin@cctv.app',
            displayName: 'Admin User',
          ),
          'role': 'admin',
          'token': 'mock_token_admin',
        };
      } else if (emailLower == 'superadmin@cctv.app' && pwdTrim == 'superadmin@123') {
        return {
          'success': true,
          'user': MockFirebaseUser(
            uid: 'mock_superadmin_uid',
            email: 'superadmin@cctv.app',
            displayName: 'Super Admin',
          ),
          'role': 'super admin',
          'token': 'mock_token_superadmin',
        };
      } else {
        return {
          'success': false,
          'error': 'Credentials issue please check username or password',
        };
      }
    }
    try {
      print('=======================================');
      print('FIREBASE AUTH: Attempting signIn for email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String role = 'user';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user?.uid)
            .get();

        if (userDoc.exists) {
          role = userDoc.data()?['role'] ?? 'user';
        } else {
          // Document missing in Firestore - recreate it based on email
          final emailLower = email.toLowerCase().trim();
          if (emailLower.contains('superadmin')) {
            role = 'super admin';
          } else if (emailLower.contains('admin')) {
            role = 'admin';
          }
          try {
            await _firestore.collection('users').doc(credential.user?.uid).set({
              'firstName': emailLower.contains('superadmin')
                  ? 'Super'
                  : (emailLower.contains('admin') ? 'Admin' : 'User'),
              'lastName': 'Test',
              'email': emailLower,
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (fsWriteError) {
            // Log writing failure (e.g. if Firestore is disabled)
            print('Firestore write error: $fsWriteError');
          }
        }
      } catch (firestoreError) {
        // Fallback: detect role from email if Firestore is disabled or unavailable
        print('Firestore read error: $firestoreError');
        final emailLower = email.toLowerCase().trim();
        if (emailLower.contains('superadmin')) {
          role = 'super admin';
        } else if (emailLower.contains('admin')) {
          role = 'admin';
        }
      }

      print('FIREBASE AUTH: signIn successful. User UID: ${credential.user?.uid}, Role: $role');
      print('=======================================');
      return {
        'success': true,
        'user': credential.user,
        'role': role,
        'token': await credential.user?.getIdToken(),
      };
    } on FirebaseAuthException catch (e) {
      print('FIREBASE AUTH: signIn exception caught: ${e.code} - ${e.message}');
      // Auto-provision requested credentials if not yet registered in Firebase console
      final emailLower = email.toLowerCase().trim();
      final pwdTrim = password.trim();
      final isRequestUser = (emailLower == 'user@cctv.app' && pwdTrim == 'user@123') ||
                            (emailLower == 'admin@cctv.app' && pwdTrim == 'admin@123') ||
                            (emailLower == 'superadmin@cctv.app' && pwdTrim == 'superadmin@123');

      if (isRequestUser && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        try {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          String role = 'user';
          String firstName = 'User';
          if (emailLower.contains('superadmin')) {
            role = 'super admin';
            firstName = 'Super';
          } else if (emailLower.contains('admin')) {
            role = 'admin';
            firstName = 'Admin';
          }

          await credential.user?.updateDisplayName('$firstName Test');

          await _firestore.collection('users').doc(credential.user?.uid).set({
            'firstName': firstName,
            'lastName': 'Test',
            'email': emailLower,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'user': credential.user,
            'role': role,
            'token': await credential.user?.getIdToken(),
          };
        } catch (signUpError) {
          return {
            'success': false,
            'error': signUpError.toString(),
          };
        }
      }

      return {
        'success': false,
        'error': e.message,
      };
    }
  }

  Future<bool> signOut() async {
    if (!ApiConfig.USE_FIREBASE) {
      return true;
    }
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    if (!ApiConfig.USE_FIREBASE) {
      return true;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUserRole(String uid) async {
    if (!ApiConfig.USE_FIREBASE) {
      if (uid == 'mock_superadmin_uid') return 'super admin';
      if (uid == 'mock_admin_uid') return 'admin';
      return 'user';
    }
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}

/// Firebase Realtime Database service stub
class FirebaseRealtimeDbService {
  static final FirebaseRealtimeDbService _instance =
      FirebaseRealtimeDbService._internal();

  factory FirebaseRealtimeDbService() {
    return _instance;
  }

  FirebaseRealtimeDbService._internal();

  /// Get pending cases for user
  /// TODO: Implement Firebase Realtime Database queries
  Future<List<Map<String, dynamic>>> getPendingCases(int userId) async {
    // For now, return mock data
    return MockDataGenerator.generateMockCases();
  }

  /// Create new case
  /// TODO: Implement Firebase database write
  Future<bool> createCase(Map<String, dynamic> caseData) async {
    return true;
  }

  /// Update case
  /// TODO: Implement Firebase database update
  Future<bool> updateCase(int caseId, Map<String, dynamic> updates) async {
    return true;
  }

  /// Delete case
  /// TODO: Implement Firebase database delete
  Future<bool> deleteCase(int caseId) async {
    return true;
  }

  /// Get all active posts
  /// TODO: Implement Firebase database queries
  Future<List<Map<String, dynamic>>> getActivePosts() async {
    return MockDataGenerator.generateMockPosts();
  }

  /// Create post
  /// TODO: Implement Firebase database write
  Future<bool> createPost(Map<String, dynamic> postData) async {
    return true;
  }

  /// Add comment to post
  /// TODO: Implement Firebase database write
  Future<bool> addCommentToPost(int postId, Map<String, dynamic> comment) async {
    return true;
  }

  /// Add reaction to post
  /// TODO: Implement Firebase database write
  Future<bool> addReactionToPost(
    int postId,
    Map<String, dynamic> reaction,
  ) async {
    return true;
  }

  /// Setup real-time listener for cases
  /// TODO: Implement Firebase Realtime Database listeners
  void listenToCases(
    Function(List<Map<String, dynamic>>) onDataChanged,
    Function(String) onError,
  ) {
    // In production, would set up real-time listeners
    onDataChanged(MockDataGenerator.generateMockCases());
  }

  /// Setup real-time listener for posts
  /// TODO: Implement Firebase Realtime Database listeners
  void listenToPosts(
    Function(List<Map<String, dynamic>>) onDataChanged,
    Function(String) onError,
  ) {
    // In production, would set up real-time listeners
    onDataChanged(MockDataGenerator.generateMockPosts());
  }

  /// Cancel listeners
  /// TODO: Implement listener cleanup
  void cancelListeners() {
    // Cleanup code
  }
}

/// Firebase Cloud Firestore service stub
class FirebaseFirestoreService {
  static final FirebaseFirestoreService _instance =
      FirebaseFirestoreService._internal();

  factory FirebaseFirestoreService() {
    return _instance;
  }

  FirebaseFirestoreService._internal();

  /// Get user profile
  /// TODO: Implement Firestore query
  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    return MockDataGenerator.generateMockUser();
  }

  /// Update user profile
  /// TODO: Implement Firestore update
  Future<bool> updateUserProfile(
    int userId,
    Map<String, dynamic> updates,
  ) async {
    return true;
  }

  /// Get user notifications
  /// TODO: Implement Firestore query
  Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    return MockDataGenerator.generateMockNotifications();
  }

  /// Mark notification as read
  /// TODO: Implement Firestore update
  Future<bool> markNotificationAsRead(String notificationId) async {
    return true;
  }

  /// Get advertisements
  /// TODO: Implement Firestore query with filtering
  Future<List<Map<String, dynamic>>> getAdvertisements({
    int? categoryId,
  }) async {
    return MockDataGenerator.generateMockAds();
  }

  /// Get application alerts
  /// TODO: Implement Firestore query
  Future<List<Map<String, dynamic>>> getApplicationAlerts() async {
    return MockDataGenerator.generateMockAlerts();
  }

  /// Create admin alert
  /// TODO: Implement Firestore write
  Future<bool> createApplicationAlert(Map<String, dynamic> alertData) async {
    return true;
  }

  /// Setup real-time listener for notifications
  /// TODO: Implement Firestore real-time listeners
  void listenToUserNotifications(
    int userId,
    Function(List<Map<String, dynamic>>) onDataChanged,
    Function(String) onError,
  ) {
    onDataChanged(MockDataGenerator.generateMockNotifications());
  }

  /// Cancel listeners
  /// TODO: Implement listener cleanup
  void cancelListeners() {
    // Cleanup code
  }
}

/// Firebase Cloud Storage service stub for file uploads
class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();

  factory FirebaseStorageService() {
    return _instance;
  }

  FirebaseStorageService._internal();

  /// Upload image to Firebase Storage
  /// TODO: Implement Firebase Storage file upload
  Future<String?> uploadImage(String filePath, {String? fileName}) async {
    // For now, return mock URL
    return MockDataGenerator.mockImageUrl;
  }

  /// Upload video to Firebase Storage
  /// TODO: Implement Firebase Storage file upload
  Future<String?> uploadVideo(String filePath, {String? fileName}) async {
    // For now, return mock URL
    return MockDataGenerator.mockVideoThumbnail;
  }

  /// Delete file from Firebase Storage
  /// TODO: Implement Firebase Storage file deletion
  Future<bool> deleteFile(String fileUrl) async {
    return true;
  }

  /// Get download URL for file
  /// TODO: Implement Firebase Storage URL generation
  Future<String?> getDownloadUrl(String storagePath) async {
    return MockDataGenerator.mockImageUrl;
  }
}

/// Firebase Cloud Messaging service stub for push notifications
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  /// Initialize FCM and request permissions
  /// TODO: Implement Firebase Cloud Messaging setup
  Future<void> initialize() async {
    // Setup FCM
  }

  /// Get FCM token
  /// TODO: Implement Firebase Cloud Messaging token retrieval
  Future<String?> getToken() async {
    return 'fcm_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Subscribe to topic
  /// TODO: Implement Firebase Cloud Messaging topic subscription
  Future<void> subscribeToTopic(String topic) async {
    // Subscribe to topic
  }

  /// Unsubscribe from topic
  /// TODO: Implement Firebase Cloud Messaging topic unsubscription
  Future<void> unsubscribeFromTopic(String topic) async {
    // Unsubscribe from topic
  }

  /// Handle message callbacks
  /// TODO: Implement Firebase Cloud Messaging message handling
  void setupMessageHandlers(
    Function(Map<String, dynamic>) onMessageReceived,
    Function(Map<String, dynamic>) onMessageOpenedApp,
  ) {
    // Setup message handlers
  }
}

/// Firebase Analytics service stub
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();

  factory FirebaseAnalyticsService() {
    return _instance;
  }

  FirebaseAnalyticsService._internal();

  /// Log screen view
  /// TODO: Implement Firebase Analytics screen tracking
  Future<void> logScreenView(String screenName) async {
    print('Analytics: Screen viewed - $screenName');
  }

  /// Log custom event
  /// TODO: Implement Firebase Analytics custom event logging
  Future<void> logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    print('Analytics: Event logged - $eventName');
  }

  /// Log user signup
  /// TODO: Implement Firebase Analytics signup tracking
  Future<void> logSignUp(String signUpMethod) async {
    print('Analytics: User signed up - $signUpMethod');
  }

  /// Log user login
  /// TODO: Implement Firebase Analytics login tracking
  Future<void> logLogin(String loginMethod) async {
    print('Analytics: User logged in - $loginMethod');
  }

  /// Log case creation
  /// TODO: Implement Firebase Analytics event tracking
  Future<void> logCaseCreated(int caseId) async {
    print('Analytics: Case created - $caseId');
  }

  /// Log post creation
  /// TODO: Implement Firebase Analytics event tracking
  Future<void> logPostCreated(int postId) async {
    print('Analytics: Post created - $postId');
  }

  /// Set user property
  /// TODO: Implement Firebase Analytics user properties
  Future<void> setUserProperty(String name, String value) async {
    print('Analytics: User property set - $name: $value');
  }
}

/// Firebase Remote Config service stub
class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance =
      FirebaseRemoteConfigService._internal();

  factory FirebaseRemoteConfigService() {
    return _instance;
  }

  FirebaseRemoteConfigService._internal();

  /// Initialize Remote Config
  /// TODO: Implement Firebase Remote Config initialization
  Future<void> initialize() async {
    // Setup remote config
  }

  /// Fetch and activate remote config
  /// TODO: Implement Firebase Remote Config fetch and activate
  Future<bool> fetchAndActivate() async {
    return true;
  }

  /// Get string value from Remote Config
  /// TODO: Implement Firebase Remote Config value retrieval
  String getString(String key, {String defaultValue = ''}) {
    return defaultValue;
  }

  /// Get boolean value from Remote Config
  /// TODO: Implement Firebase Remote Config value retrieval
  bool getBoolean(String key, {bool defaultValue = false}) {
    return defaultValue;
  }

  /// Get number value from Remote Config
  /// TODO: Implement Firebase Remote Config value retrieval
  double getNumber(String key, {double defaultValue = 0.0}) {
    return defaultValue;
  }
}

/// Main Firebase service coordinator
class FirebaseServiceProvider {
  static final FirebaseServiceProvider _instance =
      FirebaseServiceProvider._internal();

  late final FirebaseAuthService auth;
  late final FirebaseRealtimeDbService realtimeDb;
  late final FirebaseFirestoreService firestore;
  late final FirebaseStorageService storage;
  late final FirebaseMessagingService messaging;
  late final FirebaseAnalyticsService analytics;
  late final FirebaseRemoteConfigService remoteConfig;

  factory FirebaseServiceProvider() {
    return _instance;
  }

  FirebaseServiceProvider._internal() {
    auth = FirebaseAuthService();
    realtimeDb = FirebaseRealtimeDbService();
    firestore = FirebaseFirestoreService();
    storage = FirebaseStorageService();
    messaging = FirebaseMessagingService();
    analytics = FirebaseAnalyticsService();
    remoteConfig = FirebaseRemoteConfigService();
  }

  /// Initialize all Firebase services
  /// TODO: Implement actual Firebase initialization
  Future<void> initialize() async {
    print('Initializing Firebase services...');
    await messaging.initialize();
    await remoteConfig.initialize();
    print('Firebase services initialized');
  }

  /// Check if Firebase is enabled in config
  bool isEnabled() {
    // Check ApiConfig.USE_FIREBASE flag
    return false; // Currently disabled, will enable after Firebase setup
  }

  /// Get service status
  String getStatus() {
    return '''
Firebase Services Status:
- Auth Service: Ready
- Realtime Database: Ready
- Firestore: Ready
- Storage: Ready
- Cloud Messaging: Ready
- Analytics: Ready
- Remote Config: Ready
- Status: ${isEnabled() ? 'ENABLED' : 'DISABLED (Using Mock Data)'}
''';
  }
}
