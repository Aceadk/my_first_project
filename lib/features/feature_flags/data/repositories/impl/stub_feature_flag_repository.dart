import 'dart:async';
import 'package:crushhour/core/app_logger.dart';
import '../../models/feature_flags.dart';
import '../feature_flag_repository.dart';

/// Stub implementation of FeatureFlagRepository for development/testing.
///
/// This implementation uses local defaults and allows overriding flags
/// programmatically for testing different configurations.
class StubFeatureFlagRepository implements FeatureFlagRepository {
  StubFeatureFlagRepository({
    FeatureFlags? initialFlags,
  }) : _currentFlags = initialFlags ?? FeatureFlags.defaults;

  FeatureFlags _currentFlags;
  final _flagsController = StreamController<FeatureFlags>.broadcast();
  DateTime? _lastFetchTime;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    _lastFetchTime = DateTime.now();
    _flagsController.add(_currentFlags);
    AppLogger.debug('StubFeatureFlagRepository initialized with defaults');
  }

  @override
  FeatureFlags get flags => _currentFlags;

  @override
  Stream<FeatureFlags> get flagsStream => _flagsController.stream;

  @override
  Future<bool> fetchAndActivate() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    _lastFetchTime = DateTime.now();
    _flagsController.add(_currentFlags);
    return true;
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final map = _currentFlags.toMap();
    return map[key] as bool? ?? defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final map = _currentFlags.toMap();
    return map[key] as int? ?? defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final map = _currentFlags.toMap();
    return map[key] as String? ?? defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    final map = _currentFlags.toMap();
    final value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return defaultValue;
  }

  @override
  Future<void> forceRefresh() async {
    await fetchAndActivate();
  }

  @override
  DateTime? get lastFetchTime => _lastFetchTime;

  @override
  bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════════════════════════════════
  // STUB-SPECIFIC METHODS FOR TESTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update flags programmatically (for testing)
  void setFlags(FeatureFlags flags) {
    _currentFlags = flags;
    _flagsController.add(_currentFlags);
  }

  /// Update a single boolean flag (for testing)
  void setBool(String key, bool value) {
    final map = _currentFlags.toMap();
    map[key] = value;
    _currentFlags = FeatureFlags.fromMap(map);
    _flagsController.add(_currentFlags);
  }

  /// Update a single integer flag (for testing)
  void setInt(String key, int value) {
    final map = _currentFlags.toMap();
    map[key] = value;
    _currentFlags = FeatureFlags.fromMap(map);
    _flagsController.add(_currentFlags);
  }

  /// Update a single string flag (for testing)
  void setString(String key, String value) {
    final map = _currentFlags.toMap();
    map[key] = value;
    _currentFlags = FeatureFlags.fromMap(map);
    _flagsController.add(_currentFlags);
  }

  /// Reset to default flags
  void reset() {
    _currentFlags = FeatureFlags.defaults;
    _flagsController.add(_currentFlags);
  }

  /// Simulate maintenance mode
  void setMaintenanceMode(bool enabled, {String? message}) {
    _currentFlags = _currentFlags.copyWith(
      maintenanceMode: enabled,
      maintenanceMessage: message ?? 'App is under maintenance',
    );
    _flagsController.add(_currentFlags);
  }

  /// Simulate force update requirement
  void setForceUpdate(bool enabled, {String? message, String? minVersion}) {
    _currentFlags = _currentFlags.copyWith(
      forceUpdate: enabled,
      forceUpdateMessage: message ?? 'Please update the app',
      minAppVersion: minVersion ?? '2.0.0',
    );
    _flagsController.add(_currentFlags);
  }

  void dispose() {
    _flagsController.close();
  }
}
