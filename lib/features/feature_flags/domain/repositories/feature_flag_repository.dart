import 'package:crushhour/features/feature_flags/data/models/feature_flags.dart';

/// Repository interface for managing feature flags.
///
/// This abstraction allows switching between Firebase Remote Config
/// and stub implementations for development/testing.
abstract class FeatureFlagRepository {
  /// Initialize the feature flag service.
  /// Should be called during app startup.
  Future<void> initialize();

  /// Get the current feature flags.
  FeatureFlags get flags;

  /// Stream of feature flag updates.
  /// Emits whenever flags are updated from the remote source.
  Stream<FeatureFlags> get flagsStream;

  /// Fetch the latest flags from the remote source.
  /// Returns true if fetch was successful.
  Future<bool> fetchAndActivate();

  /// Get a specific boolean flag value.
  bool getBool(String key, {bool defaultValue = false});

  /// Get a specific integer flag value.
  int getInt(String key, {int defaultValue = 0});

  /// Get a specific string flag value.
  String getString(String key, {String defaultValue = ''});

  /// Get a specific double flag value.
  double getDouble(String key, {double defaultValue = 0.0});

  /// Force refresh flags from remote.
  Future<void> forceRefresh();

  /// Get the last fetch time.
  DateTime? get lastFetchTime;

  /// Check if flags have been loaded.
  bool get isInitialized;
}
