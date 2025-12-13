import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
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
    on<AuthSignedOut>(_onSignedOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _sub?.cancel();
      _sub = authRepository.authStateChanges().listen((user) {
        add(_AuthUserChanged(user));
      });
      add(_AuthUserChanged(null));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Could not connect to authentication. Please try again.',
      ));
    }
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
    try {
      await _sendOtp(phone: event.phoneNumber, emit: emit);
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Could not send code. Please try again.',
      ));
    }
  }

  Future<void> _onOtpSubmitted(
      AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      isLoading: true,
      errorMessage: null,
    ));
    try {
      final user = await authRepository.verifyOtp(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Invalid code. Please try again.',
      ));
    }
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
    try {
      await _sendOtp(phone: phone, emit: emit);
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Could not send code. Please try again.',
      ));
    }
  }

  Future<void> _onSignedOut(
      AuthSignedOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await authRepository.signOut();
      emit(AuthState.unknown());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not sign out. Try again.',
      ));
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
    emit(state.copyWith(
      status: AuthStatus.authenticating,
      phoneInProgress: phone,
      isLoading: true,
      errorMessage: null,
    ));
    try {
      await authRepository.sendOtp(phone);
      emit(state.copyWith(
        status: AuthStatus.otpSent,
        phoneInProgress: phone,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Could not send code. Please try again.',
      ));
    }
  }
}

class _AuthUserChanged extends AuthEvent {
  final CrushUser? user;
  _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
