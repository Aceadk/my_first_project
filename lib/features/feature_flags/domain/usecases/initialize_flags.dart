import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Use case for initializing feature flags.
class InitializeFlagsUseCase extends UseCase<void, NoParams> {
  final FeatureFlagRepository _repository;

  InitializeFlagsUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () => _repository.initialize(),
      logLabel: 'InitializeFlagsUseCase',
      fallbackError: 'Unable to initialize feature flags.',
    );
  }
}
