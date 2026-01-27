/// Cache duration constants for consistent data freshness.
///
/// Centralizes all cache TTL (Time To Live) values to ensure
/// consistent caching behavior across the app.
class CacheConstants {
  CacheConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // OFFLINE CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default duration for offline cache entries.
  static const Duration offlineCacheDuration = Duration(hours: 24);

  /// Duration for profile data cache.
  static const Duration profileCacheDuration = Duration(hours: 24);

  /// Duration for discovery deck cache.
  static const Duration discoveryCacheDuration = Duration(hours: 1);

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Duration for cached images.
  static const Duration imageCacheDuration = Duration(days: 7);

  /// Maximum number of cached images.
  static const int maxCachedImages = 200;

  /// Maximum size of image cache in bytes (100 MB).
  static const int maxImageCacheSizeBytes = 100 * 1024 * 1024;

  // ═══════════════════════════════════════════════════════════════════════════
  // API RESPONSE CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Duration for API response cache.
  static const Duration apiCacheDuration = Duration(minutes: 5);

  /// Duration for user profile API cache.
  static const Duration userProfileCacheDuration = Duration(minutes: 15);

  /// Duration for settings/preferences cache.
  static const Duration settingsCacheDuration = Duration(hours: 1);

  /// Duration for static content cache (e.g., prompt questions).
  static const Duration staticContentCacheDuration = Duration(days: 1);

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default duration for stories (24 hours).
  static const Duration storyDuration = Duration(hours: 24);

  /// Duration for story media cache.
  static const Duration storyMediaCacheDuration = Duration(hours: 24);

  // ═══════════════════════════════════════════════════════════════════════════
  // RATE LIMITING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Debounce delay for search inputs.
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);

  /// Throttle delay for scroll events.
  static const Duration scrollThrottleDelay = Duration(milliseconds: 100);

  /// Delay between location update requests.
  static const Duration locationUpdateDelay = Duration(minutes: 5);

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Interval for cache cleanup checks.
  static const Duration cacheCleanupInterval = Duration(hours: 6);

  /// Maximum age for cache entries before cleanup.
  static const Duration maxCacheAge = Duration(days: 7);
}
