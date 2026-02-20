import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Parameters for getting a string flag.
class GetStringFlagParams {
  final String key;
  final String defaultValue;

  const GetStringFlagParams({required this.key, this.defaultValue = ''});
}

/// Use case for getting a string feature flag value.
class GetStringFlagUseCase extends UseCase<String, GetStringFlagParams>
    with ValidatingUseCase<String, GetStringFlagParams> {
  final FeatureFlagRepository _repository;

  GetStringFlagUseCase(this._repository);

  @override
  String? validate(GetStringFlagParams params) {
    if (params.key.trim().isEmpty) {
      return 'Flag key is required';
    }
    return null;
  }

  @override
  Future<Result<String>> execute(GetStringFlagParams params) {
    return Result.guard(
      () async =>
          _repository.getString(params.key, defaultValue: params.defaultValue),
      logLabel: 'GetStringFlagUseCase',
      fallbackError: 'Unable to get flag value.',
    );
  }
}
