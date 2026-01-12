import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/core/utils/result.dart';

// Events
abstract class PhoneAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PhoneAuthReset extends PhoneAuthEvent {}

class PhoneAuthSubmitted extends PhoneAuthEvent {
  final String phoneNumber;
  PhoneAuthSubmitted(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class PhoneOtpSubmitted extends PhoneAuthEvent {
  final String phoneNumber;
  final String otp;
  PhoneOtpSubmitted(this.phoneNumber, this.otp);

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class PhoneOtpResendRequested extends PhoneAuthEvent {
  final String phoneNumber;
  PhoneOtpResendRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

// State
enum PhoneAuthStatus {
  initial,
  sendingOtp,
  otpSent,
  verifying,
  verified,
  error,
}

class PhoneAuthState extends Equatable {
  final PhoneAuthStatus status;
  final String? phoneNumber;
  final CrushUser? user;
  final bool isLoading;
  final String? errorMessage;

  const PhoneAuthState({
    required this.status,
    this.phoneNumber,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  factory PhoneAuthState.initial() => const PhoneAuthState(
        status: PhoneAuthStatus.initial,
      );

  PhoneAuthState copyWith({
    PhoneAuthStatus? status,
    String? phoneNumber,
    CrushUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PhoneAuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, phoneNumber, user, isLoading, errorMessage];
}

// Bloc
class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  final AuthRepository authRepository;

  PhoneAuthBloc({required this.authRepository})
      : super(PhoneAuthState.initial()) {
    on<PhoneAuthReset>(_onReset);
    on<PhoneAuthSubmitted>(_onPhoneSubmitted);
    on<PhoneOtpSubmitted>(_onOtpSubmitted);
    on<PhoneOtpResendRequested>(_onOtpResendRequested);
  }

  void _onReset(
    PhoneAuthReset event,
    Emitter<PhoneAuthState> emit,
  ) {
    emit(PhoneAuthState.initial());
  }

  Future<void> _onPhoneSubmitted(
    PhoneAuthSubmitted event,
    Emitter<PhoneAuthState> emit,
  ) async {
    await _sendOtp(phone: event.phoneNumber, emit: emit);
  }

  Future<void> _onOtpSubmitted(
    PhoneOtpSubmitted event,
    Emitter<PhoneAuthState> emit,
  ) async {
    emit(state.copyWith(
      status: PhoneAuthStatus.verifying,
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.verifyOtp(
        phoneNumber: event.phoneNumber,
        otp: event.otp,
      ),
      logLabel: 'PhoneAuthBloc.verifyOtp',
      fallbackError: 'Invalid code. Please try again.',
    );

    final user = result.data;
    emit(state.copyWith(
      status: user == null ? PhoneAuthStatus.error : PhoneAuthStatus.verified,
      user: user,
      isLoading: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onOtpResendRequested(
    PhoneOtpResendRequested event,
    Emitter<PhoneAuthState> emit,
  ) async {
    final phone = event.phoneNumber.isNotEmpty
        ? event.phoneNumber
        : (state.phoneNumber ?? '');

    if (phone.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Enter your phone number to resend the code.',
      ));
      return;
    }

    await _sendOtp(phone: phone, emit: emit);
  }

  Future<void> _sendOtp({
    required String phone,
    required Emitter<PhoneAuthState> emit,
  }) async {
    emit(state.copyWith(
      status: PhoneAuthStatus.sendingOtp,
      phoneNumber: phone,
      isLoading: true,
      clearError: true,
    ));

    final result = await Result.guard(
      () => authRepository.sendOtp(phone),
      logLabel: 'PhoneAuthBloc.sendOtp',
      fallbackError: 'Could not send code. Please try again.',
    );

    if (!result.isSuccess) {
      emit(state.copyWith(
        status: PhoneAuthStatus.error,
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }

    // Handle verification bypass mode
    if (authRepository.isVerificationBypassEnabled) {
      emit(state.copyWith(
        status: PhoneAuthStatus.initial,
        phoneNumber: phone,
        isLoading: false,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: PhoneAuthStatus.otpSent,
      phoneNumber: phone,
      isLoading: false,
      clearError: true,
    ));
  }
}
