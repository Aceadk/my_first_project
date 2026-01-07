import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
import '../../core/result.dart';

// Events
abstract class SessionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionStarted extends SessionEvent {}

class SessionUserChanged extends SessionEvent {
  final CrushUser? user;
  SessionUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class SessionSignOutRequested extends SessionEvent {}

class SessionDevBypassRequested extends SessionEvent {
  final String identifier;
  final String password;
  SessionDevBypassRequested(this.identifier, this.password);

  @override
  List<Object?> get props => [identifier, password];
}

// State
enum SessionStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
}

class SessionState extends Equatable {
  final SessionStatus status;
  final CrushUser? user;
  final bool isLoading;
  final String? errorMessage;

  const SessionState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  factory SessionState.unknown() => const SessionState(
        status: SessionStatus.unknown,
      );

  SessionState copyWith({
    SessionStatus? status,
    CrushUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, errorMessage];
}

// Bloc
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AuthRepository authRepository;
  StreamSubscription<CrushUser?>? _authSubscription;

  SessionBloc({required this.authRepository}) : super(SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionUserChanged>(_onUserChanged);
    on<SessionSignOutRequested>(_onSignOutRequested);
    on<SessionDevBypassRequested>(_onDevBypassRequested);
  }

  Future<void> _onStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await Result.guard(
      () async {
        await _authSubscription?.cancel();
        await authRepository.bootstrapSession();

        _authSubscription = authRepository.authStateChanges().listen((user) {
          add(SessionUserChanged(user));
        });

        return true;
      },
      logLabel: 'SessionBloc.bootstrap',
      fallbackError: 'Could not connect to authentication. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(
        status: SessionStatus.unauthenticated,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
    }
  }

  void _onUserChanged(
    SessionUserChanged event,
    Emitter<SessionState> emit,
  ) {
    emit(state.copyWith(
      status: event.user == null
          ? SessionStatus.unauthenticated
          : SessionStatus.authenticated,
      user: event.user,
      isLoading: false,
      clearError: true,
    ));
  }

  Future<void> _onSignOutRequested(
    SessionSignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await Result.guard(
      () => authRepository.signOut(),
      logLabel: 'SessionBloc.signOut',
      fallbackError: 'Could not sign out. Try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }

    emit(SessionState.unknown());
  }

  Future<void> _onDevBypassRequested(
    SessionDevBypassRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(
      status: SessionStatus.authenticating,
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.devLoginBypass(
        identifier: event.identifier,
        password: event.password,
      ),
      logLabel: 'SessionBloc.devBypass',
      fallbackError: 'Dev bypass failed.',
    );

    final user = result.data;
    if (user == null) {
      emit(state.copyWith(
        status: SessionStatus.unauthenticated,
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Dev bypass not available.',
      ));
      return;
    }

    emit(state.copyWith(
      status: SessionStatus.authenticated,
      user: user,
      isLoading: false,
      clearError: true,
    ));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
