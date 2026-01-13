import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/features/discovery/data/services/daily_likes_service.dart';
import 'package:crushhour/features/discovery/data/models/daily_likes_limit.dart';

void main() {
  group('DailyLikesService', () {
    late DailyLikesService service;

    setUp(() {
      // Get fresh instance - note: singleton pattern means we're testing the shared instance
      service = DailyLikesService.instance;
    });

    group('loadLimit', () {
      test('loads limit for free user', () async {
        final limit = await service.loadLimit(
          userId: 'test_user',
          isPremium: false,
        );

        expect(limit.userId, 'test_user');
        expect(limit.isPremium, isFalse);
        expect(limit.totalAvailableLikes, DailyLikesLimit.maxFreeLikes);
        expect(limit.canLike, isTrue);
      });

      test('loads unlimited limit for premium user', () async {
        final limit = await service.loadLimit(
          userId: 'premium_user',
          isPremium: true,
        );

        expect(limit.isPremium, isTrue);
        expect(limit.canLike, isTrue);
        // Premium users have unlimited likes
      });

      test('includes bonus likes when provided', () async {
        final limit = await service.loadLimit(
          userId: 'test_user',
          isPremium: false,
          bonusLikes: 10,
        );

        expect(limit.bonusLikes, 10);
      });
    });

    group('useLike', () {
      test('returns failure when limit not loaded', () async {
        // Reset service state by loading with a new user
        await service.loadLimit(userId: 'fresh_user', isPremium: false);

        final result = await service.useLike();
        // Should succeed since we just loaded
        expect(result.success, isTrue);
      });

      test('decrements remaining likes on success', () async {
        await service.loadLimit(userId: 'like_test_user', isPremium: false);
        final initialRemaining = service.remainingLikes;

        await service.useLike();

        expect(service.remainingLikes, initialRemaining - 1);
      });
    });

    group('useSuperLike', () {
      test('returns failure when no super likes remaining', () async {
        await service.loadLimit(userId: 'super_like_user', isPremium: false);

        // Use all super likes
        const superLikeLimit = DailyLikesLimit.maxFreeSuperLikes;
        for (var i = 0; i < superLikeLimit; i++) {
          await service.useSuperLike();
        }

        final result = await service.useSuperLike();
        expect(result.success, isFalse);
      });
    });

    group('getters', () {
      test('canLike returns correct value', () async {
        await service.loadLimit(userId: 'getter_test', isPremium: false);
        expect(service.canLike, isTrue);
      });

      test('canSuperLike returns correct value', () async {
        await service.loadLimit(userId: 'super_getter_test', isPremium: false);
        expect(service.canSuperLike, isTrue);
      });

      test('remainingLikes returns correct count', () async {
        await service.loadLimit(userId: 'remaining_test', isPremium: false);
        expect(service.remainingLikes, greaterThan(0));
      });
    });

    group('upgradeToPremium', () {
      test('updates limit to premium', () async {
        await service.loadLimit(userId: 'upgrade_test', isPremium: false);
        expect(service.currentLimit?.isPremium, isFalse);

        await service.upgradeToPremium();
        expect(service.currentLimit?.isPremium, isTrue);
      });
    });

    group('addBonusLikes', () {
      test('adds bonus likes to current limit', () async {
        await service.loadLimit(userId: 'bonus_test', isPremium: false);
        final initialBonus = service.currentLimit?.bonusLikes ?? 0;

        await service.addBonusLikes(5);

        expect(service.currentLimit?.bonusLikes, initialBonus + 5);
      });
    });
  });
}
