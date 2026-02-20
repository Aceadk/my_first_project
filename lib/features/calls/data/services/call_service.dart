import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/call.dart';

/// Service for managing in-app audio/video calls.
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';

class CallService implements CallManagerRepository {
  CallService._();
  static final CallService instance = CallService._();

  static const String _usersCollection = 'users';
  static const String _historySubcollection = 'call_history';

  final _callController = StreamController<Call>.broadcast();
  final _callStateController = StreamController<CallUIState>.broadcast();
  final _missedCallController = StreamController<Call>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _remoteCallSubscription;

  @override
  Stream<Call> get callStream => _callController.stream;
  @override
  Stream<CallUIState> get callStateStream => _callStateController.stream;
  @override
  Stream<Call> get missedCallStream => _missedCallController.stream;

  Call? _activeCall;
  Timer? _durationTimer;
  Timer? _ringTimeoutTimer;
  int _callDuration = 0;
  final Map<String, List<Call>> _historyByUser = <String, List<Call>>{};
  bool _preferRemoteSignaling = true;

  // Local UI state (not part of model)
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;

  @override
  Call? get activeCall => _activeCall;
  @override
  bool get hasActiveCall => _activeCall != null;
  @override
  bool get isMuted => _isMuted;
  @override
  bool get isSpeakerOn => _isSpeakerOn;
  @override
  bool get isVideoEnabled => _isVideoEnabled;
  @override
  bool get isFrontCamera => _isFrontCamera;

  /// Initiate an outgoing call.
  @override
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

    final remoteCallId = await _initiateRemoteCall(
      receiverId: receiverId,
      type: type,
    );
    final callId = remoteCallId ?? _generateId();

    _activeCall = Call(
      id: callId,
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
    if (remoteCallId != null) {
      _watchRemoteCall(remoteCallId);
    }

    return _activeCall!;
  }

  /// Accept an incoming call.
  ///
  /// For incoming video calls, [asType] can be used to accept as audio-only.
  @override
  Future<void> acceptCall({CallType? asType}) async {
    if (_activeCall == null) return;
    final resolvedType = asType ?? _activeCall!.type;
    await _invokeCallable('answerCall', <String, dynamic>{
      'callId': _activeCall!.id,
      'answer': <String, dynamic>{'acceptedType': resolvedType.name},
    });
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;

    _activeCall = _activeCall!.copyWith(
      type: resolvedType,
      status: CallStatus.ongoing,
      answeredAt: DateTime.now(),
    );
    _isVideoEnabled = resolvedType == CallType.video;

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.connected);
    _startDurationTimer();
  }

  /// Decline an incoming call.
  @override
  Future<void> declineCall() async {
    if (_activeCall == null) return;
    await _invokeCallable('endCall', <String, dynamic>{
      'callId': _activeCall!.id,
      'reason': CallEndReason.declined.name,
    });
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.declined,
      endedAt: DateTime.now(),
      endReason: CallEndReason.declined,
    );
    _recordCall(_activeCall!);

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  /// End the current call.
  @override
  Future<void> endCall() async {
    if (_activeCall == null) return;
    await _invokeCallable('endCall', <String, dynamic>{
      'callId': _activeCall!.id,
      'reason': CallEndReason.userHangup.name,
    });
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;

    _activeCall = _activeCall!.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
      duration: _callDuration,
      endReason: CallEndReason.userHangup,
    );
    _recordCall(_activeCall!);

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  /// Toggle mute state.
  @override
  void toggleMute() {
    _isMuted = !_isMuted;
    _emitCurrentState();
  }

  /// Toggle speaker state.
  @override
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _emitCurrentState();
  }

  /// Toggle video state (for video calls).
  @override
  void toggleVideo() {
    if (_activeCall?.type != CallType.video) return;
    _isVideoEnabled = !_isVideoEnabled;
    _emitCurrentState();
  }

  /// Switch camera (front/back).
  @override
  void switchCamera() {
    if (_activeCall?.type != CallType.video) return;
    _isFrontCamera = !_isFrontCamera;
    _emitCurrentState();
  }

  /// Handle incoming call (from push notification).
  @override
  void handleIncomingCall(Call incomingCall) {
    if (_activeCall != null) {
      // Already in a call, auto-decline
      return;
    }

    _activeCall = incomingCall;
    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.incoming);
    _watchRemoteCall(incomingCall.id);

    // Auto-end if not answered within timeout
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(Call.ringTimeout, () {
      if (_activeCall?.status == CallStatus.ringing) {
        _missedCall();
      }
    });
  }

  /// Get call history for a user.
  @override
  Future<List<Call>> getCallHistory(
    String userId, {
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId)
          .collection(_historySubcollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (before != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
      }
    } catch (_) {
      // Fall back to in-memory history when Firestore is unavailable.
    }

    final history = List<Call>.from(_historyByUser[userId] ?? const <Call>[]);
    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (before != null) {
      history.removeWhere((call) => !call.createdAt.isBefore(before));
    }
    if (history.length <= limit) return history;
    return history.take(limit).toList();
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
    _recordCall(_activeCall!);
    _missedCallController.add(_activeCall!);

    _callController.add(_activeCall!);
    _callStateController.add(CallUIState.ended);
    _cleanup();
  }

  void _recordCall(Call call) {
    _upsertHistoryEntry(call.callerId, call);
    _upsertHistoryEntry(call.receiverId, call);
    unawaited(_persistCallToFirestore(call));
  }

  void _upsertHistoryEntry(String userId, Call call) {
    final history = _historyByUser.putIfAbsent(userId, () => <Call>[]);
    final existingIndex = history.indexWhere((entry) => entry.id == call.id);
    if (existingIndex >= 0) {
      history[existingIndex] = call;
      return;
    }
    history.add(call);
  }

  Future<String?> _initiateRemoteCall({
    required String receiverId,
    required CallType type,
  }) async {
    final payload = await _invokeCallable('initiateCall', <String, dynamic>{
      'receiverId': receiverId,
      'type': type.name,
    });
    final callId = payload?['callId'];
    if (callId is String && callId.trim().isNotEmpty) {
      return callId.trim();
    }
    return null;
  }

  Future<Map<String, dynamic>?> _invokeCallable(
    String name,
    Map<String, dynamic> payload,
  ) async {
    if (!_preferRemoteSignaling) return null;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(name);
      final result = await callable
          .call<Map<String, dynamic>>(payload)
          .timeout(const Duration(seconds: 8));
      return result.data;
    } catch (_) {
      // Remote signaling is best-effort; local state remains source of truth.
    }
    return null;
  }

  void _watchRemoteCall(String callId) {
    _remoteCallSubscription?.cancel();
    _remoteCallSubscription = null;
    if (!_preferRemoteSignaling) return;
    try {
      _remoteCallSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .snapshots()
          .listen(_handleRemoteCallSnapshot, onError: (_) {});
    } catch (_) {
      _remoteCallSubscription = null;
    }
  }

  void _handleRemoteCallSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final active = _activeCall;
    if (active == null || !snapshot.exists || snapshot.id != active.id) return;

    final data = snapshot.data();
    if (data == null) return;

    final previousStatus = active.status;
    final nextStatus = _parseRemoteStatus(data['status']) ?? previousStatus;
    final updated = active.copyWith(
      status: nextStatus,
      type: _parseRemoteType(data['type']) ?? active.type,
      answeredAt: _parseTimestamp(data['answeredAt']) ?? active.answeredAt,
      endedAt: _parseTimestamp(data['endedAt']) ?? active.endedAt,
      endReason: _parseRemoteEndReason(data['endReason']) ?? active.endReason,
    );

    _activeCall = updated;
    _callController.add(updated);

    if (nextStatus == CallStatus.ongoing &&
        previousStatus != CallStatus.ongoing) {
      _ringTimeoutTimer?.cancel();
      _ringTimeoutTimer = null;
      _callStateController.add(CallUIState.connected);
      _startDurationTimer();
      return;
    }

    if (_isTerminalStatus(nextStatus) && !_isTerminalStatus(previousStatus)) {
      _ringTimeoutTimer?.cancel();
      _ringTimeoutTimer = null;
      if (nextStatus == CallStatus.missed) {
        _missedCallController.add(updated);
      }
      _recordCall(updated);
      _callStateController.add(CallUIState.ended);
      _cleanup();
    }
  }

  bool _isTerminalStatus(CallStatus status) {
    return status == CallStatus.ended ||
        status == CallStatus.missed ||
        status == CallStatus.declined ||
        status == CallStatus.failed;
  }

  CallStatus? _parseRemoteStatus(Object? raw) {
    final value = (raw as String?)?.trim().toLowerCase();
    switch (value) {
      case 'ringing':
        return CallStatus.ringing;
      case 'ongoing':
        return CallStatus.ongoing;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'declined':
        return CallStatus.declined;
      case 'failed':
        return CallStatus.failed;
      default:
        return null;
    }
  }

  CallType? _parseRemoteType(Object? raw) {
    final value = (raw as String?)?.trim().toLowerCase();
    switch (value) {
      case 'audio':
        return CallType.audio;
      case 'video':
        return CallType.video;
      default:
        return null;
    }
  }

  CallEndReason? _parseRemoteEndReason(Object? raw) {
    final value = (raw as String?)?.trim();
    if (value == null || value.isEmpty) return null;
    return CallEndReason.values.firstWhere(
      (reason) => reason.name == value,
      orElse: () => CallEndReason.unknown,
    );
  }

  DateTime? _parseTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> _persistCallToFirestore(Call call) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final payload = _toFirestorePayload(call);

      final callerRef = firestore
          .collection(_usersCollection)
          .doc(call.callerId)
          .collection(_historySubcollection)
          .doc(call.id);
      final receiverRef = firestore
          .collection(_usersCollection)
          .doc(call.receiverId)
          .collection(_historySubcollection)
          .doc(call.id);

      batch.set(callerRef, payload, SetOptions(merge: true));
      batch.set(receiverRef, payload, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  Map<String, dynamic> _toFirestorePayload(Call call) {
    return {
      'id': call.id,
      'callerId': call.callerId,
      'receiverId': call.receiverId,
      'type': call.type.name,
      'status': call.status.name,
      'createdAt': Timestamp.fromDate(call.createdAt),
      'answeredAt': call.answeredAt != null
          ? Timestamp.fromDate(call.answeredAt!)
          : null,
      'endedAt': call.endedAt != null
          ? Timestamp.fromDate(call.endedAt!)
          : null,
      'duration': call.duration,
      'endReason': call.endReason?.name,
      'callerName': call.callerName,
      'receiverName': call.receiverName,
      'callerPhotoUrl': call.callerPhotoUrl,
      'receiverPhotoUrl': call.receiverPhotoUrl,
    };
  }

  Call _fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAtRaw = data['createdAt'];
    final answeredAtRaw = data['answeredAt'];
    final endedAtRaw = data['endedAt'];

    DateTime? parseOptional(Object? raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
      return null;
    }

    return Call(
      id: data['id'] as String? ?? doc.id,
      callerId: data['callerId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CallStatus.ended,
      ),
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.tryParse(createdAtRaw as String? ?? '') ?? DateTime.now(),
      answeredAt: parseOptional(answeredAtRaw),
      endedAt: parseOptional(endedAtRaw),
      duration: data['duration'] as int?,
      endReason: data['endReason'] != null
          ? CallEndReason.values.firstWhere(
              (e) => e.name == data['endReason'],
              orElse: () => CallEndReason.unknown,
            )
          : null,
      callerName: data['callerName'] as String?,
      receiverName: data['receiverName'] as String?,
      callerPhotoUrl: data['callerPhotoUrl'] as String?,
      receiverPhotoUrl: data['receiverPhotoUrl'] as String?,
    );
  }

  void _emitCurrentState() {
    if (_activeCall != null) {
      _callController.add(_activeCall!);
    }
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
    _remoteCallSubscription?.cancel();
    _remoteCallSubscription = null;
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

  @override
  void dispose() {
    _durationTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    _remoteCallSubscription?.cancel();
    _callController.close();
    _callStateController.close();
    _missedCallController.close();
  }

  @visibleForTesting
  void clearHistoryForTest() {
    _historyByUser.clear();
  }

  @visibleForTesting
  void markActiveCallMissedForTest() {
    _missedCall();
  }

  @visibleForTesting
  void setPreferRemoteSignalingForTest(bool value) {
    _preferRemoteSignaling = value;
    if (!value) {
      _remoteCallSubscription?.cancel();
      _remoteCallSubscription = null;
    }
  }
}
