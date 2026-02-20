import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for cancelling a date plan.
class CancelDatePlanParams {
  final String planId;

  const CancelDatePlanParams({required this.planId});
}

/// Use case for cancelling a date plan.
class CancelDatePlanUseCase extends UseCase<void, CancelDatePlanParams>
    with ValidatingUseCase<void, CancelDatePlanParams> {
  final DatePlanService _service;

  CancelDatePlanUseCase([DatePlanService? service])
    : _service = service ?? DatePlanService.instance;

  @override
  String? validate(CancelDatePlanParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(CancelDatePlanParams params) {
    return Result.guard(
      () => _service.cancelPlan(params.planId),
      logLabel: 'CancelDatePlanUseCase',
      fallbackError: 'Unable to cancel date plan.',
    );
  }
}
