import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/data/models/profile_insights.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Use case for watching profile insights changes as a stream.
class WatchInsightsUseCase extends StreamUseCase<ProfileInsights, NoParams> {
  final ProfileInsightsService _service;

  WatchInsightsUseCase([ProfileInsightsService? service])
      : _service = service ?? ProfileInsightsService.instance;

  @override
  Stream<ProfileInsights> call(NoParams params) {
    return _service.insightsStream;
  }
}
