import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../call_repository.dart';

/// Firebase implementation of CallRepository.
///
/// This implementation uses Firebase Cloud Functions to initiate calls
/// and manage call sessions. The actual WebRTC/Agora signaling should
/// be handled by the backend.
class FirebaseCallRepository implements CallRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  CallSession? _currentSession;
  final StreamController<CallEngineEvent> _eventController =
      StreamController<CallEngineEvent>.broadcast();

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final callable = _functions.httpsCallable('startCall');
    final result = await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'isVideoCall': isVideoCall,
    });

    final data = result.data;
    final channelName = data['channelName'] as String?;
    final localUid = data['localUid'] as int?;

    if (channelName == null || localUid == null) {
      throw Exception('Invalid call session data from server');
    }

    _currentSession = CallSession(
      matchId: matchId,
      localUid: localUid,
      channelName: channelName,
      isVideoCall: isVideoCall,
    );

    // Emit joined channel event
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.joinedChannel,
    ));

    return _currentSession!;
  }

  @override
  Future<void> endCall() async {
    if (_currentSession == null) return;

    try {
      final callable = _functions.httpsCallable('endCall');
      await callable.call<Map<String, dynamic>>({
        'matchId': _currentSession!.matchId,
        'channelName': _currentSession!.channelName,
      });
    } finally {
      _currentSession = null;
    }
  }

  @override
  Stream<CallEngineEvent> engineEvents() {
    return _eventController.stream;
  }

  /// Notify that a remote user joined the call.
  /// This should be called by the actual WebRTC/Agora integration.
  void notifyUserJoined(int remoteUid) {
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.userJoined,
      remoteUid: remoteUid,
    ));
  }

  /// Notify that a remote user left the call.
  /// This should be called by the actual WebRTC/Agora integration.
  void notifyUserOffline(int remoteUid) {
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.userOffline,
      remoteUid: remoteUid,
    ));
  }

  /// Notify of an error in the call.
  void notifyError(String error) {
    _eventController.add(CallEngineEvent(
      type: CallEngineEventType.error,
      error: error,
    ));
  }

  /// Clean up resources.
  void dispose() {
    _eventController.close();
  }
}
