/// Defines caching policies for data fetching.
enum CachePolicy {
  /// Always fetch from network, ignore cache.
  networkOnly,

  /// Try cache first, fall back to network if cache miss or expired.
  cacheFirst,

  /// Try network first, fall back to cache if network fails.
  networkFirst,

  /// Return cache immediately, then fetch network and update.
  /// Best for real-time data that benefits from immediate display.
  cacheAndNetwork,

  /// Only use cache, never hit network.
  cacheOnly,
}

/// Configuration for cache entries.
class CacheConfig {
  /// How long cached data remains valid.
  final Duration maxAge;

  /// Whether to refresh cache in background when stale but valid.
  final bool refreshInBackground;

  /// Maximum number of items to keep in memory cache.
  final int maxMemoryItems;

  const CacheConfig({
    this.maxAge = const Duration(minutes: 5),
    this.refreshInBackground = true,
    this.maxMemoryItems = 100,
  });

  /// Short-lived cache for frequently changing data.
  static const shortLived = CacheConfig(
    maxAge: Duration(minutes: 1),
    refreshInBackground: true,
  );

  /// Standard cache for most data.
  static const standard = CacheConfig(
    maxAge: Duration(minutes: 5),
    refreshInBackground: true,
  );

  /// Long-lived cache for stable data.
  static const longLived = CacheConfig(
    maxAge: Duration(hours: 1),
    refreshInBackground: false,
  );

  /// Persistent cache for rarely changing data.
  static const persistent = CacheConfig(
    maxAge: Duration(days: 1),
    refreshInBackground: false,
  );
}

/// Represents a cached entry with metadata.
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration maxAge;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.maxAge,
  });

  /// Check if the cache entry is still valid.
  bool get isValid => DateTime.now().difference(cachedAt) < maxAge;

  /// Check if the cache entry is stale but could be used as fallback.
  bool get isStale => !isValid;

  /// Time until this entry expires.
  Duration get timeToExpiry {
    final elapsed = DateTime.now().difference(cachedAt);
    final remaining = maxAge - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
