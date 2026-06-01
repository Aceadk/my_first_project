import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/features/auth/data/repositories/impl/apple_sign_in_failure_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  group('mapAppleSignInFailure', () {
    test('maps canceled authorization to providerCancelled', () {
      final failure = mapAppleSignInFailure(
        const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'The operation was canceled.',
        ),
      );

      expect(failure.type, AuthFailureType.providerCancelled);
      expect(failure.message, 'Apple Sign-In was cancelled.');
    });

    test('maps failed authorization to Apple ID setup guidance', () {
      final failure = mapAppleSignInFailure(
        const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.failed,
          message: 'The operation couldn’t be completed.',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(failure.message, contains('signed into an Apple ID'));
      expect(failure.message, contains('iPhone simulator'));
    });

    test('maps credential-related authorization errors to retry guidance', () {
      const codes = <AuthorizationErrorCode>[
        AuthorizationErrorCode.credentialExport,
        AuthorizationErrorCode.credentialImport,
        AuthorizationErrorCode.matchedExcludedCredential,
      ];

      for (final code in codes) {
        final failure = mapAppleSignInFailure(
          SignInWithAppleAuthorizationException(
            code: code,
            message: 'Credential operation failed.',
          ),
        );

        expect(failure.type, AuthFailureType.unsupportedProvider);
        expect(failure.message, 'Apple Sign-In failed. Please try again.');
      }
    });

    test('maps credentials exceptions to Apple ID setup guidance', () {
      final failure = mapAppleSignInFailure(
        const SignInWithAppleCredentialsException(
          message: 'No credentials found in the keychain.',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(failure.message, contains('signed into an Apple ID'));
    });

    test('preserves unsupported-device guidance for plain exceptions', () {
      final failure = mapAppleSignInFailure(
        Exception('Apple Sign-In is not available on this device.'),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(failure.message, 'Apple Sign-In is not available on this device.');
    });

    test('maps firebase operation-not-allowed to provider guidance', () {
      final failure = mapAppleSignInFailure(
        fb.FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Operation not allowed.',
        ),
      );

      expect(failure.type, AuthFailureType.unsupportedProvider);
      expect(
        failure.message,
        'Apple Sign-In is not enabled for this project yet.',
      );
    });

    test('maps account-exists-with-different-credential to emailAlreadyInUse',
        () {
      final failure = mapAppleSignInFailure(
        fb.FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Account exists.',
        ),
      );

      expect(failure.type, AuthFailureType.emailAlreadyInUse);
      expect(failure.message, contains('different sign-in method'));
    });

    test('maps invalid-credential and missing-or-invalid-nonce to retry', () {
      for (final code in const <String>[
        'invalid-credential',
        'missing-or-invalid-nonce',
      ]) {
        final failure = mapAppleSignInFailure(
          fb.FirebaseAuthException(code: code, message: 'bad nonce'),
        );

        expect(failure.type, AuthFailureType.invalidCredentials);
        expect(
          failure.message,
          'Apple Sign-In credentials were rejected. Please try again.',
        );
      }
    });

    test('maps too-many-requests and network-request-failed', () {
      final rateLimited = mapAppleSignInFailure(
        fb.FirebaseAuthException(code: 'too-many-requests', message: 'slow'),
      );
      expect(rateLimited.type, AuthFailureType.rateLimited);

      final network = mapAppleSignInFailure(
        fb.FirebaseAuthException(
          code: 'network-request-failed',
          message: 'offline',
        ),
      );
      expect(network.type, AuthFailureType.network);
    });
  });
}
