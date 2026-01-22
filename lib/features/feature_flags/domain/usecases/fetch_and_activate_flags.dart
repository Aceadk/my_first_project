import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Use case for fetching and activating feature flags from remote.
class FetchAndActivateFlagsUseCase extends UseCase<bool, NoParams> {
  final FeatureFlagRepository _repository;

  FetchAndActivateFlagsUseCase(this._repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return Result.guard(
      () => _repository.fetchAndActivate(),
      logLabel: 'FetchAndActivateFlagsUseCase',
      fallbackError: 'Unable to fetch feature flags.',
    );
  }
}
