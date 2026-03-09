import 'package:crushhour/features/chat/presentation/bloc/realtime_state_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  group('RealtimeStateCubit', () {
    test(
      'updateTyping emits only when typing set meaningfully changes',
      () async {
        final cubit = RealtimeStateCubit();
        final states = <RealtimeState>[];
        final sub = cubit.stream.listen(states.add);

        cubit.updateTyping({'user-1'});
        await tick();
        cubit.updateTyping({'user-1'});
        await tick();
        cubit.updateTyping({'user-1', 'user-2'});
        await tick();

        expect(states.length, 2);
        expect(states.first.typingUserIds, {'user-1'});
        expect(states.last.typingUserIds, {'user-1', 'user-2'});

        await sub.cancel();
        await cubit.close();
      },
    );

    test('updateTyping stores an immutable defensive copy', () async {
      final cubit = RealtimeStateCubit();
      final externalSet = <String>{'user-1'};

      cubit.updateTyping(externalSet);
      await tick();

      externalSet.add('user-2');
      expect(cubit.state.typingUserIds, {'user-1'});
      expect(
        () => cubit.state.typingUserIds.add('user-3'),
        throwsUnsupportedError,
      );

      await cubit.close();
    });

    test('presence and media updates skip duplicate emits', () async {
      final cubit = RealtimeStateCubit();
      final states = <RealtimeState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.updatePresence(false); // duplicate initial value
      await tick();
      cubit.updatePresence(true);
      await tick();
      cubit.updatePresence(true); // duplicate
      await tick();
      cubit.updateMediaEnabled(true); // duplicate initial value
      await tick();
      cubit.updateMediaEnabled(false);
      await tick();
      cubit.updateMediaEnabled(false); // duplicate
      await tick();

      expect(states.length, 2);
      expect(states[0].otherUserOnline, true);
      expect(states[1].mediaSendingEnabled, false);

      await sub.cancel();
      await cubit.close();
    });
  });
}
