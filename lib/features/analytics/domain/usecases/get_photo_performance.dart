import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/data/models/profile_insights.dart';
import 'package:crushhour/features/analytics/domain/repositories/profile_insights_repository.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Use case for getting photo performance metrics.
class GetPhotoPerformanceUseCase
    extends UseCase<List<PhotoPerformance>, NoParams> {
  final ProfileInsightsRepository _service;

  GetPhotoPerformanceUseCase([ProfileInsightsRepository? service])
      : _service = service ?? ProfileInsightsService.instance;

  @override
  Future<Result<List<PhotoPerformance>>> call(NoParams params) {
    return Result.guard(
      () async => _service.getPhotoPerformance(),
      logLabel: 'GetPhotoPerformanceUseCase',
      fallbackError: 'Unable to load photo performance.',
    );
  }
}
