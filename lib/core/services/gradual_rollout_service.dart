import 'dart:math';

import 'package:crushhour/core/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for gradual feature rollouts based on user cohorts.
///
/// Features:
/// - Percentage-based rollout
/// - Consistent bucketing (same user always in same bucket)
/// - A/B testing support
/// - User segmentation
class GradualRolloutService {
  GradualRolloutService._();

  static final GradualRolloutService instance = GradualRolloutService._();

  static const String _bucketKey = 'rollout_bucket';
  static const String _userIdKey = 'rollout_user_id';

  SharedPreferences? _prefs;
  int? _bucket;
  String? _userId;
  bool _isInitialized = false;

  /// Initialize the service.
  /// Call this after SharedPreferences is available.
  Future<void> initialize(SharedPreferences prefs) async {
    if (_isInitialized) return;

    _prefs = prefs;

    // Get or create a persistent bucket for this user
    _bucket = _prefs!.getInt(_bucketKey);
    if (_bucket == null) {
      _bucket = Random().nextInt(100);
      await _prefs!.setInt(_bucketKey, _bucket!);
    }

    // Get or create a persistent user ID for rollouts
    _userId = _prefs!.getString(_userIdKey);
    if (_userId == null) {
      _userId = _generateUserId();
      await _prefs!.setString(_userIdKey, _userId!);
    }

    _isInitialized = true;
    AppLogger.debug('GradualRolloutService: Initialized - bucket $_bucket');
  }

  String _generateUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(1000000);
    return '${timestamp}_$randomPart';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERCENTAGE-BASED ROLLOUT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if a feature should be enabled based on rollout percentage.
  ///
  /// [featureName] is used to create consistent bucketing per feature.
  /// [percentage] is 0-100 representing the rollout percentage.
  ///
  /// Example:
  /// ```dart
  /// if (GradualRolloutService.instance.isEnabledForPercentage('new_feature', 25)) {
  ///   // Feature enabled for this user (25% rollout)
  /// }
  /// ```
  bool isEnabledForPercentage(String featureName, int percentage) {
    if (!_isInitialized || _bucket == null) return false;
    if (percentage <= 0) return false;
    if (percentage >= 100) return true;

    // Use feature-specific bucketing for independent rollouts
    final featureBucket = _getFeatureBucket(featureName);
    return featureBucket < percentage;
  }

  /// Get the bucket for a specific feature (0-99).
  /// This ensures each feature has independent rollout.
  int _getFeatureBucket(String featureName) {
    // Combine user bucket with feature name hash for feature-specific bucketing
    final hash = featureName.hashCode.abs();
    return (_bucket! + hash) % 100;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // A/B TESTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get which variant the user is in for an A/B test.
  ///
  /// [experimentName] is the name of the experiment.
  /// [variants] is the list of variant names (e.g., ['control', 'variant_a', 'variant_b']).
  ///
  /// Returns the variant name this user is assigned to.
  String getVariant(String experimentName, List<String> variants) {
    if (!_isInitialized || variants.isEmpty) {
      return variants.isNotEmpty ? variants.first : 'control';
    }

    final bucket = _getFeatureBucket(experimentName);
    final index = bucket % variants.length;
    return variants[index];
  }

  /// Check if user is in a specific variant.
  bool isInVariant(
    String experimentName,
    String variant,
    List<String> variants,
  ) {
    return getVariant(experimentName, variants) == variant;
  }

  /// Get A/B test weights for weighted distribution.
  ///
  /// [experimentName] is the name of the experiment.
  /// [weights] maps variant names to their weights (0-100, should sum to 100).
  ///
  /// Example:
  /// ```dart
  /// final variant = getWeightedVariant('checkout_flow', {
  ///   'control': 50,
  ///   'variant_a': 30,
  ///   'variant_b': 20,
  /// });
  /// ```
  String getWeightedVariant(String experimentName, Map<String, int> weights) {
    if (!_isInitialized || weights.isEmpty) {
      return weights.keys.first;
    }

    final bucket = _getFeatureBucket(experimentName);

    int cumulative = 0;
    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (bucket < cumulative) {
        return entry.key;
      }
    }

    return weights.keys.last;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER SEGMENTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if feature is enabled based on user attributes.
  ///
  /// [featureName] is the feature being checked.
  /// [rules] define the targeting rules.
  bool isEnabledForUser(
    String featureName, {
    required RolloutRules rules,
    String? userId,
    DateTime? userCreatedAt,
    bool? isPremium,
    String? country,
    String? appVersion,
  }) {
    // Check percentage rollout first
    if (rules.percentage != null && rules.percentage! < 100) {
      if (!isEnabledForPercentage(featureName, rules.percentage!)) {
        return false;
      }
    }

    // Check user whitelist
    if (rules.whitelistedUserIds != null && userId != null) {
      if (rules.whitelistedUserIds!.contains(userId)) {
        return true;
      }
    }

    // Check user blacklist
    if (rules.blacklistedUserIds != null && userId != null) {
      if (rules.blacklistedUserIds!.contains(userId)) {
        return false;
      }
    }

    // Check premium requirement
    if (rules.premiumOnly == true && isPremium != true) {
      return false;
    }

    // Check new users only
    if (rules.newUsersOnly == true && userCreatedAt != null) {
      final now = DateTime.now();
      final daysSinceCreation = now.difference(userCreatedAt).inDays;
      if (daysSinceCreation > (rules.newUserDaysThreshold ?? 7)) {
        return false;
      }
    }

    // Check country targeting
    if (rules.countries != null && rules.countries!.isNotEmpty) {
      if (country == null || !rules.countries!.contains(country)) {
        return false;
      }
    }

    // Check minimum app version
    if (rules.minAppVersion != null && appVersion != null) {
      if (_compareVersions(appVersion, rules.minAppVersion!) < 0) {
        return false;
      }
    }

    return true;
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLength = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the user's current bucket (0-99).
  int get bucket => _bucket ?? 0;

  /// Get the user's rollout ID.
  String get userId => _userId ?? '';

  /// Check if service is initialized.
  bool get isInitialized => _isInitialized;

  /// Reset the bucket (for testing purposes).
  Future<void> resetBucket() async {
    if (_prefs == null) return;

    _bucket = Random().nextInt(100);
    await _prefs!.setInt(_bucketKey, _bucket!);
  }

  /// Force a specific bucket (for testing purposes).
  Future<void> setBucket(int bucket) async {
    if (_prefs == null) return;

    _bucket = bucket.clamp(0, 99);
    await _prefs!.setInt(_bucketKey, _bucket!);
  }
}

/// Rules for targeted feature rollout.
class RolloutRules {
  const RolloutRules({
    this.percentage,
    this.whitelistedUserIds,
    this.blacklistedUserIds,
    this.premiumOnly,
    this.newUsersOnly,
    this.newUserDaysThreshold,
    this.countries,
    this.minAppVersion,
  });

  /// Percentage of users to enable (0-100).
  final int? percentage;

  /// User IDs that should always have the feature.
  final List<String>? whitelistedUserIds;

  /// User IDs that should never have the feature.
  final List<String>? blacklistedUserIds;

  /// Only enable for premium users.
  final bool? premiumOnly;

  /// Only enable for new users.
  final bool? newUsersOnly;

  /// Days threshold for "new user" definition.
  final int? newUserDaysThreshold;

  /// Countries to enable for (ISO codes).
  final List<String>? countries;

  /// Minimum app version required.
  final String? minAppVersion;
}
