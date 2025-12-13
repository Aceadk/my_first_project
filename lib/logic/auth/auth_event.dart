import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthPhoneSubmitted extends AuthEvent {
  final String phoneNumber;
  AuthPhoneSubmitted(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOtpSubmitted extends AuthEvent {
  final String phoneNumber;
  final String otp;
  AuthOtpSubmitted(this.phoneNumber, this.otp);

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class AuthOtpResendRequested extends AuthEvent {
  final String phoneNumber;
  AuthOtpResendRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthSignedOut extends AuthEvent {}
