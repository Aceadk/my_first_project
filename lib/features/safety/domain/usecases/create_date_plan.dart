import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/safety/data/models/date_plan.dart';
import 'package:crushhour/features/safety/data/services/date_plan_service.dart';

/// Parameters for creating a date plan.
class CreateDatePlanParams {
  final String userId;
  final String matchId;
  final String matchName;
  final String? matchPhotoUrl;
  final DateTime dateTime;
  final String location;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? notes;
  final List<EmergencyContact> sharedWith;
  final Duration checkInDelay;

  const CreateDatePlanParams({
    required this.userId,
    required this.matchId,
    required this.matchName,
    this.matchPhotoUrl,
    required this.dateTime,
    required this.location,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.notes,
    this.sharedWith = const [],
    this.checkInDelay = const Duration(hours: 2),
  });
}

/// Use case for creating a date plan with safety features.
class CreateDatePlanUseCase extends UseCase<DatePlan, CreateDatePlanParams>
    with ValidatingUseCase<DatePlan, CreateDatePlanParams> {
  final DatePlanService _service;

  CreateDatePlanUseCase([DatePlanService? service])
    : _service = service ?? DatePlanService.instance;

  @override
  String? validate(CreateDatePlanParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    if (params.matchId.trim().isEmpty) {
      return 'Match ID is required';
    }
    if (params.matchName.trim().isEmpty) {
      return 'Match name is required';
    }
    if (params.location.trim().isEmpty) {
      return 'Location is required';
    }
    if (params.dateTime.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    return null;
  }

  @override
  Future<Result<DatePlan>> execute(CreateDatePlanParams params) {
    return Result.guard(
      () => _service.createDatePlan(
        userId: params.userId,
        matchId: params.matchId,
        matchName: params.matchName,
        matchPhotoUrl: params.matchPhotoUrl,
        dateTime: params.dateTime,
        location: params.location,
        locationAddress: params.locationAddress,
        locationLatitude: params.locationLatitude,
        locationLongitude: params.locationLongitude,
        notes: params.notes,
        sharedWith: params.sharedWith,
        checkInDelay: params.checkInDelay,
      ),
      logLabel: 'CreateDatePlanUseCase',
      fallbackError: 'Unable to create date plan. Please try again.',
    );
  }
}
