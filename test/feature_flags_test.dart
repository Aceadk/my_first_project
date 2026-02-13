import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/feature_flags/data/models/feature_flags.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/presentation/bloc/feature_flag_cubit.dart';

import 'mock/firebase_mock.dart';

// ---------------------------------------------------------------------------
// Mock implementation of FeatureFlagRepository
// ---------------------------------------------------------------------------
class MockFeatureFlagRepository implements FeatureFlagRepository {
  MockFeatureFlagRepository({
    FeatureFlags? initialFlags,
    this.shouldFailInitialize = false,
    this.shouldFailFetch = false,
    this.shouldFailForceRefresh = false,
    this.fetchReturnsSuccess = true,
  }) : _flags = initialFlags ?? const FeatureFlags();

  FeatureFlags _flags;
  final bool shouldFailInitialize;
  final bool shouldFailFetch;
  final bool shouldFailForceRefresh;
  final bool fetchReturnsSuccess;

  bool _initialized = false;
  DateTime? _lastFetchTime;

  final _flagsStreamController = StreamController<FeatureFlags>.broadcast();

  /// Manually push new flags (simulates Remote Config update).
  void pushFlags(FeatureFlags flags) {
    _flags = flags;
    _flagsStreamController.add(flags);
  }

  // Custom per-key overrides for getBool/getInt/getString/getDouble testing
  final Map<String, dynamic> _overrides = {};

  void setOverride(String key, dynamic value) => _overrides[key] = value;

  // FeatureFlagRepository interface ----------------------------------------

  @override
  Future<void> initialize() async {
    if (shouldFailInitialize) {
      throw Exception('Initialization failed');
    }
    _initialized = true;
    _lastFetchTime = DateTime.now();
  }

  @override
  FeatureFlags get flags => _flags;

  @override
  Stream<FeatureFlags> get flagsStream => _flagsStreamController.stream;

  @override
  Future<bool> fetchAndActivate() async {
    if (shouldFailFetch) {
      throw Exception('Fetch failed');
    }
    _lastFetchTime = DateTime.now();
    return fetchReturnsSuccess;
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    if (_overrides.containsKey(key)) return _overrides[key] as bool;
    return defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    if (_overrides.containsKey(key)) return _overrides[key] as int;
    return defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    if (_overrides.containsKey(key)) return _overrides[key] as String;
    return defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0.0}) {
    if (_overrides.containsKey(key)) return _overrides[key] as double;
    return defaultValue;
  }

  @override
  Future<void> forceRefresh() async {
    if (shouldFailForceRefresh) {
      throw Exception('Force refresh failed');
    }
    _lastFetchTime = DateTime.now();
  }

  @override
  DateTime? get lastFetchTime => _lastFetchTime;

  @override
  bool get isInitialized => _initialized;

  void dispose() {
    _flagsStreamController.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setupFirebaseAnalyticsMocks();

  group('FeatureFlags model', () {
    test('default constructor has expected defaults', () {
      const flags = FeatureFlags();
      expect(flags.enableSuperLike, isTrue);
      expect(flags.enableRewind, isTrue);
      expect(flags.dailyLikeLimit, 100);
      expect(flags.dailySuperLikeLimit, 5);
      expect(flags.maintenanceMode, isFalse);
      expect(flags.forceUpdate, isFalse);
      expect(flags.minAppVersion, '1.0.0');
      expect(flags.enableVideoChat, isTrue);
      expect(flags.maxPhotos, 6);
      expect(flags.enableAnalytics, isTrue);
      expect(flags.debugLoggingEnabled, isFalse);
    });

    test('fromMap creates flags from map data', () {
      final flags = FeatureFlags.fromMap(const {
        'enable_super_like': false,
        'daily_like_limit': 50,
        'maintenance_mode': true,
        'maintenance_message': 'Under maintenance',
        'min_app_version': '2.0.0',
        'force_update': true,
        'force_update_message': 'Please update',
        'max_photos': 9,
      });

      expect(flags.enableSuperLike, isFalse);
      expect(flags.dailyLikeLimit, 50);
      expect(flags.maintenanceMode, isTrue);
      expect(flags.maintenanceMessage, 'Under maintenance');
      expect(flags.minAppVersion, '2.0.0');
      expect(flags.forceUpdate, isTrue);
      expect(flags.forceUpdateMessage, 'Please update');
      expect(flags.maxPhotos, 9);
    });

    test('fromMap uses defaults for missing keys', () {
      final flags = FeatureFlags.fromMap(const {});
      expect(flags.enableSuperLike, isTrue);
      expect(flags.dailyLikeLimit, 100);
      expect(flags.maintenanceMode, isFalse);
      expect(flags.minAppVersion, '1.0.0');
    });

    test('toMap round-trips through fromMap', () {
      const original = FeatureFlags(
        enableSuperLike: false,
        dailyLikeLimit: 42,
        maintenanceMode: true,
        maintenanceMessage: 'down',
      );
      final map = original.toMap();
      final restored = FeatureFlags.fromMap(map);

      expect(restored.enableSuperLike, original.enableSuperLike);
      expect(restored.dailyLikeLimit, original.dailyLikeLimit);
      expect(restored.maintenanceMode, original.maintenanceMode);
      expect(restored.maintenanceMessage, original.maintenanceMessage);
    });

    test('copyWith overrides specific fields', () {
      const flags = FeatureFlags();
      final updated = flags.copyWith(
        enableSuperLike: false,
        maintenanceMode: true,
        dailyLikeLimit: 25,
      );

      expect(updated.enableSuperLike, isFalse);
      expect(updated.maintenanceMode, isTrue);
      expect(updated.dailyLikeLimit, 25);
      // unchanged
      expect(updated.enableRewind, isTrue);
      expect(updated.enableVideoChat, isTrue);
    });

    test('FeatureFlags.defaults is const default', () {
      expect(FeatureFlags.defaults, const FeatureFlags());
    });
  });

  group('FeatureFlagState', () {
    test('initial state has correct values', () {
      const state = FeatureFlagState.initial();
      expect(state.status, FeatureFlagStatus.initial);
      expect(state.flags, const FeatureFlags());
      expect(state.lastFetchTime, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.isLoaded, isFalse);
    });

    test('isLoading returns true for loading and refreshing', () {
      const loading = FeatureFlagState(
        status: FeatureFlagStatus.loading,
        flags: FeatureFlags(),
      );
      expect(loading.isLoading, isTrue);

      const refreshing = FeatureFlagState(
        status: FeatureFlagStatus.refreshing,
        flags: FeatureFlags(),
      );
      expect(refreshing.isLoading, isTrue);
    });

    test('copyWith creates correct copy', () {
      const state = FeatureFlagState.initial();
      final updated = state.copyWith(
        status: FeatureFlagStatus.loaded,
        errorMessage: null,
      );
      expect(updated.status, FeatureFlagStatus.loaded);
      expect(updated.errorMessage, isNull);
      expect(updated.flags, const FeatureFlags());
    });
  });

  group('FeatureFlagCubit', () {
    late MockFeatureFlagRepository repository;
    late FeatureFlagCubit cubit;

    setUp(() {
      repository = MockFeatureFlagRepository();
      cubit = FeatureFlagCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
      repository.dispose();
    });

    test('initial state is FeatureFlagStatus.initial', () {
      expect(cubit.state.status, FeatureFlagStatus.initial);
      expect(cubit.state.flags, const FeatureFlags());
    });

    test('initialize emits loading then loaded on success', () async {
      final states = <FeatureFlagState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0].status, FeatureFlagStatus.loading);
      expect(states[1].status, FeatureFlagStatus.loaded);
      expect(states[1].lastFetchTime, isNotNull);

      await sub.cancel();
    });

    test('initialize emits error state on failure', () async {
      final failRepo = MockFeatureFlagRepository(shouldFailInitialize: true);
      final failCubit = FeatureFlagCubit(repository: failRepo);

      final states = <FeatureFlagState>[];
      final sub = failCubit.stream.listen(states.add);

      await failCubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0].status, FeatureFlagStatus.loading);
      expect(states[1].status, FeatureFlagStatus.error);
      expect(states[1].errorMessage, isNotNull);
      // Falls back to defaults on error
      expect(states[1].flags, FeatureFlags.defaults);

      await sub.cancel();
      await failCubit.close();
      failRepo.dispose();
    });

    test('refresh emits refreshing then loaded on success', () async {
      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s.status == FeatureFlagStatus.refreshing), isTrue);
      expect(states.last.status, FeatureFlagStatus.loaded);

      await sub.cancel();
    });

    test('refresh emits error when fetchAndActivate returns false', () async {
      final failRepo = MockFeatureFlagRepository(fetchReturnsSuccess: false);
      final failCubit = FeatureFlagCubit(repository: failRepo);
      await failCubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = failCubit.stream.listen(states.add);

      await failCubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, FeatureFlagStatus.error);
      expect(states.last.errorMessage, 'Failed to refresh flags');

      await sub.cancel();
      await failCubit.close();
      failRepo.dispose();
    });

    test('refresh emits error on exception', () async {
      final failRepo = MockFeatureFlagRepository(shouldFailFetch: true);
      final failCubit = FeatureFlagCubit(repository: failRepo);
      await failCubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = failCubit.stream.listen(states.add);

      await failCubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, FeatureFlagStatus.error);
      expect(states.last.errorMessage, isNotNull);

      await sub.cancel();
      await failCubit.close();
      failRepo.dispose();
    });

    test('forceRefresh emits refreshing then loaded on success', () async {
      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.forceRefresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s.status == FeatureFlagStatus.refreshing), isTrue);
      expect(states.last.status, FeatureFlagStatus.loaded);
      expect(states.last.lastFetchTime, isNotNull);

      await sub.cancel();
    });

    test('forceRefresh emits error on failure', () async {
      final failRepo = MockFeatureFlagRepository(shouldFailForceRefresh: true);
      final failCubit = FeatureFlagCubit(repository: failRepo);
      await failCubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = failCubit.stream.listen(states.add);

      await failCubit.forceRefresh();
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, FeatureFlagStatus.error);
      expect(states.last.errorMessage, isNotNull);

      await sub.cancel();
      await failCubit.close();
      failRepo.dispose();
    });

    test('isEnabled delegates to repository.getBool', () {
      repository.setOverride('my_flag', true);
      expect(cubit.isEnabled('my_flag'), isTrue);

      repository.setOverride('my_flag', false);
      expect(cubit.isEnabled('my_flag'), isFalse);
    });

    test('isEnabled returns false for unknown flags', () {
      expect(cubit.isEnabled('unknown_flag'), isFalse);
    });

    test('convenience getters reflect current flags state', () async {
      repository.pushFlags(const FeatureFlags(
        maintenanceMode: true,
        maintenanceMessage: 'Server down',
        forceUpdate: true,
        forceUpdateMessage: 'Please update now',
        minAppVersion: '3.0.0',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isMaintenanceMode, isTrue);
      expect(cubit.maintenanceMessage, 'Server down');
      expect(cubit.requiresForceUpdate, isTrue);
      expect(cubit.forceUpdateMessage, 'Please update now');
      expect(cubit.minAppVersion, '3.0.0');
    });

    test('flagsStream updates cubit state when repository pushes', () async {
      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      final states = <FeatureFlagState>[];
      final sub = cubit.stream.listen(states.add);

      repository.pushFlags(const FeatureFlags(maintenanceMode: true));
      await Future<void>.delayed(Duration.zero);

      expect(states.last.flags.maintenanceMode, isTrue);
      expect(states.last.lastFetchTime, isNotNull);

      await sub.cancel();
    });

    test('close cancels stream subscription', () async {
      await cubit.close();
      // Should not throw when repository pushes after close
      repository.pushFlags(const FeatureFlags(maintenanceMode: true));
    });
  });

  group('FeatureFlagRepository mock - typed getters', () {
    late MockFeatureFlagRepository repo;

    setUp(() {
      repo = MockFeatureFlagRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('getBool returns default when no override', () {
      expect(repo.getBool('x'), isFalse);
      expect(repo.getBool('x', defaultValue: true), isTrue);
    });

    test('getInt returns default when no override', () {
      expect(repo.getInt('x'), 0);
      expect(repo.getInt('x', defaultValue: 42), 42);
    });

    test('getString returns default when no override', () {
      expect(repo.getString('x'), '');
      expect(repo.getString('x', defaultValue: 'hello'), 'hello');
    });

    test('getDouble returns default when no override', () {
      expect(repo.getDouble('x'), 0.0);
      expect(repo.getDouble('x', defaultValue: 3.14), 3.14);
    });

    test('getBool/getInt/getString/getDouble return overrides', () {
      repo.setOverride('bFlag', true);
      repo.setOverride('iFlag', 99);
      repo.setOverride('sFlag', 'world');
      repo.setOverride('dFlag', 2.71);

      expect(repo.getBool('bFlag'), isTrue);
      expect(repo.getInt('iFlag'), 99);
      expect(repo.getString('sFlag'), 'world');
      expect(repo.getDouble('dFlag'), 2.71);
    });
  });
}
