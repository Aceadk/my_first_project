import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/domain/usecases/check_entitlement.dart';

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

  /// Message describing why the swipe was blocked.
  final String? blockedMessage;

  /// Paywall source to use when the swipe was blocked by entitlement.
  final String? paywallSource;

  const SwipeRightResult({
    this.match,
    required this.success,
    this.remainingSwipes,
    this.blockedMessage,
    this.paywallSource,
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
  final CheckEntitlementUseCase _checkEntitlementUseCase;

  SwipeRightUseCase(
    this._discoveryRepository,
    SubscriptionRepository subscriptionRepository, {
    CheckEntitlementUseCase? checkEntitlementUseCase,
  }) : _checkEntitlementUseCase =
           checkEntitlementUseCase ??
           CheckEntitlementUseCase(subscriptionRepository);

  /// Reset the daily swipe counter (call at day change or plan upgrade).
  void resetDailyCounter() {
    _checkEntitlementUseCase.clearCache();
  }

  @override
  Future<Result<SwipeRightResult>> call(SwipeRightParams params) async {
    final entitlementResult = await _checkEntitlementUseCase(
      CheckEntitlementParams(
        feature: SubscriptionEntitlementFeature.likes,
        userId: params.userId,
      ),
    );
    if (!entitlementResult.isSuccess || entitlementResult.data == null) {
      return Result.failure(
        entitlementResult.errorMessage ?? 'Could not verify subscription.',
      );
    }

    final decision = entitlementResult.data!;
    if (!decision.isAllowed) {
      return Result.success(
        SwipeRightResult(
          success: false,
          remainingSwipes: decision.remainingFreeUses ?? 0,
          blockedMessage: decision.blockedMessage,
          paywallSource: decision.paywallSource,
        ),
      );
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
    int? remaining = decision.remainingFreeUses;
    if (decision.tier.isFree) {
      await _checkEntitlementUseCase.recordSuccessfulLike(params.userId);
      remaining = await _checkEntitlementUseCase.remainingFreeLikes(
        params.userId,
      );
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
