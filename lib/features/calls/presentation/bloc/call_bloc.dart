import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/call_repository.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository callRepository;
  StreamSubscription<CallEngineEvent>? _engineSub;

  CallBloc({required this.callRepository}) : super(const CallState()) {
    on<CallStarted>(_onCallStarted);
    on<CallEnded>(_onCallEnded);
    on<CallEngineUpdated>(_onCallEngineUpdated);

    _engineSub = callRepository.engineEvents().listen((event) {
      add(CallEngineUpdated(event));
    });
  }

  Future<void> _onCallStarted(
      CallStarted event, Emitter<CallState> emit) async {
    emit(state.copyWith(
      status: CallStatus.connecting,
      matchId: event.matchId,
      isVideoCall: event.isVideoCall,
    ));

    try {
      final session = await callRepository.startCall(
        matchId: event.matchId,
        isVideoCall: event.isVideoCall,
      );
      emit(state.copyWith(
        status: CallStatus.connecting,
        localUid: session.localUid,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CallStatus.error,
        errorMessage: 'Call failed: $e',
      ));
    }
  }

  Future<void> _onCallEnded(CallEnded event, Emitter<CallState> emit) async {
    await callRepository.endCall();
    emit(state.copyWith(status: CallStatus.ended));
  }

  void _onCallEngineUpdated(CallEngineUpdated event, Emitter<CallState> emit) {
    switch (event.event.type) {
      case CallEngineEventType.joinedChannel:
        emit(state.copyWith(status: CallStatus.inCall));
        break;
      case CallEngineEventType.userJoined:
        emit(state.copyWith(
          status: CallStatus.inCall,
          remoteUid: event.event.remoteUid,
        ));
        break;
      case CallEngineEventType.userOffline:
        // If remote leaves, we can end the call
        emit(state.copyWith(remoteUid: null));
        break;
      case CallEngineEventType.error:
        emit(state.copyWith(
          status: CallStatus.error,
          errorMessage: event.event.error,
        ));
        break;
    }
  }

  @override
  Future<void> close() {
    _engineSub?.cancel();
    return super.close();
  }
}
