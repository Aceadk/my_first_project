import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Use case for watching current pose changes as a stream.
class WatchCurrentPoseUseCase
    extends StreamUseCase<VerificationPose, NoParams> {
  final PhotoVerificationService _service;

  WatchCurrentPoseUseCase([PhotoVerificationService? service])
      : _service = service ?? PhotoVerificationService.instance;

  @override
  Stream<VerificationPose> call(NoParams params) {
    return _service.currentPoseStream;
  }
}
