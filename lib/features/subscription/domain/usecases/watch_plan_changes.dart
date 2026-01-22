import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';

/// Use case for watching subscription plan changes as a stream.
class WatchPlanChangesUseCase extends StreamUseCase<SubscriptionPlan, NoParams> {
  final SubscriptionRepository _repository;

  WatchPlanChangesUseCase(this._repository);

  @override
  Stream<SubscriptionPlan> call(NoParams params) {
    return _repository.watchPlan();
  }
}
