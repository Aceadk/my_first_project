import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/discovery/data/models/daily_likes_limit.dart';

void main() {
  group('DailyLikesLimit', () {
    test('computes free-tier limits, remaining counts, and flags', () {
      final limit = DailyLikesLimit(
        userId: 'u1',
        date: DateTime(2026, 2, 13),
        likesUsed: 10,
        superLikesUsed: 0,
        bonusLikes: 5,
      );

      expect(limit.totalAvailableLikes, DailyLikesLimit.maxFreeLikes + 5);
      expect(limit.remainingLikes, DailyLikesLimit.maxFreeLikes - 10 + 5);
      expect(limit.remainingSuperLikes, DailyLikesLimit.maxFreeSuperLikes);
      expect(limit.canLike, isTrue);
      expect(limit.canSuperLike, isTrue);
      expect(limit.usagePercentage, closeTo(10 / 55, 0.0001));
    });

    test('clamps remaining counters at zero and max thresholds', () {
      final limit = DailyLikesLimit(
        userId: 'u1',
        date: DateTime(2026, 2, 13),
        likesUsed: 999,
        superLikesUsed: 999,
      );

      expect(limit.remainingLikes, 0);
      expect(limit.remainingSuperLikes, 0);
      expect(limit.canLike, isFalse);
      expect(limit.canSuperLike, isFalse);
    });

    test(
      'premium mode exposes unlimited likes and premium super-like limit',
      () {
        final premium = DailyLikesLimit(
          userId: 'u2',
          date: DateTime(2026, 2, 13),
          likesUsed: 200,
          superLikesUsed: 2,
          isPremium: true,
        );

        expect(premium.totalAvailableLikes, 999999);
        expect(premium.remainingLikes, 999999);
        expect(
          premium.remainingSuperLikes,
          DailyLikesLimit.maxPremiumSuperLikes - 2,
        );
        expect(premium.canLike, isTrue);
        expect(premium.canSuperLike, isTrue);
        expect(premium.usagePercentage, 0.0);
      },
    );

    test('copyWith, useLike, and useSuperLike update counters', () {
      final base = DailyLikesLimit(userId: 'u1', date: DateTime(2026, 2, 13));

      final copied = base.copyWith(bonusLikes: 3, likesUsed: 1);
      expect(copied.bonusLikes, 3);
      expect(copied.likesUsed, 1);

      expect(base.useLike().likesUsed, 1);
      expect(base.useSuperLike().superLikesUsed, 1);
    });

    test('serializes and deserializes with defaults', () {
      final now = DateTime(2026, 2, 13, 10, 30);
      final model = DailyLikesLimit(
        userId: 'u1',
        date: now,
        likesUsed: 2,
        superLikesUsed: 1,
        isPremium: false,
        bonusLikes: 4,
      );

      final json = model.toJson();
      final restored = DailyLikesLimit.fromJson(json);

      expect(restored, model);

      final defaults = DailyLikesLimit.fromJson({
        'userId': 'u2',
        'date': now.toIso8601String(),
      });
      expect(defaults.likesUsed, 0);
      expect(defaults.superLikesUsed, 0);
      expect(defaults.isPremium, isFalse);
      expect(defaults.bonusLikes, 0);
    });

    test('forToday normalizes date to start of day and keeps options', () {
      final today = DailyLikesLimit.forToday(
        userId: 'today-user',
        isPremium: true,
        bonusLikes: 7,
      );

      expect(today.userId, 'today-user');
      expect(today.isPremium, isTrue);
      expect(today.bonusLikes, 7);
      expect(today.date.hour, 0);
      expect(today.date.minute, 0);
      expect(today.date.second, 0);
      expect(today.resetTimeDisplay, startsWith('Resets in '));
    });
  });
}
