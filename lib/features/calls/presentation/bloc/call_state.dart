import 'package:equatable/equatable.dart';

enum CallStatus { idle, connecting, inCall, ended, error }

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

  CallState copyWith({
    CallStatus? status,
    String? matchId,
    bool? isVideoCall,
    int? localUid,
    int? remoteUid,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      matchId: matchId ?? this.matchId,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      localUid: localUid ?? this.localUid,
      remoteUid: remoteUid ?? this.remoteUid,
      errorMessage: errorMessage ?? this.errorMessage,
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
