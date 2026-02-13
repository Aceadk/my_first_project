import 'package:crushhour/features/calls/data/repositories/call_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/stub_call_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StubCallRepository', () {
    test('startCall returns session and emits joinedChannel event', () async {
      final repo = StubCallRepository();
      addTearDown(repo.dispose);

      final events = <CallEngineEvent>[];
      final sub = repo.engineEvents().listen(events.add);
      addTearDown(sub.cancel);

      final session = await repo.startCall(
        matchId: 'match-123',
        isVideoCall: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(session.matchId, 'match-123');
      expect(session.channelName, 'demo_channel_match-123');
      expect(session.localUid, greaterThanOrEqualTo(0));
      expect(session.localUid, lessThan(100000));
      expect(session.isVideoCall, isTrue);

      expect(
        events.any((e) => e.type == CallEngineEventType.joinedChannel),
        isTrue,
      );
    });

    test('endCall emits userOffline event', () async {
      final repo = StubCallRepository();
      addTearDown(repo.dispose);

      final events = <CallEngineEvent>[];
      final sub = repo.engineEvents().listen(events.add);
      addTearDown(sub.cancel);

      await repo.startCall(matchId: 'match-456', isVideoCall: false);
      await repo.endCall();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        events.where((e) => e.type == CallEngineEventType.userOffline),
        isNotEmpty,
      );
    });
  });
}
