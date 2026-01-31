import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for getting active plans.
class GetActivePlansParams {
  final String userId;

  const GetActivePlansParams({required this.userId});
}

/// Use case for getting active date plans for a user.
class GetActivePlansUseCase
    extends UseCase<List<DatePlan>, GetActivePlansParams>
    with ValidatingUseCase<List<DatePlan>, GetActivePlansParams> {
  final DatePlanService _service;

  GetActivePlansUseCase([DatePlanService? service])
      : _service = service ?? DatePlanService.instance;

  @override
  String? validate(GetActivePlansParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    return null;
  }

  @override
  Future<Result<List<DatePlan>>> execute(GetActivePlansParams params) {
    return Result.guard(
      () => _service.getActivePlans(params.userId),
      logLabel: 'GetActivePlansUseCase',
      fallbackError: 'Unable to load active plans.',
    );
  }
}
