import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Use case for uploading ID document for verification.
class UploadIdDocumentUseCase extends UseCase<void, NoParams> {
  final ProfileRepository _profileRepository;

  UploadIdDocumentUseCase(this._profileRepository);

  @override
  Future<Result<void>> call(NoParams params) {
    return Result.guard(
      () => _profileRepository.uploadIdDocument(),
      logLabel: 'UploadIdDocumentUseCase',
      fallbackError: 'Unable to upload ID document. Please try again.',
    );
  }
}
