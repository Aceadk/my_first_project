import 'dart:async';

import 'package:crushhour/features/feature_flags/data/repositories/impl/firebase_feature_flag_repository.dart';
import 'package:crushhour/features/feature_flags/domain/models/feature_flags.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake (project convention — no mockito codegen) exposing only the
/// `FirebaseRemoteConfig` surface used by [FirebaseFeatureFlagRepository].
/// `getAll()` returns `{}` so `_updateFlags()` skips the value loop and just
/// pushes defaults through the broadcast controller — enough to exercise the
/// real-time update listener and its teardown.
class _FakeRemoteConfig extends Fake implements FirebaseRemoteConfig {
  _FakeRemoteConfig(this._updates);

  final Stream<RemoteConfigUpdate> _updates;

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => _updates;

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}

  @override
  Future<bool> fetchAndActivate() async => true;

  @override
  Future<bool> activate() async => true;

  @override
  Map<String, RemoteConfigValue> getAll() => const {};
}

void main() {
  group('FirebaseFeatureFlagRepository disposal (STATE-002)', () {
    late StreamController<RemoteConfigUpdate> updates;
    late FirebaseFeatureFlagRepository repo;

    setUp(() {
      updates = StreamController<RemoteConfigUpdate>.broadcast();
      repo = FirebaseFeatureFlagRepository(
        remoteConfig: _FakeRemoteConfig(updates.stream),
      );
    });

    tearDown(() async {
      await updates.close();
    });

    test('live config updates propagate while initialized', () async {
      await repo.initialize();

      final received = <FeatureFlags>[];
      final sub = repo.flagsStream.listen(received.add);

      updates.add(RemoteConfigUpdate({'enable_super_like'}));
      await Future<void>.delayed(Duration.zero);

      expect(received, isNotEmpty);
      await sub.cancel();
    });

    test(
      'a config update after dispose() neither throws nor emits '
      '(subscription cancelled + closed-controller guard)',
      () async {
        await repo.initialize();

        var emittedAfterDispose = false;
        final sub = repo.flagsStream.listen((_) => emittedAfterDispose = true);

        repo.dispose();

        // Before the fix this re-entered _updateFlags() and called
        // _flagsController.add() on a closed controller -> StateError.
        updates.add(RemoteConfigUpdate({'enable_super_like'}));
        await Future<void>.delayed(Duration.zero);

        expect(emittedAfterDispose, isFalse);
        await sub.cancel();
      },
    );

    test('dispose() is idempotent', () async {
      await repo.initialize();
      repo.dispose();
      expect(repo.dispose, returnsNormally);
    });
  });
}
