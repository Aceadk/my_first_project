import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';

/// Parameters for password-based sign in.
class SignInParams {
  final String identifier; // email or username
  final String password;

  const SignInParams({
    required this.identifier,
    required this.password,
  });
}

/// Use case for signing in with email/username and password.
///
/// This encapsulates the business logic for password authentication,
/// including input normalization and error handling.
class SignInWithPasswordUseCase extends UseCase<CrushUser, SignInParams>
    with ValidatingUseCase<CrushUser, SignInParams> {
  final AuthRepository _authRepository;

  SignInWithPasswordUseCase(this._authRepository);

  @override
  String? validate(SignInParams params) {
    if (params.identifier.trim().isEmpty) {
      return 'Please enter your email or username';
    }
    if (params.password.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  @override
  Future<Result<CrushUser>> execute(SignInParams params) {
    return Result.guard(
      () => _authRepository.loginWithPassword(
        identifier: params.identifier.trim(),
        password: params.password,
      ),
      logLabel: 'SignInWithPasswordUseCase',
      fallbackError: 'Unable to sign in. Please check your credentials.',
    );
  }
}
