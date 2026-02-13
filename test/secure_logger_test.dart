import 'package:crushhour/core/security/secure_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureLogger', () {
    late bool originalEnableSensitive;
    late bool originalRedactSensitive;

    setUp(() {
      originalEnableSensitive = SecureLogger.enableSensitiveLogging;
      originalRedactSensitive = SecureLogger.redactSensitiveData;
      SecureLogger.enableSensitiveLogging = true;
      SecureLogger.redactSensitiveData = true;
    });

    tearDown(() {
      SecureLogger.enableSensitiveLogging = originalEnableSensitive;
      SecureLogger.redactSensitiveData = originalRedactSensitive;
    });

    test('redactToken handles null/empty/short/long tokens', () {
      expect(SecureLogger.redactToken(null), '<empty>');
      expect(SecureLogger.redactToken(''), '<empty>');
      expect(SecureLogger.redactToken('abcd'), contains('abcd...abcd'));
      expect(
        SecureLogger.redactToken('abcdefghijklmnopqrst'),
        contains('abcd...qrst'),
      );
    });

    test('logging methods are callable without throwing', () {
      SecureLogger.debug('debug message');
      SecureLogger.warning('warn message');
      SecureLogger.error('error message');
      SecureLogger.error('error with details', StateError('boom'));

      SecureLogger.logToken(type: 'FCM', token: null, context: 'startup');
      SecureLogger.logToken(type: 'FCM', token: '', context: 'startup');
      SecureLogger.logToken(
        type: 'FCM',
        token: 'abcdefghijklmnopqrstuv',
        context: 'refresh',
      );
      SecureLogger.logTokenRefresh(type: 'FCM', token: null);
      SecureLogger.logTokenRefresh(type: 'FCM', token: 'token-value');
      SecureLogger.logTokenError(
        type: 'FCM',
        operation: 'subscribe',
        error: StateError('denied'),
      );

      SecureLogger.logAuth(
        event: 'login_success',
        userId: 'user_12345',
        metadata: const {'provider': 'email'},
      );
      SecureLogger.logSecurityEvent(
        event: 'rate_limit_triggered',
        severity: 'warning',
        details: const {'endpoint': '/auth/login'},
      );
    });

    test('OTP logging supports redacted and non-redacted modes', () {
      SecureLogger.redactSensitiveData = true;
      SecureLogger.logOtp(
        type: 'Email',
        recipient: 'alice@example.com',
        code: '123456',
      );

      SecureLogger.redactSensitiveData = false;
      SecureLogger.logOtp(type: 'SMS', recipient: '5551112222', code: '999999');
    });
  });
}
