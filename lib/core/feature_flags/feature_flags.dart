import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag definitions for the app.
/// Use these to gate features behind flags for:
/// - Premium features
/// - A/B testing
/// - Gradual rollouts
/// - Kill switches
enum FeatureFlag {
  // Premium Features
  unlimitedSwipes('unlimited_swipes', defaultValue: false, isPremium: true),
  unlimitedRewinds('unlimited_rewinds', defaultValue: false, isPremium: true),
  seeWhoLikesYou('see_who_likes_you', defaultValue: false, isPremium: true),
  passport('passport', defaultValue: false, isPremium: true),
  superLikes('super_likes', defaultValue: false, isPremium: true),
  readReceipts('read_receipts', defaultValue: false, isPremium: true),
  priorityLikes('priority_likes', defaultValue: false, isPremium: true),
  advancedFilters('advanced_filters', defaultValue: false, isPremium: true),
  unlimitedMedia('unlimited_media', defaultValue: false, isPremium: true),
  unsendMessages('unsend_messages', defaultValue: false, isPremium: true),

  // A/B Test Features
  newMatchAnimation('new_match_animation', defaultValue: true),
  cardStackPreview('card_stack_preview', defaultValue: false),
  enhancedProfileEditor('enhanced_profile_editor', defaultValue: true),
  videoProfiles('video_profiles', defaultValue: true),
  voiceMessages('voice_messages', defaultValue: true),

  // Rollout Features
  newChatUI('new_chat_ui', defaultValue: false),
  enhancedDiscovery('enhanced_discovery', defaultValue: false),
  socialLogin('social_login', defaultValue: true),
  emailOtp('email_otp', defaultValue: true),
  phoneOtp('phone_otp', defaultValue: true),

  // Kill Switches
  matchingEnabled('matching_enabled', defaultValue: true),
  messagingEnabled('messaging_enabled', defaultValue: true),
  mediaUploadEnabled('media_upload_enabled', defaultValue: true),
  videoCallsEnabled('video_calls_enabled', defaultValue: false),

  // Debug Features (only in debug mode)
  devBypass('dev_bypass', defaultValue: false, debugOnly: true),
  mockData('mock_data', defaultValue: false, debugOnly: true),
  verboseLogging('verbose_logging', defaultValue: false, debugOnly: true);

  const FeatureFlag(
    this.key, {
    required this.defaultValue,
    this.isPremium = false,
    this.debugOnly = false,
  });

  final String key;
  final bool defaultValue;
  final bool isPremium;
  final bool debugOnly;
}

/// Manages feature flags with support for:
/// - Local overrides (for testing)
/// - Remote configuration
/// - User-specific flags (premium)
/// - A/B test variants
class FeatureFlagService {
  static FeatureFlagService? _instance;
  static FeatureFlagService get instance =>
      _instance ??= FeatureFlagService._();

  FeatureFlagService._();

  SharedPreferences? _prefs;
  final Map<String, bool> _localOverrides = {};
  final Map<String, bool> _remoteFlags = {};
  final Map<String, bool> _userFlags = {};
  final _flagChangeController = StreamController<FeatureFlag>.broadcast();

  /// Stream of flag changes for reactive UI updates.
  Stream<FeatureFlag> get onFlagChanged => _flagChangeController.stream;

  /// Initialize the feature flag service.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocalOverrides();
  }

  void _loadLocalOverrides() {
    final overridesJson = _prefs?.getString('feature_flag_overrides');
    if (overridesJson != null) {
      try {
        final overrides = json.decode(overridesJson) as Map<String, dynamic>;
        for (final entry in overrides.entries) {
          if (entry.value is bool) {
            _localOverrides[entry.key] = entry.value as bool;
          }
        }
      } catch (e) {
        AppLogger.error('FeatureFlags: Error parsing local overrides: $e');
      }
    }
  }

  Future<void> _saveLocalOverrides() async {
    await _prefs?.setString(
      'feature_flag_overrides',
      json.encode(_localOverrides),
    );
  }

  /// Check if a feature is enabled.
  bool isEnabled(FeatureFlag flag) {
    // Debug-only flags are always disabled in release
    if (flag.debugOnly && !kDebugMode) {
      return false;
    }

    // Check local overrides first (for testing)
    if (_localOverrides.containsKey(flag.key)) {
      return _localOverrides[flag.key]!;
    }

    // Check user-specific flags (premium status)
    if (_userFlags.containsKey(flag.key)) {
      return _userFlags[flag.key]!;
    }

    // Check remote configuration
    if (_remoteFlags.containsKey(flag.key)) {
      return _remoteFlags[flag.key]!;
    }

    // Fall back to default
    return flag.defaultValue;
  }

  /// Check if any of the given flags are enabled.
  bool isAnyEnabled(List<FeatureFlag> flags) {
    return flags.any((flag) => isEnabled(flag));
  }

  /// Check if all of the given flags are enabled.
  bool areAllEnabled(List<FeatureFlag> flags) {
    return flags.every((flag) => isEnabled(flag));
  }

  /// Set a local override for testing.
  Future<void> setLocalOverride(FeatureFlag flag, bool value) async {
    _localOverrides[flag.key] = value;
    await _saveLocalOverrides();
    _flagChangeController.add(flag);
  }

  /// Remove a local override.
  Future<void> removeLocalOverride(FeatureFlag flag) async {
    _localOverrides.remove(flag.key);
    await _saveLocalOverrides();
    _flagChangeController.add(flag);
  }

  /// Clear all local overrides.
  Future<void> clearLocalOverrides() async {
    final flags = _localOverrides.keys.toList();
    _localOverrides.clear();
    await _saveLocalOverrides();
    for (final key in flags) {
      final flag = FeatureFlag.values.where((f) => f.key == key).firstOrNull;
      if (flag != null) {
        _flagChangeController.add(flag);
      }
    }
  }

  /// Update flags from remote configuration.
  /// Call this after fetching from Firebase Remote Config or similar.
  void updateRemoteFlags(Map<String, bool> flags) {
    for (final entry in flags.entries) {
      final oldValue = _remoteFlags[entry.key];
      if (oldValue != entry.value) {
        _remoteFlags[entry.key] = entry.value;
        final flag =
            FeatureFlag.values.where((f) => f.key == entry.key).firstOrNull;
        if (flag != null) {
          _flagChangeController.add(flag);
        }
      }
    }
  }

  /// Update user-specific flags (e.g., based on subscription).
  void updateUserFlags(Map<String, bool> flags) {
    for (final entry in flags.entries) {
      final oldValue = _userFlags[entry.key];
      if (oldValue != entry.value) {
        _userFlags[entry.key] = entry.value;
        final flag =
            FeatureFlag.values.where((f) => f.key == entry.key).firstOrNull;
        if (flag != null) {
          _flagChangeController.add(flag);
        }
      }
    }
  }

  /// Enable all premium features for a user.
  void enablePremiumFeatures() {
    final premiumFlags = FeatureFlag.values.where((f) => f.isPremium);
    for (final flag in premiumFlags) {
      _userFlags[flag.key] = true;
      _flagChangeController.add(flag);
    }
  }

  /// Disable all premium features for a user.
  void disablePremiumFeatures() {
    final premiumFlags = FeatureFlag.values.where((f) => f.isPremium);
    for (final flag in premiumFlags) {
      _userFlags[flag.key] = false;
      _flagChangeController.add(flag);
    }
  }

  /// Get all currently enabled flags.
  List<FeatureFlag> getEnabledFlags() {
    return FeatureFlag.values.where((flag) => isEnabled(flag)).toList();
  }

  /// Get all premium flags and their status.
  Map<FeatureFlag, bool> getPremiumFlagStatus() {
    return Map.fromEntries(
      FeatureFlag.values
          .where((f) => f.isPremium)
          .map((f) => MapEntry(f, isEnabled(f))),
    );
  }

  /// Dispose resources.
  void dispose() {
    _flagChangeController.close();
  }
}

/// Extension for easy flag checking.
extension FeatureFlagExtension on FeatureFlag {
  bool get isEnabled => FeatureFlagService.instance.isEnabled(this);
}
