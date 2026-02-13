import 'package:crushhour/features/calls/data/models/call.dart';
import 'package:crushhour/features/calls/data/services/call_service.dart';
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
      await resetService();
    });

    tearDown(() async {
      await resetService();
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

      expect(service.hasActiveCall, isTrue);
      expect(call.status, CallStatus.ringing);
      expect(service.isVideoEnabled, isFalse);
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

    test('incoming call handling and call history placeholder', () async {
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

      final history = await service.getCallHistory('u1');
      expect(history, isEmpty);

      final busyIncoming = incoming.copyWith(id: 'incoming-2');
      service.handleIncomingCall(busyIncoming);
      expect(service.activeCall?.id, 'incoming-1');
    });
  });
}
