import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Use case for starting a Plus subscription checkout session.
/// Returns the checkout URL.
class StartPlusCheckoutUseCase extends UseCase<String, NoParams> {
  final SubscriptionRepository _repository;

  StartPlusCheckoutUseCase(this._repository);

  @override
  Future<Result<String>> call(NoParams params) {
    return Result.guard(
      () => _repository.startPlusCheckout(),
      logLabel: 'StartPlusCheckoutUseCase',
      fallbackError: 'Unable to start checkout. Please try again.',
    );
  }
}
