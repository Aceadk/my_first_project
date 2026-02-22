import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/core/services/gradual_rollout_service.dart';

void main() {
  final service = GradualRolloutService.instance;

  group('GradualRolloutService', () {
    test('returns safe defaults before initialize', () {
      expect(service.isInitialized, isFalse);
      expect(service.bucket, 0);
      expect(service.userId, isEmpty);
      expect(service.isEnabledForPercentage('feature-a', 50), isFalse);
      expect(service.getVariant('exp-empty', const []), 'control');
    });

    test('initialize assigns persistent bucket and user id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await service.initialize(prefs);

      expect(service.isInitialized, isTrue);
      expect(service.bucket, inInclusiveRange(0, 99));
      expect(service.userId, isNotEmpty);
      expect(prefs.getInt('rollout_bucket'), service.bucket);
      expect(prefs.getString('rollout_user_id'), service.userId);
    });

    test('percentage rollout and reset/set bucket utilities work', () async {
      expect(service.isEnabledForPercentage('feature-b', 0), isFalse);
      expect(service.isEnabledForPercentage('feature-b', -1), isFalse);
      expect(service.isEnabledForPercentage('feature-b', 100), isTrue);

      await service.setBucket(120);
      expect(service.bucket, 99);

      await service.setBucket(-5);
      expect(service.bucket, 0);

      await service.resetBucket();
      expect(service.bucket, inInclusiveRange(0, 99));
    });

    test('variant assignment APIs return deterministic valid variants', () {
      final variants = <String>['control', 'a', 'b'];
      final variant = service.getVariant('experiment-1', variants);
      expect(variants, contains(variant));
      expect(service.isInVariant('experiment-1', variant, variants), isTrue);

      final weighted = service.getWeightedVariant('experiment-2', const {
        'control': 50,
        'variant_a': 30,
        'variant_b': 20,
      });
      expect(const <String>[
        'control',
        'variant_a',
        'variant_b',
      ], contains(weighted));
    });

    test('weighted variant with empty map throws due missing fallback key', () {
      expect(
        () => service.getWeightedVariant('experiment-empty', const {}),
        throwsStateError,
      );
    });

    test('user targeting rules enforce all guard branches', () async {
      await service.setBucket(10);

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(percentage: 0),
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(whitelistedUserIds: <String>['allow-me']),
          userId: 'allow-me',
        ),
        isTrue,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(blacklistedUserIds: <String>['block-me']),
          userId: 'block-me',
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(premiumOnly: true),
          isPremium: false,
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(
            newUsersOnly: true,
            newUserDaysThreshold: 7,
          ),
          userCreatedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(countries: <String>['US', 'CA']),
          country: 'DE',
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(minAppVersion: '2.0.0'),
          appVersion: '1.9.9',
        ),
        isFalse,
      );

      expect(
        service.isEnabledForUser(
          'feature-rules',
          rules: const RolloutRules(
            percentage: 100,
            countries: <String>['US'],
            minAppVersion: '1.0.0',
          ),
          country: 'US',
          appVersion: '1.2.0',
          isPremium: true,
          userCreatedAt: DateTime.now(),
        ),
        isTrue,
      );
    });
  });
}
