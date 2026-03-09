import 'package:crushhour/core/errors.dart';

/// Canonical auth failure types for data/domain/presentation mapping.
enum AuthFailureType {
  invalidCredentials,
  accountNotFound,
  invalidOtp,
  otpExpired,
  otpNotRequested,
  invalidEmailLink,
  emailAlreadyInUse,
  usernameAlreadyInUse,
  weakPassword,
  rateLimited,
  unauthorized,
  network,
  unsupportedProvider,
  providerCancelled,
  sessionMissing,
  unknown,
}

extension AuthFailureTypeX on AuthFailureType {
  String get code {
    switch (this) {
      case AuthFailureType.invalidCredentials:
        return 'auth_invalid_credentials';
      case AuthFailureType.accountNotFound:
        return 'auth_account_not_found';
      case AuthFailureType.invalidOtp:
        return 'auth_invalid_otp';
      case AuthFailureType.otpExpired:
        return 'auth_otp_expired';
      case AuthFailureType.otpNotRequested:
        return 'auth_otp_not_requested';
      case AuthFailureType.invalidEmailLink:
        return 'auth_invalid_email_link';
      case AuthFailureType.emailAlreadyInUse:
        return 'auth_email_already_in_use';
      case AuthFailureType.usernameAlreadyInUse:
        return 'auth_username_already_in_use';
      case AuthFailureType.weakPassword:
        return 'auth_weak_password';
      case AuthFailureType.rateLimited:
        return 'auth_rate_limited';
      case AuthFailureType.unauthorized:
        return 'auth_unauthorized';
      case AuthFailureType.network:
        return 'auth_network_error';
      case AuthFailureType.unsupportedProvider:
        return 'auth_unsupported_provider';
      case AuthFailureType.providerCancelled:
        return 'auth_provider_cancelled';
      case AuthFailureType.sessionMissing:
        return 'auth_session_missing';
      case AuthFailureType.unknown:
        return 'auth_unknown';
    }
  }

  String get defaultMessage {
    switch (this) {
      case AuthFailureType.invalidCredentials:
        return 'Invalid credentials. Please try again.';
      case AuthFailureType.accountNotFound:
        return 'No account found for this sign-in method.';
      case AuthFailureType.invalidOtp:
        return 'Invalid code. Please try again.';
      case AuthFailureType.otpExpired:
        return 'Code expired. Please request a new one.';
      case AuthFailureType.otpNotRequested:
        return 'Request a code first and then try again.';
      case AuthFailureType.invalidEmailLink:
        return 'Invalid or expired email link.';
      case AuthFailureType.emailAlreadyInUse:
        return 'This email is already in use.';
      case AuthFailureType.usernameAlreadyInUse:
        return 'This username is already taken.';
      case AuthFailureType.weakPassword:
        return 'Password does not meet security requirements.';
      case AuthFailureType.rateLimited:
        return 'Too many attempts. Please wait and try again.';
      case AuthFailureType.unauthorized:
        return 'You are not authorized to perform this action.';
      case AuthFailureType.network:
        return 'Network error. Check your connection and try again.';
      case AuthFailureType.unsupportedProvider:
        return 'Sign-in method is not supported on this platform.';
      case AuthFailureType.providerCancelled:
        return 'Sign-in was cancelled.';
      case AuthFailureType.sessionMissing:
        return 'Please sign in again to continue.';
      case AuthFailureType.unknown:
        return 'Authentication failed. Please try again.';
    }
  }

  static AuthFailureType? fromCode(String code) {
    final normalized = code
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll('/', '_')
        .replaceAll('.', '_');

    switch (normalized) {
      case 'auth_invalid_credentials':
      case 'wrong_password':
      case 'invalid_credential':
      case 'invalid_email_or_password':
      case 'incorrect_password':
      case 'password_is_incorrect':
      case 'current_password_is_incorrect':
        return AuthFailureType.invalidCredentials;
      case 'auth_account_not_found':
      case 'user_not_found':
      case 'no_account_found':
        return AuthFailureType.accountNotFound;
      case 'auth_invalid_otp':
      case 'invalid_verification_code':
      case 'invalid_code':
        return AuthFailureType.invalidOtp;
      case 'auth_otp_expired':
      case 'code_expired':
      case 'expired_code':
      case 'expired_action_code':
      case 'otp_expired':
        return AuthFailureType.otpExpired;
      case 'auth_otp_not_requested':
      case 'no_otp_requested':
      case 'no_verification_in_progress':
      case 'invalid_verification_id':
        return AuthFailureType.otpNotRequested;
      case 'auth_invalid_email_link':
      case 'invalid_sign_in_link':
      case 'invalid_action_code':
        return AuthFailureType.invalidEmailLink;
      case 'auth_email_already_in_use':
      case 'email_already_in_use':
      case 'account_exists_with_different_credential':
        return AuthFailureType.emailAlreadyInUse;
      case 'auth_username_already_in_use':
      case 'username_already_in_use':
      case 'username_taken':
        return AuthFailureType.usernameAlreadyInUse;
      case 'auth_weak_password':
      case 'weak_password':
        return AuthFailureType.weakPassword;
      case 'auth_rate_limited':
      case 'too_many_requests':
      case 'quota_exceeded':
        return AuthFailureType.rateLimited;
      case 'auth_unauthorized':
      case 'permission_denied':
      case 'forbidden':
      case 'operation_not_allowed':
      case 'user_disabled':
        return AuthFailureType.unauthorized;
      case 'auth_network_error':
      case 'network_request_failed':
      case 'network_error':
      case 'socket_exception':
      case 'timeout':
        return AuthFailureType.network;
      case 'auth_unsupported_provider':
      case 'provider_not_supported':
        return AuthFailureType.unsupportedProvider;
      case 'auth_provider_cancelled':
      case 'cancelled':
      case 'sign_in_cancelled':
        return AuthFailureType.providerCancelled;
      case 'auth_session_missing':
      case 'no_user_logged_in':
      case 'requires_recent_login':
        return AuthFailureType.sessionMissing;
      case 'auth_unknown':
        return AuthFailureType.unknown;
      default:
        return null;
    }
  }
}

/// Typed auth exception that carries a normalized auth failure code.
class AuthFailure extends RepositoryException {
  AuthFailure(this.type, {String? message, this.cause})
    : super(type.code, message ?? type.defaultMessage);

  final AuthFailureType type;
  final Object? cause;
}

/// Maps arbitrary auth-layer errors into [AuthFailure].
class AuthFailureMapper {
  static AuthFailure from(
    Object error, {
    AuthFailureType fallbackType = AuthFailureType.unknown,
    String? fallbackMessage,
  }) {
    if (error is AuthFailure) {
      return error;
    }

    if (error is RepositoryException) {
      final byCode = AuthFailureTypeX.fromCode(error.code);
      final mappedType =
          byCode ?? _typeFromMessage(error.message, fallbackType);
      return AuthFailure(
        mappedType,
        message: _resolveMessage(
          mappedType: mappedType,
          fallbackType: fallbackType,
          fallbackMessage: fallbackMessage,
          originalMessage: error.message,
        ),
        cause: error,
      );
    }

    final dynamic maybeWithCode = error;
    String? runtimeCode;
    try {
      final code = maybeWithCode.code;
      if (code is String && code.trim().isNotEmpty) {
        runtimeCode = code;
      }
    } catch (_) {
      runtimeCode = null;
    }

    final byRuntimeCode = runtimeCode == null
        ? null
        : AuthFailureTypeX.fromCode(runtimeCode);
    final originalMessage = _extractMessage(error);
    final mappedType =
        byRuntimeCode ?? _typeFromMessage(originalMessage, fallbackType);

    return AuthFailure(
      mappedType,
      message: _resolveMessage(
        mappedType: mappedType,
        fallbackType: fallbackType,
        fallbackMessage: fallbackMessage,
        originalMessage: originalMessage,
      ),
      cause: error,
    );
  }

  static AuthFailureType _typeFromMessage(
    String message,
    AuthFailureType fallbackType,
  ) {
    final normalized = message.toLowerCase().trim();
    if (normalized.isEmpty) return fallbackType;

    if (normalized.contains('too-many-requests') ||
        normalized.contains('too many requests') ||
        normalized.contains('rate limit')) {
      return AuthFailureType.rateLimited;
    }
    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('internet connection') ||
        normalized.contains('timeout')) {
      return AuthFailureType.network;
    }
    if (normalized.contains('invalid sign-in link') ||
        normalized.contains('invalid or expired email link') ||
        normalized.contains('expired email link') ||
        normalized.contains('invalid email link')) {
      return AuthFailureType.invalidEmailLink;
    }
    if (normalized.contains('no otp requested') ||
        normalized.contains('no verification in progress')) {
      return AuthFailureType.otpNotRequested;
    }
    if (normalized.contains('otp expired') ||
        normalized.contains('code expired')) {
      return AuthFailureType.otpExpired;
    }
    if (normalized.contains('invalid otp') ||
        normalized.contains('invalid code') ||
        normalized.contains('invalid verification code') ||
        normalized.contains('invalid email otp') ||
        normalized.contains('invalid or expired code')) {
      return AuthFailureType.invalidOtp;
    }
    if (normalized.contains('already exists') && normalized.contains('email')) {
      return AuthFailureType.emailAlreadyInUse;
    }
    if (normalized.contains('username') &&
        (normalized.contains('already taken') ||
            normalized.contains('already exists'))) {
      return AuthFailureType.usernameAlreadyInUse;
    }
    if (normalized.contains('not supported on this platform') ||
        normalized.contains('not available on this device')) {
      return AuthFailureType.unsupportedProvider;
    }
    if (normalized.contains('cancelled')) {
      return AuthFailureType.providerCancelled;
    }
    if (normalized.contains('no user logged in') ||
        normalized.contains('please sign in again')) {
      return AuthFailureType.sessionMissing;
    }
    if (normalized.contains('user not found') ||
        normalized.contains('no account found')) {
      return AuthFailureType.accountNotFound;
    }
    if (normalized.contains('invalid credentials') ||
        normalized.contains('invalid email or password') ||
        normalized.contains('incorrect password') ||
        normalized.contains('wrong password')) {
      return AuthFailureType.invalidCredentials;
    }
    if (normalized.contains('weak password')) {
      return AuthFailureType.weakPassword;
    }
    if (normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('permission denied')) {
      return AuthFailureType.unauthorized;
    }
    return fallbackType;
  }

  static String _resolveMessage({
    required AuthFailureType mappedType,
    required AuthFailureType fallbackType,
    required String? fallbackMessage,
    required String originalMessage,
  }) {
    if (mappedType == fallbackType && fallbackMessage != null) {
      return fallbackMessage;
    }
    if (mappedType != AuthFailureType.unknown) {
      return mappedType.defaultMessage;
    }
    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      return fallbackMessage;
    }
    if (originalMessage.isNotEmpty) {
      return originalMessage;
    }
    return mappedType.defaultMessage;
  }

  static String _extractMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.substring('Exception:'.length).trim();
    }
    return raw;
  }
}
