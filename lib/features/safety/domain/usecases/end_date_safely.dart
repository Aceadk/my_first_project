import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for ending a date safely.
class EndDateSafelyParams {
  final String planId;

  const EndDateSafelyParams({required this.planId});
}

/// Use case for ending a date and notifying contacts of safe return.
class EndDateSafelyUseCase extends UseCase<DatePlan, EndDateSafelyParams>
    with ValidatingUseCase<DatePlan, EndDateSafelyParams> {
  final DatePlanService _service;

  EndDateSafelyUseCase([DatePlanService? service])
      : _service = service ?? DatePlanService.instance;

  @override
  String? validate(EndDateSafelyParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    return null;
  }

  @override
  Future<Result<DatePlan>> execute(EndDateSafelyParams params) {
    return Result.guard(
      () => _service.endDateSafely(params.planId),
      logLabel: 'EndDateSafelyUseCase',
      fallbackError: 'Unable to end date. Please try again.',
    );
  }
}
