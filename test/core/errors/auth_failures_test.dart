import 'package:crushhour/core/errors.dart';
import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailureMapper', () {
    test('maps OTP request-missing message to otpNotRequested', () {
      final mapped = AuthFailureMapper.from(
        Exception('No OTP requested for this phone number'),
      );

      expect(mapped.type, AuthFailureType.otpNotRequested);
      expect(mapped.code, AuthFailureType.otpNotRequested.code);
      expect(mapped.message, AuthFailureType.otpNotRequested.defaultMessage);
    });

    test('maps expired code message to otpExpired', () {
      final mapped = AuthFailureMapper.from(
        Exception('OTP expired. Please request a new code.'),
      );

      expect(mapped.type, AuthFailureType.otpExpired);
      expect(mapped.message, AuthFailureType.otpExpired.defaultMessage);
    });

    test('maps repository code to invalidCredentials', () {
      final mapped = AuthFailureMapper.from(
        RepositoryException('wrong-password', 'Incorrect password'),
      );

      expect(mapped.type, AuthFailureType.invalidCredentials);
      expect(mapped.code, AuthFailureType.invalidCredentials.code);
      expect(mapped.message, AuthFailureType.invalidCredentials.defaultMessage);
    });

    test('prefers fallback message for matching fallback type', () {
      final mapped = AuthFailureMapper.from(
        Exception('Unknown social failure'),
        fallbackType: AuthFailureType.unsupportedProvider,
        fallbackMessage: 'Google Sign-In failed. Please try again.',
      );

      expect(mapped.type, AuthFailureType.unsupportedProvider);
      expect(mapped.message, 'Google Sign-In failed. Please try again.');
    });

    test('uses fallback type/message when error cannot be classified', () {
      final mapped = AuthFailureMapper.from(
        Exception('Something odd happened'),
        fallbackType: AuthFailureType.unknown,
        fallbackMessage: 'Could not complete authentication.',
      );

      expect(mapped.type, AuthFailureType.unknown);
      expect(mapped.code, AuthFailureType.unknown.code);
      expect(mapped.message, 'Could not complete authentication.');
    });
  });
}
