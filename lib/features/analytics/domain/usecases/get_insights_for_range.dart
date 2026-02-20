import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/analytics/domain/models/profile_insights.dart';
import 'package:crushhour/features/analytics/data/services/profile_insights_service.dart';

/// Parameters for getting insights for a date range.
class GetInsightsForRangeParams {
  final String userId;
  final DateTime start;
  final DateTime end;

  const GetInsightsForRangeParams({
    required this.userId,
    required this.start,
    required this.end,
  });
}

/// Use case for getting profile insights for a specific date range.
class GetInsightsForRangeUseCase
    extends UseCase<ProfileInsights, GetInsightsForRangeParams>
    with ValidatingUseCase<ProfileInsights, GetInsightsForRangeParams> {
  final ProfileInsightsService _service;

  GetInsightsForRangeUseCase([ProfileInsightsService? service])
    : _service = service ?? ProfileInsightsService.instance;

  @override
  String? validate(GetInsightsForRangeParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    if (params.end.isBefore(params.start)) {
      return 'End date must be after start date';
    }
    if (params.end.difference(params.start).inDays > 365) {
      return 'Date range cannot exceed 1 year';
    }
    return null;
  }

  @override
  Future<Result<ProfileInsights>> execute(GetInsightsForRangeParams params) {
    return Result.guard(
      () => _service.getInsightsForRange(
        userId: params.userId,
        start: params.start,
        end: params.end,
      ),
      logLabel: 'GetInsightsForRangeUseCase',
      fallbackError: 'Unable to load insights for the selected range.',
    );
  }
}
