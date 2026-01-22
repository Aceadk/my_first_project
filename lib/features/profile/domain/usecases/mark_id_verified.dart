import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Use case for marking user's ID as verified.
class MarkIdVerifiedUseCase extends UseCase<CrushUser, NoParams> {
  final ProfileRepository _profileRepository;

  MarkIdVerifiedUseCase(this._profileRepository);

  @override
  Future<Result<CrushUser>> call(NoParams params) {
    return Result.guard(
      () => _profileRepository.markIdVerified(),
      logLabel: 'MarkIdVerifiedUseCase',
      fallbackError: 'Unable to verify ID. Please try again.',
    );
  }
}
