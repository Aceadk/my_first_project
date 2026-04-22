import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../call_repository.dart';
import 'call_contract_support.dart';

/// Firebase implementation of CallRepository.
///
/// This implementation uses Firebase Cloud Functions to initiate calls
/// and manage call sessions. The actual WebRTC/Agora signaling should
/// be handled by the backend.
class FirebaseCallRepository implements CallRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

    final matchSnapshot = await _firestore
        .collection('matches')
        .doc(matchId)
        .get();
    if (!matchSnapshot.exists) {
      throw Exception('Match not found');
    }

    final receiverId = resolveOtherParticipantId(
      matchSnapshot.data() ?? const <String, dynamic>{},
      userId,
    );

    final callable = _functions.httpsCallable('initiateCall');
    final result = await callable.call<Map<String, dynamic>>({
      'receiverId': receiverId,
      'type': isVideoCall ? 'video' : 'audio',
    });

    _currentSession = callSessionFromStartResponse(
      result.data,
      matchId: matchId,
      isVideoCall: isVideoCall,
    );

    // Emit joined channel event
    _eventController.add(
      CallEngineEvent(type: CallEngineEventType.joinedChannel),
    );

    return _currentSession!;
  }

  @override
  Future<void> endCall() async {
    if (_currentSession == null) return;

    try {
      final callable = _functions.httpsCallable('endCall');
      await callable.call<Map<String, dynamic>>({
        'callId': _currentSession!.channelName,
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
    _eventController.add(
      CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: remoteUid,
      ),
    );
  }

  /// Notify that a remote user left the call.
  /// This should be called by the actual WebRTC/Agora integration.
  void notifyUserOffline(int remoteUid) {
    _eventController.add(
      CallEngineEvent(
        type: CallEngineEventType.userOffline,
        remoteUid: remoteUid,
      ),
    );
  }

  /// Notify of an error in the call.
  void notifyError(String error) {
    _eventController.add(
      CallEngineEvent(type: CallEngineEventType.error, error: error),
    );
  }

  /// Clean up resources.
  void dispose() {
    _eventController.close();
  }
}
