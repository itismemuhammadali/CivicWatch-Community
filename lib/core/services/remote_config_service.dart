import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String _defaultTelnyxApiKey =
      String.fromEnvironment('TELNYX_API_KEY', defaultValue: '');
  static const String _defaultTelnyxFromNumber =
      String.fromEnvironment('TELNYX_FROM_NUMBER', defaultValue: '+18005550199');
  static const String _defaultAppDownloadUrl =
      'https://play.google.com/store/apps/details?id=com.commctv.app';

  static const bool _defaultBannerAdsEnabled = false;
  static const String _defaultAdMobBannerUnitIdIOS = '';
  static const String _defaultAdMobBannerUnitIdAndroid = '';
  static const bool _defaultAdMobTestMode = false;

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await _remoteConfig!.setDefaults({
        'telnyx_api_key': _defaultTelnyxApiKey,
        'telnyx_from_number': _defaultTelnyxFromNumber,
        'app_download_url': _defaultAppDownloadUrl,
        'banner_ads_enabled': _defaultBannerAdsEnabled,
        'admob_banner_ad_unit_id_ios': _defaultAdMobBannerUnitIdIOS,
        'admob_banner_ad_unit_id_android': _defaultAdMobBannerUnitIdAndroid,
        'admob_test_mode': _defaultAdMobTestMode,
      });

      await _remoteConfig!.fetchAndActivate();
      _isInitialized = true;
    } catch (e) {
      debugPrint('RemoteConfigService initialize error: $e');
    }
  }

  String get telnyxApiKey {
    try {
      final value = _remoteConfig?.getString('telnyx_api_key') ?? '';
      return value.isNotEmpty ? value : _defaultTelnyxApiKey;
    } catch (_) {
      return _defaultTelnyxApiKey;
    }
  }

  String get telnyxFromNumber {
    try {
      final value = _remoteConfig?.getString('telnyx_from_number') ?? '';
      return value.isNotEmpty ? value : _defaultTelnyxFromNumber;
    } catch (_) {
      return _defaultTelnyxFromNumber;
    }
  }

  String get appDownloadUrl {
    try {
      final value = _remoteConfig?.getString('app_download_url') ?? '';
      return value.isNotEmpty ? value : _defaultAppDownloadUrl;
    } catch (_) {
      return _defaultAppDownloadUrl;
    }
  }

  bool get bannerAdsEnabled {
    try {
      return _remoteConfig?.getBool('banner_ads_enabled') ??
          _defaultBannerAdsEnabled;
    } catch (_) {
      return _defaultBannerAdsEnabled;
    }
  }

  bool get adMobTestMode {
    try {
      return _remoteConfig?.getBool('admob_test_mode') ??
          _defaultAdMobTestMode;
    } catch (_) {
      return _defaultAdMobTestMode;
    }
  }

  String get admobBannerUnitIdIOS {
    try {
      final value = _remoteConfig?.getString('admob_banner_ad_unit_id_ios') ?? '';
      return value.isNotEmpty ? value : _defaultAdMobBannerUnitIdIOS;
    } catch (_) {
      return _defaultAdMobBannerUnitIdIOS;
    }
  }

  String get admobBannerUnitIdAndroid {
    try {
      final value =
          _remoteConfig?.getString('admob_banner_ad_unit_id_android') ?? '';
      return value.isNotEmpty ? value : _defaultAdMobBannerUnitIdAndroid;
    } catch (_) {
      return _defaultAdMobBannerUnitIdAndroid;
    }
  }
}
