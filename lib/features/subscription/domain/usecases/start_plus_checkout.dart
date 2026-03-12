import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

/// Parameters for checkout
class CheckoutParams {
  final SubscriptionTier tier;
  final BillingPeriod period;

  const CheckoutParams({required this.tier, required this.period});
}

/// Use case for starting a subscription checkout session.
/// Returns the checkout URL.
class StartCheckoutUseCase extends UseCase<String, CheckoutParams> {
  final SubscriptionRepository _repository;

  StartCheckoutUseCase(this._repository);

  @override
  Future<Result<String>> call(CheckoutParams params) {
    return Result.guard(
      () => _repository.startCheckout(tier: params.tier, period: params.period),
      logLabel: 'StartCheckoutUseCase',
      fallbackError: 'Unable to start checkout. Please try again.',
    );
  }
}
