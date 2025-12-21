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

class AuthEmailLinkRequested extends AuthEvent {
  final String email;
  AuthEmailLinkRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthEmailLinkSubmitted extends AuthEvent {
  final String email;
  final String emailLink;
  AuthEmailLinkSubmitted(this.email, this.emailLink);

  @override
  List<Object?> get props => [email, emailLink];
}

class AuthEmailPasswordSubmitted extends AuthEvent {
  final String email;
  final String password;
  AuthEmailPasswordSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthEmailOtpRequested extends AuthEvent {
  final String identifier;
  AuthEmailOtpRequested(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class AuthEmailOtpSubmitted extends AuthEvent {
  final String identifier;
  final String otp;
  AuthEmailOtpSubmitted(this.identifier, this.otp);

  @override
  List<Object?> get props => [identifier, otp];
}

class AuthEmailOtpResendRequested extends AuthEvent {
  final String identifier;
  AuthEmailOtpResendRequested(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class AuthSignedOut extends AuthEvent {}
