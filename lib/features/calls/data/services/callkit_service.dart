import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS CallKit bridge for native incoming call UI and call actions.
import 'package:crushhour/features/calls/domain/repositories/callkit_repository.dart';

class CallKitService implements CallKitRepository {
  CallKitService._();

  static final CallKitService instance = CallKitService._();

  static const MethodChannel _methodChannel = MethodChannel(
    'crushhour/callkit',
  );
  static const EventChannel _eventChannel = EventChannel(
    'crushhour/callkit_events',
  );

  Stream<CallKitEvent>? _events;

  @override
  Stream<CallKitEvent> get events {
    _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((raw) {
          final map = _toStringMap(raw);
          return _parseEvent(map);
        })
        .where((event) => event.type != CallKitEventType.unknown);
    return _events!;
  }

  @override
  Future<bool> showIncomingCall({
    required String callId,
    required String callerId,
    required bool isVideoCall,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
  }) async {
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('showIncomingCall', {
            'callId': callId,
            'callerId': callerId,
            'callerName': callerName,
            'callerPhotoUrl': callerPhotoUrl,
            'receiverId': receiverId,
            'isVideoCall': isVideoCall,
            'callType': isVideoCall ? 'video' : 'audio',
          });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> endCall({
    required String callId,
    String reason = 'ended',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('endCall', {
        'callId': callId,
        'reason': reason,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setMuted({required String callId, required bool isMuted}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('setMuted', {
        'callId': callId,
        'isMuted': isMuted,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static CallKitEvent parseEventForTest(Map<String, dynamic> raw) {
    return _parseEvent(raw);
  }

  static CallKitEvent _parseEvent(Map<String, dynamic> raw) {
    final type = _parseEventType(raw['type'] as String?);
    final payload = _toStringMap(raw['payload']);
    final callId = _firstNonEmptyString(raw['callId'], payload['callId']);
    final isMuted = _asBool(raw['isMuted'] ?? payload['isMuted']);
    final error = _firstNonEmptyString(raw['error']);

    return CallKitEvent(
      type: type,
      callId: callId,
      isMuted: isMuted,
      error: error,
      payload: payload,
    );
  }

  static CallKitEventType _parseEventType(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'answered':
        return CallKitEventType.answered;
      case 'declined':
        return CallKitEventType.declined;
      case 'ended':
        return CallKitEventType.ended;
      case 'muted_changed':
        return CallKitEventType.mutedChanged;
      case 'incoming_reported':
        return CallKitEventType.incomingReported;
      case 'incoming_report_failed':
        return CallKitEventType.incomingReportFailed;
      case 'audio_activated':
        return CallKitEventType.audioActivated;
      case 'audio_deactivated':
        return CallKitEventType.audioDeactivated;
      default:
        return CallKitEventType.unknown;
    }
  }

  static Map<String, dynamic> _toStringMap(Object? raw) {
    if (raw is! Map) return const <String, dynamic>{};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static String? _firstNonEmptyString(Object? first, [Object? second]) {
    for (final raw in <Object?>[first, second]) {
      final value = raw is String ? raw.trim() : '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static bool? _asBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final lowered = raw.trim().toLowerCase();
      if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
        return true;
      }
      if (lowered == 'false' || lowered == '0' || lowered == 'no') {
        return false;
      }
    }
    return null;
  }
}
