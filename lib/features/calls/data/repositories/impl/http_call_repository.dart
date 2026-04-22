import 'dart:async';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/network/api_version.dart';

import 'package:crushhour/core/network/api_client.dart';
import '../call_repository.dart';
import 'call_contract_support.dart';

/// HTTP-based implementation of CallRepository.
///
/// Uses HTTP to get call credentials and manage call state.
/// The actual WebRTC/Agora connection is handled by the client.
class HttpCallRepository implements CallRepository {
  HttpCallRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  final _eventController = StreamController<CallEngineEvent>.broadcast();
  CallSession? _currentSession;

  @override
  Future<CallSession> startCall({
    required String matchId,
    required bool isVideoCall,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.callStart,
      body: {'match_id': matchId, 'is_video': isVideoCall},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      _eventController.add(
        CallEngineEvent(
          type: CallEngineEventType.error,
          error: result.error?.message ?? 'Failed to start call',
        ),
      );
      throw Exception(result.error?.message ?? 'Failed to start call');
    }

    _currentSession = callSessionFromStartResponse(
      result.data!,
      matchId: matchId,
      isVideoCall: isVideoCall,
    );

    // Emit joined event
    _eventController.add(
      CallEngineEvent(type: CallEngineEventType.joinedChannel),
    );

    return _currentSession!;
  }

  @override
  Future<void> endCall() async {
    if (_currentSession == null) return;

    final result = await _apiClient.post<void>(
      ApiEndpoints.callEnd,
      body: {'call_id': _currentSession!.channelName},
    );

    if (result.isFailure) {
      AppLogger.error(
        'HttpCallRepository: Failed to end call - ${result.error}',
      );
    }

    _currentSession = null;
  }

  @override
  Stream<CallEngineEvent> engineEvents() {
    return _eventController.stream;
  }

  /// Notify that the remote user joined.
  void notifyRemoteUserJoined(int remoteUid) {
    _eventController.add(
      CallEngineEvent(
        type: CallEngineEventType.userJoined,
        remoteUid: remoteUid,
      ),
    );
  }

  /// Notify that the remote user left.
  void notifyRemoteUserOffline(int remoteUid) {
    _eventController.add(
      CallEngineEvent(
        type: CallEngineEventType.userOffline,
        remoteUid: remoteUid,
      ),
    );
  }

  /// Notify of an error.
  void notifyError(String error) {
    _eventController.add(
      CallEngineEvent(type: CallEngineEventType.error, error: error),
    );
  }

  /// Dispose resources.
  void dispose() {
    _eventController.close();
  }
}
