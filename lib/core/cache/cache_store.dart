import 'dart:async';
import 'dart:collection';
import 'cache_policy.dart';

/// Abstract interface for cache storage.
/// Can be implemented with in-memory, SharedPreferences, SQLite, etc.
abstract class CacheStore {
  /// Get a value from cache.
  Future<CacheEntry<T>?> get<T>(String key);

  /// Put a value in cache.
  Future<void> put<T>(String key, T value, CacheConfig config);

  /// Remove a value from cache.
  Future<void> remove(String key);

  /// Remove all entries matching a prefix.
  Future<void> removeByPrefix(String prefix);

  /// Clear all cached data.
  Future<void> clear();

  /// Check if a key exists and is valid.
  Future<bool> hasValid(String key);
}

/// In-memory cache store with LRU eviction.
/// Suitable for session-scoped caching.
class MemoryCacheStore implements CacheStore {
  final int _maxEntries;
  final LinkedHashMap<String, _CacheBox> _cache = LinkedHashMap();

  MemoryCacheStore({int maxEntries = 100}) : _maxEntries = maxEntries;

  @override
  Future<CacheEntry<T>?> get<T>(String key) async {
    final box = _cache[key];
    if (box == null) return null;

    // Move to end for LRU
    _cache.remove(key);
    _cache[key] = box;

    return CacheEntry<T>(
      data: box.data as T,
      cachedAt: box.cachedAt,
      maxAge: box.maxAge,
    );
  }

  @override
  Future<void> put<T>(String key, T value, CacheConfig config) async {
    // Evict oldest if at capacity
    while (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheBox(
      data: value,
      cachedAt: DateTime.now(),
      maxAge: config.maxAge,
    );
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> removeByPrefix(String prefix) async {
    final keysToRemove = _cache.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  Future<bool> hasValid(String key) async {
    final entry = await get<dynamic>(key);
    return entry?.isValid ?? false;
  }

  /// Get current cache size.
  int get size => _cache.length;

  /// Get all cached keys.
  Iterable<String> get keys => _cache.keys;
}

class _CacheBox {
  final dynamic data;
  final DateTime cachedAt;
  final Duration maxAge;

  _CacheBox({required this.data, required this.cachedAt, required this.maxAge});
}
