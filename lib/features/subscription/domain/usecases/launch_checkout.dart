import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

/// Parameters for launching a checkout URL.
class LaunchCheckoutParams {
  final String url;

  const LaunchCheckoutParams({required this.url});
}

/// Use case for launching a checkout URL in browser/in-app browser.
class LaunchCheckoutUseCase extends UseCase<void, LaunchCheckoutParams>
    with ValidatingUseCase<void, LaunchCheckoutParams> {
  final SubscriptionRepository _repository;

  LaunchCheckoutUseCase(this._repository);

  @override
  String? validate(LaunchCheckoutParams params) {
    if (params.url.isEmpty) {
      return 'Checkout URL is required';
    }
    if (!params.url.startsWith('http://') &&
        !params.url.startsWith('https://')) {
      return 'Invalid checkout URL';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(LaunchCheckoutParams params) {
    return Result.guard(
      () => _repository.launchCheckoutUrl(params.url),
      logLabel: 'LaunchCheckoutUseCase',
      fallbackError: 'Unable to open checkout. Please try again.',
    );
  }
}
