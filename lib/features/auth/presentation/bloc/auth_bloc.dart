import 'dart:async';
import 'package:crushhour/core/session/session_bootstrap_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/domain/usecases/auth_flow_use_cases.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/services/user_data_clearance_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthFlowUseCases authFlowUseCases;
  final SessionBootstrapService _sessionBootstrapService;
  StreamSubscription<CrushUser?>? _sub;
  bool _didInitialRefresh = false;

  AuthBloc({
    required AuthRepository authRepository,
    AuthFlowUseCases? authFlowUseCases,
    SessionBootstrapService? sessionBootstrapService,
  }) : authFlowUseCases = authFlowUseCases ?? AuthFlowUseCases(authRepository),
       _sessionBootstrapService =
           sessionBootstrapService ??
           SessionBootstrapService(
             authFlowUseCases:
                 authFlowUseCases ?? AuthFlowUseCases(authRepository),
           ),
       super(AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthOtpResendRequested>(_onOtpResendRequested);
    on<AuthEmailLinkRequested>(_onEmailLinkRequested);
    on<AuthEmailLinkSubmitted>(_onEmailLinkSubmitted);
    on<AuthEmailPasswordSubmitted>(_onEmailPasswordSubmitted);
    on<AuthEmailOtpRequested>(_onEmailOtpRequested);
    on<AuthEmailOtpSubmitted>(_onEmailOtpSubmitted);
    on<AuthEmailOtpResendRequested>(_onEmailOtpResendRequested);
    on<AuthEmailOtpCancelled>(_onEmailOtpCancelled);
    on<AuthSignedOut>(_onSignedOut);
    on<AuthUserRefreshRequested>(_onUserRefreshRequested);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final bootstrapResult = await _sessionBootstrapService.bootstrap(
      existingSubscription: _sub,
      onUserChanged: (user) => add(_AuthUserChanged(user)),
    );
    if (!bootstrapResult.isSuccess) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: bootstrapResult.errorMessage,
        ),
      );
      return;
    }
    _sub = bootstrapResult.data;
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user == null) {
      _didInitialRefresh = false;
    } else if (!_didInitialRefresh) {
      _didInitialRefresh = true;
      add(AuthUserRefreshRequested());
    }
    emit(
      state.copyWith(
        status: event.user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: event.user,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onPhoneSubmitted(
    AuthPhoneSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _sendOtp(phone: event.phoneNumber, emit: emit);
  }

  Future<void> _onOtpSubmitted(
    AuthOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.verifyOtp(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
    );
    final user = result.data;
    if (user != null) {
      await AnalyticsService.instance.logLogin(method: 'phone');
      await AnalyticsService.instance.logPhoneVerificationCompleted(
        success: true,
      );
    } else {
      await AnalyticsService.instance.logPhoneVerificationCompleted(
        success: false,
      );
    }
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user ?? state.user,
        isLoading: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  Future<void> _onOtpResendRequested(
    AuthOtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final phone = event.phoneNumber.isNotEmpty
        ? event.phoneNumber
        : (state.phoneInProgress ?? '');
    if (phone.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Enter your phone number to resend the code.',
        ),
      );
      return;
    }
    await _sendOtp(phone: phone, emit: emit);
  }

  Future<void> _onEmailLinkRequested(
    AuthEmailLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter your email address.'));
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        emailInProgress: email,
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.sendEmailSignInLink(email: email);
    if (!result.isSuccess) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: result.errorMessage,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.emailLinkSent,
        emailInProgress: email,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onEmailLinkSubmitted(
    AuthEmailLinkSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        emailInProgress: event.email.trim().isEmpty
            ? state.emailInProgress
            : event.email.trim(),
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.signInWithEmailLink(
      email: event.email.trim(),
      emailLink: event.emailLink,
    );
    final user = result.data;
    if (user != null) {
      await AnalyticsService.instance.logLogin(method: 'email_link');
    }
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user ?? state.user,
        isLoading: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  Future<void> _onEmailPasswordSubmitted(
    AuthEmailPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        emailInProgress: event.email.trim(),
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.signInWithEmailPassword(
      email: event.email.trim(),
      password: event.password,
    );
    final user = result.data;
    if (user != null) {
      await AnalyticsService.instance.logLogin(method: 'email_password');
    }
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user ?? state.user,
        isLoading: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  Future<void> _onEmailOtpRequested(
    AuthEmailOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final identifier = event.identifier.trim();
    if (identifier.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter your username or email.'));
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        emailOtpIdentifier: identifier,
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.requestEmailOtp(
      identifier: identifier,
      purpose: EmailOtpPurpose.login,
    );
    if (!result.isSuccess) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: result.errorMessage,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.emailOtpSent,
        emailOtpIdentifier: identifier,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onEmailOtpSubmitted(
    AuthEmailOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        emailOtpIdentifier: event.identifier.trim(),
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.verifyEmailOtp(
      identifier: event.identifier.trim(),
      otp: event.otp.trim(),
      purpose: EmailOtpPurpose.login,
    );
    final user = result.data;
    if (user != null) {
      await AnalyticsService.instance.logLogin(method: 'email_otp');
    }
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user ?? state.user,
        isLoading: false,
        errorMessage: result.errorMessage,
      ),
    );
  }

  Future<void> _onEmailOtpResendRequested(
    AuthEmailOtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final identifier = event.identifier.trim().isNotEmpty
        ? event.identifier.trim()
        : '';
    if (identifier.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Enter your username or email to resend the code.',
        ),
      );
      return;
    }
    await _onEmailOtpRequested(AuthEmailOtpRequested(identifier), emit);
  }

  void _onEmailOtpCancelled(
    AuthEmailOtpCancelled event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        emailOtpIdentifier: null,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // CRITICAL: Clear all user-specific data BEFORE signing out
    // This prevents the next user from seeing previous user's data
    await UserDataClearanceService.instance.clearAllUserData();

    final result = await authFlowUseCases.signOut();
    if (!result.isSuccess) {
      emit(state.copyWith(isLoading: false, errorMessage: result.errorMessage));
      return;
    }
    emit(AuthState.unknown());
  }

  Future<void> _onUserRefreshRequested(
    AuthUserRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await authFlowUseCases.refreshCurrentUser();
    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(user: result.data, status: AuthStatus.authenticated));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> _sendOtp({
    required String phone,
    required Emitter<AuthState> emit,
  }) async {
    await AnalyticsService.instance.logPhoneVerificationStarted();
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        phoneInProgress: phone,
        isLoading: true,
        errorMessage: null,
      ),
    );
    final result = await authFlowUseCases.sendOtp(phoneNumber: phone);
    if (!result.isSuccess) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: result.errorMessage,
        ),
      );
      return;
    }
    if (authFlowUseCases.isVerificationBypassEnabled) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          phoneInProgress: phone,
          isLoading: false,
          errorMessage: null,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.otpSent,
        phoneInProgress: phone,
        isLoading: false,
        errorMessage: null,
      ),
    );
  }
}

class _AuthUserChanged extends AuthEvent {
  final CrushUser? user;
  _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
