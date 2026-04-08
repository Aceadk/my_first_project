import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

const String _googleIosConfigMessage =
    'Google Sign-In could not complete on iOS. Check that Google Sign-In is enabled in Firebase Auth and that the iOS Google client configuration matches your app bundle and URL scheme.';
const String _googleSimulatorKeychainMessage =
    'Google Sign-In cannot access the iOS keychain. Ensure the iOS target includes the Google keychain-sharing entitlement, then retry on a physical iPhone if the simulator still reports a keychain error.';

AuthFailure mapGoogleSignInFailure(Object error) {
  if (error is AuthFailure) {
    return error;
  }

  final errorMessage = error.toString().replaceFirst('Exception:', '').trim();
  final normalizedMessage = errorMessage.toLowerCase();

  if (normalizedMessage.contains('not supported on this platform')) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message: 'Google Sign-In is not supported on this platform.',
      cause: error,
    );
  }

  if (normalizedMessage.contains('missing auth tokens')) {
    return AuthFailure(
      AuthFailureType.unsupportedProvider,
      message:
          'Google Sign-In did not return valid authentication tokens. Please try again.',
      cause: error,
    );
  }

  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return AuthFailure(
          AuthFailureType.providerCancelled,
          message: 'Google Sign-In was cancelled.',
          cause: error,
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        if ((error.description ?? '').toLowerCase().contains(
          'keychain error',
        )) {
          return AuthFailure(
            AuthFailureType.unsupportedProvider,
            message: _googleSimulatorKeychainMessage,
            cause: error,
          );
        }
        return AuthFailure(
          AuthFailureType.unsupportedProvider,
          message: _googleIosConfigMessage,
          cause: error,
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return AuthFailure(
          AuthFailureType.unsupportedProvider,
          message:
              'Google Sign-In could not present its sign-in screen. Try again with the app in the foreground.',
          cause: error,
        );
      case GoogleSignInExceptionCode.interrupted:
        return AuthFailure(
          AuthFailureType.unknown,
          message: 'Google Sign-In was interrupted. Please try again.',
          cause: error,
        );
      case GoogleSignInExceptionCode.unknownError:
      case GoogleSignInExceptionCode.userMismatch:
        return AuthFailure(
          AuthFailureType.unknown,
          message:
              error.description ?? 'Google Sign-In failed. Please try again.',
          cause: error,
        );
    }
  }

  if (error is fb.FirebaseAuthException) {
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
          message: 'Google Sign-In is not enabled for this project yet.',
          cause: error,
        );
      case 'invalid-credential':
        return AuthFailure(
          AuthFailureType.invalidCredentials,
          message: 'Google Sign-In credentials are invalid or expired.',
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
  }

  return AuthFailureMapper.from(
    error,
    fallbackType: AuthFailureType.unsupportedProvider,
    fallbackMessage: 'Google Sign-In failed. Please try again.',
  );
}
