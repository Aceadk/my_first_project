import 'package:equatable/equatable.dart';
import 'preferences.dart';
import 'privacy_settings.dart';
import 'profile_prompt.dart';

class Profile extends Equatable {
  // ═══════════════════════════════════════════════════════════════════════════
  // CORE IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  final String id; // Firestore user document ID
  final String name;
  final int age;
  final String gender;
  final String? sexualOrientation;
  final DateTime? dateOfBirth;
  final DateTime? lastDobChangeAt; // Track when DOB was last changed (once per month)
  final DateTime? lastNameChangeAt; // Track when name was last changed (once per month)

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA
  // ═══════════════════════════════════════════════════════════════════════════
  final List<String> photoUrls;
  final List<String> videoUrls;
  final int primaryPhotoIndex; // Index of the photo to use as display picture

  /// Returns the primary/display photo URL, or null if no photos exist
  String? get displayPhotoUrl {
    if (photoUrls.isEmpty) return null;
    final index = primaryPhotoIndex.clamp(0, photoUrls.length - 1);
    return photoUrls[index];
  }

  /// Check if user can change their display name (once per month)
  bool get canChangeName {
    if (lastNameChangeAt == null) return true;
    final daysSinceLastChange = DateTime.now().difference(lastNameChangeAt!).inDays;
    return daysSinceLastChange >= 30;
  }

  /// Days remaining until name can be changed again
  int get daysUntilNameChange {
    if (lastNameChangeAt == null) return 0;
    final daysSinceLastChange = DateTime.now().difference(lastNameChangeAt!).inDays;
    return (30 - daysSinceLastChange).clamp(0, 30);
  }

  /// Check if user can change their date of birth (once per month)
  bool get canChangeDob {
    if (lastDobChangeAt == null) return true;
    final daysSinceLastChange = DateTime.now().difference(lastDobChangeAt!).inDays;
    return daysSinceLastChange >= 30;
  }

  /// Days remaining until DOB can be changed again
  int get daysUntilDobChange {
    if (lastDobChangeAt == null) return 0;
    final daysSinceLastChange = DateTime.now().difference(lastDobChangeAt!).inDays;
    return (30 - daysSinceLastChange).clamp(0, 30);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO & INTERESTS
  // ═══════════════════════════════════════════════════════════════════════════
  final String bio;
  final List<String> interests;
  @Deprecated('Use profilePrompts instead for structured prompts')
  final List<String> prompts;

  /// Structured profile prompts with question-answer pairs.
  /// Used for conversation starters on the profile.
  final List<ProfilePrompt> profilePrompts;

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIC INFO
  // ═══════════════════════════════════════════════════════════════════════════
  final int? heightCm; // Height stored in cm, display in cm or ft/inches
  final String? relationshipGoals;

  // ═══════════════════════════════════════════════════════════════════════════
  // LANGUAGES
  // ═══════════════════════════════════════════════════════════════════════════
  final List<String> languages;

  // ═══════════════════════════════════════════════════════════════════════════
  // MORE ABOUT ME
  // ═══════════════════════════════════════════════════════════════════════════
  final String? zodiacSign;
  final String? educationLevel;
  final String? familyPlans;
  final String? personalityType; // MBTI

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFESTYLE
  // ═══════════════════════════════════════════════════════════════════════════
  final String? workout;
  final String? socialMedia;
  final String? sleepingHabits;
  final String? smoking;
  final String? drinking;
  final String? diet;
  final String? exercise; // Legacy field, kept for compatibility

  // ═══════════════════════════════════════════════════════════════════════════
  // PETS
  // ═══════════════════════════════════════════════════════════════════════════
  final String? pets;

  // ═══════════════════════════════════════════════════════════════════════════
  // WORK & EDUCATION
  // ═══════════════════════════════════════════════════════════════════════════
  final String? jobTitle;
  final String? company;
  final String? school;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  final String country;
  final String city;
  final String? livingIn; // Display location (can be different from actual)
  final double? latitude;
  final double? longitude;

  // ═══════════════════════════════════════════════════════════════════════════
  // DISTANCE (for discovery)
  // ═══════════════════════════════════════════════════════════════════════════
  final double? distance; // Distance from current user in km or miles
  final String? distanceUnit; // 'km' or 'mi'

  /// Returns a human-readable distance string (e.g., "5 km away")
  String? get distanceDisplay {
    if (distance == null) return null;
    final unit = distanceUnit ?? 'km';
    if (distance! < 1) {
      return 'Less than 1 $unit away';
    }
    return '${distance!.round()} $unit away';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUSIC PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════════
  final List<String> favoriteSongs; // Up to 5 songs
  final String? favoriteSinger;

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════
  final bool isVerified;
  final String? verificationBadge;

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════════
  final DiscoveryPreferences preferences;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVACY SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  final ProfilePrivacySettings privacySettings;

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
    this.lastDobChangeAt,
    this.lastNameChangeAt,
    required this.photoUrls,
    required this.videoUrls,
    this.primaryPhotoIndex = 0,
    required this.bio,
    required this.interests,
    this.prompts = const [],
    this.profilePrompts = const [],
    this.heightCm,
    this.relationshipGoals,
    this.languages = const [],
    this.zodiacSign,
    this.educationLevel,
    this.familyPlans,
    this.personalityType,
    this.workout,
    this.socialMedia,
    this.sleepingHabits,
    this.smoking,
    this.drinking,
    this.diet,
    this.exercise,
    this.pets,
    this.jobTitle,
    this.company,
    this.school,
    required this.country,
    required this.city,
    this.livingIn,
    this.latitude,
    this.longitude,
    this.distance,
    this.distanceUnit,
    this.favoriteSongs = const [],
    this.favoriteSinger,
    required this.isVerified,
    this.verificationBadge,
    required this.preferences,
    this.privacySettings = const ProfilePrivacySettings(),
  });

  /// Sentinel object for copyWith null handling
  static const _unset = Object();

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    Object? sexualOrientation = _unset,
    Object? dateOfBirth = _unset,
    Object? lastDobChangeAt = _unset,
    Object? lastNameChangeAt = _unset,
    List<String>? photoUrls,
    List<String>? videoUrls,
    int? primaryPhotoIndex,
    String? bio,
    List<String>? interests,
    List<String>? prompts,
    List<ProfilePrompt>? profilePrompts,
    Object? heightCm = _unset,
    Object? relationshipGoals = _unset,
    List<String>? languages,
    Object? zodiacSign = _unset,
    Object? educationLevel = _unset,
    Object? familyPlans = _unset,
    Object? personalityType = _unset,
    Object? workout = _unset,
    Object? socialMedia = _unset,
    Object? sleepingHabits = _unset,
    Object? smoking = _unset,
    Object? drinking = _unset,
    Object? diet = _unset,
    Object? exercise = _unset,
    Object? pets = _unset,
    Object? jobTitle = _unset,
    Object? company = _unset,
    Object? school = _unset,
    String? country,
    String? city,
    Object? livingIn = _unset,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? distance = _unset,
    Object? distanceUnit = _unset,
    List<String>? favoriteSongs,
    Object? favoriteSinger = _unset,
    bool? isVerified,
    Object? verificationBadge = _unset,
    DiscoveryPreferences? preferences,
    ProfilePrivacySettings? privacySettings,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      sexualOrientation: identical(sexualOrientation, _unset)
          ? this.sexualOrientation
          : sexualOrientation as String?,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      lastDobChangeAt: identical(lastDobChangeAt, _unset)
          ? this.lastDobChangeAt
          : lastDobChangeAt as DateTime?,
      lastNameChangeAt: identical(lastNameChangeAt, _unset)
          ? this.lastNameChangeAt
          : lastNameChangeAt as DateTime?,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      primaryPhotoIndex: primaryPhotoIndex ?? this.primaryPhotoIndex,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      // ignore: deprecated_member_use_from_same_package
      prompts: prompts ?? this.prompts, // Keep for backwards compatibility
      profilePrompts: profilePrompts ?? this.profilePrompts,
      heightCm:
          identical(heightCm, _unset) ? this.heightCm : heightCm as int?,
      relationshipGoals: identical(relationshipGoals, _unset)
          ? this.relationshipGoals
          : relationshipGoals as String?,
      languages: languages ?? this.languages,
      zodiacSign: identical(zodiacSign, _unset)
          ? this.zodiacSign
          : zodiacSign as String?,
      educationLevel: identical(educationLevel, _unset)
          ? this.educationLevel
          : educationLevel as String?,
      familyPlans: identical(familyPlans, _unset)
          ? this.familyPlans
          : familyPlans as String?,
      personalityType: identical(personalityType, _unset)
          ? this.personalityType
          : personalityType as String?,
      workout:
          identical(workout, _unset) ? this.workout : workout as String?,
      socialMedia: identical(socialMedia, _unset)
          ? this.socialMedia
          : socialMedia as String?,
      sleepingHabits: identical(sleepingHabits, _unset)
          ? this.sleepingHabits
          : sleepingHabits as String?,
      smoking:
          identical(smoking, _unset) ? this.smoking : smoking as String?,
      drinking:
          identical(drinking, _unset) ? this.drinking : drinking as String?,
      diet: identical(diet, _unset) ? this.diet : diet as String?,
      exercise:
          identical(exercise, _unset) ? this.exercise : exercise as String?,
      pets: identical(pets, _unset) ? this.pets : pets as String?,
      jobTitle:
          identical(jobTitle, _unset) ? this.jobTitle : jobTitle as String?,
      company:
          identical(company, _unset) ? this.company : company as String?,
      school: identical(school, _unset) ? this.school : school as String?,
      country: country ?? this.country,
      city: city ?? this.city,
      livingIn:
          identical(livingIn, _unset) ? this.livingIn : livingIn as String?,
      latitude:
          identical(latitude, _unset) ? this.latitude : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      distance:
          identical(distance, _unset) ? this.distance : distance as double?,
      distanceUnit: identical(distanceUnit, _unset)
          ? this.distanceUnit
          : distanceUnit as String?,
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      favoriteSinger: identical(favoriteSinger, _unset)
          ? this.favoriteSinger
          : favoriteSinger as String?,
      isVerified: isVerified ?? this.isVerified,
      verificationBadge: identical(verificationBadge, _unset)
          ? this.verificationBadge
          : verificationBadge as String?,
      preferences: preferences ?? this.preferences,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        gender,
        sexualOrientation,
        dateOfBirth,
        lastDobChangeAt,
        lastNameChangeAt,
        photoUrls,
        videoUrls,
        primaryPhotoIndex,
        bio,
        interests,
        // ignore: deprecated_member_use_from_same_package
        prompts, // Keep for backwards compatibility in Equatable comparison
        profilePrompts,
        heightCm,
        relationshipGoals,
        languages,
        zodiacSign,
        educationLevel,
        familyPlans,
        personalityType,
        workout,
        socialMedia,
        sleepingHabits,
        smoking,
        drinking,
        diet,
        exercise,
        pets,
        jobTitle,
        company,
        school,
        country,
        city,
        livingIn,
        latitude,
        longitude,
        distance,
        distanceUnit,
        favoriteSongs,
        favoriteSinger,
        isVerified,
        verificationBadge,
        preferences,
        privacySettings,
      ];
}
