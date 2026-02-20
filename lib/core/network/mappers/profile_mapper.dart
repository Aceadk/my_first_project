import 'package:crushhour/core/network/dto/profile_dto.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';

/// Mapper for profile-related DTOs to domain models.
class ProfileMapper {
  ProfileMapper._();

  /// Convert ProfileDto to Profile domain model.
  static Profile profileFromDto(ProfileDto dto) {
    return Profile(
      id: dto.id,
      name: dto.displayName ?? '',
      age: _calculateAge(dto.birthDate),
      gender: dto.gender ?? '',
      sexualOrientation: null,
      dateOfBirth: dto.birthDate,
      photoUrls: dto.photos?.map((p) => p.url).toList() ?? const [],
      videoUrls: const [],
      primaryPhotoIndex: _findPrimaryPhotoIndex(dto.photos),
      bio: dto.bio ?? '',
      interests: dto.interests ?? const [],
      prompts: const [],
      heightCm: dto.height,
      relationshipGoals: dto.relationshipGoals,
      languages: dto.languages ?? const [],
      zodiacSign: dto.zodiacSign,
      educationLevel: dto.education,
      familyPlans: null,
      personalityType: dto.personalityType,
      workout: dto.exerciseHabit,
      socialMedia: null,
      sleepingHabits: null,
      smoking: dto.smokingHabit,
      drinking: dto.drinkingHabit,
      diet: dto.dietaryPreference,
      exercise: dto.exerciseHabit,
      pets: dto.pets,
      jobTitle: dto.jobTitle,
      company: dto.company,
      school: dto.education,
      country: dto.location?.country ?? '',
      city: dto.location?.city ?? '',
      livingIn: dto.livingIn,
      latitude: dto.location?.latitude,
      longitude: dto.location?.longitude,
      favoriteSongs: const [],
      favoriteSinger: null,
      isVerified: dto.isVerified ?? false,
      verificationBadge: dto.isVerified == true ? 'verified' : null,
      preferences: _preferencesFromDto(dto),
      privacySettings: const ProfilePrivacySettings(),
    );
  }

  /// Convert Profile to ProfileDto for API requests.
  static ProfileDto profileToDto(Profile profile) {
    return ProfileDto(
      id: profile.id,
      displayName: profile.name,
      bio: profile.bio,
      birthDate: profile.dateOfBirth,
      gender: profile.gender,
      interestedIn: profile.preferences.showMeGenders,
      photos: profile.photoUrls
          .asMap()
          .entries
          .map(
            (e) => ProfilePhotoDto(
              id: 'photo_${e.key}',
              url: e.value,
              isPrimary: e.key == profile.primaryPhotoIndex,
              order: e.key,
            ),
          )
          .toList(),
      location: LocationDto(
        latitude: profile.latitude,
        longitude: profile.longitude,
        city: profile.city,
        country: profile.country,
      ),
      height: profile.heightCm,
      jobTitle: profile.jobTitle,
      company: profile.company,
      education: profile.school,
      livingIn: profile.livingIn,
      hometown: null,
      languages: profile.languages,
      interests: profile.interests,
      relationshipGoals: profile.relationshipGoals,
      drinkingHabit: profile.drinking,
      smokingHabit: profile.smoking,
      exerciseHabit: profile.workout,
      dietaryPreference: profile.diet,
      zodiacSign: profile.zodiacSign,
      personalityType: profile.personalityType,
      lovingLanguage: null,
      communicationStyle: null,
      pets: profile.pets,
      isVerified: profile.isVerified,
      isPremium: false,
      profileCompleteness: null,
    );
  }

  /// Convert Profile to UpdateProfileRequestDto for updates.
  static UpdateProfileRequestDto profileToUpdateRequest(Profile profile) {
    return UpdateProfileRequestDto(
      displayName: profile.name,
      bio: profile.bio,
      birthDate: profile.dateOfBirth,
      gender: profile.gender,
      interestedIn: profile.preferences.showMeGenders,
      height: profile.heightCm,
      jobTitle: profile.jobTitle,
      company: profile.company,
      education: profile.school,
      livingIn: profile.livingIn,
      hometown: null,
      languages: profile.languages,
      interests: profile.interests,
      relationshipGoals: profile.relationshipGoals,
      drinkingHabit: profile.drinking,
      smokingHabit: profile.smoking,
      exerciseHabit: profile.workout,
      dietaryPreference: profile.diet,
      zodiacSign: profile.zodiacSign,
      personalityType: profile.personalityType,
      lovingLanguage: null,
      communicationStyle: null,
      pets: profile.pets,
    );
  }

  /// Convert DiscoveryPreferencesDto to domain model.
  static DiscoveryPreferences preferencesFromDto(
    DiscoveryPreferencesDto dto, {
    String? country,
    String? city,
  }) {
    return DiscoveryPreferences(
      minAge: dto.minAge ?? 18,
      maxAge: dto.maxAge ?? 50,
      maxDistanceKm: (dto.maxDistance ?? 50).toDouble(),
      showMeGenders: dto.genderPreferences ?? ['women', 'men'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: !(dto.showMe ?? true),
      incognitoMode: false,
      country: country ?? '',
      city: city ?? '',
    );
  }

  /// Convert DiscoveryPreferences to DTO.
  static DiscoveryPreferencesDto preferencesToDto(DiscoveryPreferences prefs) {
    return DiscoveryPreferencesDto(
      minAge: prefs.minAge,
      maxAge: prefs.maxAge,
      maxDistance: prefs.maxDistanceKm.round(),
      distanceUnit: 'km',
      genderPreferences: prefs.showMeGenders,
      showMe: !prefs.hideFromDiscovery,
      globalMode: false,
    );
  }

  static int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 18;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.clamp(18, 99);
  }

  static int _findPrimaryPhotoIndex(List<ProfilePhotoDto>? photos) {
    if (photos == null || photos.isEmpty) return 0;
    final primaryIndex = photos.indexWhere((p) => p.isPrimary == true);
    return primaryIndex >= 0 ? primaryIndex : 0;
  }

  static DiscoveryPreferences _preferencesFromDto(ProfileDto dto) {
    return DiscoveryPreferences(
      minAge: 18,
      maxAge: 50,
      maxDistanceKm: 50,
      showMeGenders: dto.interestedIn ?? ['women', 'men'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: dto.location?.country ?? '',
      city: dto.location?.city ?? '',
    );
  }
}
