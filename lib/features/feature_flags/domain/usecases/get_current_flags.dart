import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/models/feature_flags.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Use case for getting current feature flags.
class GetCurrentFlagsUseCase extends UseCase<FeatureFlags, NoParams> {
  final FeatureFlagRepository _repository;

  GetCurrentFlagsUseCase(this._repository);

  @override
  Future<Result<FeatureFlags>> call(NoParams params) {
    return Result.guard(
      () async => _repository.flags,
      logLabel: 'GetCurrentFlagsUseCase',
      fallbackError: 'Unable to get current flags.',
    );
  }
}
