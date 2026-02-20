import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Use case for watching check-in status changes as a stream.
class WatchCheckInStatusUseCase extends StreamUseCase<CheckInStatus, NoParams> {
  final DatePlanService _service;

  WatchCheckInStatusUseCase([DatePlanService? service])
    : _service = service ?? DatePlanService.instance;

  @override
  Stream<CheckInStatus> call(NoParams params) {
    return _service.checkInStream;
  }
}
