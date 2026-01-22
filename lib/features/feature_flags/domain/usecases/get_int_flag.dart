import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Parameters for getting an integer flag.
class GetIntFlagParams {
  final String key;
  final int defaultValue;

  const GetIntFlagParams({
    required this.key,
    this.defaultValue = 0,
  });
}

/// Use case for getting an integer feature flag value.
class GetIntFlagUseCase extends UseCase<int, GetIntFlagParams>
    with ValidatingUseCase<int, GetIntFlagParams> {
  final FeatureFlagRepository _repository;

  GetIntFlagUseCase(this._repository);

  @override
  String? validate(GetIntFlagParams params) {
    if (params.key.trim().isEmpty) {
      return 'Flag key is required';
    }
    return null;
  }

  @override
  Future<Result<int>> execute(GetIntFlagParams params) {
    return Result.guard(
      () async => _repository.getInt(
        params.key,
        defaultValue: params.defaultValue,
      ),
      logLabel: 'GetIntFlagUseCase',
      fallbackError: 'Unable to get flag value.',
    );
  }
}
