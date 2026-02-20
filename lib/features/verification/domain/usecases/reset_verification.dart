import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Use case for resetting verification to retry.
class ResetVerificationUseCase extends UseCase<void, NoParams> {
  final PhotoVerificationService _service;

  ResetVerificationUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () async => _service.resetVerification(),
      logLabel: 'ResetVerificationUseCase',
      fallbackError: 'Unable to reset verification.',
    );
  }
}
