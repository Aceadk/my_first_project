import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for adding emergency contact.
class AddEmergencyContactParams {
  final String planId;
  final EmergencyContact contact;

  const AddEmergencyContactParams({
    required this.planId,
    required this.contact,
  });
}

/// Use case for adding an emergency contact to a date plan.
class AddEmergencyContactUseCase extends UseCase<DatePlan, AddEmergencyContactParams>
    with ValidatingUseCase<DatePlan, AddEmergencyContactParams> {
  final DatePlanService _service;

  AddEmergencyContactUseCase([DatePlanService? service])
      : _service = service ?? DatePlanService.instance;

  @override
  String? validate(AddEmergencyContactParams params) {
    if (params.planId.trim().isEmpty) {
      return 'Plan ID is required';
    }
    if (params.contact.name.trim().isEmpty) {
      return 'Contact name is required';
    }
    if (params.contact.phone.trim().isEmpty) {
      return 'Contact phone is required';
    }
    return null;
  }

  @override
  Future<Result<DatePlan>> execute(AddEmergencyContactParams params) {
    return Result.guard(
      () => _service.addEmergencyContact(
        planId: params.planId,
        contact: params.contact,
      ),
      logLabel: 'AddEmergencyContactUseCase',
      fallbackError: 'Unable to add emergency contact.',
    );
  }
}
