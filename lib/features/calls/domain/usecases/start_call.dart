import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';

/// Parameters for starting a call.
class StartCallParams {
  final String matchId;
  final bool isVideoCall;

  const StartCallParams({
    required this.matchId,
    this.isVideoCall = false,
  });
}

/// Use case for starting an audio or video call with a match.
class StartCallUseCase extends UseCase<CallSession, StartCallParams>
    with ValidatingUseCase<CallSession, StartCallParams> {
  final CallRepository _repository;

  StartCallUseCase(this._repository);

  @override
  String? validate(StartCallParams params) {
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required to start a call';
    }
    return null;
  }

  @override
  Future<Result<CallSession>> execute(StartCallParams params) {
    return Result.guard(
      () => _repository.startCall(
        matchId: params.matchId,
        isVideoCall: params.isVideoCall,
      ),
      logLabel: 'StartCallUseCase',
      fallbackError: 'Unable to start call. Please try again.',
    );
  }
}
