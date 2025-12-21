import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
import '../../core/result.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<CrushUser?>? _sub;

  AuthBloc({required this.authRepository}) : super(AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthOtpResendRequested>(_onOtpResendRequested);
    on<AuthEmailLinkRequested>(_onEmailLinkRequested);
    on<AuthEmailLinkSubmitted>(_onEmailLinkSubmitted);
    on<AuthEmailPasswordSubmitted>(_onEmailPasswordSubmitted);
    on<AuthSignedOut>(_onSignedOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () async {
        await _sub?.cancel();
        final sub = authRepository.authStateChanges().listen((user) {
          add(_AuthUserChanged(user));
        });
        add(_AuthUserChanged(null));
        return sub;
      },
      logLabel: 'AuthRepository.authStateChanges',
      fallbackError:
          'Could not connect to authentication. Please try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }
    _sub = result.data;
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
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
      AuthPhoneSubmitted event, Emitter<AuthState> emit) async {
    await _sendOtp(phone: event.phoneNumber, emit: emit);
  }

  Future<void> _onOtpSubmitted(
      AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      isLoading: true,
      errorMessage: null,
    ));
    final result = await Result.guard(
      () => authRepository.verifyOtp(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      ),
      logLabel: 'AuthRepository.verifyOtp',
      fallbackError: 'Invalid code. Please try again.',
    );
    final user = result.data;
    emit(state.copyWith(
      status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user ?? state.user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onOtpResendRequested(
      AuthOtpResendRequested event, Emitter<AuthState> emit) async {
    final phone = event.phoneNumber.isNotEmpty
        ? event.phoneNumber
        : (state.phoneInProgress ?? '');
    if (phone.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Enter your phone number to resend the code.',
      ));
      return;
    }
    await _sendOtp(phone: phone, emit: emit);
  }

  Future<void> _onEmailLinkRequested(
      AuthEmailLinkRequested event, Emitter<AuthState> emit) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter your email address.'));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      emailInProgress: email,
      isLoading: true,
      errorMessage: null,
    ));
    final result = await Result.guard(
      () => authRepository.sendEmailSignInLink(email),
      logLabel: 'AuthRepository.sendEmailSignInLink',
      fallbackError: 'Could not send sign-in link. Please try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.emailLinkSent,
      emailInProgress: email,
      isLoading: false,
      errorMessage: null,
    ));
  }

  Future<void> _onEmailLinkSubmitted(
      AuthEmailLinkSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      emailInProgress: event.email.trim().isEmpty
          ? state.emailInProgress
          : event.email.trim(),
      isLoading: true,
      errorMessage: null,
    ));
    final result = await Result.guard(
      () => authRepository.signInWithEmailLink(
        email: event.email.trim(),
        emailLink: event.emailLink,
      ),
      logLabel: 'AuthRepository.signInWithEmailLink',
      fallbackError: 'Invalid or expired email link.',
    );
    final user = result.data;
    emit(state.copyWith(
      status:
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user ?? state.user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onEmailPasswordSubmitted(
      AuthEmailPasswordSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      emailInProgress: event.email.trim(),
      isLoading: true,
      errorMessage: null,
    ));
    final result = await Result.guard(
      () => authRepository.signInWithEmailPassword(
        email: event.email.trim(),
        password: event.password,
      ),
      logLabel: 'AuthRepository.signInWithEmailPassword',
      fallbackError: 'Could not sign in. Please try again.',
    );
    final user = result.data;
    emit(state.copyWith(
      status:
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user ?? state.user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onSignedOut(
      AuthSignedOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () => authRepository.signOut(),
      logLabel: 'AuthRepository.signOut',
      fallbackError: 'Could not sign out. Try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }
    emit(AuthState.unknown());
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
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      phoneInProgress: phone,
      isLoading: true,
      errorMessage: null,
    ));
    final result = await Result.guard(
      () => authRepository.sendOtp(phone),
      logLabel: 'AuthRepository.sendOtp',
      fallbackError: 'Could not send code. Please try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.otpSent,
      phoneInProgress: phone,
      isLoading: false,
      errorMessage: null,
    ));
  }
}

class _AuthUserChanged extends AuthEvent {
  final CrushUser? user;
  _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
