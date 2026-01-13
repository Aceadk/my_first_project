import 'dart:async';
import 'dart:math';
import '../models/call.dart';

/// Service for managing in-app audio/video calls.
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  final _callController = StreamController<Call>.broadcast();
  final _callStateController = StreamController<CallUIState>.broadcast();

  Stream<Call> get callStream => _callController.stream;
  Stream<CallUIState> get callStateStream => _callStateController.stream;

  Call? _activeCall;
  Timer? _durationTimer;
  int _callDuration = 0;

  // Local UI state (not part of model)
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;

  Call? get activeCall => _activeCall;
  bool get hasActiveCall => _activeCall != null;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isFrontCamera => _isFrontCamera;

  /// Initiate an outgoing call.
  Future<Call> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType type,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  }) async {
    if (_activeCall != null) {
      throw Exception('Already in a call');
    }

    _activeCall = Call(
      id: _generateId(),
      callerId: callerId,
      receiverId: receiverId,
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      callerName: callerName,
      receiverName: receiverName,
      callerPhotoUrl: callerPhotoUrl,
      receiverPhotoUrl: receiverPhotoUrl,
    );

    _isVideoEnabled = type == CallType.video;
    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.outgoing);

    // Simulate connection (in production, use WebRTC signaling)
    _simulateCallConnection();

    return _activeCall!;
  }

  /// Accept an incoming call.
  Future<void> acceptCall() async {
    if (_activeCall == null) return;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.ongoing,
      answeredAt: DateTime.now(),
    );

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.connected);
    _startDurationTimer();
  }

  /// Decline an incoming call.
  Future<void> declineCall() async {
    if (_activeCall == null) return;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.declined,
      endedAt: DateTime.now(),
      endReason: CallEndReason.declined,
    );

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  /// End the current call.
  Future<void> endCall() async {
    if (_activeCall == null) return;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
      duration: _callDuration,
      endReason: CallEndReason.userHangup,
    );

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  /// Toggle mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    _emitCurrentState();
  }

  /// Toggle speaker state.
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _emitCurrentState();
  }

  /// Toggle video state (for video calls).
  void toggleVideo() {
    if (_activeCall?.type != CallType.video) return;
    _isVideoEnabled = !_isVideoEnabled;
    _emitCurrentState();
  }

  /// Switch camera (front/back).
  void switchCamera() {
    if (_activeCall?.type != CallType.video) return;
    _isFrontCamera = !_isFrontCamera;
    _emitCurrentState();
  }

  /// Handle incoming call (from push notification).
  void handleIncomingCall(Call incomingCall) {
    if (_activeCall != null) {
      // Already in a call, auto-decline
      return;
    }

    _activeCall = incomingCall;
    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.incoming);

    // Auto-end if not answered within timeout
    Future.delayed(Call.ringTimeout, () {
      if (_activeCall?.status == CallStatus.ringing) {
        _missedCall();
      }
    });
  }

  /// Get call history for a user.
  Future<List<Call>> getCallHistory(String userId, {int limit = 20}) async {
    // In production, fetch from backend
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  void _simulateCallConnection() {
    // Simulate ringing for 3 seconds then connect
    Future.delayed(const Duration(seconds: 3), () {
      if (_activeCall?.status == CallStatus.ringing) {
        acceptCall();
      }
    });
  }

  void _startDurationTimer() {
    _callDuration = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeCall != null && _activeCall!.status == CallStatus.ongoing) {
        _callDuration++;
        _activeCall = _activeCall!.copyWith(duration: _callDuration);
        _callController.add(_activeCall!);
      }
    });
  }

  void _missedCall() {
    if (_activeCall == null) return;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.missed,
      endedAt: DateTime.now(),
      endReason: CallEndReason.missed,
    );

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  void _emitCurrentState() {
    if (_activeCall != null) {
      _callController.add(_activeCall!);
    }
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callDuration = 0;
    _isMuted = false;
    _isSpeakerOn = false;
    _isVideoEnabled = true;
    _isFrontCamera = true;

    // Keep reference briefly for UI to show end state
    Future.delayed(const Duration(seconds: 2), () {
      _activeCall = null;
    });
  }

  String _generateId() {
    return 'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void dispose() {
    _durationTimer?.cancel();
    _callController.close();
    _callStateController.close();
  }
}

/// Call UI state for display.
enum CallUIState {
  idle,
  outgoing,
  incoming,
  connecting,
  connected,
  ended,
}
