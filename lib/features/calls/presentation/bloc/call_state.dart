import 'package:equatable/equatable.dart';

enum CallStatus { idle, connecting, inCall, ended, error }

/// Sentinel used by [CallState.copyWith] to distinguish "not provided" from
/// "explicitly set to null" for nullable fields.
const _sentinel = Object();

class CallState extends Equatable {
  final CallStatus status;
  final String? matchId;
  final bool isVideoCall;
  final int? localUid;
  final int? remoteUid;
  final String? errorMessage;

  const CallState({
    this.status = CallStatus.idle,
    this.matchId,
    this.isVideoCall = true,
    this.localUid,
    this.remoteUid,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Nullable fields ([remoteUid], [errorMessage], [matchId], [localUid]) can
  /// be explicitly set to `null` to clear them. Omitting a field keeps the
  /// current value.
  CallState copyWith({
    CallStatus? status,
    Object? matchId = _sentinel,
    bool? isVideoCall,
    Object? localUid = _sentinel,
    Object? remoteUid = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return CallState(
      status: status ?? this.status,
      matchId: matchId == _sentinel ? this.matchId : matchId as String?,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      localUid: localUid == _sentinel ? this.localUid : localUid as int?,
      remoteUid: remoteUid == _sentinel ? this.remoteUid : remoteUid as int?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        matchId,
        isVideoCall,
        localUid,
        remoteUid,
        errorMessage,
      ];
}
