import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Use case for refreshing subscription status from the billing provider.
class RefreshSubscriptionStatusUseCase
    extends UseCase<SubscriptionStatus, NoParams> {
  final SubscriptionRepository _repository;

  RefreshSubscriptionStatusUseCase(this._repository);

  @override
  Future<Result<SubscriptionStatus>> call(NoParams params) {
    return Result.guard(
      () => _repository.refreshStatus(),
      logLabel: 'RefreshSubscriptionStatusUseCase',
      fallbackError: 'Unable to refresh subscription status. Please try again.',
    );
  }
}
