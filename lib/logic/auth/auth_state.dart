import 'package:equatable/equatable.dart';
import '../../data/models/user.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  otpSent,
  authenticating,
  authenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final CrushUser? user;
  final String? phoneInProgress;
  final bool isLoading;
  final String? errorMessage;
  static const _unset = Object();

  const AuthState({
    required this.status,
    required this.user,
    required this.phoneInProgress,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthState.unknown() => const AuthState(
        status: AuthStatus.unknown,
        user: null,
        phoneInProgress: null,
        isLoading: false,
        errorMessage: null,
      );

  AuthState copyWith({
    AuthStatus? status,
    CrushUser? user,
    String? phoneInProgress,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phoneInProgress: phoneInProgress ?? this.phoneInProgress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, phoneInProgress, isLoading, errorMessage];
}
