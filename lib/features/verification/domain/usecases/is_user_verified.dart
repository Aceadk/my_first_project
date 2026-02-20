import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/verification/data/services/photo_verification_service.dart';

/// Parameters for checking if user is verified.
class IsUserVerifiedParams {
  final String userId;

  const IsUserVerifiedParams({required this.userId});
}

/// Use case for checking if a user is verified.
class IsUserVerifiedUseCase extends UseCase<bool, IsUserVerifiedParams>
    with ValidatingUseCase<bool, IsUserVerifiedParams> {
  final PhotoVerificationService _service;

  IsUserVerifiedUseCase([PhotoVerificationService? service])
    : _service = service ?? PhotoVerificationService.instance;

  @override
  String? validate(IsUserVerifiedParams params) {
    if (params.userId.trim().isEmpty) {
      return 'User ID is required';
    }
    return null;
  }

  @override
  Future<Result<bool>> execute(IsUserVerifiedParams params) {
    return Result.guard(
      () => _service.isUserVerified(params.userId),
      logLabel: 'IsUserVerifiedUseCase',
      fallbackError: 'Unable to check verification status.',
    );
  }
}
