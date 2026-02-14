import 'dart:async';

import 'package:crushhour/features/discovery/data/models/daily_likes_limit.dart';
import 'package:crushhour/features/discovery/data/services/daily_likes_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyLikesService hotspot branches', () {
    late DailyLikesService service;
    late List<Duration> scheduledDelays;
    late List<Timer> timers;

    setUp(() {
      scheduledDelays = <Duration>[];
      timers = <Timer>[];

      service = DailyLikesService.test(
        delayExecutor: (_) async {},
        resetScheduler: (delay, callback) {
          scheduledDelays.add(delay);
          final timer = Timer(const Duration(days: 1), callback);
          timers.add(timer);
          return timer;
        },
      );
    });

    tearDown(() {
      service.dispose();
      for (final timer in timers) {
        if (timer.isActive) {
          timer.cancel();
        }
      }
    });

    test('default getters are safe before limit is loaded', () {
      expect(service.currentLimit, isNull);
      expect(service.canLike, isFalse);
      expect(service.canSuperLike, isFalse);
      expect(service.remainingLikes, 0);
      expect(service.remainingSuperLikes, 0);
      expect(service.getTimeUntilReset(), Duration.zero);
      expect(service.getUsagePercentage(), 0.0);
      expect(service.getResetTimeDisplay(), 'Unknown');
    });

    test('loadLimit emits stream value and schedules reset', () async {
      final emittedFuture = service.limitStream.first;
      final loaded = await service.loadLimit(userId: 'user-1', bonusLikes: 2);
      final emitted = await emittedFuture;

      expect(loaded.userId, 'user-1');
      expect(loaded.bonusLikes, 2);
      expect(emitted, loaded);
      expect(scheduledDelays, hasLength(1));
      expect(scheduledDelays.single > Duration.zero, isTrue);
    });

    test('useLike returns failure when limit not loaded', () async {
      final result = await service.useLike();
      expect(result.success, isFalse);
      expect(result.remainingLikes, 0);
      expect(result.message, 'Likes not loaded. Please try again.');
      expect(result.timeUntilReset, isNull);
      expect(result.isSuperLike, isFalse);
    });

    test('useSuperLike returns failure when limit not loaded', () async {
      final result = await service.useSuperLike();
      expect(result.success, isFalse);
      expect(result.remainingLikes, 0);
      expect(result.message, 'Likes not loaded. Please try again.');
      expect(result.timeUntilReset, isNull);
      expect(result.isSuperLike, isFalse);
    });

    test('useLike covers success warning and no-likes-left branches', () async {
      await service.loadLimit(userId: 'free-user', isPremium: false);

      LikeResult? warningResult;
      for (var i = 0; i < DailyLikesLimit.maxFreeLikes - 5; i++) {
        warningResult = await service.useLike();
      }

      expect(warningResult, isNotNull);
      expect(warningResult!.success, isTrue);
      expect(warningResult.remainingLikes, 5);
      expect(warningResult.message, 'Only 5 likes left today!');

      for (var i = 0; i < 5; i++) {
        await service.useLike();
      }

      final noLikesResult = await service.useLike();
      expect(noLikesResult.success, isFalse);
      expect(noLikesResult.remainingLikes, 0);
      expect(
        noLikesResult.message,
        'No likes remaining. Upgrade to Premium for unlimited likes!',
      );
      expect(noLikesResult.timeUntilReset, isNotNull);
    });

    test('useSuperLike covers success and exhausted branches', () async {
      await service.loadLimit(userId: 'free-super-user', isPremium: false);

      final success = await service.useSuperLike();
      expect(success.success, isTrue);
      expect(success.isSuperLike, isTrue);
      expect(success.remainingLikes, 0);

      final exhausted = await service.useSuperLike();
      expect(exhausted.success, isFalse);
      expect(exhausted.remainingLikes, 0);
      expect(
        exhausted.message,
        'No Super Likes remaining. Get more with Premium!',
      );
      expect(exhausted.timeUntilReset, isNotNull);
    });

    test(
      'upgradeToPremium/addBonusLikes/resetLimits update state correctly',
      () async {
        await service.loadLimit(
          userId: 'upgrade-user',
          isPremium: false,
          bonusLikes: 3,
        );

        await service.addBonusLikes(2);
        expect(service.currentLimit!.bonusLikes, 5);

        await service.upgradeToPremium();
        expect(service.currentLimit!.isPremium, isTrue);
        expect(service.canLike, isTrue);

        await service.resetLimits();
        expect(service.currentLimit, isNotNull);
        expect(service.currentLimit!.isPremium, isTrue);
        expect(service.currentLimit!.bonusLikes, 0);
        expect(scheduledDelays.length >= 2, isTrue);
      },
    );

    test('upgrade/add bonus/reset are no-op when no current limit', () async {
      await service.upgradeToPremium();
      await service.addBonusLikes(10);
      await service.resetLimits();

      expect(service.currentLimit, isNull);
      expect(service.canLike, isFalse);
    });

    test('usage and reset display reflect current state', () async {
      await service.loadLimit(userId: 'usage-user');
      expect(service.getUsagePercentage(), 0.0);
      expect(service.getResetTimeDisplay(), startsWith('Resets in'));

      await service.useLike();
      expect(service.getUsagePercentage(), greaterThan(0.0));
      expect(service.getTimeUntilReset(), greaterThan(Duration.zero));
    });
  });
}
