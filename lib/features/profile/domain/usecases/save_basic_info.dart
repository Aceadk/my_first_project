import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';

/// Parameters for saving basic profile information.
class SaveBasicInfoParams {
  final String? username;
  final String name;
  final String? lastName;
  final int age;
  final String gender;
  final String? sexualOrientation;
  final DateTime? dateOfBirth;
  final bool? showFirstName;
  final bool? showLastName;

  const SaveBasicInfoParams({
    this.username,
    required this.name,
    this.lastName,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
    this.showFirstName,
    this.showLastName,
  });
}

/// Use case for saving basic profile information (name, age, gender).
class SaveBasicInfoUseCase extends UseCase<CrushUser, SaveBasicInfoParams>
    with ValidatingUseCase<CrushUser, SaveBasicInfoParams> {
  final ProfileRepository _profileRepository;

  SaveBasicInfoUseCase(this._profileRepository);

  @override
  String? validate(SaveBasicInfoParams params) {
    if (params.name.trim().isEmpty) {
      return 'Name is required';
    }
    if (params.name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (params.age < 18) {
      return 'You must be 18 or older to use this app';
    }
    if (params.age > 120) {
      return 'Please enter a valid age';
    }
    if (params.gender.trim().isEmpty) {
      return 'Please select your gender';
    }
    return null;
  }

  @override
  Future<Result<CrushUser>> execute(SaveBasicInfoParams params) {
    return Result.guard(
      () => _profileRepository.saveBasicInfo(
        username: params.username,
        name: params.name.trim(),
        lastName: params.lastName?.trim(),
        age: params.age,
        gender: params.gender,
        sexualOrientation: params.sexualOrientation,
        dateOfBirth: params.dateOfBirth,
        showFirstName: params.showFirstName,
        showLastName: params.showLastName,
      ),
      logLabel: 'SaveBasicInfoUseCase',
      fallbackError: 'Unable to save profile. Please try again.',
    );
  }
}
