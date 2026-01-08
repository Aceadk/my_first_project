import 'dart:async';
import '../call_repository.dart';

/// Stub implementation of CallRepository.
/// Replace this with your actual video calling backend (e.g., Agora, Twilio, WebRTC).
class StubCallRepository implements CallRepository {
  final _eventController = StreamController<CallEngineEvent>.broadcast();

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    // TODO: Implement call initiation with your video calling backend
    throw UnimplementedError('Video calling not implemented. Connect your video backend.');
  }

  @override
  Future<void> endCall() async {
    // TODO: Implement call termination
  }

  @override
  Stream<CallEngineEvent> engineEvents() => _eventController.stream;

  void dispose() {
    _eventController.close();
  }
}
