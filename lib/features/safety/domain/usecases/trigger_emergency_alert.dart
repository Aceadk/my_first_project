import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for triggering emergency alert.
class TriggerEmergencyAlertParams {
  final String planId;

  const TriggerEmergencyAlertParams({required this.planId});
}

/// Use case for triggering an emergency alert to all contacts.
class TriggerEmergencyAlertUseCase
    extends UseCase<void, TriggerEmergencyAlertParams>
    with ValidatingUseCase<void, TriggerEmergencyAlertParams> {
  final DatePlanService _service;

  TriggerEmergencyAlertUseCase([DatePlanService? service])
    : _service = service ?? DatePlanService.instance;

  @override
  String? validate(TriggerEmergencyAlertParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(TriggerEmergencyAlertParams params) {
    return Result.guard(
      () => _service.triggerEmergencyAlert(params.planId),
      logLabel: 'TriggerEmergencyAlertUseCase',
      fallbackError:
          'Unable to send emergency alert. Please call emergency services.',
    );
  }
}
