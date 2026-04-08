import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

AuthFailure mapFirebaseEmailPasswordFailure(
  fb.FirebaseAuthException error, {
  required bool isSignIn,
}) {
  switch (error.code) {
    case 'user-not-found':
      return AuthFailure(
        AuthFailureType.accountNotFound,
        message:
            'No account found for this email. Create an account first, then try signing in again.',
        cause: error,
      );
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-email':
      return AuthFailure(
        AuthFailureType.invalidCredentials,
        message: 'Invalid email or password. Please try again.',
        cause: error,
      );
    case 'email-already-in-use':
      return AuthFailure(
        AuthFailureType.emailAlreadyInUse,
        message:
            'An account with this email already exists. Please sign in instead, or use a different email address.',
        cause: error,
      );
    case 'weak-password':
      return AuthFailure(
        AuthFailureType.weakPassword,
        message: 'Password does not meet security requirements.',
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
    case 'operation-not-allowed':
      return AuthFailure(
        AuthFailureType.unsupportedProvider,
        message: isSignIn
            ? 'Email/password sign-in is not enabled for this project.'
            : 'Email/password sign-up is not enabled for this project.',
        cause: error,
      );
    default:
      return AuthFailureMapper.from(
        error,
        fallbackType: isSignIn
            ? AuthFailureType.invalidCredentials
            : AuthFailureType.unknown,
        fallbackMessage: isSignIn
            ? 'Could not sign in. Please try again.'
            : 'Could not create account. Please try again.',
      );
  }
}
