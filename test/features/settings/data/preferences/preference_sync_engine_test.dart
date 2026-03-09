import 'package:crushhour/features/settings/data/preferences/preference_sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferenceSyncEngine', () {
    const engine = PreferenceSyncEngine<Map<String, int>>(
      equals: _mapEquals,
      resolveConflict: _mergeMaps,
    );

    test('prefers newer remote snapshot', () {
      final result = engine.resolve(
        local: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'value': 1},
          updatedAt: DateTime.utc(2026, 3, 8, 10, 0, 0),
        ),
        remote: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'value': 2},
          updatedAt: DateTime.utc(2026, 3, 8, 10, 1, 0),
        ),
      );

      expect(result.source, PreferenceResolutionSource.remote);
      expect(result.hadConflict, isFalse);
      expect(result.value, const {'value': 2});
    });

    test('prefers newer local snapshot', () {
      final result = engine.resolve(
        local: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'value': 2},
          updatedAt: DateTime.utc(2026, 3, 8, 10, 2, 0),
        ),
        remote: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'value': 1},
          updatedAt: DateTime.utc(2026, 3, 8, 10, 1, 0),
        ),
      );

      expect(result.source, PreferenceResolutionSource.local);
      expect(result.hadConflict, isFalse);
      expect(result.value, const {'value': 2});
    });

    test('merges on equal timestamps with conflicting values', () {
      final updatedAt = DateTime.utc(2026, 3, 8, 10, 0, 0);
      final result = engine.resolve(
        local: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'a': 1},
          updatedAt: updatedAt,
        ),
        remote: PreferenceSyncSnapshot<Map<String, int>>(
          value: const {'b': 2},
          updatedAt: updatedAt,
        ),
      );

      expect(result.source, PreferenceResolutionSource.merged);
      expect(result.hadConflict, isTrue);
      expect(result.value, const {'a': 1, 'b': 2});
    });

    test('merges when both timestamps are absent and values conflict', () {
      final result = engine.resolve(
        local: const PreferenceSyncSnapshot<Map<String, int>>(value: {'a': 1}),
        remote: const PreferenceSyncSnapshot<Map<String, int>>(value: {'b': 2}),
      );

      expect(result.source, PreferenceResolutionSource.merged);
      expect(result.hadConflict, isTrue);
      expect(result.value, const {'a': 1, 'b': 2});
    });
  });
}

bool _mapEquals(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

Map<String, int> _mergeMaps(Map<String, int> local, Map<String, int> remote) {
  return <String, int>{...local, ...remote};
}
