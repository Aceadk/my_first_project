import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Shared mapping for the `FirebaseAuthException`s that federated provider
/// sign-in (Apple, Google) surface in common.
///
/// Returns `null` when [error] is not one of the shared provider error codes so
/// each provider mapper can fall back to its own provider-specific handling.
/// [providerLabel] customizes the `operation-not-allowed` message, while
/// [invalidCredentialMessage]/[invalidCredentialCodes] let each provider map
/// its credential-rejection codes (Apple also reports `missing-or-invalid-nonce`).
AuthFailure? mapProviderFirebaseAuthFailure(
  fb.FirebaseAuthException error, {
  required String providerLabel,
  required String invalidCredentialMessage,
  Set<String> invalidCredentialCodes = const <String>{'invalid-credential'},
}) {
  switch (error.code) {
    case 'account-exists-with-different-credential':
      return AuthFailure(
        AuthFailureType.emailAlreadyInUse,
        message:
            'An account already exists with the same email but a different sign-in method.',
        cause: error,
      );
    case 'operation-not-allowed':
      return AuthFailure(
        AuthFailureType.unsupportedProvider,
        message: '$providerLabel is not enabled for this project yet.',
        cause: error,
      );
    case 'too-many-requests':
      return AuthFailure(
        AuthFailureType.rateLimited,
        message: AuthFailureType.rateLimited.defaultMessage,
        cause: error,
      );
    case 'network-request-failed':
      return AuthFailure(
        AuthFailureType.network,
        message: AuthFailureType.network.defaultMessage,
        cause: error,
      );
  }

  if (invalidCredentialCodes.contains(error.code)) {
    return AuthFailure(
      AuthFailureType.invalidCredentials,
      message: invalidCredentialMessage,
      cause: error,
    );
  }

  return null;
}
