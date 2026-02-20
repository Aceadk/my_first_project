import 'dart:async';

enum CallKitEventType {
  answered,
  declined,
  ended,
  mutedChanged,
  incomingReported,
  incomingReportFailed,
  audioActivated,
  audioDeactivated,
  unknown,
}

class CallKitEvent {
  const CallKitEvent({
    required this.type,
    this.callId,
    this.isMuted,
    this.error,
    this.payload = const <String, dynamic>{},
  });

  final CallKitEventType type;
  final String? callId;
  final bool? isMuted;
  final String? error;
  final Map<String, dynamic> payload;
}

abstract class CallKitRepository {
  Stream<CallKitEvent> get events;

  Future<bool> showIncomingCall({
    required String callId,
    required String callerId,
    required bool isVideoCall,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
  });

  Future<bool> endCall({required String callId, String reason = 'ended'});

  Future<bool> setMuted({required String callId, required bool isMuted});
}
