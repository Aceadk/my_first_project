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
  });
}
