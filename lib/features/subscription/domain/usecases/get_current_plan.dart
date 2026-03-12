import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

/// Use case for fetching the current subscription tier.
class GetCurrentPlanUseCase extends UseCase<SubscriptionTier, NoParams> {
  final SubscriptionRepository _repository;

  GetCurrentPlanUseCase(this._repository);

  @override
  Future<Result<SubscriptionTier>> call(NoParams params) {
    return Result.guard(
      () => _repository.getCurrentPlan(),
      logLabel: 'GetCurrentPlanUseCase',
      fallbackError: 'Unable to load subscription tier. Please try again.',
    );
  }
}
