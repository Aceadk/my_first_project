import 'package:crushhour/core/utils/auth_state_reset_policy.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

CrushUser _user(String id) => CrushUser(
  id: id,
  phoneNumber: '+10000000000',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  tier: SubscriptionTier.free,
);

void main() {
  group('AuthStateResetPolicy', () {
    test('does not reset on first authenticated emission', () {
      final policy = AuthStateResetPolicy();

      expect(policy.shouldResetFor(_user('user-1')), isFalse);
    });

    test('resets on logout after an authenticated user', () {
      final policy = AuthStateResetPolicy();
      policy.shouldResetFor(_user('user-1'));

      expect(policy.shouldResetFor(null), isTrue);
    });

    test('resets on authenticated user switch', () {
      final policy = AuthStateResetPolicy();
      policy.shouldResetFor(_user('user-1'));

      expect(policy.shouldResetFor(_user('user-2')), isTrue);
    });

    test('does not reset on repeated same user id', () {
      final policy = AuthStateResetPolicy();
      policy.shouldResetFor(_user('user-1'));

      expect(policy.shouldResetFor(_user('user-1')), isFalse);
    });
  });
}
