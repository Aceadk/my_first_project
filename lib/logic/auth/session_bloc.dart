import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
import 'package:crushhour/core/utils/result.dart';
import '../../core/security/session_manager.dart';

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

class SessionTimeoutOccurred extends SessionEvent {}

class SessionActivityRecorded extends SessionEvent {}

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
  final SessionManager _sessionManager = SessionManager.instance;
  StreamSubscription<CrushUser?>? _authSubscription;

  /// Session timeout duration. Default is 30 minutes.
  /// Can be configured at startup.
  final Duration sessionTimeout;

  SessionBloc({
    required this.authRepository,
    this.sessionTimeout = const Duration(minutes: 30),
  }) : super(SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionUserChanged>(_onUserChanged);
    on<SessionSignOutRequested>(_onSignOutRequested);
    on<SessionDevBypassRequested>(_onDevBypassRequested);
    on<SessionTimeoutOccurred>(_onSessionTimeout);
    on<SessionActivityRecorded>(_onActivityRecorded);
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

        // Initialize session manager for inactivity timeout
        await _sessionManager.initialize(
          timeout: sessionTimeout,
          onExpired: () => add(SessionTimeoutOccurred()),
        );

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
      () async {
        await authRepository.signOut();
        await _sessionManager.clearSession();
      },
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

  Future<void> _onSessionTimeout(
    SessionTimeoutOccurred event,
    Emitter<SessionState> emit,
  ) async {
    // Auto-logout due to inactivity
    await authRepository.signOut();
    await _sessionManager.clearSession();

    emit(state.copyWith(
      status: SessionStatus.unauthenticated,
      user: null,
      isLoading: false,
      errorMessage: 'Session expired due to inactivity. Please sign in again.',
    ));
  }

  void _onActivityRecorded(
    SessionActivityRecorded event,
    Emitter<SessionState> emit,
  ) {
    // Record user activity to reset inactivity timer
    _sessionManager.recordActivity();
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
    _sessionManager.dispose();
    return super.close();
  }
}
