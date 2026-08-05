import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  // App IDs from AdMob Console
  static const String androidAppId = 'ca-app-pub-3997483101533938~2199805461';
  static const String iosAppId = 'ca-app-pub-3997483101533938~3424211042';

  // Test Banner Ad Unit IDs provided by Google for development/testing
  static const String _testBannerAdUnitIdAndroid =
      'ca-app-pub-3904725345774897/6300978111';
  static const String _testBannerAdUnitIdIOS =
      'ca-app-pub-3904725345774897/2934735716';

  // Production Banner Ad Unit IDs (Update these once created in AdMob console)
  static String prodBannerAdUnitIdAndroid = '';
  static String prodBannerAdUnitIdIOS = '';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Google Mobile Ads SDK (Android & iOS only)
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('AdMob is not supported on Web.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob SDK initialized successfully.');
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  /// Returns the appropriate Banner Ad Unit ID based on platform & debug mode
  static String get bannerAdUnitId {
    if (kIsWeb) return '';

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kDebugMode || prodBannerAdUnitIdAndroid.isEmpty) {
        return _testBannerAdUnitIdAndroid;
      }
      return prodBannerAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (kDebugMode || prodBannerAdUnitIdIOS.isEmpty) {
        return _testBannerAdUnitIdIOS;
      }
      return prodBannerAdUnitIdIOS;
    }
    return '';
  }
}
