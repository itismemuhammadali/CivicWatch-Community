import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageKeys {
  static const accessToken = 'access_token';
  static const userId = 'user_id';
  static const roleId = 'role_id';
  static const roleDescription = 'role_description';
  static const firstName = 'first_name';
  static const lastName = 'last_name';
  static const email = 'user_email';
  static const profileImageUrl = 'profile_image_url';
  static const dashboardType = 'dashboard_type';
  static const userTabIndex = 'user_tab_index';
  static const adminTabIndex = 'admin_tab_index';
  static const superAdminTabIndex = 'super_admin_tab_index';
  static const adTabIndex = 'ad_tab_index';
  static const firebaseUid = 'firebase_uid';
  AuthStorageKeys._();
}

enum DashboardType { user, admin, superAdmin, ad }

class AuthStorage {
  final FlutterSecureStorage _storage;
  static String? _cachedFirstName;
  static String? _cachedLastName;
  static String? _cachedEmail;
  static String? _cachedProfileImageUrl;
  static int? _cachedUserId;
  static String? _cachedFirebaseUid;

  const AuthStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static String? get cachedFirstName => _cachedFirstName;
  static String? get cachedLastName => _cachedLastName;
  static String? get cachedEmail => _cachedEmail;
  static String? get cachedProfileImageUrl => _cachedProfileImageUrl;
  static int? get cachedUserId => _cachedUserId;
  static String? get cachedFirebaseUid => _cachedFirebaseUid;

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    final userId = await readUserId();
    return token != null && token.trim().isNotEmpty && userId != null;
  }

  Future<void> saveAuth({
    required String accessToken,
    required int userId,
    int? roleId,
    String? roleDescription,
    String? firstName,
    String? lastName,
    String? email,
    String? profileImageUrl,
    DashboardType dashboardType = DashboardType.user,
    String? firebaseUid,
  }) async {
    _cachedUserId = userId;
    _cachedFirstName = firstName;
    _cachedLastName = lastName;
    _cachedEmail = email;
    _cachedProfileImageUrl = profileImageUrl;
    _cachedFirebaseUid = firebaseUid;

    await _storage.write(key: AuthStorageKeys.accessToken, value: accessToken);
    await _storage.write(key: AuthStorageKeys.userId, value: '$userId');
    await _storage.write(
      key: AuthStorageKeys.roleId,
      value: roleId == null ? null : '$roleId',
    );
    await _storage.write(
      key: AuthStorageKeys.roleDescription,
      value: roleDescription,
    );
    await _storage.write(key: AuthStorageKeys.firstName, value: firstName);
    await _storage.write(key: AuthStorageKeys.lastName, value: lastName);
    await _storage.write(key: AuthStorageKeys.email, value: email);
    await _storage.write(
      key: AuthStorageKeys.profileImageUrl,
      value: profileImageUrl,
    );
    await _storage.write(
      key: AuthStorageKeys.dashboardType,
      value: dashboardType.name,
    );
    if (firebaseUid != null) {
      await _storage.write(key: AuthStorageKeys.firebaseUid, value: firebaseUid);
    }
  }

  Future<String?> readAccessToken() =>
      _storage.read(key: AuthStorageKeys.accessToken);

  Future<int?> readUserId() async {
    final value = await _storage.read(key: AuthStorageKeys.userId);
    return value == null ? null : int.tryParse(value);
  }

  Future<int?> readRoleId() async {
    final value = await _storage.read(key: AuthStorageKeys.roleId);
    return value == null ? null : int.tryParse(value);
  }

  Future<String?> readRoleDescription() =>
      _storage.read(key: AuthStorageKeys.roleDescription);

  Future<String?> readFirstName() =>
      _storage.read(key: AuthStorageKeys.firstName);

  Future<String?> readLastName() =>
      _storage.read(key: AuthStorageKeys.lastName);

  Future<String?> readEmail() => _storage.read(key: AuthStorageKeys.email);

  Future<String?> readProfileImageUrl() =>
      _storage.read(key: AuthStorageKeys.profileImageUrl);

  Future<String?> readFirebaseUid() =>
      _storage.read(key: AuthStorageKeys.firebaseUid);

  Future<void> hydrateCache() async {
    _cachedUserId = await readUserId();
    _cachedFirstName = await readFirstName();
    _cachedLastName = await readLastName();
    _cachedEmail = await readEmail();
    _cachedProfileImageUrl = await readProfileImageUrl();
    _cachedFirebaseUid = await readFirebaseUid();
  }

  Future<DashboardType?> readDashboardType() async {
    final value = await _storage.read(key: AuthStorageKeys.dashboardType);
    return switch (value) {
      'superAdmin' => DashboardType.superAdmin,
      'admin' => DashboardType.admin,
      'ad' => DashboardType.ad,
      'user' => DashboardType.user,
      _ => null,
    };
  }

  Future<void> saveLastTabIndex(DashboardType type, int index) async {
    final key = switch (type) {
      DashboardType.user => AuthStorageKeys.userTabIndex,
      DashboardType.admin => AuthStorageKeys.adminTabIndex,
      DashboardType.superAdmin => AuthStorageKeys.superAdminTabIndex,
      DashboardType.ad => AuthStorageKeys.adTabIndex,
    };
    await _storage.write(key: key, value: '$index');
  }

  Future<int?> readLastTabIndex(DashboardType type) async {
    final key = switch (type) {
      DashboardType.user => AuthStorageKeys.userTabIndex,
      DashboardType.admin => AuthStorageKeys.adminTabIndex,
      DashboardType.superAdmin => AuthStorageKeys.superAdminTabIndex,
      DashboardType.ad => AuthStorageKeys.adTabIndex,
    };
    final value = await _storage.read(key: key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> clear() async {
    _cachedUserId = null;
    _cachedFirstName = null;
    _cachedLastName = null;
    _cachedEmail = null;
    _cachedProfileImageUrl = null;
    _cachedFirebaseUid = null;

    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.userId);
    await _storage.delete(key: AuthStorageKeys.roleId);
    await _storage.delete(key: AuthStorageKeys.roleDescription);
    await _storage.delete(key: AuthStorageKeys.firstName);
    await _storage.delete(key: AuthStorageKeys.lastName);
    await _storage.delete(key: AuthStorageKeys.email);
    await _storage.delete(key: AuthStorageKeys.profileImageUrl);
    await _storage.delete(key: AuthStorageKeys.dashboardType);
    await _storage.delete(key: AuthStorageKeys.userTabIndex);
    await _storage.delete(key: AuthStorageKeys.adminTabIndex);
    await _storage.delete(key: AuthStorageKeys.adTabIndex);
    await _storage.delete(key: AuthStorageKeys.firebaseUid);
  }
}
