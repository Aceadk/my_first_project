import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Parameters for recording a like received.
class RecordLikeReceivedParams {
  final bool isSuperLike;

  const RecordLikeReceivedParams({this.isSuperLike = false});
}

/// Use case for recording when a like is received.
class RecordLikeReceivedUseCase extends UseCase<void, RecordLikeReceivedParams> {
  final ProfileInsightsService _service;

  RecordLikeReceivedUseCase([ProfileInsightsService? service])
      : _service = service ?? ProfileInsightsService.instance;

  @override
  Future<Result<void>> call(RecordLikeReceivedParams params) {
    return Result.guard(
      () => _service.recordLikeReceived(isSuperLike: params.isSuperLike),
      logLabel: 'RecordLikeReceivedUseCase',
      fallbackError: 'Unable to record like received.',
    );
  }
}
