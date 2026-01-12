import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart';
import 'package:crushhour/core/utils/result.dart';

// Events
abstract class EmailAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EmailAuthReset extends EmailAuthEvent {}

class EmailLinkRequested extends EmailAuthEvent {
  final String email;
  EmailLinkRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class EmailLinkSubmitted extends EmailAuthEvent {
  final String email;
  final String emailLink;
  EmailLinkSubmitted(this.email, this.emailLink);

  @override
  List<Object?> get props => [email, emailLink];
}

class EmailPasswordSubmitted extends EmailAuthEvent {
  final String email;
  final String password;
  EmailPasswordSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class EmailOtpRequested extends EmailAuthEvent {
  final String identifier;
  EmailOtpRequested(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class EmailOtpSubmitted extends EmailAuthEvent {
  final String identifier;
  final String otp;
  EmailOtpSubmitted(this.identifier, this.otp);

  @override
  List<Object?> get props => [identifier, otp];
}

class EmailOtpResendRequested extends EmailAuthEvent {
  final String identifier;
  EmailOtpResendRequested(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

// State
enum EmailAuthStatus {
  initial,
  sendingLink,
  linkSent,
  sendingOtp,
  otpSent,
  authenticating,
  authenticated,
  error,
}

class EmailAuthState extends Equatable {
  final EmailAuthStatus status;
  final String? email;
  final String? identifier;
  final CrushUser? user;
  final bool isLoading;
  final String? errorMessage;

  const EmailAuthState({
    required this.status,
    this.email,
    this.identifier,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  factory EmailAuthState.initial() => const EmailAuthState(
        status: EmailAuthStatus.initial,
      );

  EmailAuthState copyWith({
    EmailAuthStatus? status,
    String? email,
    String? identifier,
    CrushUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmailAuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      identifier: identifier ?? this.identifier,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, email, identifier, user, isLoading, errorMessage];
}

// Bloc
class EmailAuthBloc extends Bloc<EmailAuthEvent, EmailAuthState> {
  final AuthRepository authRepository;

  EmailAuthBloc({required this.authRepository})
      : super(EmailAuthState.initial()) {
    on<EmailAuthReset>(_onReset);
    on<EmailLinkRequested>(_onLinkRequested);
    on<EmailLinkSubmitted>(_onLinkSubmitted);
    on<EmailPasswordSubmitted>(_onPasswordSubmitted);
    on<EmailOtpRequested>(_onOtpRequested);
    on<EmailOtpSubmitted>(_onOtpSubmitted);
    on<EmailOtpResendRequested>(_onOtpResendRequested);
  }

  void _onReset(
    EmailAuthReset event,
    Emitter<EmailAuthState> emit,
  ) {
    emit(EmailAuthState.initial());
  }

  Future<void> _onLinkRequested(
    EmailLinkRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter your email address.'));
      return;
    }

    emit(state.copyWith(
      status: EmailAuthStatus.sendingLink,
      email: email,
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.sendEmailSignInLink(email),
      logLabel: 'EmailAuthBloc.sendEmailLink',
      fallbackError: 'Could not send sign-in link. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(
        status: EmailAuthStatus.error,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }

    emit(state.copyWith(
      status: EmailAuthStatus.linkSent,
      email: email,
      isLoading: false,
      clearError: true,
    ));
  }

  Future<void> _onLinkSubmitted(
    EmailLinkSubmitted event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(state.copyWith(
      status: EmailAuthStatus.authenticating,
      email: event.email.trim().isEmpty ? state.email : event.email.trim(),
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.signInWithEmailLink(
        email: event.email.trim(),
        emailLink: event.emailLink,
      ),
      logLabel: 'EmailAuthBloc.signInWithLink',
      fallbackError: 'Invalid or expired email link.',
    );

    final user = result.data;
    emit(state.copyWith(
      status:
          user == null ? EmailAuthStatus.error : EmailAuthStatus.authenticated,
      user: user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onPasswordSubmitted(
    EmailPasswordSubmitted event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(state.copyWith(
      status: EmailAuthStatus.authenticating,
      email: event.email.trim(),
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.signInWithEmailPassword(
        email: event.email.trim(),
        password: event.password,
      ),
      logLabel: 'EmailAuthBloc.signInWithPassword',
      fallbackError: 'Could not sign in. Please try again.',
    );

    final user = result.data;
    emit(state.copyWith(
      status:
          user == null ? EmailAuthStatus.error : EmailAuthStatus.authenticated,
      user: user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onOtpRequested(
    EmailOtpRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    final identifier = event.identifier.trim();
    if (identifier.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter your username or email.'));
      return;
    }

    emit(state.copyWith(
      status: EmailAuthStatus.sendingOtp,
      identifier: identifier,
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.requestEmailOtp(
        identifier: identifier,
        purpose: EmailOtpPurpose.login,
      ),
      logLabel: 'EmailAuthBloc.requestOtp',
      fallbackError: 'Could not send code. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(
        status: EmailAuthStatus.error,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }

    emit(state.copyWith(
      status: EmailAuthStatus.otpSent,
      identifier: identifier,
      isLoading: false,
      clearError: true,
    ));
  }

  Future<void> _onOtpSubmitted(
    EmailOtpSubmitted event,
    Emitter<EmailAuthState> emit,
  ) async {
    emit(state.copyWith(
      status: EmailAuthStatus.authenticating,
      identifier: event.identifier.trim(),
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.verifyEmailOtp(
        identifier: event.identifier.trim(),
        otp: event.otp.trim(),
        purpose: EmailOtpPurpose.login,
      ),
      logLabel: 'EmailAuthBloc.verifyOtp',
      fallbackError: 'Invalid or expired code. Please try again.',
    );

    final user = result.data;
    emit(state.copyWith(
      status:
          user == null ? EmailAuthStatus.error : EmailAuthStatus.authenticated,
      user: user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onOtpResendRequested(
    EmailOtpResendRequested event,
    Emitter<EmailAuthState> emit,
  ) async {
    final identifier = event.identifier.trim().isNotEmpty
        ? event.identifier.trim()
        : (state.identifier ?? '');

    if (identifier.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Enter your username or email to resend the code.',
      ));
      return;
    }

    add(EmailOtpRequested(identifier));
  }
}
