import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Use case for watching verification status changes as a stream.
class WatchVerificationUseCase
    extends StreamUseCase<PhotoVerification, NoParams> {
  final PhotoVerificationService _service;

  WatchVerificationUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  Stream<PhotoVerification> call(NoParams params) {
    return _service.verificationStream;
  }
}
