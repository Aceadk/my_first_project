import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Use case for watching date plan changes as a stream.
class WatchDatePlanUseCase extends StreamUseCase<DatePlan, NoParams> {
  final DatePlanService _service;

  WatchDatePlanUseCase([DatePlanService? service])
    : _service = service ?? DatePlanService.instance;

  @override
  Stream<DatePlan> call(NoParams params) {
    return _service.datePlanStream;
  }
}
