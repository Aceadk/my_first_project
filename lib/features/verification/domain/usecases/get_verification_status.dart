import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/models/photo_verification.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Parameters for getting verification status.
class GetVerificationStatusParams {
  final String userId;

  const GetVerificationStatusParams({required this.userId});
}

/// Use case for getting verification status for a user.
class GetVerificationStatusUseCase
    extends UseCase<PhotoVerification?, GetVerificationStatusParams>
    with ValidatingUseCase<PhotoVerification?, GetVerificationStatusParams> {
  final PhotoVerificationService _service;

  GetVerificationStatusUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  String? validate(GetVerificationStatusParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    return null;
  }

  @override
  Future<Result<PhotoVerification?>> execute(
    GetVerificationStatusParams params,
  ) {
    return Result.guard(
      () => _service.getVerificationStatus(params.userId),
      logLabel: 'GetVerificationStatusUseCase',
      fallbackError: 'Unable to get verification status.',
    );
  }
}
