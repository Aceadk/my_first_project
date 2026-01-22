import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Parameters for starting verification.
class StartVerificationParams {
  final String userId;

  const StartVerificationParams({required this.userId});
}

/// Use case for starting a new photo verification session.
class StartVerificationUseCase
    extends UseCase<PhotoVerification, StartVerificationParams>
    with ValidatingUseCase<PhotoVerification, StartVerificationParams> {
  final PhotoVerificationService _service;

  StartVerificationUseCase([PhotoVerificationService? service])
      : _service = service ?? PhotoVerificationService.instance;

  @override
  String? validate(StartVerificationParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    return null;
  }

  @override
  Future<Result<PhotoVerification>> execute(StartVerificationParams params) {
    return Result.guard(
      () => _service.startVerification(params.userId),
      logLabel: 'StartVerificationUseCase',
      fallbackError: 'Unable to start verification. Please try again.',
    );
  }
}
