import 'package:crushhour/core/utils/result.dart';
import '../../../data/repositories/auth_repository.dart';
import '../use_case.dart';

/// Parameters for sending phone OTP.
class SendPhoneOtpParams {
  final String phoneNumber;

  const SendPhoneOtpParams({required this.phoneNumber});
}

/// Use case for sending OTP to a phone number.
///
/// Handles phone number validation and OTP request.
class SendPhoneOtpUseCase extends UseCase<void, SendPhoneOtpParams>
    with ValidatingUseCase<void, SendPhoneOtpParams> {
  final AuthRepository _authRepository;

  SendPhoneOtpUseCase(this._authRepository);

  @override
  String? validate(SendPhoneOtpParams params) {
    final phone = params.phoneNumber.trim();
    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }
    // Basic phone validation - should start with + and have digits
    if (!phone.startsWith('+') || phone.length < 10) {
      return 'Please enter a valid phone number with country code';
    }
    return null;
  }

  @override
  Future<Result<void>> execute(SendPhoneOtpParams params) {
    return Result.guard(
      () => _authRepository.sendOtp(params.phoneNumber.trim()),
      logLabel: 'SendPhoneOtpUseCase',
      fallbackError: 'Unable to send verification code. Please try again.',
    );
  }
}
