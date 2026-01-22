import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Parameters for updating a profile.
class UpdateProfileParams {
  final Profile profile;

  const UpdateProfileParams({required this.profile});
}

/// Use case for updating an existing profile.
class UpdateProfileUseCase extends UseCase<CrushUser, UpdateProfileParams> {
  final ProfileRepository _profileRepository;

  UpdateProfileUseCase(this._profileRepository);

  @override
  Future<Result<CrushUser>> call(UpdateProfileParams params) {
    return Result.guard(
      () => _profileRepository.updateProfile(params.profile),
      logLabel: 'UpdateProfileUseCase',
      fallbackError: 'Unable to update profile. Please try again.',
    );
  }
}
