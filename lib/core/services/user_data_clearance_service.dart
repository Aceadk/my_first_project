import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/security/biometric_service.dart';
import 'package:crushhour/core/security/session_manager.dart';
import 'package:crushhour/core/services/app_state_preserver.dart';
import 'package:crushhour/shared/widgets/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to clear all user-specific data on logout.
///
/// This is CRITICAL for security - prevents next user from seeing
/// previous user's data (profile, chats, matches, preferences).
class UserDataClearanceService {
  UserDataClearanceService._();
  static final instance = UserDataClearanceService._();

  /// All SharedPreferences keys that contain user-specific data.
  /// These MUST be cleared on logout to prevent data leakage.
  static const List<String> _userSpecificKeys = [
    // Safety settings (blocked users, muted users, reports)
    'safety_blocked',
    'safety_muted_messages',
    'safety_muted_calls',
    'safety_reported_users',

    // Privacy settings
    'privacy_settings',

    // Discovery preferences (age filters, location, etc.)
    'discovery_distance_km',
    'discovery_min_age',
    'discovery_max_age',
    'discovery_interests',
    'discovery_show_distance',
    'discovery_visible',
    'discovery_passport_enabled',
    'discovery_passport_location',
    'discovery_passport_lat',
    'discovery_passport_lng',
    'discovery_min_height_cm',
    'discovery_max_height_cm',
    'discovery_education_levels',
    'discovery_relationship_goals',
    'discovery_verified_only',
    'discovery_language_filters',
    'discovery_smoking_filter',
    'discovery_drinking_filter',
    'discovery_exercise_filter',
    'discovery_pets_filter',
    'discovery_family_plans_filter',
    'discovery_zodiac_filter',
    'discovery_religion_filter',

    // Locale settings (user-specific location)
    'locale_latitude',
    'locale_longitude',

    // DB-002: Offline queue and cache storage (critical for data isolation)
    'offline_action_queue',
    'offline_profile_cache',
    'offline_deck_cache',
    'offline_deck_cached_at',
  ];

  /// Clear all user-specific data from the device.
  /// Call this on logout BEFORE navigating away.
  Future<void> clearAllUserData() async {
    // 1. Clear SharedPreferences user-specific keys
    await _clearSharedPreferences();

    // 2. Clear secure-storage artifacts that can restore user-specific state
    await _clearSecureSessionArtifacts();

    // 3. Clear image cache (profile photos, match photos)
    _clearImageCache();
  }

  /// Clear user-specific keys from SharedPreferences.
  Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in _userSpecificKeys) {
      await prefs.remove(key);
    }
  }

  /// Clear the in-memory image cache.
  void _clearImageCache() {
    NetworkImageCache.instance.clear();
  }

  Future<void> _clearSecureSessionArtifacts() async {
    await Future.wait([
      _clearBestEffort(
        'session timeout state',
        SessionManager.instance.clearSession,
      ),
      _clearBestEffort(
        'preserved app route',
        AppStatePreserver.instance.clearPreservedRoute,
      ),
      _clearBestEffort(
        'biometric credentials',
        BiometricService.instance.clear,
      ),
    ]);
  }

  Future<void> _clearBestEffort(
    String label,
    Future<void> Function() clear,
  ) async {
    try {
      await clear();
    } catch (error, stackTrace) {
      AppLogger.error(
        'UserDataClearanceService: failed to clear $label',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
