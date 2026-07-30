import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsKeys {
  static const generalNotification = 'app_setting_general_notification';
  static const sound = 'app_setting_sound';
  static const vibrate = 'app_setting_vibrate';
  static const appUpdates = 'app_setting_app_updates';
  static const billReminder = 'app_setting_bill_reminder';
  static const promotion = 'app_setting_promotion';
  static const discountAvailable = 'app_setting_discount_available';
  static const paymentRequest = 'app_setting_payment_request';
  static const newServiceAvailable = 'app_setting_new_service_available';
  static const newTipsAvailable = 'app_setting_new_tips_available';
  static const drawerCountryPrefix = 'drawer_country_user_';

  static const all = <String>{
    generalNotification,
    sound,
    vibrate,
    appUpdates,
    billReminder,
    promotion,
    discountAvailable,
    paymentRequest,
    newServiceAvailable,
    newTipsAvailable,
  };

  AppSettingsKeys._();
}

class AppSettingsStorage {
  final FlutterSecureStorage _storage;
  static final Map<int, String> _cachedDrawerCountries = <int, String>{};

  const AppSettingsStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static String? cachedDrawerCountry(int userId) {
    return _cachedDrawerCountries[userId];
  }

  Future<bool> readBool(String key, {bool fallback = false}) async {
    final value = await _storage.read(key: key);
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }

  Future<void> writeBool(String key, bool value) {
    return _storage.write(key: key, value: value.toString());
  }

  Future<int?> readInt(String key) async {
    final value = await _storage.read(key: key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> writeInt(String key, int value) {
    return _storage.write(key: key, value: '$value');
  }

  Future<String?> readString(String key) {
    return _storage.read(key: key);
  }

  Future<void> writeString(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  String drawerCountryKey(int userId) {
    return '${AppSettingsKeys.drawerCountryPrefix}$userId';
  }

  Future<String?> readDrawerCountry(int userId) async {
    final value = await readString(drawerCountryKey(userId));
    if (value != null) {
      _cachedDrawerCountries[userId] = value;
    }
    return value;
  }

  Future<void> writeDrawerCountry(int userId, String value) async {
    _cachedDrawerCountries[userId] = value;
    await writeString(drawerCountryKey(userId), value);
  }

  Future<Map<String, bool>> readAll() async {
    final result = <String, bool>{};
    for (final key in AppSettingsKeys.all) {
      result[key] = await readBool(key);
    }
    return result;
  }
}
