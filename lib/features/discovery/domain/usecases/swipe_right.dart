import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';

/// Parameters for right swipe (like).
class SwipeRightParams {
  final String userId;
  final String targetUserId;
  final String? attachedMessage;

  const SwipeRightParams({
    required this.userId,
    required this.targetUserId,
    this.attachedMessage,
  });
}

/// Result of a right swipe operation.
class SwipeRightResult {
  /// The match if mutual, null if pending.
  final CrushMatch? match;

  /// Whether the swipe was recorded successfully.
  final bool success;

  /// Remaining swipes for free users (null for Plus users).
  final int? remainingSwipes;

  const SwipeRightResult({
    this.match,
    required this.success,
    this.remainingSwipes,
  });
}

/// Use case for liking a profile (right swipe).
///
/// Business logic:
/// - Checks subscription plan for swipe limits
/// - Enforces daily swipe limit for free users
/// - Records the like and checks for mutual match
class SwipeRightUseCase extends UseCase<SwipeRightResult, SwipeRightParams> {
  final DiscoveryRepository _discoveryRepository;
  final SubscriptionRepository _subscriptionRepository;

  /// Tracks remaining free swipes for the session.
  /// Reset when the day changes or user upgrades.
  int? _remainingFreeSwipesToday;

  SwipeRightUseCase(this._discoveryRepository, this._subscriptionRepository);

  /// Reset the daily swipe counter (call at day change or plan upgrade).
  void resetDailyCounter() {
    _remainingFreeSwipesToday = null;
  }

  @override
  Future<Result<SwipeRightResult>> call(SwipeRightParams params) async {
    // Get current subscription plan
    final planResult = await Result.guard(
      () => _subscriptionRepository.getCurrentPlan(),
      logLabel: 'SwipeRightUseCase.getPlan',
    );

    if (!planResult.isSuccess) {
      return Result.failure(
        planResult.errorMessage ?? 'Could not verify subscription.',
      );
    }

    final plan = planResult.data ?? SubscriptionPlan.free;

    // Check swipe limits for free users
    if (plan.isFree) {
      _remainingFreeSwipesToday ??= CrushConstants.freeDailySwipeLimit;

      if (_remainingFreeSwipesToday! <= 0) {
        return const Result.success(SwipeRightResult(
          success: false,
          remainingSwipes: 0,
        ));
      }
    }

    // Execute the swipe
    final swipeResult = await Result.guard(
      () => _discoveryRepository.swipeRight(
        userId: params.userId,
        targetUserId: params.targetUserId,
        attachedMessage: params.attachedMessage,
      ),
      logLabel: 'SwipeRightUseCase.swipe',
      fallbackError: 'Could not like this profile. Please try again.',
    );

    if (!swipeResult.isSuccess) {
      return Result.failure(swipeResult.errorMessage!);
    }

    // Decrement counter for free users on success
    int? remaining;
    if (plan.isFree && _remainingFreeSwipesToday != null) {
      _remainingFreeSwipesToday = _remainingFreeSwipesToday! - 1;
      remaining = _remainingFreeSwipesToday;
    }

    return Result.success(SwipeRightResult(
      match: swipeResult.data,
      success: true,
      remainingSwipes: remaining,
    ));
  }
}
