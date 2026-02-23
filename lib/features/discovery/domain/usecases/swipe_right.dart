import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  /// DISC-003: Persisted to SharedPreferences to survive app restarts.
  int? _remainingFreeSwipesToday;
  static const _swipeCountKey = 'discovery_free_swipes_remaining';
  static const _swipeDateKey = 'discovery_free_swipes_date';

  SwipeRightUseCase(this._discoveryRepository, this._subscriptionRepository);

  /// Reset the daily swipe counter (call at day change or plan upgrade).
  void resetDailyCounter() {
    _remainingFreeSwipesToday = null;
  }

  /// DISC-003: Load persisted counter, resetting if date has changed.
  Future<int> _loadOrInitCounter() async {
    if (_remainingFreeSwipesToday != null) return _remainingFreeSwipesToday!;
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_swipeDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == today) {
      _remainingFreeSwipesToday =
          prefs.getInt(_swipeCountKey) ?? CrushConstants.freeDailySwipeLimit;
    } else {
      _remainingFreeSwipesToday = CrushConstants.freeDailySwipeLimit;
      await prefs.setString(_swipeDateKey, today);
      await prefs.setInt(_swipeCountKey, _remainingFreeSwipesToday!);
    }
    return _remainingFreeSwipesToday!;
  }

  /// DISC-003: Persist the counter after each swipe.
  Future<void> _persistCounter() async {
    if (_remainingFreeSwipesToday == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_swipeCountKey, _remainingFreeSwipesToday!);
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
      // DISC-003: Load persisted counter
      final remaining = await _loadOrInitCounter();

      if (remaining <= 0) {
        return const Result.success(
          SwipeRightResult(success: false, remainingSwipes: 0),
        );
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
      // DISC-003: Persist after decrement
      await _persistCounter();
    }

    return Result.success(
      SwipeRightResult(
        match: swipeResult.data,
        success: true,
        remainingSwipes: remaining,
      ),
    );
  }
}
