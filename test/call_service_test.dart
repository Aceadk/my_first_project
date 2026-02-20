import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallService', () {
    final service = CallService.instance;

    Future<void> resetService() async {
      if (service.hasActiveCall) {
        await service.endCall();
        await Future<void>.delayed(
          const Duration(seconds: 2, milliseconds: 100),
        );
      }
    }

    setUp(() async {
      service.setPreferRemoteSignalingForTest(false);
      await resetService();
      service.clearHistoryForTest();
    });

    tearDown(() async {
      await resetService();
      service.clearHistoryForTest();
      service.setPreferRemoteSignalingForTest(true);
    });

    test('initiateCall creates an active outgoing call', () async {
      final callEvents = <Call>[];
      final uiStates = <CallUIState>[];
      final callSub = service.callStream.listen(callEvents.add);
      final stateSub = service.callStateStream.listen(uiStates.add);

      final call = await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
        callerName: 'Caller',
        receiverName: 'Receiver',
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.hasActiveCall, isTrue);
      expect(call.status, CallStatus.ringing);
      expect(service.isVideoEnabled, isFalse);
      expect(callEvents, isNotEmpty);
      expect(uiStates, isNotEmpty);
      expect(callEvents.last.id, call.id);
      expect(uiStates.last, CallUIState.outgoing);

      await callSub.cancel();
      await stateSub.cancel();
    });

    test('cannot initiate a second call while one is active', () async {
      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
      );

      await expectLater(
        service.initiateCall(
          callerId: 'u1',
          receiverId: 'u3',
          type: CallType.video,
        ),
        throwsException,
      );
    });

    test('initiateCall no longer auto-connects after a delay', () async {
      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
      );

      await Future<void>.delayed(const Duration(milliseconds: 3200));

      expect(service.activeCall, isNotNull);
      expect(service.activeCall!.status, CallStatus.ringing);
    });

    test(
      'acceptCall sets ongoing state and duration starts incrementing',
      () async {
        await service.initiateCall(
          callerId: 'u1',
          receiverId: 'u2',
          type: CallType.video,
        );

        await service.acceptCall();
        expect(service.activeCall!.status, CallStatus.ongoing);

        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(service.activeCall!.duration, greaterThanOrEqualTo(1));
      },
    );

    test('toggle methods update local UI state for video calls', () async {
      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.video,
      );

      expect(service.isMuted, isFalse);
      service.toggleMute();
      expect(service.isMuted, isTrue);

      expect(service.isSpeakerOn, isFalse);
      service.toggleSpeaker();
      expect(service.isSpeakerOn, isTrue);

      expect(service.isVideoEnabled, isTrue);
      service.toggleVideo();
      expect(service.isVideoEnabled, isFalse);

      expect(service.isFrontCamera, isTrue);
      service.switchCamera();
      expect(service.isFrontCamera, isFalse);
    });

    test('toggleVideo and switchCamera are no-op for audio call', () async {
      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
      );

      final beforeVideo = service.isVideoEnabled;
      final beforeCamera = service.isFrontCamera;

      service.toggleVideo();
      service.switchCamera();

      expect(service.isVideoEnabled, beforeVideo);
      expect(service.isFrontCamera, beforeCamera);
    });

    test('declineCall and endCall transition to ended states', () async {
      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
      );

      await service.declineCall();
      expect(service.activeCall!.status, CallStatus.declined);
      expect(service.activeCall!.endReason, CallEndReason.declined);

      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));
      expect(service.activeCall, isNull);

      await service.initiateCall(
        callerId: 'u1',
        receiverId: 'u2',
        type: CallType.audio,
      );
      await service.acceptCall();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await service.endCall();
      expect(service.activeCall!.status, CallStatus.ended);
      expect(service.activeCall!.endReason, CallEndReason.userHangup);
      expect(service.activeCall!.duration, greaterThanOrEqualTo(1));
    });

    test(
      'incoming call handling supports accept-as-audio and history',
      () async {
        final incoming = Call(
          id: 'incoming-1',
          callerId: 'u9',
          receiverId: 'u1',
          type: CallType.video,
          status: CallStatus.ringing,
          createdAt: DateTime.now(),
        );

        service.handleIncomingCall(incoming);
        expect(service.activeCall?.id, 'incoming-1');

        final busyIncoming = incoming.copyWith(id: 'incoming-2');
        service.handleIncomingCall(busyIncoming);
        expect(service.activeCall?.id, 'incoming-1');

        await service.acceptCall(asType: CallType.audio);
        expect(service.activeCall?.status, CallStatus.ongoing);
        expect(service.activeCall?.type, CallType.audio);
        await service.endCall();

        final receiverHistory = await service.getCallHistory('u1');
        final callerHistory = await service.getCallHistory('u9');
        expect(receiverHistory, isNotEmpty);
        expect(callerHistory, isNotEmpty);
        expect(receiverHistory.first.id, 'incoming-1');
        expect(callerHistory.first.id, 'incoming-1');
      },
    );

    test('getCallHistory supports limit and before filtering', () async {
      final now = DateTime.now();
      final older = Call(
        id: 'hist-older',
        callerId: 'u9',
        receiverId: 'u1',
        type: CallType.audio,
        status: CallStatus.ringing,
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final newer = older.copyWith(
        id: 'hist-newer',
        createdAt: now.subtract(const Duration(days: 1)),
      );

      service.handleIncomingCall(older);
      await service.declineCall();
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

      service.handleIncomingCall(newer);
      await service.declineCall();
      await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 100));

      final latestOnly = await service.getCallHistory('u1', limit: 1);
      expect(latestOnly.length, 1);
      expect(latestOnly.first.id, 'hist-newer');

      final olderOnly = await service.getCallHistory(
        'u1',
        before: now.subtract(const Duration(days: 1)),
        limit: 10,
      );
      expect(olderOnly, isNotEmpty);
      expect(olderOnly.first.id, 'hist-older');
    });

    test('missedCallStream emits and records missed calls', () async {
      final missedEvents = <Call>[];
      final missedSub = service.missedCallStream.listen(missedEvents.add);

      final incoming = Call(
        id: 'missed-1',
        callerId: 'u9',
        receiverId: 'u1',
        type: CallType.audio,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
        callerName: 'Alex',
      );

      service.handleIncomingCall(incoming);
      service.markActiveCallMissedForTest();
      await Future<void>.delayed(Duration.zero);

      expect(missedEvents.length, 1);
      expect(missedEvents.single.id, 'missed-1');
      expect(missedEvents.single.status, CallStatus.missed);
      expect(missedEvents.single.endReason, CallEndReason.missed);

      final history = await service.getCallHistory('u1');
      expect(history, isNotEmpty);
      expect(history.first.id, 'missed-1');
      expect(history.first.status, CallStatus.missed);

      await missedSub.cancel();
    });

    test('missedCallStream is not emitted for declined calls', () async {
      final missedEvents = <Call>[];
      final missedSub = service.missedCallStream.listen(missedEvents.add);

      final incoming = Call(
        id: 'declined-1',
        callerId: 'u9',
        receiverId: 'u1',
        type: CallType.video,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      );

      service.handleIncomingCall(incoming);
      await service.declineCall();
      await Future<void>.delayed(Duration.zero);

      expect(missedEvents, isEmpty);

      await missedSub.cancel();
    });
  });
}
