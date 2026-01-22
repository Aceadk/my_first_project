import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';

/// Use case for ending an active call.
class EndCallUseCase extends UseCase<void, NoParams> {
  final CallRepository _repository;

  EndCallUseCase(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () => _repository.endCall(),
      logLabel: 'EndCallUseCase',
      fallbackError: 'Unable to end call. Please try again.',
    );
  }
}
