import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';

/// Use case for watching subscription plan changes as a stream.
class WatchPlanChangesUseCase
    extends StreamUseCase<SubscriptionTier, NoParams> {
  final SubscriptionRepository _repository;

  WatchPlanChangesUseCase(this._repository);

  @override
  Stream<SubscriptionTier> call(NoParams params) {
    return _repository.watchPlan();
  }
}
