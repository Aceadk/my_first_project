import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Use case for force refreshing feature flags from remote.
class ForceRefreshFlagsUseCase extends UseCase<void, NoParams> {
  final FeatureFlagRepository _repository;

  ForceRefreshFlagsUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () => _repository.forceRefresh(),
      logLabel: 'ForceRefreshFlagsUseCase',
      fallbackError: 'Unable to refresh feature flags.',
    );
  }
}
