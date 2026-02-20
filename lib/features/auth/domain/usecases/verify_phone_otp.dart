import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';

/// Parameters for verifying phone OTP.
class VerifyPhoneOtpParams {
  final String phoneNumber;
  final String otp;

  const VerifyPhoneOtpParams({required this.phoneNumber, required this.otp});
}

/// Use case for verifying a phone OTP code.
///
/// Validates the OTP and completes phone authentication.
class VerifyPhoneOtpUseCase extends UseCase<CrushUser, VerifyPhoneOtpParams>
    with ValidatingUseCase<CrushUser, VerifyPhoneOtpParams> {
  final AuthRepository _authRepository;

  VerifyPhoneOtpUseCase(this._authRepository);

  @override
  String? validate(VerifyPhoneOtpParams params) {
    if (params.phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (params.otp.trim().isEmpty) {
      return 'Please enter the verification code';
    }
    if (params.otp.trim().length != 6) {
      return 'Verification code must be 6 digits';
    }
    return null;
  }

  @override
  Future<Result<CrushUser>> execute(VerifyPhoneOtpParams params) {
    return Result.guard(
      () => _authRepository.verifyOtp(
        phoneNumber: params.phoneNumber.trim(),
        otp: params.otp.trim(),
      ),
      logLabel: 'VerifyPhoneOtpUseCase',
      fallbackError: 'Invalid verification code. Please try again.',
    );
  }
}
