import 'dart:async';
import 'dart:convert';
import 'package:crushhour/core/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/core/constants/cache_constants.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile_prompt.dart';

/// Service for caching profiles and data for offline access.
class OfflineCacheService {
  static const String _profileCacheKey = 'offline_profiles_cache';
  static const String _lastSyncKey = 'offline_last_sync';
  static const String _deckCacheKey = 'offline_deck_cache';
  static const Duration _cacheExpiry = CacheConstants.offlineCacheDuration;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;

  /// Stream of connectivity status changes.
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current online status.
  bool get isOnline => _isOnline;

  /// Updates the connectivity status.
  void updateConnectivity(bool isOnline) {
    _isOnline = isOnline;
    _connectivityController.add(isOnline);
  }

  /// Caches a profile for offline access.
  Future<void> cacheProfile(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);

      cachedProfiles[profile.id] = _CachedProfile(
        profile: profile,
        cachedAt: DateTime.now(),
      );

      await _saveCachedProfiles(prefs, cachedProfiles);
      AppLogger.debug('[OfflineCache] Cached profile: ${profile.id}');
    } catch (e) {
      AppLogger.error('[OfflineCache] Error caching profile: $e');
    }
  }

  /// Caches multiple profiles at once.
  Future<void> cacheProfiles(List<Profile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);

      for (final profile in profiles) {
        cachedProfiles[profile.id] = _CachedProfile(
          profile: profile,
          cachedAt: DateTime.now(),
        );
      }

      await _saveCachedProfiles(prefs, cachedProfiles);
      AppLogger.debug('[OfflineCache] Cached ${profiles.length} profiles');
    } catch (e) {
      AppLogger.error('[OfflineCache] Error caching profiles: $e');
    }
  }

  /// Retrieves a cached profile by user ID.
  Future<Profile?> getCachedProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);
      final cached = cachedProfiles[userId];

      if (cached != null && !_isExpired(cached.cachedAt)) {
        AppLogger.debug('[OfflineCache] Retrieved cached profile: $userId');
        return cached.profile;
      }
    } catch (e) {
      AppLogger.error('[OfflineCache] Error retrieving cached profile: $e');
    }
    return null;
  }

  /// Retrieves all valid cached profiles.
  Future<List<Profile>> getAllCachedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);

      return cachedProfiles.values
          .where((cached) => !_isExpired(cached.cachedAt))
          .map((cached) => cached.profile)
          .toList();
    } catch (e) {
      AppLogger.error('[OfflineCache] Error retrieving all cached profiles: $e');
    }
    return [];
  }

  /// Caches deck profiles for offline swiping.
  Future<void> cacheDeckProfiles(List<Profile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final deckCache = profiles
          .map((p) => _CachedProfile(
                profile: p,
                cachedAt: DateTime.now(),
              ))
          .toList();

      final jsonList = deckCache.map((c) => c.toJson()).toList();
      await prefs.setString(_deckCacheKey, jsonEncode(jsonList));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      AppLogger.debug('[OfflineCache] Cached ${profiles.length} deck profiles');
    } catch (e) {
      AppLogger.error('[OfflineCache] Error caching deck profiles: $e');
    }
  }

  /// Retrieves cached deck profiles for offline swiping.
  Future<List<Profile>> getCachedDeckProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_deckCacheKey);

      if (jsonStr == null) return [];

      final jsonList = jsonDecode(jsonStr) as List;
      final cachedList = jsonList
          .map((j) => _CachedProfile.fromJson(j as Map<String, dynamic>))
          .where((cached) => !_isExpired(cached.cachedAt))
          .map((cached) => cached.profile)
          .toList();

      AppLogger.debug('[OfflineCache] Retrieved ${cachedList.length} deck profiles');
      return cachedList;
    } catch (e) {
      AppLogger.error('[OfflineCache] Error retrieving deck profiles: $e');
    }
    return [];
  }

  /// Gets the last sync time.
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncStr = prefs.getString(_lastSyncKey);
      if (syncStr != null) {
        return DateTime.parse(syncStr);
      }
    } catch (e) {
      AppLogger.error('[OfflineCache] Error getting last sync time: $e');
    }
    return null;
  }

  /// Removes a profile from cache.
  Future<void> removeFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);

      cachedProfiles.remove(userId);
      await _saveCachedProfiles(prefs, cachedProfiles);

      AppLogger.debug('[OfflineCache] Removed profile from cache: $userId');
    } catch (e) {
      AppLogger.error('[OfflineCache] Error removing from cache: $e');
    }
  }

  /// Clears all cached data.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
      await prefs.remove(_deckCacheKey);
      await prefs.remove(_lastSyncKey);

      AppLogger.debug('[OfflineCache] Cache cleared');
    } catch (e) {
      AppLogger.error('[OfflineCache] Error clearing cache: $e');
    }
  }

  /// Cleans up expired cache entries.
  Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);

      final validProfiles = <String, _CachedProfile>{};
      for (final entry in cachedProfiles.entries) {
        if (!_isExpired(entry.value.cachedAt)) {
          validProfiles[entry.key] = entry.value;
        }
      }

      if (validProfiles.length != cachedProfiles.length) {
        await _saveCachedProfiles(prefs, validProfiles);
        AppLogger.debug(
            '[OfflineCache] Cleaned up ${cachedProfiles.length - validProfiles.length} expired entries');
      }
    } catch (e) {
      AppLogger.error('[OfflineCache] Error cleaning up cache: $e');
    }
  }

  /// Returns cache statistics.
  Future<CacheStats> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfiles = await _getCachedProfiles(prefs);
      final deckJson = prefs.getString(_deckCacheKey);
      final lastSync = await getLastSyncTime();

      int deckCount = 0;
      if (deckJson != null) {
        final jsonList = jsonDecode(deckJson) as List;
        deckCount = jsonList.length;
      }

      return CacheStats(
        profileCount: cachedProfiles.length,
        deckProfileCount: deckCount,
        lastSyncTime: lastSync,
      );
    } catch (e) {
      AppLogger.error('[OfflineCache] Error getting cache stats: $e');
    }
    return const CacheStats(profileCount: 0, deckProfileCount: 0);
  }

  bool _isExpired(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) > _cacheExpiry;
  }

  Future<Map<String, _CachedProfile>> _getCachedProfiles(
      SharedPreferences prefs) async {
    final jsonStr = prefs.getString(_profileCacheKey);
    if (jsonStr == null) return {};

    try {
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return jsonMap.map((key, value) => MapEntry(
          key, _CachedProfile.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveCachedProfiles(
      SharedPreferences prefs, Map<String, _CachedProfile> profiles) async {
    final jsonMap = profiles.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_profileCacheKey, jsonEncode(jsonMap));
  }

  void dispose() {
    _connectivityController.close();
  }
}

/// Internal class for cached profile with timestamp.
class _CachedProfile {
  final Profile profile;
  final DateTime cachedAt;

  _CachedProfile({
    required this.profile,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'profile': _profileToJson(profile),
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory _CachedProfile.fromJson(Map<String, dynamic> json) {
    return _CachedProfile(
      profile: _profileFromJson(json['profile'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  static Map<String, dynamic> _profileToJson(Profile p) => {
        'id': p.id,
        'name': p.name,
        'lastName': p.lastName,
        'age': p.age,
        'gender': p.gender,
        'sexualOrientation': p.sexualOrientation,
        'dateOfBirth': p.dateOfBirth?.toIso8601String(),
        'photoUrls': p.photoUrls,
        'videoUrls': p.videoUrls,
        'primaryPhotoIndex': p.primaryPhotoIndex,
        'bio': p.bio,
        'interests': p.interests,
        'profilePrompts': p.profilePrompts
            .map((pp) => {'questionId': pp.questionId, 'answer': pp.answer})
            .toList(),
        'heightCm': p.heightCm,
        'relationshipGoals': p.relationshipGoals,
        'languages': p.languages,
        'zodiacSign': p.zodiacSign,
        'educationLevel': p.educationLevel,
        'familyPlans': p.familyPlans,
        'personalityType': p.personalityType,
        'religion': p.religion,
        'workout': p.workout,
        'smoking': p.smoking,
        'drinking': p.drinking,
        'pets': p.pets,
        'jobTitle': p.jobTitle,
        'company': p.company,
        'school': p.school,
        'country': p.country,
        'city': p.city,
        'livingIn': p.livingIn,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'distance': p.distance,
        'distanceUnit': p.distanceUnit,
        'isVerified': p.isVerified,
        'verificationBadge': p.verificationBadge,
        'privacySettings': p.privacySettings.toJson(),
      };

  static Profile _profileFromJson(Map<String, dynamic> json) {
    final prompts = (json['profilePrompts'] as List<dynamic>?)
            ?.map((p) => ProfilePrompt(
                  questionId: p['questionId'] as String? ?? '',
                  answer: p['answer'] as String? ?? '',
                ))
            .toList() ??
        [];

    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      lastName: json['lastName'] as String?,
      age: json['age'] as int,
      gender: json['gender'] as String,
      sexualOrientation: json['sexualOrientation'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      primaryPhotoIndex: json['primaryPhotoIndex'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      profilePrompts: prompts,
      heightCm: json['heightCm'] as int?,
      relationshipGoals: json['relationshipGoals'] as String?,
      languages: List<String>.from(json['languages'] ?? []),
      zodiacSign: json['zodiacSign'] as String?,
      educationLevel: json['educationLevel'] as String?,
      familyPlans: json['familyPlans'] as String?,
      personalityType: json['personalityType'] as String?,
      religion: json['religion'] as String?,
      workout: json['workout'] as String?,
      smoking: json['smoking'] as String?,
      drinking: json['drinking'] as String?,
      pets: json['pets'] as String?,
      jobTitle: json['jobTitle'] as String?,
      company: json['company'] as String?,
      school: json['school'] as String?,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      livingIn: json['livingIn'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      distanceUnit: json['distanceUnit'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationBadge: json['verificationBadge'] as String?,
      preferences: DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 100,
        showMeGenders: const ['all'],
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: json['country'] as String? ?? '',
        city: json['city'] as String? ?? '',
      ),
      privacySettings: ProfilePrivacySettings.fromJson(
        json['privacySettings'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Statistics about the offline cache.
class CacheStats {
  final int profileCount;
  final int deckProfileCount;
  final DateTime? lastSyncTime;

  const CacheStats({
    required this.profileCount,
    required this.deckProfileCount,
    this.lastSyncTime,
  });

  String get lastSyncLabel {
    if (lastSyncTime == null) return 'Never';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
