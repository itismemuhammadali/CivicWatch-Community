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

  // Test Interstitial Ad Unit IDs
  static const String _testInterstitialAdUnitIdAndroid =
      'ca-app-pub-3904725345774897/1033173712';
  static const String _testInterstitialAdUnitIdIOS =
      'ca-app-pub-3904725345774897/4411468910';

  // Production Interstitial Ad Unit IDs
  static String prodInterstitialAdUnitIdAndroid = '';
  static String prodInterstitialAdUnitIdIOS = '';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InterstitialAd? _interstitialAd;

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

  /// Returns the appropriate Interstitial Ad Unit ID based on platform & debug mode
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kDebugMode || prodInterstitialAdUnitIdAndroid.isEmpty) {
        return _testInterstitialAdUnitIdAndroid;
      }
      return prodInterstitialAdUnitIdAndroid;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (kDebugMode || prodInterstitialAdUnitIdIOS.isEmpty) {
        return _testInterstitialAdUnitIdIOS;
      }
      return prodInterstitialAdUnitIdIOS;
    }
    return '';
  }

  /// Loads an interstitial ad in the background so it's ready to show instantly.
  void loadInterstitialAd() {
    if (kIsWeb || !_isInitialized) return;

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows the pre-loaded interstitial ad, then triggers loading the next one.
  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      debugPrint('Warning: InterstitialAd not ready yet.');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Ad showed fullscreen.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Ad dismissed fullscreen.');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Load the next one
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
