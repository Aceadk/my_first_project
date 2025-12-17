import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/core/config/config_validation.dart';

void main() {
  group('ConfigValidation.billingIssues', () {
    test('detects placeholder or invalid billing values', () {
      final issues = ConfigValidation.billingIssues(
        values: BillingValues(
          plusPriceId: 'price_plus_placeholder',
          successUrl: 'http://invalid',
          cancelUrl: '',
        ),
      );

      expect(issues, isNotEmpty);
      expect(
        issues.any((i) => i.contains('plusPriceId')),
        isTrue,
      );
    });

    test('returns empty when billing values look valid', () {
      final issues = ConfigValidation.billingIssues(
        values: BillingValues(
          plusPriceId: 'price_123',
          successUrl: 'https://example.com/success',
          cancelUrl: 'https://example.com/cancel',
        ),
      );
      expect(issues, isEmpty);
    });
  });
}
