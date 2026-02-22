import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/calls/domain/repositories/call_repository.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_event.dart';

void main() {
  group('CallEvent', () {
    test('CallStarted stores match and media mode values', () {
      final event = CallStarted(matchId: 'match-1', isVideoCall: true);

      expect(event.props, ['match-1', true]);
      expect(event, CallStarted(matchId: 'match-1', isVideoCall: true));
    });

    test('CallEnded has empty props and equatable semantics', () {
      expect(CallEnded().props, isEmpty);
      expect(CallEnded(), CallEnded());
    });

    test('CallEngineUpdated exposes engine event in props', () {
      final engineEvent = CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: 42,
      );
      final event = CallEngineUpdated(engineEvent);

      expect(event.props, [engineEvent]);
      expect(event, CallEngineUpdated(engineEvent));
    });
  });
}
