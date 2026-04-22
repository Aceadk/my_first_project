import 'package:crushhour/features/calls/data/repositories/call_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/call_contract_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('call contract helpers', () {
    test(
      'resolveOtherParticipantId supports multiple persisted match shapes',
      () {
        expect(
          resolveOtherParticipantId(<String, dynamic>{
            'userIds': <String>['user-1', 'user-2'],
          }, 'user-1'),
          'user-2',
        );

        expect(
          resolveOtherParticipantId(<String, dynamic>{
            'users': <String>['user-1', 'user-3'],
          }, 'user-1'),
          'user-3',
        );

        expect(
          resolveOtherParticipantId(<String, dynamic>{
            'participants': <String>['user-4', 'user-1'],
          }, 'user-1'),
          'user-4',
        );
      },
    );

    test(
      'callSessionFromStartResponse accepts both new and legacy response keys',
      () {
        final fromRest = callSessionFromStartResponse(
          <String, dynamic>{'call_id': 'call-11', 'local_uid': 0},
          matchId: 'match-1',
          isVideoCall: true,
        );

        expect(
          fromRest,
          isA<CallSession>()
              .having(
                (session) => session.channelName,
                'channelName',
                'call-11',
              )
              .having((session) => session.localUid, 'localUid', 0),
        );

        final fromCallable = callSessionFromStartResponse(
          <String, dynamic>{
            'callId': 'call-22',
            'channelName': 'channel-22',
            'localUid': 42,
          },
          matchId: 'match-2',
          isVideoCall: false,
        );

        expect(fromCallable.channelName, 'channel-22');
        expect(fromCallable.localUid, 42);
        expect(fromCallable.isVideoCall, isFalse);
      },
    );
  });
}
