import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Parameters for loading profile insights.
class LoadInsightsParams {
  final String userId;

  const LoadInsightsParams({required this.userId});
}

/// Use case for loading profile insights for a user.
class LoadInsightsUseCase extends UseCase<ProfileInsights, LoadInsightsParams>
    with ValidatingUseCase<ProfileInsights, LoadInsightsParams> {
  final ProfileInsightsService _service;

  LoadInsightsUseCase([ProfileInsightsService? service])
    : _service = service ?? ProfileInsightsService.instance;

  @override
  String? validate(LoadInsightsParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required to load insights';
    }
    return null;
  }

  @override
  Future<Result<ProfileInsights>> execute(LoadInsightsParams params) {
    return Result.guard(
      () => _service.loadInsights(params.userId),
      logLabel: 'LoadInsightsUseCase',
      fallbackError: 'Unable to load insights. Please try again.',
    );
  }
}
