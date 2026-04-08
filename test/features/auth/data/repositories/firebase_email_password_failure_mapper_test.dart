import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/features/auth/data/repositories/impl/firebase_email_password_failure_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapFirebaseEmailPasswordFailure', () {
    test('maps missing login account to accountNotFound', () {
      final failure = mapFirebaseEmailPasswordFailure(
        fb.FirebaseAuthException(code: 'user-not-found'),
        isSignIn: true,
      );

      expect(failure.type, AuthFailureType.accountNotFound);
      expect(failure.message, contains('No account found'));
      expect(failure.message, contains('Create an account first'));
    });

    test('maps wrong password to invalid credentials', () {
      final failure = mapFirebaseEmailPasswordFailure(
        fb.FirebaseAuthException(code: 'wrong-password'),
        isSignIn: true,
      );

      expect(failure.type, AuthFailureType.invalidCredentials);
      expect(failure.message, 'Invalid email or password. Please try again.');
    });

    test('maps duplicate sign-up email to emailAlreadyInUse', () {
      final failure = mapFirebaseEmailPasswordFailure(
        fb.FirebaseAuthException(code: 'email-already-in-use'),
        isSignIn: false,
      );

      expect(failure.type, AuthFailureType.emailAlreadyInUse);
      expect(failure.message, contains('already exists'));
      expect(failure.message, contains('Please sign in instead'));
    });
  });
}
