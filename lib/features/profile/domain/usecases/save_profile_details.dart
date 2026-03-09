import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Parameters for saving detailed profile information.
class SaveProfileDetailsParams {
  final String bio;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final String? jobTitle;
  final String? company;
  final String? school;
  final List<String> interests;
  final String? city;
  final String? country;
  final ProfileFavourites? favourites;

  const SaveProfileDetailsParams({
    required this.bio,
    required this.photoUrls,
    this.videoUrls = const [],
    this.jobTitle,
    this.company,
    this.school,
    required this.interests,
    this.city,
    this.country,
    this.favourites,
  });
}

/// Use case for saving detailed profile information (bio, photos, interests).
class SaveProfileDetailsUseCase
    extends UseCase<CrushUser, SaveProfileDetailsParams>
    with ValidatingUseCase<CrushUser, SaveProfileDetailsParams> {
  final ProfileRepository _profileRepository;

  SaveProfileDetailsUseCase(this._profileRepository);

  @override
  String? validate(SaveProfileDetailsParams params) {
    if (params.photoUrls.isEmpty) {
      return 'At least one photo is required';
    }
    if (params.photoUrls.length > 9) {
      return 'Maximum 9 photos allowed';
    }
    if (params.bio.length > 500) {
      return 'Bio must be 500 characters or less';
    }
    if (params.interests.isEmpty) {
      return 'Select at least one interest';
    }
    if (params.interests.length > 10) {
      return 'Maximum 10 interests allowed';
    }
    return null;
  }

  @override
  Future<Result<CrushUser>> execute(SaveProfileDetailsParams params) {
    return Result.guard(
      () => _profileRepository.saveProfileDetails(
        bio: params.bio.trim(),
        photoUrls: params.photoUrls,
        videoUrls: params.videoUrls,
        jobTitle: params.jobTitle?.trim(),
        company: params.company?.trim(),
        school: params.school?.trim(),
        interests: params.interests,
        city: params.city?.trim(),
        country: params.country?.trim(),
        favourites: params.favourites,
      ),
      logLabel: 'SaveProfileDetailsUseCase',
      fallbackError: 'Unable to save profile details. Please try again.',
    );
  }
}
