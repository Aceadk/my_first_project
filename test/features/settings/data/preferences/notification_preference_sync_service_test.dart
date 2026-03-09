import 'package:crushhour/features/settings/data/preferences/notification_preference_sync_service.dart';
import 'package:crushhour/features/settings/data/preferences/preference_sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferenceSyncService', () {
    test('hydrates to newer remote snapshot', () async {
      final localUpdatedAt = DateTime.utc(2026, 3, 8, 10, 0, 0);
      final remoteUpdatedAt = DateTime.utc(2026, 3, 8, 10, 5, 0);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'notifications_push': false,
        'notifications_sync_updated_at_ms':
            localUpdatedAt.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final service = NotificationPreferenceSyncService.testable(
        preferences: prefs,
        fetchRemoteSnapshot: () async =>
            PreferenceSyncSnapshot<NotificationPreferenceRecord>(
              value: NotificationPreferenceRecord.defaults.copyWith(push: true),
              updatedAt: remoteUpdatedAt,
            ),
      );

      final hydration = await service.hydrate();
      final localAfter = service.readLocalSnapshot().value;

      expect(hydration.source, PreferenceResolutionSource.remote);
      expect(hydration.hadConflict, isFalse);
      expect(localAfter.push, isTrue);
    });

    test('marks conflict when timestamps match and values diverge', () async {
      final updatedAt = DateTime.utc(2026, 3, 8, 10, 0, 0);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'notifications_push': false,
        'notifications_sync_updated_at_ms': updatedAt.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final service = NotificationPreferenceSyncService.testable(
        preferences: prefs,
        fetchRemoteSnapshot: () async =>
            PreferenceSyncSnapshot<NotificationPreferenceRecord>(
              value: NotificationPreferenceRecord.defaults.copyWith(push: true),
              updatedAt: updatedAt,
            ),
      );

      final hydration = await service.hydrate();

      expect(hydration.source, PreferenceResolutionSource.merged);
      expect(hydration.hadConflict, isTrue);
      expect(hydration.record.push, isTrue);
    });

    test('persists local and forwards full payload to remote sync', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      NotificationPreferenceRecord? remoteRecord;
      DateTime? remoteUpdatedAt;
      final service = NotificationPreferenceSyncService.testable(
        preferences: prefs,
        pushRemoteSnapshot: (record, updatedAt) async {
          remoteRecord = record;
          remoteUpdatedAt = updatedAt;
        },
        now: () => DateTime.utc(2026, 3, 8, 12, 0, 0),
      );

      final next = NotificationPreferenceRecord.defaults.copyWith(
        push: false,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 7,
      );
      await service.persist(next);

      final local = service.readLocalSnapshot().value;
      expect(local.push, isFalse);
      expect(local.quietHoursEnabled, isTrue);
      expect(local.quietHoursStart, 23);
      expect(local.quietHoursEnd, 7);
      expect(remoteRecord?.push, isFalse);
      expect(remoteRecord?.quietHoursEnabled, isTrue);
      expect(remoteUpdatedAt, DateTime.utc(2026, 3, 8, 12, 0, 0));
    });
  });
}
