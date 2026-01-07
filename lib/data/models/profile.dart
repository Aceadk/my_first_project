import 'package:equatable/equatable.dart';
import 'preferences.dart';

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

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA
  // ═══════════════════════════════════════════════════════════════════════════
  final List<String> photoUrls;
  final List<String> videoUrls;

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO & INTERESTS
  // ═══════════════════════════════════════════════════════════════════════════
  final String bio;
  final List<String> interests;
  final List<String> prompts;

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

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
    required this.photoUrls,
    required this.videoUrls,
    required this.bio,
    required this.interests,
    this.prompts = const [],
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
    this.favoriteSongs = const [],
    this.favoriteSinger,
    required this.isVerified,
    this.verificationBadge,
    required this.preferences,
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
    List<String>? photoUrls,
    List<String>? videoUrls,
    String? bio,
    List<String>? interests,
    List<String>? prompts,
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
    List<String>? favoriteSongs,
    Object? favoriteSinger = _unset,
    bool? isVerified,
    Object? verificationBadge = _unset,
    DiscoveryPreferences? preferences,
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
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      prompts: prompts ?? this.prompts,
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
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      favoriteSinger: identical(favoriteSinger, _unset)
          ? this.favoriteSinger
          : favoriteSinger as String?,
      isVerified: isVerified ?? this.isVerified,
      verificationBadge: identical(verificationBadge, _unset)
          ? this.verificationBadge
          : verificationBadge as String?,
      preferences: preferences ?? this.preferences,
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
        photoUrls,
        videoUrls,
        bio,
        interests,
        prompts,
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
        favoriteSongs,
        favoriteSinger,
        isVerified,
        verificationBadge,
        preferences,
      ];
}
