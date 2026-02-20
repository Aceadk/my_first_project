import 'dart:async';
import 'package:crushhour/features/calls/domain/models/call.dart';

enum CallUIState { idle, outgoing, incoming, connecting, connected, ended }

abstract class CallManagerRepository {
  Stream<Call> get callStream;
  Stream<CallUIState> get callStateStream;
  Stream<Call> get missedCallStream;
  Call? get activeCall;
  bool get hasActiveCall;
  bool get isMuted;
  bool get isSpeakerOn;
  bool get isVideoEnabled;
  bool get isFrontCamera;

  Future<Call> initiateCall({
    required String callerId,
    required String receiverId,
    required CallType type,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  });
  Future<void> acceptCall({CallType? asType});
  Future<void> declineCall();
  Future<void> endCall();
  void toggleMute();
  void toggleSpeaker();
  void toggleVideo();
  void switchCamera();
  void handleIncomingCall(Call incomingCall);
  Future<List<Call>> getCallHistory(
    String userId, {
    int limit = 20,
    DateTime? before,
  });
  void dispose();
}
