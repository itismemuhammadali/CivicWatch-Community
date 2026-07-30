import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local cache storage keys for offline data persistence
class LocalCacheKeys {
  // Cases
  static const pendingCases = 'pending_cases_cache';
  static const approvedCases = 'approved_cases_cache';
  static const caseDetail = 'case_detail_cache_';

  // Posts
  static const activePosts = 'active_posts_cache';
  static const recentPosts = 'recent_posts_cache';
  static const userPosts = 'user_posts_cache_';
  static const savedPosts = 'saved_posts_cache';

  // Reels
  static const activeReels = 'active_reels_cache';
  static const userReel = 'user_reel_cache_';

  // Alerts
  static const applicationAlerts = 'application_alerts_cache';

  // Ads
  static const advertisements = 'advertisements_cache';
  static const adsByCategory = 'ads_by_category_cache_';

  // Notifications
  static const notifications = 'notifications_cache';

  // System Data
  static const countries = 'countries_cache';
  static const states = 'states_cache';
  static const genders = 'genders_cache';
  static const roles = 'roles_cache';

  // Dashboard
  static const dashboardStats = 'dashboard_stats_cache';

  // Metadata
  static const lastSyncTime = 'last_sync_time';
  static const cacheVersion = 'cache_version';

  LocalCacheKeys._();
}

/// Local data cache for offline-first architecture
/// Stores data fetched from mock/backend for offline access
class LocalDataCache {
  final FlutterSecureStorage _storage;
  static const String _cacheVersion = '1.0.0';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  const LocalDataCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Save data to cache with expiration
  Future<void> saveData({
    required String key,
    required List<Map<String, dynamic>>? data,
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    if (data == null) return;

    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(cacheDuration)
          .millisecondsSinceEpoch,
      'version': _cacheVersion,
    };

    try {
      await _storage.write(
        key: key,
        value: jsonEncode(cacheEntry),
      );
    } catch (e) {
      print('Error saving cache for $key: $e');
    }
  }

  /// Save single object to cache
  Future<void> saveSingleData({
    required String key,
    required Map<String, dynamic>? data,
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    if (data == null) return;

    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expires_at': DateTime.now()
          .add(cacheDuration)
          .millisecondsSinceEpoch,
      'version': _cacheVersion,
    };

    try {
      await _storage.write(
        key: key,
        value: jsonEncode(cacheEntry),
      );
    } catch (e) {
      print('Error saving cache for $key: $e');
    }
  }

  /// Retrieve cached data if not expired
  Future<List<Map<String, dynamic>>?> getData(String key) async {
    try {
      final cached = await _storage.read(key: key);
      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final expiresAt = decoded['expires_at'] as int?;

      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Cache expired, delete it
        await _storage.delete(key: key);
        return null;
      }

      final data = decoded['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error reading cache for $key: $e');
      return null;
    }
  }

  /// Retrieve single cached object if not expired
  Future<Map<String, dynamic>?> getSingleData(String key) async {
    try {
      final cached = await _storage.read(key: key);
      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final expiresAt = decoded['expires_at'] as int?;

      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Cache expired, delete it
        await _storage.delete(key: key);
        return null;
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (e) {
      print('Error reading cache for $key: $e');
      return null;
    }
  }

  /// Cache management - Cases
  Future<void> cachePendingCases(List<Map<String, dynamic>>? cases) =>
      saveData(key: LocalCacheKeys.pendingCases, data: cases);

  Future<List<Map<String, dynamic>>?> getPendingCases() =>
      getData(LocalCacheKeys.pendingCases);

  Future<void> cacheApprovedCases(List<Map<String, dynamic>>? cases) =>
      saveData(key: LocalCacheKeys.approvedCases, data: cases);

  Future<List<Map<String, dynamic>>?> getApprovedCases() =>
      getData(LocalCacheKeys.approvedCases);

  /// Cache management - Posts
  Future<void> cacheActivePosts(List<Map<String, dynamic>>? posts) =>
      saveData(key: LocalCacheKeys.activePosts, data: posts);

  Future<List<Map<String, dynamic>>?> getActivePosts() =>
      getData(LocalCacheKeys.activePosts);

  Future<void> cacheRecentPosts(List<Map<String, dynamic>>? posts) =>
      saveData(key: LocalCacheKeys.recentPosts, data: posts);

  Future<List<Map<String, dynamic>>?> getRecentPosts() =>
      getData(LocalCacheKeys.recentPosts);

  Future<void> cacheUserPosts(int userId, List<Map<String, dynamic>>? posts) =>
      saveData(key: '${LocalCacheKeys.userPosts}$userId', data: posts);

  Future<List<Map<String, dynamic>>?> getUserPosts(int userId) =>
      getData('${LocalCacheKeys.userPosts}$userId');

  Future<void> cacheSavedPosts(List<Map<String, dynamic>>? posts) =>
      saveData(key: LocalCacheKeys.savedPosts, data: posts);

  Future<List<Map<String, dynamic>>?> getSavedPosts() =>
      getData(LocalCacheKeys.savedPosts);

  /// Cache management - Reels
  Future<void> cacheActiveReels(List<Map<String, dynamic>>? reels) =>
      saveData(key: LocalCacheKeys.activeReels, data: reels);

  Future<List<Map<String, dynamic>>?> getActiveReels() =>
      getData(LocalCacheKeys.activeReels);

  Future<void> cacheUserReel(int userId, Map<String, dynamic>? reel) =>
      saveSingleData(key: '${LocalCacheKeys.userReel}$userId', data: reel);

  Future<Map<String, dynamic>?> getUserReel(int userId) =>
      getSingleData('${LocalCacheKeys.userReel}$userId');

  /// Cache management - Alerts
  Future<void> cacheApplicationAlerts(List<Map<String, dynamic>>? alerts) =>
      saveData(key: LocalCacheKeys.applicationAlerts, data: alerts);

  Future<List<Map<String, dynamic>>?> getApplicationAlerts() =>
      getData(LocalCacheKeys.applicationAlerts);

  /// Cache management - Ads
  Future<void> cacheAdvertisements(List<Map<String, dynamic>>? ads) =>
      saveData(key: LocalCacheKeys.advertisements, data: ads);

  Future<List<Map<String, dynamic>>?> getAdvertisements() =>
      getData(LocalCacheKeys.advertisements);

  Future<void> cacheAdsByCategory(
      int categoryId, List<Map<String, dynamic>>? ads) =>
      saveData(
          key: '${LocalCacheKeys.adsByCategory}$categoryId', data: ads);

  Future<List<Map<String, dynamic>>?> getAdsByCategory(int categoryId) =>
      getData('${LocalCacheKeys.adsByCategory}$categoryId');

  /// Cache management - Notifications
  Future<void> cacheNotifications(List<Map<String, dynamic>>? notifications) =>
      saveData(key: LocalCacheKeys.notifications, data: notifications);

  Future<List<Map<String, dynamic>>?> getNotifications() =>
      getData(LocalCacheKeys.notifications);

  /// Cache management - System Data
  Future<void> cacheCountries(List<Map<String, dynamic>>? countries) =>
      saveData(
        key: LocalCacheKeys.countries,
        data: countries,
        cacheDuration: const Duration(days: 30), // Longer cache for static data
      );

  Future<List<Map<String, dynamic>>?> getCountries() =>
      getData(LocalCacheKeys.countries);

  Future<void> cacheStates(List<Map<String, dynamic>>? states) =>
      saveData(
        key: LocalCacheKeys.states,
        data: states,
        cacheDuration: const Duration(days: 30),
      );

  Future<List<Map<String, dynamic>>?> getStates() =>
      getData(LocalCacheKeys.states);

  Future<void> cacheGenders(List<Map<String, dynamic>>? genders) =>
      saveData(
        key: LocalCacheKeys.genders,
        data: genders,
        cacheDuration: const Duration(days: 30),
      );

  Future<List<Map<String, dynamic>>?> getGenders() =>
      getData(LocalCacheKeys.genders);

  Future<void> cacheRoles(List<Map<String, dynamic>>? roles) =>
      saveData(
        key: LocalCacheKeys.roles,
        data: roles,
        cacheDuration: const Duration(days: 30),
      );

  Future<List<Map<String, dynamic>>?> getRoles() =>
      getData(LocalCacheKeys.roles);

  /// Cache management - Dashboard
  Future<void> cacheDashboardStats(Map<String, dynamic>? stats) =>
      saveSingleData(key: LocalCacheKeys.dashboardStats, data: stats);

  Future<Map<String, dynamic>?> getDashboardStats() =>
      getSingleData(LocalCacheKeys.dashboardStats);

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final allKeys = [
        LocalCacheKeys.pendingCases,
        LocalCacheKeys.approvedCases,
        LocalCacheKeys.activePosts,
        LocalCacheKeys.recentPosts,
        LocalCacheKeys.savedPosts,
        LocalCacheKeys.activeReels,
        LocalCacheKeys.applicationAlerts,
        LocalCacheKeys.advertisements,
        LocalCacheKeys.notifications,
        LocalCacheKeys.countries,
        LocalCacheKeys.states,
        LocalCacheKeys.genders,
        LocalCacheKeys.roles,
        LocalCacheKeys.dashboardStats,
        LocalCacheKeys.lastSyncTime,
      ];

      for (final key in allKeys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear specific category cache
  Future<void> clearCasesCache() async {
    await _storage.delete(key: LocalCacheKeys.pendingCases);
    await _storage.delete(key: LocalCacheKeys.approvedCases);
  }

  Future<void> clearPostsCache() async {
    await _storage.delete(key: LocalCacheKeys.activePosts);
    await _storage.delete(key: LocalCacheKeys.recentPosts);
    await _storage.delete(key: LocalCacheKeys.savedPosts);
  }

  Future<void> clearReelsCache() async {
    await _storage.delete(key: LocalCacheKeys.activeReels);
  }

  Future<void> clearAdsCache() async {
    await _storage.delete(key: LocalCacheKeys.advertisements);
  }

  /// Get cache size info (for debugging)
  Future<Map<String, String>> getCacheInfo() async {
    try {
      final info = <String, String>{};
      final keys = [
        LocalCacheKeys.pendingCases,
        LocalCacheKeys.activePosts,
        LocalCacheKeys.activeReels,
        LocalCacheKeys.advertisements,
        LocalCacheKeys.notifications,
      ];

      for (final key in keys) {
        final cached = await _storage.read(key: key);
        if (cached != null) {
          final sizeKb = cached.length / 1024;
          info[key] = '${sizeKb.toStringAsFixed(2)} KB';
        }
      }

      return info;
    } catch (e) {
      print('Error getting cache info: $e');
      return {};
    }
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    await _storage.write(
      key: LocalCacheKeys.lastSyncTime,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final syncTime = await _storage.read(key: LocalCacheKeys.lastSyncTime);
      if (syncTime != null) {
        return DateTime.parse(syncTime);
      }
    } catch (e) {
      print('Error reading last sync time: $e');
    }
    return null;
  }
}
