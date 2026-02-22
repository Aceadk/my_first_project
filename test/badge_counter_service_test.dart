import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/services/badge_counter_service.dart';

void main() {
  group('BadgeCountState', () {
    test('totalCount sums all counters', () {
      const state = BadgeCountState(
        unreadChats: 3,
        newMatches: 4,
        unreadNotifications: 5,
      );

      expect(state.totalCount, 12);
    });

    test('copyWith updates only provided values', () {
      const initial = BadgeCountState(
        unreadChats: 1,
        newMatches: 2,
        unreadNotifications: 3,
      );

      final next = initial.copyWith(newMatches: 9);

      expect(next.unreadChats, 1);
      expect(next.newMatches, 9);
      expect(next.unreadNotifications, 3);
    });

    test('equatable props compare states by value', () {
      const a = BadgeCountState(
        unreadChats: 1,
        newMatches: 2,
        unreadNotifications: 3,
      );
      const b = BadgeCountState(
        unreadChats: 1,
        newMatches: 2,
        unreadNotifications: 3,
      );
      const c = BadgeCountState(
        unreadChats: 1,
        newMatches: 2,
        unreadNotifications: 4,
      );

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('BadgeCounterCubit', () {
    test('updateUnreadChats emits only on value change', () async {
      final cubit = BadgeCounterCubit();
      final emitted = <BadgeCountState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.updateUnreadChats(5);
      cubit.updateUnreadChats(5);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.unreadChats, 5);
      expect(emitted, [const BadgeCountState(unreadChats: 5)]);

      await sub.cancel();
      await cubit.close();
    });

    test('updateNewMatches emits only on value change', () async {
      final cubit = BadgeCounterCubit();
      final emitted = <BadgeCountState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.updateNewMatches(2);
      cubit.updateNewMatches(2);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.newMatches, 2);
      expect(emitted, [const BadgeCountState(newMatches: 2)]);

      await sub.cancel();
      await cubit.close();
    });

    test('updateUnreadNotifications emits only on value change', () async {
      final cubit = BadgeCounterCubit();
      final emitted = <BadgeCountState>[];
      final sub = cubit.stream.listen(emitted.add);

      cubit.updateUnreadNotifications(7);
      cubit.updateUnreadNotifications(7);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.unreadNotifications, 7);
      expect(emitted, [const BadgeCountState(unreadNotifications: 7)]);

      await sub.cancel();
      await cubit.close();
    });

    test('clear resets all counters to zero', () async {
      final cubit = BadgeCounterCubit();

      cubit
        ..updateUnreadChats(3)
        ..updateNewMatches(4)
        ..updateUnreadNotifications(5)
        ..clear();

      expect(cubit.state, const BadgeCountState());
      await cubit.close();
    });
  });
}
