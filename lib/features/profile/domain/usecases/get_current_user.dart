import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Use case for fetching the current user's profile.
class GetCurrentUserUseCase extends UseCase<CrushUser?, NoParams> {
  final ProfileRepository _profileRepository;

  GetCurrentUserUseCase(this._profileRepository);

  @override
  Future<Result<CrushUser?>> call(NoParams params) {
    return Result.guard(
      () => _profileRepository.getCurrentUser(),
      logLabel: 'GetCurrentUserUseCase',
      fallbackError: 'Unable to load profile. Please try again.',
    );
  }
}
