import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';

void main() {
  group('AuthEvent', () {
    test('events with no payload have empty props and equatable semantics', () {
      expect(AuthStarted().props, isEmpty);
      expect(AuthEmailOtpCancelled().props, isEmpty);
      expect(AuthSignedOut().props, isEmpty);
      expect(AuthUserRefreshRequested().props, isEmpty);

      expect(AuthStarted(), AuthStarted());
      expect(AuthSignedOut(), AuthSignedOut());
    });

    test('phone auth events expose expected payloads', () {
      expect(AuthPhoneSubmitted('+15550001111').props, ['+15550001111']);
      expect(AuthOtpSubmitted('+15550001111', '123456').props, [
        '+15550001111',
        '123456',
      ]);
      expect(AuthOtpResendRequested('+15550001111').props, ['+15550001111']);
    });

    test('email link and password events expose expected payloads', () {
      expect(AuthEmailLinkRequested('a@b.com').props, ['a@b.com']);
      expect(AuthEmailLinkSubmitted('a@b.com', 'magic-link').props, [
        'a@b.com',
        'magic-link',
      ]);
      expect(AuthEmailPasswordSubmitted('a@b.com', 'secret').props, [
        'a@b.com',
        'secret',
      ]);
    });

    test('email OTP events expose expected payloads', () {
      expect(AuthEmailOtpRequested('user@example.com').props, [
        'user@example.com',
      ]);
      expect(AuthEmailOtpSubmitted('user@example.com', '654321').props, [
        'user@example.com',
        '654321',
      ]);
      expect(AuthEmailOtpResendRequested('user@example.com').props, [
        'user@example.com',
      ]);
    });
  });
}
