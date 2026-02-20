import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Parameters for getting a boolean flag.
class GetBoolFlagParams {
  final String key;
  final bool defaultValue;

  const GetBoolFlagParams({required this.key, this.defaultValue = false});
}

/// Use case for getting a boolean feature flag value.
class GetBoolFlagUseCase extends UseCase<bool, GetBoolFlagParams>
    with ValidatingUseCase<bool, GetBoolFlagParams> {
  final FeatureFlagRepository _repository;

  GetBoolFlagUseCase(this._repository);

  @override
  String? validate(GetBoolFlagParams params) {
    if (params.key.trim().isEmpty) {
      return 'Flag key is required';
    }
    return null;
  }

  @override
  Future<Result<bool>> execute(GetBoolFlagParams params) {
    return Result.guard(
      () async =>
          _repository.getBool(params.key, defaultValue: params.defaultValue),
      logLabel: 'GetBoolFlagUseCase',
      fallbackError: 'Unable to get flag value.',
    );
  }
}
