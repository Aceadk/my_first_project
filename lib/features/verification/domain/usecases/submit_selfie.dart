import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Parameters for submitting selfie.
class SubmitSelfieParams {
  final String userId;
  final String selfieUrl;

  const SubmitSelfieParams({required this.userId, required this.selfieUrl});
}

/// Use case for submitting a selfie for photo verification.
class SubmitSelfieUseCase extends UseCase<PhotoVerification, SubmitSelfieParams>
    with ValidatingUseCase<PhotoVerification, SubmitSelfieParams> {
  final PhotoVerificationService _service;

  SubmitSelfieUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  String? validate(SubmitSelfieParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    if (params.selfieUrl.trim().isEmpty) {
      return 'Selfie URL is required';
    }
    return null;
  }

  @override
  Future<Result<PhotoVerification>> execute(SubmitSelfieParams params) {
    return Result.guard(
      () => _service.submitSelfie(
        userId: params.userId,
        selfieUrl: params.selfieUrl,
      ),
      logLabel: 'SubmitSelfieUseCase',
      fallbackError: 'Unable to submit selfie. Please try again.',
    );
  }
}
