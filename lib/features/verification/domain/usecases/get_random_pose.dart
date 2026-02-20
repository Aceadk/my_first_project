import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Use case for getting a random verification pose.
class GetRandomPoseUseCase extends UseCase<VerificationPose, NoParams> {
  final PhotoVerificationService _service;

  GetRandomPoseUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  Future<Result<VerificationPose>> call(NoParams params) {
    return Result.guard(
      () async => _service.getRandomPose(),
      logLabel: 'GetRandomPoseUseCase',
      fallbackError: 'Unable to get verification pose.',
    );
  }
}
