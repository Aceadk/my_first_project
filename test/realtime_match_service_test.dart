import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/discovery/data/services/realtime_match_service.dart';

void main() {
  group('RealtimeMatchService', () {
    test(
      'startListening emits notification and clears source record',
      () async {
        final events = StreamController<RealtimeChildAddedEvent>.broadcast();
        final notifications = <RealtimeMatchNotification>[];
        final removed = <String>[];
        String? listenedPath;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (path) {
            listenedPath = path;
            return events.stream;
          },
        );

        final sub = service.onNewMatch.listen(notifications.add);

        service.startListening('user-1');
        expect(listenedPath, 'users/user-1/newMatches');

        events.add(
          RealtimeChildAddedEvent(
            key: 'match-1',
            value: {
              'otherUserId': 'user-2',
              'otherUserName': 'Alex',
              'otherUserPhotoUrl': 'https://example.com/alex.jpg',
              'createdAt': 42,
            },
            remove: () async {
              removed.add('match-1');
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(notifications, hasLength(1));
        expect(notifications.first.matchId, 'match-1');
        expect(notifications.first.otherUserId, 'user-2');
        expect(notifications.first.otherUserName, 'Alex');
        expect(
          notifications.first.otherUserPhotoUrl,
          'https://example.com/alex.jpg',
        );
        expect(notifications.first.createdAt, 42);
        expect(removed, ['match-1']);

        await sub.cancel();
        await events.close();
        service.dispose();
      },
    );

    test(
      'ignores malformed events and handles remove failures safely',
      () async {
        final events = StreamController<RealtimeChildAddedEvent>.broadcast();
        final notifications = <RealtimeMatchNotification>[];
        var removeAttempts = 0;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (_) => events.stream,
        );

        final sub = service.onNewMatch.listen(notifications.add);
        service.startListening('user-1');

        events.add(
          RealtimeChildAddedEvent(
            key: null,
            value: {'otherUserId': 'user-2'},
            remove: () async {},
          ),
        );
        events.add(
          RealtimeChildAddedEvent(
            key: 'match-bad',
            value: 'not-a-map',
            remove: () async {},
          ),
        );
        events.add(
          RealtimeChildAddedEvent(
            key: 'match-2',
            value: {
              'otherUserId': 'user-9',
              'otherUserName': 'Jamie',
              'createdAt': 100,
            },
            remove: () async {
              removeAttempts++;
              throw Exception('remove failed');
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(notifications, hasLength(1));
        expect(notifications.first.matchId, 'match-2');
        expect(removeAttempts, 1);

        await sub.cancel();
        await events.close();
        service.dispose();
      },
    );

    test(
      'startListening is idempotent for same user and switches cleanly',
      () async {
        var firstCancelCalls = 0;
        final firstController =
            StreamController<RealtimeChildAddedEvent>.broadcast(
              onCancel: () {
                firstCancelCalls++;
              },
            );
        final secondController =
            StreamController<RealtimeChildAddedEvent>.broadcast();
        var listenCalls = 0;

        final service = RealtimeMatchService.test(
          childAddedStreamFactory: (path) {
            listenCalls++;
            if (path.contains('user-1')) {
              return firstController.stream;
            }
            return secondController.stream;
          },
        );

        service.startListening('user-1');
        service.startListening('user-1');
        expect(listenCalls, 1);

        service.startListening('user-2');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(listenCalls, 2);
        expect(firstCancelCalls, 1);

        service.stopListening();

        await firstController.close();
        await secondController.close();
        service.dispose();
      },
    );

    test('onError callback consumes stream errors without crashing', () async {
      final events = StreamController<RealtimeChildAddedEvent>.broadcast();
      final notifications = <RealtimeMatchNotification>[];

      final service = RealtimeMatchService.test(
        childAddedStreamFactory: (_) => events.stream,
      );
      final sub = service.onNewMatch.listen(notifications.add);

      service.startListening('user-1');
      events.addError(Exception('listener failure'));
      events.add(
        RealtimeChildAddedEvent(
          key: 'match-3',
          value: {
            'otherUserId': 'user-3',
            'otherUserName': 'Taylor',
            'createdAt': 111,
          },
          remove: () async {},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifications, hasLength(1));
      expect(notifications.first.matchId, 'match-3');

      await sub.cancel();
      await events.close();
      service.dispose();
    });
  });
}
