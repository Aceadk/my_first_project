import 'dart:async';
import 'dart:math';
import '../call_repository.dart';

/// Mock implementation of CallRepository.
/// Simulates call behavior for demo purposes without actual video.
/// Replace with your actual video calling backend (e.g., Agora, Twilio, WebRTC).
class StubCallRepository implements CallRepository {
  final _eventController = StreamController<CallEngineEvent>.broadcast();
  final _random = Random();
  Timer? _simulationTimer;
  bool _isInCall = false;

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 500));

    _isInCall = true;
    final localUid = _random.nextInt(100000);
    final channelName = 'demo_channel_$matchId';

    // Simulate joining channel
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.joinedChannel,
    ));

    // Simulate remote user joining after 1-2 seconds (50% of the time)
    _simulationTimer =
        Timer(Duration(milliseconds: 1000 + _random.nextInt(1000)), () {
      if (_isInCall && _random.nextBool()) {
        _eventController.add(CallEngineEvent(
          type: CallEngineEventType.userJoined,
          remoteUid: _random.nextInt(100000),
        ));
      }
    });

    return CallSession(
      matchId: matchId,
      localUid: localUid,
      channelName: channelName,
      isVideoCall: isVideoCall,
    );
  }

  @override
  Future<void> endCall() async {
    _isInCall = false;
    _simulationTimer?.cancel();

    // Simulate disconnection
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.userOffline,
    ));
  }

  @override
  Stream<CallEngineEvent> engineEvents() => _eventController.stream;

  void dispose() {
    _simulationTimer?.cancel();
    _eventController.close();
  }
}
