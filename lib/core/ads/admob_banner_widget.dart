import 'dart:async';
import 'package:cctv_app/core/ads/admob_service.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class AdMobBannerWidget extends StatefulWidget {
  final AdSize adSize;

  const AdMobBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  Map<String, dynamic>? _activeSystemAd;
  StreamSubscription? _systemAdSub;

  @override
  void initState() {
    super.initState();
    _checkAndLoadAds();
  }

  void _checkAndLoadAds() {
    if (kIsWeb) return;

    // Check if AdMob banner ads are enabled by system
    if (AdMobService.areBannerAdsEnabled) {
      _loadBannerAd();
    } else {
      // Check if system ads from Firestore are pushed
      _listenToSystemAds();
    }
  }

  void _loadBannerAd() {
    if (kIsWeb || !AdMobService.instance.isInitialized) return;

    final adUnitId = AdMobService.bannerAdUnitId;
    if (adUnitId.isEmpty) {
      // If AdMob has no valid unit ID, check system ads
      _listenToSystemAds();
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
            // Fallback to checking active system ads
            _listenToSystemAds();
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  void _listenToSystemAds() {
    if (_systemAdSub != null) return;
    try {
      _systemAdSub = FirebaseFirestore.instance
          .collection('ads')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen(
        (snapshot) {
          if (!mounted) return;
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            setState(() {
              _activeSystemAd = null;
            });
            return;
          }

          // Pick the first active system ad with content
          final adData = docs.first.data();
          setState(() {
            _activeSystemAd = adData;
          });
        },
        onError: (err) {
          debugPrint('System ads listen error: $err');
          if (mounted) {
            setState(() {
              _activeSystemAd = null;
            });
          }
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _systemAdSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    // 1. If AdMob banner is loaded from the system, display it
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // 2. If a system ad is pushed from Firestore, display a clean mini banner
    if (_activeSystemAd != null) {
      return _buildSystemAdBanner(_activeSystemAd!);
    }

    // 3. If no ad is being pushed by the system, collapse completely (0 height)
    return const SizedBox.shrink();
  }

  Widget _buildSystemAdBanner(Map<String, dynamic> ad) {
    final title = (ad['title'] ?? '').toString();
    final note = (ad['note'] ?? '').toString();
    final imageUrl = (ad['coverImageUrl'] ?? '').toString();
    final link = (ad['destinationUrl'] ?? '').toString();

    return InkWell(
      onTap: () {
        if (link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
          ),
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.campaign,
                    size: 28,
                    color: kPrimaryColor,
                  ),
                ),
              )
            else
              const Icon(Icons.campaign, size: 28, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.isNotEmpty ? title : 'Promoted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
