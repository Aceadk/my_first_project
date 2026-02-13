import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/promo_code.dart';

void main() {
  group('PromoCode', () {
    test('isValid respects expiration and max redemptions', () {
      final valid = PromoCode(
        code: 'WELCOME50',
        type: PromoCodeType.discount,
        discountPercent: 50,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        maxRedemptions: 100,
        currentRedemptions: 25,
      );
      expect(valid.isValid, isTrue);
      expect(valid.isExpired, isFalse);
      expect(valid.isMaxedOut, isFalse);

      final expired = PromoCode(
        code: 'OLD',
        type: PromoCodeType.discount,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isValid, isFalse);
      expect(expired.isExpired, isTrue);

      const maxed = PromoCode(
        code: 'LIMITED',
        type: PromoCodeType.freeTrial,
        maxRedemptions: 10,
        currentRedemptions: 10,
      );
      expect(maxed.isValid, isFalse);
      expect(maxed.isMaxedOut, isTrue);
    });

    test('serializes and deserializes correctly', () {
      final code = PromoCode(
        code: 'BONUS',
        type: PromoCodeType.combined,
        description: 'Special launch offer',
        discountPercent: 20,
        freeTrialDays: 7,
        bonusLikes: 15,
        bonusSuperLikes: 3,
        expiresAt: DateTime(2030, 1, 1),
        maxRedemptions: 500,
        currentRedemptions: 12,
      );

      final json = code.toJson();
      final parsed = PromoCode.fromJson(json);

      expect(parsed.code, equals('BONUS'));
      expect(parsed.type, equals(PromoCodeType.combined));
      expect(parsed.description, equals('Special launch offer'));
      expect(parsed.discountPercent, equals(20));
      expect(parsed.freeTrialDays, equals(7));
      expect(parsed.bonusLikes, equals(15));
      expect(parsed.bonusSuperLikes, equals(3));
      expect(parsed.maxRedemptions, equals(500));
      expect(parsed.currentRedemptions, equals(12));
      expect(parsed.expiresAt, isNotNull);
    });

    test('fromJson falls back to discount type for unknown values', () {
      final parsed = PromoCode.fromJson(const {
        'code': 'UNKNOWN',
        'type': 'does_not_exist',
      });

      expect(parsed.type, equals(PromoCodeType.discount));
    });
  });

  group('PromoCodeTypeX', () {
    test('returns displayName and icon for each enum value', () {
      expect(PromoCodeType.discount.displayName, equals('Discount'));
      expect(PromoCodeType.discount.icon, equals('%'));

      expect(PromoCodeType.freeTrial.displayName, equals('Free Trial'));
      expect(PromoCodeType.freeTrial.icon, equals('🎁'));

      expect(PromoCodeType.bonusLikes.displayName, equals('Bonus Likes'));
      expect(PromoCodeType.bonusLikes.icon, equals('❤️'));

      expect(
        PromoCodeType.bonusSuperLikes.displayName,
        equals('Bonus Super Likes'),
      );
      expect(PromoCodeType.bonusSuperLikes.icon, equals('⭐'));

      expect(PromoCodeType.combined.displayName, equals('Special Offer'));
      expect(PromoCodeType.combined.icon, equals('🎉'));
    });
  });

  group('PromoCodeRedemptionResult', () {
    test('success constructor sets fields correctly', () {
      const promo = PromoCode(
        code: 'SUCCESS',
        type: PromoCodeType.freeTrial,
        freeTrialDays: 14,
      );
      final result = PromoCodeRedemptionResult.success(
        promoCode: promo,
        appliedBenefits: const ['14-day trial'],
      );

      expect(result.success, isTrue);
      expect(result.promoCode, equals(promo));
      expect(result.errorMessage, isNull);
      expect(result.appliedBenefits, equals(const ['14-day trial']));
    });

    test('failure constructor sets error and marks unsuccessful', () {
      final result = PromoCodeRedemptionResult.failure('Invalid code');

      expect(result.success, isFalse);
      expect(result.promoCode, isNull);
      expect(result.errorMessage, equals('Invalid code'));
      expect(result.appliedBenefits, isNull);
    });
  });
}
