import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/security/session_manager.dart';
import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/core/services/analytics_service.dart';

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

class SessionTimeoutOccurred extends SessionEvent {}

class SessionActivityRecorded extends SessionEvent {}

// State
enum SessionStatus { unknown, unauthenticated, authenticating, authenticated }

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

  factory SessionState.unknown() =>
      const SessionState(status: SessionStatus.unknown);

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
      emit(
        state.copyWith(
          status: SessionStatus.unauthenticated,
          isLoading: false,
          errorMessage: result.errorMessage,
        ),
      );
    }
  }

  Future<void> _onUserChanged(
    SessionUserChanged event,
    Emitter<SessionState> emit,
  ) async {
    final user = event.user;
    final analytics = AnalyticsService.instance;

    // Register/unregister FCM token and analytics based on auth state
    if (user != null) {
      await PushNotificationService.instance.registerForUser(user.id);

      // Set analytics user ID and properties
      await analytics.setUserId(user.id);
      await analytics.setUserProperties(
        subscriptionPlan: user.plan.name,
        gender: user.profile?.gender,
        age: user.profile?.age,
        country: user.profile?.country,
        isVerified: user.isIdVerified,
      );
      await analytics.logLogin(method: 'session_restore');
    } else {
      await analytics.setUserId(null);
    }

    emit(
      state.copyWith(
        status: user == null
            ? SessionStatus.unauthenticated
            : SessionStatus.authenticated,
        user: user,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> _onSignOutRequested(
    SessionSignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await Result.guard(
      () async {
        // Track logout
        await AnalyticsService.instance.logLogout();
        await AnalyticsService.instance.setUserId(null);

        // Unregister FCM token before signing out
        await PushNotificationService.instance.unregisterForUser();
        await authRepository.signOut();
        await _sessionManager.clearSession();
      },
      logLabel: 'SessionBloc.signOut',
      fallbackError: 'Could not sign out. Try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(isLoading: false, errorMessage: result.errorMessage));
      return;
    }

    emit(SessionState.unknown());
  }

  Future<void> _onSessionTimeout(
    SessionTimeoutOccurred event,
    Emitter<SessionState> emit,
  ) async {
    // Auto-logout due to inactivity
    await PushNotificationService.instance.unregisterForUser();
    await authRepository.signOut();
    await _sessionManager.clearSession();

    emit(
      state.copyWith(
        status: SessionStatus.unauthenticated,
        user: null,
        isLoading: false,
        errorMessage:
            'Session expired due to inactivity. Please sign in again.',
      ),
    );
  }

  void _onActivityRecorded(
    SessionActivityRecorded event,
    Emitter<SessionState> emit,
  ) {
    // Record user activity to reset inactivity timer
    _sessionManager.recordActivity();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _sessionManager.dispose();
    return super.close();
  }
}
