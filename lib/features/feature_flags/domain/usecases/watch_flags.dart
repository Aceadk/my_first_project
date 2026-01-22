import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/feature_flags/data/models/feature_flags.dart';
import 'package:crushhour/features/feature_flags/data/repositories/feature_flag_repository.dart';

/// Use case for watching feature flag changes as a stream.
class WatchFlagsUseCase extends StreamUseCase<FeatureFlags, NoParams> {
  final FeatureFlagRepository _repository;

  WatchFlagsUseCase(this._repository);

  @override
  Stream<FeatureFlags> call(NoParams params) {
    return _repository.flagsStream;
  }
}
