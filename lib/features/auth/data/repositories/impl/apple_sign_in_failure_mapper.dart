import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'provider_firebase_auth_failure_mapper.dart';

const String _appleIdSetupMessage =
    'Apple Sign-In could not complete. Make sure this device is signed into an Apple ID. If you are using the iPhone simulator, open Settings, sign in to Apple Account, and try again.';
const String _appleRetryMessage = 'Apple Sign-In failed. Please try again.';

AuthFailure mapAppleSignInFailure(Object error) {
  if (error is AuthFailure) {
    return error;
  }

  final errorMessage = error.toString().replaceFirst('Exception:', '').trim();
  final normalizedMessage = errorMessage.toLowerCase();

  if (normalizedMessage.contains('not available on this device') ||
      normalizedMessage.contains('not supported on this platform')) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message: 'Apple Sign-In is not available on this device.',
      cause: error,
    );
  }

  if (normalizedMessage.contains('missing identity token')) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message:
          'Apple Sign-In did not return a valid identity token. Please try again.',
      cause: error,
    );
  }

  if (error is SignInWithAppleNotSupportedException) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message: 'Apple Sign-In is not available on this device.',
      cause: error,
    );
  }

  if (error is SignInWithAppleCredentialsException) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message: _appleIdSetupMessage,
      cause: error,
    );
  }

  if (error is SignInWithAppleAuthorizationException) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return AuthFailure(
          AuthFailureType.providerCancelled,
          message: 'Apple Sign-In was cancelled.',
          cause: error,
        );
      case AuthorizationErrorCode.failed:
      case AuthorizationErrorCode.invalidResponse:
      case AuthorizationErrorCode.notHandled:
      case AuthorizationErrorCode.notInteractive:
      case AuthorizationErrorCode.unknown:
        return AuthFailure(
          AuthFailureType.unsupportedProvider,
          message: _appleIdSetupMessage,
          cause: error,
        );
      case AuthorizationErrorCode.credentialExport:
      case AuthorizationErrorCode.credentialImport:
      case AuthorizationErrorCode.matchedExcludedCredential:
        return AuthFailure(
          AuthFailureType.unsupportedProvider,
          message: _appleRetryMessage,
          cause: error,
        );
    }
  }

  if (error is fb.FirebaseAuthException) {
    final mapped = mapProviderFirebaseAuthFailure(
      error,
      providerLabel: 'Apple Sign-In',
      invalidCredentialMessage:
          'Apple Sign-In credentials were rejected. Please try again.',
      invalidCredentialCodes: const <String>{
        'invalid-credential',
        'missing-or-invalid-nonce',
      },
    );
    if (mapped != null) {
      return mapped;
    }
  }

  return AuthFailureMapper.from(
    error,
    fallbackType: AuthFailureType.unsupportedProvider,
    fallbackMessage: 'Apple Sign-In failed. Please try again.',
  );
}
