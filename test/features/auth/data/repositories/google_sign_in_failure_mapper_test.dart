import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/features/auth/data/repositories/impl/google_sign_in_failure_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  group('mapGoogleSignInFailure', () {
    test('maps canceled Google sign-in to providerCancelled', () {
      final failure = mapGoogleSignInFailure(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      expect(failure.type, AuthFailureType.providerCancelled);
      expect(failure.message, 'Google Sign-In was cancelled.');
    });

    test('maps client configuration failures to actionable iOS guidance', () {
      final failure = mapGoogleSignInFailure(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'Missing or invalid iOS client configuration.',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(failure.message, contains('enabled in Firebase Auth'));
      expect(failure.message, contains('iOS Google client configuration'));
    });

    test('maps keychain provider failures to entitlement guidance', () {
      final failure = mapGoogleSignInFailure(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: 'keychain error',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(failure.message, contains('cannot access the iOS keychain'));
      expect(failure.message, contains('keychain-sharing entitlement'));
      expect(failure.message, contains('physical iPhone'));
    });

    test('preserves missing-token guidance for plain exceptions', () {
      final failure = mapGoogleSignInFailure(
        Exception('Google Sign-In failed. Missing auth tokens.'),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(
        failure.message,
        'Google Sign-In did not return valid authentication tokens. Please try again.',
      );
    });

    test('maps firebase operation-not-allowed to provider guidance', () {
      final failure = mapGoogleSignInFailure(
        fb.FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Operation not allowed.',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(
        failure.message,
        'Google Sign-In is not enabled for this project yet.',
      );
    });

    test('maps account-exists-with-different-credential to emailAlreadyInUse',
        () {
      final failure = mapGoogleSignInFailure(
        fb.FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Account exists.',
        ),
      );

      expect(failure.type, AuthFailureType.emailAlreadyInUse);
      expect(failure.message, contains('different sign-in method'));
    });

    test('maps invalid-credential to invalidCredentials guidance', () {
      final failure = mapGoogleSignInFailure(
        fb.FirebaseAuthException(
          code: 'invalid-credential',
          message: 'expired',
        ),
      );

      expect(failure.type, AuthFailureType.invalidCredentials);
      expect(
        failure.message,
        'Google Sign-In credentials are invalid or expired.',
      );
    });

    test('maps too-many-requests and network-request-failed', () {
      final rateLimited = mapGoogleSignInFailure(
        fb.FirebaseAuthException(code: 'too-many-requests', message: 'slow'),
      );
      expect(rateLimited.type, AuthFailureType.rateLimited);

      final network = mapGoogleSignInFailure(
        fb.FirebaseAuthException(
          code: 'network-request-failed',
          message: 'offline',
        ),
      );
      expect(network.type, AuthFailureType.network);
    });
  });
}
