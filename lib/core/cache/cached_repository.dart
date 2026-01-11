import 'dart:async';
import 'cache_policy.dart';
import 'cache_store.dart';

/// Mixin that adds caching capabilities to a repository.
///
/// Usage:
/// ```dart
/// class CachedProfileRepository extends ProfileRepository with CachingMixin {
///   CachedProfileRepository(this._delegate, CacheStore store) {
///     initCache(store);
///   }
/// }
/// ```
mixin CachingMixin {
  late final CacheStore _cacheStore;

  void initCache(CacheStore store) {
    _cacheStore = store;
  }

  /// Execute a cached operation.
  ///
  /// [key] - Unique cache key for this operation
  /// [fetch] - Function to fetch fresh data
  /// [policy] - Caching policy to use
  /// [config] - Cache configuration
  Future<T> cached<T>({
    required String key,
    required Future<T> Function() fetch,
    CachePolicy policy = CachePolicy.cacheFirst,
    CacheConfig config = CacheConfig.standard,
  }) async {
    switch (policy) {
      case CachePolicy.networkOnly:
        return _fetchAndCache(key, fetch, config);

      case CachePolicy.cacheOnly:
        final cached = await _cacheStore.get<T>(key);
        if (cached != null) return cached.data;
        throw CacheMissException(key);

      case CachePolicy.cacheFirst:
        final cached = await _cacheStore.get<T>(key);
        if (cached != null && cached.isValid) {
          // Refresh in background if configured and stale
          if (config.refreshInBackground && cached.isStale) {
            _fetchAndCache(key, fetch, config);
          }
          return cached.data;
        }
        return _fetchAndCache(key, fetch, config);

      case CachePolicy.networkFirst:
        try {
          return await _fetchAndCache(key, fetch, config);
        } catch (_) {
          final cached = await _cacheStore.get<T>(key);
          if (cached != null) return cached.data;
          rethrow;
        }

      case CachePolicy.cacheAndNetwork:
        // This should be handled by the caller with streams
        // For simple Future API, behave like networkFirst
        try {
          return await _fetchAndCache(key, fetch, config);
        } catch (_) {
          final cached = await _cacheStore.get<T>(key);
          if (cached != null) return cached.data;
          rethrow;
        }
    }
  }

  Future<T> _fetchAndCache<T>(
    String key,
    Future<T> Function() fetch,
    CacheConfig config,
  ) async {
    final data = await fetch();
    await _cacheStore.put<T>(key, data, config);
    return data;
  }

  /// Invalidate a specific cache key.
  Future<void> invalidate(String key) => _cacheStore.remove(key);

  /// Invalidate all cache entries with a given prefix.
  Future<void> invalidateByPrefix(String prefix) =>
      _cacheStore.removeByPrefix(prefix);

  /// Clear all cache.
  Future<void> clearCache() => _cacheStore.clear();
}

/// Exception thrown when cache-only access fails.
class CacheMissException implements Exception {
  final String key;
  CacheMissException(this.key);

  @override
  String toString() => 'CacheMissException: No cached data for key "$key"';
}

/// Helper to generate cache keys.
class CacheKeys {
  static String profile(String userId) => 'profile:$userId';
  static String deck(String userId) => 'deck:$userId';
  static String matches(String userId) => 'matches:$userId';
  static String messages(String matchId) => 'messages:$matchId';
  static String user(String userId) => 'user:$userId';
  static String subscription(String userId) => 'subscription:$userId';
}
