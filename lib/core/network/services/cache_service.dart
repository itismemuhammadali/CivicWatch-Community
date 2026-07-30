import 'package:cctv_app/core/storage/local_data_cache.dart';

/// Cache service that provides easy access to local data cache
/// This service wraps LocalDataCache and can be injected into other services
class CacheService {
  final LocalDataCache _cache;

  CacheService({LocalDataCache? cache})
    : _cache = cache ?? const LocalDataCache();

  /// Get active posts from cache or null if expired/not found
  Future<List<Map<String, dynamic>>?> getActivePosts() =>
      _cache.getActivePosts();

  Future<void> cacheActivePosts(List<Map<String, dynamic>>? posts) =>
      _cache.cacheActivePosts(posts);

  /// Get recent posts from cache
  Future<List<Map<String, dynamic>>?> getRecentPosts() =>
      _cache.getRecentPosts();

  Future<void> cacheRecentPosts(List<Map<String, dynamic>>? posts) =>
      _cache.cacheRecentPosts(posts);

  /// Get pending cases from cache
  Future<List<Map<String, dynamic>>?> getPendingCases() =>
      _cache.getPendingCases();

  Future<void> cachePendingCases(List<Map<String, dynamic>>? cases) =>
      _cache.cachePendingCases(cases);

  /// Get approved cases from cache
  Future<List<Map<String, dynamic>>?> getApprovedCases() =>
      _cache.getApprovedCases();

  Future<void> cacheApprovedCases(List<Map<String, dynamic>>? cases) =>
      _cache.cacheApprovedCases(cases);

  /// Get user posts from cache
  Future<List<Map<String, dynamic>>?> getUserPosts(int userId) =>
      _cache.getUserPosts(userId);

  Future<void> cacheUserPosts(int userId, List<Map<String, dynamic>>? posts) =>
      _cache.cacheUserPosts(userId, posts);

  /// Get saved posts from cache
  Future<List<Map<String, dynamic>>?> getSavedPosts() =>
      _cache.getSavedPosts();

  Future<void> cacheSavedPosts(List<Map<String, dynamic>>? posts) =>
      _cache.cacheSavedPosts(posts);

  /// Get active reels from cache
  Future<List<Map<String, dynamic>>?> getActiveReels() =>
      _cache.getActiveReels();

  Future<void> cacheActiveReels(List<Map<String, dynamic>>? reels) =>
      _cache.cacheActiveReels(reels);

  /// Get user reel from cache
  Future<Map<String, dynamic>?> getUserReel(int userId) =>
      _cache.getUserReel(userId);

  Future<void> cacheUserReel(int userId, Map<String, dynamic>? reel) =>
      _cache.cacheUserReel(userId, reel);

  /// Get alerts from cache
  Future<List<Map<String, dynamic>>?> getApplicationAlerts() =>
      _cache.getApplicationAlerts();

  Future<void> cacheApplicationAlerts(List<Map<String, dynamic>>? alerts) =>
      _cache.cacheApplicationAlerts(alerts);

  /// Get ads from cache
  Future<List<Map<String, dynamic>>?> getAdvertisements() =>
      _cache.getAdvertisements();

  Future<void> cacheAdvertisements(List<Map<String, dynamic>>? ads) =>
      _cache.cacheAdvertisements(ads);

  /// Get notifications from cache
  Future<List<Map<String, dynamic>>?> getNotifications() =>
      _cache.getNotifications();

  Future<void> cacheNotifications(List<Map<String, dynamic>>? notifications) =>
      _cache.cacheNotifications(notifications);

  /// Get system data from cache
  Future<List<Map<String, dynamic>>?> getCountries() =>
      _cache.getCountries();

  Future<void> cacheCountries(List<Map<String, dynamic>>? countries) =>
      _cache.cacheCountries(countries);

  Future<List<Map<String, dynamic>>?> getStates() => _cache.getStates();

  Future<void> cacheStates(List<Map<String, dynamic>>? states) =>
      _cache.cacheStates(states);

  Future<List<Map<String, dynamic>>?> getGenders() => _cache.getGenders();

  Future<void> cacheGenders(List<Map<String, dynamic>>? genders) =>
      _cache.cacheGenders(genders);

  Future<List<Map<String, dynamic>>?> getRoles() => _cache.getRoles();

  Future<void> cacheRoles(List<Map<String, dynamic>>? roles) =>
      _cache.cacheRoles(roles);

  /// Get dashboard stats
  Future<Map<String, dynamic>?> getDashboardStats() =>
      _cache.getDashboardStats();

  Future<void> cacheDashboardStats(Map<String, dynamic>? stats) =>
      _cache.cacheDashboardStats(stats);

  /// Cache management
  Future<void> clearAllCache() => _cache.clearAllCache();
  Future<void> clearCasesCache() => _cache.clearCasesCache();
  Future<void> clearPostsCache() => _cache.clearPostsCache();
  Future<void> clearReelsCache() => _cache.clearReelsCache();
  Future<void> clearAdsCache() => _cache.clearAdsCache();

  /// Get cache info
  Future<Map<String, String>> getCacheInfo() => _cache.getCacheInfo();

  /// Sync management
  Future<void> updateLastSyncTime() => _cache.updateLastSyncTime();
  Future<DateTime?> getLastSyncTime() => _cache.getLastSyncTime();
}
