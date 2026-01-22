import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for starting a date.
class StartDateParams {
  final String planId;

  const StartDateParams({required this.planId});
}

/// Use case for starting a date (when user arrives at location).
class StartDateUseCase extends UseCase<DatePlan, StartDateParams>
    with ValidatingUseCase<DatePlan, StartDateParams> {
  final DatePlanService _service;

  StartDateUseCase([DatePlanService? service])
      : _service = service ?? DatePlanService.instance;

  @override
  String? validate(StartDateParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    return null;
  }

  @override
  Future<Result<DatePlan>> execute(StartDateParams params) {
    return Result.guard(
      () => _service.startDate(params.planId),
      logLabel: 'StartDateUseCase',
      fallbackError: 'Unable to start date. Please try again.',
    );
  }
}
