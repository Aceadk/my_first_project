import 'package:crushhour/core/utils/result.dart';
import '../../../data/repositories/auth_repository.dart';
import '../use_case.dart';

/// Use case for signing out the current user.
///
/// Clears auth state and invalidates the session.
class SignOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () => _authRepository.signOut(),
      logLabel: 'SignOutUseCase',
      fallbackError: 'Unable to sign out. Please try again.',
    );
  }
}
