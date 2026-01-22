import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for checking in.
class CheckInParams {
  final String planId;

  const CheckInParams({required this.planId});
}

/// Use case for checking in during a date to confirm safety.
class CheckInUseCase extends UseCase<DatePlan, CheckInParams>
    with ValidatingUseCase<DatePlan, CheckInParams> {
  final DatePlanService _service;

  CheckInUseCase([DatePlanService? service])
      : _service = service ?? DatePlanService.instance;

  @override
  String? validate(CheckInParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    return null;
  }

  @override
  Future<Result<DatePlan>> execute(CheckInParams params) {
    return Result.guard(
      () => _service.checkIn(params.planId),
      logLabel: 'CheckInUseCase',
      fallbackError: 'Unable to check in. Please try again.',
    );
  }
}
