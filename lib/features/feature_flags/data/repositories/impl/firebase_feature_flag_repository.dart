import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../models/feature_flags.dart';
import '../feature_flag_repository.dart';

/// Firebase Remote Config implementation of FeatureFlagRepository.
///
/// This implementation fetches feature flags from Firebase Remote Config
/// and supports real-time updates in debug mode.
class FirebaseFeatureFlagRepository implements FeatureFlagRepository {
  FirebaseFeatureFlagRepository({
    FirebaseRemoteConfig? remoteConfig,
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final _flagsController = StreamController<FeatureFlags>.broadcast();

  FeatureFlags _currentFlags = FeatureFlags.defaults;
  DateTime? _lastFetchTime;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        // Fetch every 12 hours in production, 1 minute in debug
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ));

      // Set default values
      await _remoteConfig.setDefaults(FeatureFlags.defaults.toMap());

      // Fetch and activate on startup
      await fetchAndActivate();

      // Listen for real-time updates (if available)
      _remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint('Remote Config updated, activating...');
        await _remoteConfig.activate();
        _updateFlags();
      });

      _isInitialized = true;
      debugPrint('FirebaseFeatureFlagRepository initialized');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
      // Use defaults if initialization fails
      _currentFlags = FeatureFlags.defaults;
      _isInitialized = true;
    }
  }

  @override
  FeatureFlags get flags => _currentFlags;

  @override
  Stream<FeatureFlags> get flagsStream => _flagsController.stream;

  @override
  Future<bool> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      _lastFetchTime = DateTime.now();
      _updateFlags();
      debugPrint('Remote Config fetched and activated: $activated');
      return activated;
    } catch (e) {
      debugPrint('Error fetching Remote Config: $e');
      return false;
    }
  }

  void _updateFlags() {
    final map = <String, dynamic>{};

    // Extract all values from Remote Config
    for (final key in _remoteConfig.getAll().keys) {
      final value = _remoteConfig.getValue(key);
      switch (value.source) {
        case ValueSource.valueStatic:
        case ValueSource.valueDefault:
        case ValueSource.valueRemote:
          // Try to determine the type from the key name pattern
          if (key.startsWith('enable_') ||
              key.startsWith('force_') ||
              key.endsWith('_mode') ||
              key.endsWith('_enabled')) {
            map[key] = value.asBool();
          } else if (key.endsWith('_limit') ||
              key.endsWith('_days') ||
              key.endsWith('_minutes') ||
              key.endsWith('_threshold') ||
              key.startsWith('max_') ||
              key.startsWith('daily_') ||
              key.startsWith('show_')) {
            map[key] = value.asInt();
          } else if (key.endsWith('_message') || key.endsWith('_version')) {
            map[key] = value.asString();
          } else {
            // Default to string for unknown keys
            map[key] = value.asString();
          }
      }
    }

    _currentFlags = FeatureFlags.fromMap(map);
    _flagsController.add(_currentFlags);
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('FirebaseFeatureFlagRepository: Error getting bool "$key", using default: $e');
      return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('FirebaseFeatureFlagRepository: Error getting int "$key", using default: $e');
      return defaultValue;
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('FirebaseFeatureFlagRepository: Error getting string "$key", using default: $e');
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      debugPrint('FirebaseFeatureFlagRepository: Error getting double "$key", using default: $e');
      return defaultValue;
    }
  }

  @override
  Future<void> forceRefresh() async {
    try {
      // Clear cache by setting minimum fetch interval to 0 temporarily
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ));

      await fetchAndActivate();

      // Reset to normal fetch interval
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ));
    } catch (e) {
      debugPrint('Error force refreshing Remote Config: $e');
    }
  }

  @override
  DateTime? get lastFetchTime => _lastFetchTime;

  @override
  bool get isInitialized => _isInitialized;

  void dispose() {
    _flagsController.close();
  }
}
