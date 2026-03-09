import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';
import 'package:crushhour/shared/utils/profile_media_limits.dart';

enum ProfileEditFormError { minPhotosRequired, userNotSignedIn }

class ProfileEditFormValidationResult {
  final ProfileEditFormError? error;

  const ProfileEditFormValidationResult._({this.error});

  bool get isValid => error == null;

  String? get message {
    switch (error) {
      case ProfileEditFormError.minPhotosRequired:
        return 'Add at least one photo to keep your profile visible.';
      case ProfileEditFormError.userNotSignedIn:
        return 'You need to be signed in to save changes.';
      case null:
        return null;
    }
  }

  static const valid = ProfileEditFormValidationResult._();

  factory ProfileEditFormValidationResult.invalid(ProfileEditFormError error) {
    return ProfileEditFormValidationResult._(error: error);
  }
}

class ProfileEditFormSnapshot {
  final String firstName;
  final String lastName;
  final String bio;
  final String jobTitle;
  final String company;
  final String school;
  final String livingIn;
  final String favoriteSinger;
  final String country;
  final String city;
  final List<String> photos;
  final List<String> videos;
  final int primaryPhotoIndex;
  final bool showFirstName;
  final bool showLastName;
  final int? heightCm;
  final String? relationshipGoals;
  final List<String> languages;
  final String? zodiacSign;
  final String? educationLevel;
  final String? familyPlans;
  final String? personalityType;
  final String? religion;
  final String? workout;
  final String? socialMedia;
  final String? sleepingHabits;
  final String? smoking;
  final String? drinking;
  final String? pets;
  final List<String> favoriteSongs;
  final List<String> interests;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? sexualOrientation;
  final String? lookingFor;
  final List<ProfilePrompt> profilePrompts;

  ProfileEditFormSnapshot({
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.jobTitle,
    required this.company,
    required this.school,
    required this.livingIn,
    required this.favoriteSinger,
    required this.country,
    required this.city,
    required List<String> photos,
    required List<String> videos,
    required this.primaryPhotoIndex,
    required this.showFirstName,
    required this.showLastName,
    required this.heightCm,
    required this.relationshipGoals,
    required List<String> languages,
    required this.zodiacSign,
    required this.educationLevel,
    required this.familyPlans,
    required this.personalityType,
    required this.religion,
    required this.workout,
    required this.socialMedia,
    required this.sleepingHabits,
    required this.smoking,
    required this.drinking,
    required this.pets,
    required List<String> favoriteSongs,
    required List<String> interests,
    required this.dateOfBirth,
    required this.gender,
    required this.sexualOrientation,
    required this.lookingFor,
    required List<ProfilePrompt> profilePrompts,
  }) : photos = List.unmodifiable(photos),
       videos = List.unmodifiable(videos),
       languages = List.unmodifiable(languages),
       favoriteSongs = List.unmodifiable(favoriteSongs),
       interests = List.unmodifiable(interests),
       profilePrompts = List.unmodifiable(profilePrompts);
}

class ProfileEditFormModel {
  const ProfileEditFormModel._();

  static const DiscoveryPreferences _defaultPreferences = DiscoveryPreferences(
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 50,
    showMeGenders: <String>['female', 'male'],
    showMyDistance: true,
    showMyAge: true,
    hideFromDiscovery: false,
    incognitoMode: false,
    country: 'Unknown',
    city: 'Unknown',
  );

  static ProfileEditFormValidationResult validateSelectedPhotos(
    List<String> photos,
  ) {
    if (photos.length < ProfileMediaLimits.minPhotos) {
      return ProfileEditFormValidationResult.invalid(
        ProfileEditFormError.minPhotosRequired,
      );
    }
    return ProfileEditFormValidationResult.valid;
  }

  static ProfileEditFormValidationResult validateUploadedPhotos(
    List<String> uploadedPhotos,
  ) {
    if (uploadedPhotos.length < ProfileMediaLimits.minPhotos) {
      return ProfileEditFormValidationResult.invalid(
        ProfileEditFormError.minPhotosRequired,
      );
    }
    return ProfileEditFormValidationResult.valid;
  }

  static String? resolveUserId({
    required String? stateUserId,
    required String? stateProfileId,
    required String? authUserId,
  }) {
    return stateUserId ?? stateProfileId ?? authUserId;
  }

  static ProfileEditFormValidationResult validateUserId(String? userId) {
    if (userId == null) {
      return ProfileEditFormValidationResult.invalid(
        ProfileEditFormError.userNotSignedIn,
      );
    }
    return ProfileEditFormValidationResult.valid;
  }

  static Profile buildFallbackProfile({
    required ProfileEditFormSnapshot form,
    required String? stateUserId,
    required String? authUserId,
    required Profile? existingProfile,
  }) {
    return Profile(
      id: stateUserId ?? authUserId ?? 'TEMP',
      name: '',
      lastName: existingProfile?.lastName,
      age: existingProfile?.age ?? 18,
      gender: form.gender ?? existingProfile?.gender ?? '',
      sexualOrientation:
          form.sexualOrientation ?? existingProfile?.sexualOrientation,
      dateOfBirth: form.dateOfBirth ?? existingProfile?.dateOfBirth,
      bio: '',
      photoUrls: List.of(form.photos),
      videoUrls: List.of(form.videos),
      primaryPhotoIndex: form.primaryPhotoIndex,
      isVerified: existingProfile?.isVerified ?? false,
      jobTitle: _currentOrFallback(form.jobTitle, existingProfile?.jobTitle),
      company: _currentOrFallback(form.company, existingProfile?.company),
      school: _currentOrFallback(form.school, existingProfile?.school),
      interests: form.interests.isNotEmpty
          ? List.of(form.interests)
          : (existingProfile?.interests ?? const <String>[]),
      profilePrompts: form.profilePrompts.isNotEmpty
          ? List.of(form.profilePrompts)
          : (existingProfile?.profilePrompts ?? const <ProfilePrompt>[]),
      heightCm: form.heightCm ?? existingProfile?.heightCm,
      relationshipGoals:
          form.relationshipGoals ?? existingProfile?.relationshipGoals,
      languages: form.languages.isNotEmpty
          ? List.of(form.languages)
          : (existingProfile?.languages ?? const <String>[]),
      zodiacSign: form.zodiacSign ?? existingProfile?.zodiacSign,
      educationLevel: form.educationLevel ?? existingProfile?.educationLevel,
      familyPlans: form.familyPlans ?? existingProfile?.familyPlans,
      personalityType: form.personalityType ?? existingProfile?.personalityType,
      religion: form.religion ?? existingProfile?.religion,
      workout: form.workout ?? existingProfile?.workout,
      socialMedia: form.socialMedia ?? existingProfile?.socialMedia,
      sleepingHabits: form.sleepingHabits ?? existingProfile?.sleepingHabits,
      smoking: form.smoking ?? existingProfile?.smoking,
      drinking: form.drinking ?? existingProfile?.drinking,
      pets: form.pets ?? existingProfile?.pets,
      livingIn: _currentOrFallback(form.livingIn, existingProfile?.livingIn),
      favoriteSongs: form.favoriteSongs.isNotEmpty
          ? List.of(form.favoriteSongs)
          : (existingProfile?.favoriteSongs ?? const <String>[]),
      favoriteSinger: _currentOrFallback(
        form.favoriteSinger,
        existingProfile?.favoriteSinger,
      ),
      country: existingProfile?.country ?? 'Unknown',
      city: existingProfile?.city ?? 'Unknown',
      latitude: existingProfile?.latitude,
      longitude: existingProfile?.longitude,
      preferences: existingProfile?.preferences ?? _defaultPreferences,
      privacySettings:
          existingProfile?.privacySettings ?? const ProfilePrivacySettings(),
    );
  }

  static Profile buildUpdatedProfile({
    required Profile base,
    required ProfileEditFormSnapshot form,
    required List<String> uploadedPhotoUrls,
    required List<String> uploadedVideoUrls,
    DateTime Function()? now,
  }) {
    final saveTimestamp = (now ?? DateTime.now)();
    final newFirstName = form.firstName.trim();
    final newLastName = form.lastName.trim();
    final baseLastName = base.lastName?.trim() ?? '';
    final nameChanged =
        newFirstName != base.name || newLastName != baseLastName;
    final dobChanged = form.dateOfBirth != base.dateOfBirth;
    final updatedPrivacy = base.privacySettings.copyWith(
      showFirstName: form.showFirstName,
      showLastName: form.showLastName,
    );
    final updatedPreferences = base.preferences.copyWith(
      showMeGenders: form.lookingFor != null
          ? ProfileFieldOptions.lookingForToShowMeGenders(form.lookingFor!)
          : base.preferences.showMeGenders,
    );

    return base.copyWith(
      name: newFirstName,
      lastName: newLastName.isEmpty ? null : newLastName,
      bio: form.bio.trim(),
      photoUrls: List.of(uploadedPhotoUrls),
      videoUrls: List.of(uploadedVideoUrls),
      primaryPhotoIndex: form.primaryPhotoIndex,
      lastNameChangeAt: nameChanged ? saveTimestamp : base.lastNameChangeAt,
      lastDobChangeAt: dobChanged ? saveTimestamp : base.lastDobChangeAt,
      heightCm: form.heightCm,
      relationshipGoals: form.relationshipGoals,
      languages: List.of(form.languages),
      zodiacSign: form.zodiacSign,
      educationLevel: form.educationLevel,
      familyPlans: form.familyPlans,
      personalityType: form.personalityType,
      religion: form.religion,
      workout: form.workout,
      socialMedia: form.socialMedia,
      sleepingHabits: form.sleepingHabits,
      smoking: form.smoking,
      drinking: form.drinking,
      pets: form.pets,
      interests: List.of(form.interests),
      profilePrompts: List.of(form.profilePrompts),
      jobTitle: _trimmedOrNull(form.jobTitle),
      company: _trimmedOrNull(form.company),
      school: _trimmedOrNull(form.school),
      livingIn: _trimmedOrNull(form.livingIn),
      favoriteSongs: List.of(form.favoriteSongs),
      favoriteSinger: _trimmedOrBase(form.favoriteSinger, base.favoriteSinger),
      dateOfBirth: form.dateOfBirth,
      gender: form.gender,
      sexualOrientation: form.sexualOrientation,
      privacySettings: updatedPrivacy,
      preferences: updatedPreferences,
      country: _trimmedOrBase(form.country, base.country) ?? base.country,
      city: _trimmedOrBase(form.city, base.city) ?? base.city,
    );
  }

  static String? _currentOrFallback(String current, String? fallback) {
    return current.isNotEmpty ? current : fallback;
  }

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  static String? _trimmedOrBase(String value, String? baseValue) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty ? trimmed : baseValue;
  }
}
