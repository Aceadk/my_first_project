import 'dart:async';

import 'package:crushhour/core/utils/managed_timer_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagedTimerRegistry', () {
    test(
      'startPeriodic restarts existing key and keeps a single timer',
      () async {
        final registry = ManagedTimerRegistry();
        var firstTimerFired = false;
        var secondTimerTicks = 0;

        registry.startPeriodic(
          'poll',
          const Duration(milliseconds: 40),
          (_) => firstTimerFired = true,
        );

        await Future<void>.delayed(const Duration(milliseconds: 5));

        registry.startPeriodic(
          'poll',
          const Duration(milliseconds: 5),
          (_) => secondTimerTicks += 1,
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(firstTimerFired, isFalse);
        expect(secondTimerTicks, greaterThan(0));
        expect(registry.keys.where((k) => k == 'poll').length, 1);

        registry.cancelAll();
      },
    );

    test('startOneShot auto-removes key after callback', () async {
      final registry = ManagedTimerRegistry();
      var fireCount = 0;

      registry.startOneShot(
        'typing',
        const Duration(milliseconds: 10),
        () => fireCount += 1,
      );

      expect(registry.contains('typing'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(fireCount, 1);
      expect(registry.contains('typing'), isFalse);
      expect(registry.isEmpty, isTrue);
    });

    test('cancelWhere and cancelAll remove matching timers safely', () async {
      final registry = ManagedTimerRegistry();

      registry.startPeriodic(
        'messages_match-1',
        const Duration(milliseconds: 50),
        (_) {},
      );
      registry.startPeriodic(
        'presence_user-1',
        const Duration(milliseconds: 50),
        (_) {},
      );
      registry.startPeriodic('other', const Duration(milliseconds: 50), (_) {});

      registry.cancelWhere((key) => key.startsWith('messages_'));

      expect(registry.contains('messages_match-1'), isFalse);
      expect(registry.contains('presence_user-1'), isTrue);
      expect(registry.contains('other'), isTrue);

      registry.cancelAll();
      expect(registry.isEmpty, isTrue);
    });
  });
}
