abstract class CallRepository {
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  });

  Future<void> endCall();

  Stream<CallEngineEvent> engineEvents();
}

class CallSession {
  final String matchId;
  final int localUid;
  final String channelName;
  final bool isVideoCall;

  CallSession({
    required this.matchId,
    required this.localUid,
    required this.channelName,
    required this.isVideoCall,
  });
}

enum CallEngineEventType {
  joinedChannel,
  userJoined,
  userOffline,
  error,
}

class CallEngineEvent {
  final CallEngineEventType type;
  final int? remoteUid;
  final String? error;

  CallEngineEvent({
    required this.type,
    this.remoteUid,
    this.error,
  });
}
