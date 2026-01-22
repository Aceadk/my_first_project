import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Use case for fetching the current subscription plan.
class GetCurrentPlanUseCase extends UseCase<SubscriptionPlan, NoParams> {
  final SubscriptionRepository _repository;

  GetCurrentPlanUseCase(this._repository);

  @override
  Future<Result<SubscriptionPlan>> call(NoParams params) {
    return Result.guard(
      () => _repository.getCurrentPlan(),
      logLabel: 'GetCurrentPlanUseCase',
      fallbackError: 'Unable to load subscription plan. Please try again.',
    );
  }
}
