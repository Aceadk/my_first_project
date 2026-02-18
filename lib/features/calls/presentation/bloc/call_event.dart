import 'package:equatable/equatable.dart';
import '../../domain/repositories/call_repository.dart';

abstract class CallEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CallStarted extends CallEvent {
  final String matchId;
  final bool isVideoCall;

  CallStarted({required this.matchId, required this.isVideoCall});

  @override
  List<Object?> get props => [matchId, isVideoCall];
}

class CallEnded extends CallEvent {}

class CallEngineUpdated extends CallEvent {
  final CallEngineEvent event;

  CallEngineUpdated(this.event);

  @override
  List<Object?> get props => [event];
}
