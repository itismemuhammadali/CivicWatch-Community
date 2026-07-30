import 'package:cctv_app/core/components/ad_top_header.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/application_ad.dart';
import 'package:cctv_app/core/network/services/ads_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/ads/pages/create_ad_page.dart';
import 'package:cctv_app/feature/ads/pages/stats_page.dart';
import 'package:cctv_app/feature/ads/widget/application_ad_card.dart';
import 'package:flutter/material.dart';

class AdsPage extends StatefulWidget {
  const AdsPage({super.key});

  @override
  State<AdsPage> createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  final AdsService _adsService = AdsService();
  int selectedIndex = 0;
  bool _isLoading = true;
  bool _isResumingAd = false;
  int? _resumingAdId;
  bool _isSubmittingDraftAd = false;
  int? _submittingDraftAdId;
  String? _error;
  final Map<String, List<ApplicationAd>> _adsByStatus = {};

  static const _tabs = [
    _AdsStatusTab(label: 'Active Ads', status: 'active'),
    _AdsStatusTab(label: 'Pending Ads', status: 'pending'),
    _AdsStatusTab(label: 'Scheduled Ads', status: 'scheduled'),
    _AdsStatusTab(label: 'Cancelled', status: 'cancelled'),
  ];

  List<ApplicationAd> _getMockAds(String status) {
    switch (status) {
      case 'active':
        return [
          ApplicationAd(
            id: 1,
            title: 'Summer Sale - 30% Off',
            note: '',
            status: 'active',
            categoryId: 1,
            categoryName: 'Summer',
            destinationUrl: '',
            coverMetaId: 1,
            coverImageUrl: 'assets/images/ad_summer_sale.jpg',
            rotationOrder: 1,
            displayIntervalSeconds: 30,
            isGlobal: true,
            startAt: '2025-05-01',
            endAt: null,
            createdAt: '2025-05-01',
            runDays: 12,
          ),
          ApplicationAd(
            id: 2,
            title: 'Limited Edition Sneakers Available Now!',
            note: '',
            status: 'active',
            categoryId: 2,
            categoryName: 'Sneakers',
            destinationUrl: '',
            coverMetaId: 2,
            coverImageUrl: 'assets/images/ad_sneakers.jpg',
            rotationOrder: 2,
            displayIntervalSeconds: 30,
            isGlobal: true,
            startAt: '2025-06-15',
            endAt: null,
            createdAt: '2025-06-15',
            runDays: 5,
          ),
        ];
      case 'pending':
        return [
          ApplicationAd(
            id: 3,
            title: 'New Arrivals Just Dropped!',
            note: '/product/smartwatch-x3',
            status: 'pending',
            categoryId: 3,
            categoryName: 'New',
            destinationUrl: '/product/smartwatch-x3',
            coverMetaId: 3,
            coverImageUrl: 'assets/images/ad_coming_soon.jpg',
            rotationOrder: 1,
            displayIntervalSeconds: 30,
            isGlobal: true,
            startAt: '2025-05-01',
            endAt: '2025-05-31',
            createdAt: '2025-05-01',
            runDays: 30,
          ),
        ];
      case 'scheduled':
        return [
          ApplicationAd(
            id: 4,
            title: 'Exclusive Summer Collection Launched!',
            note: '',
            status: 'scheduled',
            categoryId: 4,
            categoryName: 'Summer',
            destinationUrl: '',
            coverMetaId: 4,
            coverImageUrl: 'assets/images/ad_summer_collection.jpg',
            rotationOrder: 1,
            displayIntervalSeconds: 30,
            isGlobal: true,
            startAt: '2025-08-31',
            endAt: null,
            createdAt: '2025-07-01',
            runDays: 31,
          ),
        ];
      case 'cancelled':
        return [
          ApplicationAd(
            id: 5,
            title: 'Exclusive Summer Collection Launched!',
            note: '',
            status: 'cancelled',
            categoryId: 5,
            categoryName: 'Summer',
            destinationUrl: '',
            coverMetaId: 5,
            coverImageUrl: 'assets/images/ad_summer_collection.jpg',
            rotationOrder: 1,
            displayIntervalSeconds: 30,
            isGlobal: true,
            startAt: '2025-08-31',
            endAt: '2025-08-31',
            createdAt: '2025-07-01',
            runDays: 31,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdsForSelectedTab();
  }

  Future<void> _loadAdsForSelectedTab({bool forceRefresh = false}) async {
    final selectedTab = _tabs[selectedIndex];
    if (!forceRefresh && _adsByStatus.containsKey(selectedTab.status)) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Use mock data
    _adsByStatus[selectedTab.status] = _getMockAds(selectedTab.status);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _openCreateAdPage() async {
    final didCreate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateAdPage()),
    );

    if (didCreate == true && mounted) {
      final draftIndex = _tabs.indexWhere((tab) => tab.status == 'draft');
      setState(() {
        _adsByStatus.remove('draft');
        selectedIndex = draftIndex == -1 ? selectedIndex : draftIndex;
      });
      await _loadAdsForSelectedTab(forceRefresh: true);
    }
  }

  void _onTabSelected(int index) {
    if (selectedIndex == index) return;
    setState(() {
      selectedIndex = index;
    });
    _loadAdsForSelectedTab();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdTopHeader(),
          Space.vertical(20),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              text: "Create new ads",
              height: 36,
              isMainAxisSizeMin: true,
              postfixIcon: Icon(Icons.add, color: kWhiteColor),
              onPressed: _openCreateAdPage,
            ),
          ),
          Space.vertical(20),
          Text(
            _tabs[selectedIndex].label,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Space.vertical(8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _onTabSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor.withValues(alpha: 0.1) : kWhiteColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : kGreyColor,
                        ),
                      ),
                      child: Text(
                        _tabs[index].label,
                        style: context.medium.copyWith(
                          fontSize: 13,
                          color: isSelected ? kPrimaryColor : kDarkGreyColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Space.vertical(8),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(color: kRedColor),
            ),
            Space.vertical(8),
            TextButton(
              onPressed: () => _loadAdsForSelectedTab(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final ads = _adsByStatus[_tabs[selectedIndex].status] ?? const [];
    if (ads.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadAdsForSelectedTab(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 40),
          children: [
            Center(
              child: Text(
                'No ${_tabs[selectedIndex].label.toLowerCase()} found',
                style: context.normal.copyWith(color: kDarkGreyColor),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAdsForSelectedTab(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 10, bottom: 16),
        itemCount: ads.length,
        separatorBuilder: (_, __) => Space.vertical(10),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return AdsListCard(
            ad: ad,
            primaryAction: _buildPrimaryAction(ad),
            secondaryAction: _buildSecondaryAction(ad),
            tertiaryAction: _buildStatsAction(),
          );
        },
      ),
    );
  }

  AdCardAction? _buildPrimaryAction(ApplicationAd ad) {
    final status = ad.status.trim().toLowerCase();

    if (status == 'pending') {
      return AdCardAction(
        label: 'Resume',
        buttonColor: kGreenColor,
        textColor: kWhiteColor,
        processing: _isResumingAd && _resumingAdId == ad.id,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        onPressed: () => _resumeAd(ad),
      );
    }

    if (status == 'active') {
      return AdCardAction(
        label: 'End',
        buttonColor: kRedColor,
        textColor: kWhiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: () {},
      );
    }

    if (status == 'scheduled') {
      return AdCardAction(
        label: 'Pending',
        buttonColor: kPrimaryColor,
        textColor: kWhiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        onPressed: () {},
      );
    }

    if (status == 'cancelled') {
      return AdCardAction(
        label: 'Cancel',
        buttonColor: kPrimaryColor,
        textColor: kWhiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        onPressed: () {},
      );
    }

    return null;
  }

  AdCardAction? _buildSecondaryAction(ApplicationAd ad) {
    final status = ad.status.trim().toLowerCase();

    if (status == 'active' || status == 'pending' || status == 'scheduled' || status == 'cancelled') {
      return AdCardAction(
        label: 'Pause',
        buttonColor: kWhiteColor,
        textColor: kBlackColor,
        showBorder: true,
        borderColor: kGreyColor,
        onPressed: () {},
      );
    }

    return null;
  }

  AdCardAction _buildStatsAction() {
    return AdCardAction(
      label: 'Stats',
      buttonColor: kWhiteColor,
      textColor: kBlackColor,
      showBorder: true,
      borderColor: kGreyColor,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatsPage()),
        );
      },
    );
  }

  Future<void> _resumeAd(ApplicationAd ad) async {
    if (_isResumingAd) return;

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      setState(() {
        _isResumingAd = true;
        _resumingAdId = ad.id;
      });

      final response = await _adsService.resumeAd(
        accessToken: accessToken,
        adId: ad.id,
      );

      if (!mounted) return;
      AppAlert.showSuccess(
        context,
        (response['MESSAGE'] as String?)?.trim().isNotEmpty == true
            ? response['MESSAGE'] as String
            : 'Ad resumed successfully',
      );
      _adsByStatus.remove(_tabs[selectedIndex].status);
      await _loadAdsForSelectedTab(forceRefresh: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to resume ad: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isResumingAd = false;
        _resumingAdId = null;
      });
    }
  }
}

class _AdsStatusTab {
  final String label;
  final String status;

  const _AdsStatusTab({required this.label, required this.status});
}
