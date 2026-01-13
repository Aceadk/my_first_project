import '../models/profile.dart';
import '../models/preferences.dart';
import '../models/privacy_settings.dart';

/// Data Transfer Object for Profile.
/// Handles conversion between wire format (JSON) and domain model.
class ProfileDto {
  // Core identity
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? sexualOrientation;
  final String? dateOfBirth;
  final String? lastNameChangeAt;

  // Media
  final List<String> photoUrls;
  final List<String> videoUrls;
  final int primaryPhotoIndex;

  // Bio & Interests
  final String bio;
  final List<String> interests;
  final List<String> prompts;

  // Basic Info
  final int? heightCm;
  final String? relationshipGoals;
  final List<String> languages;

  // More About Me
  final String? zodiacSign;
  final String? educationLevel;
  final String? familyPlans;
  final String? personalityType;

  // Lifestyle
  final String? workout;
  final String? socialMedia;
  final String? sleepingHabits;
  final String? smoking;
  final String? drinking;
  final String? diet;
  final String? exercise;
  final String? pets;

  // Work & Education
  final String? jobTitle;
  final String? company;
  final String? school;

  // Location
  final String country;
  final String city;
  final String? livingIn;
  final double? latitude;
  final double? longitude;

  // Music
  final List<String> favoriteSongs;
  final String? favoriteSinger;

  // Verification
  final bool isVerified;
  final String? verificationBadge;

  // Preferences (nested)
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? privacySettings;

  const ProfileDto({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.sexualOrientation,
    this.dateOfBirth,
    this.lastNameChangeAt,
    required this.photoUrls,
    required this.videoUrls,
    this.primaryPhotoIndex = 0,
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
    this.preferences,
    this.privacySettings,
  });

  /// Create from JSON (API response).
  /// Handles both snake_case and camelCase field names for flexibility.
  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      id: json['id'] as String? ?? json['profile_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      sexualOrientation: json['sexual_orientation'] as String? ??
                         json['sexualOrientation'] as String?,
      dateOfBirth: json['date_of_birth'] as String? ??
                   json['dateOfBirth'] as String?,
      lastNameChangeAt: json['last_name_change_at'] as String? ??
                        json['lastNameChangeAt'] as String?,
      photoUrls: _parseStringList(json['photo_urls'] ?? json['photoUrls']),
      videoUrls: _parseStringList(json['video_urls'] ?? json['videoUrls']),
      primaryPhotoIndex: json['primary_photo_index'] as int? ??
                         json['primaryPhotoIndex'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      interests: _parseStringList(json['interests']),
      prompts: _parseStringList(json['prompts']),
      heightCm: json['height_cm'] as int? ?? json['heightCm'] as int?,
      relationshipGoals: json['relationship_goals'] as String? ??
                         json['relationshipGoals'] as String?,
      languages: _parseStringList(json['languages']),
      zodiacSign: json['zodiac_sign'] as String? ??
                  json['zodiacSign'] as String?,
      educationLevel: json['education_level'] as String? ??
                      json['educationLevel'] as String?,
      familyPlans: json['family_plans'] as String? ??
                   json['familyPlans'] as String?,
      personalityType: json['personality_type'] as String? ??
                       json['personalityType'] as String?,
      workout: json['workout'] as String?,
      socialMedia: json['social_media'] as String? ??
                   json['socialMedia'] as String?,
      sleepingHabits: json['sleeping_habits'] as String? ??
                      json['sleepingHabits'] as String?,
      smoking: json['smoking'] as String?,
      drinking: json['drinking'] as String?,
      diet: json['diet'] as String?,
      exercise: json['exercise'] as String?,
      pets: json['pets'] as String?,
      jobTitle: json['job_title'] as String? ?? json['jobTitle'] as String?,
      company: json['company'] as String?,
      school: json['school'] as String?,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      livingIn: json['living_in'] as String? ?? json['livingIn'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      favoriteSongs: _parseStringList(json['favorite_songs'] ?? json['favoriteSongs']),
      favoriteSinger: json['favorite_singer'] as String? ??
                      json['favoriteSinger'] as String?,
      isVerified: json['is_verified'] as bool? ??
                  json['isVerified'] as bool? ?? false,
      verificationBadge: json['verification_badge'] as String? ??
                         json['verificationBadge'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      privacySettings: json['privacy_settings'] as Map<String, dynamic>? ??
                       json['privacySettings'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON (API request) using snake_case.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      if (sexualOrientation != null) 'sexual_orientation': sexualOrientation,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (lastNameChangeAt != null) 'last_name_change_at': lastNameChangeAt,
      'photo_urls': photoUrls,
      'video_urls': videoUrls,
      'primary_photo_index': primaryPhotoIndex,
      'bio': bio,
      'interests': interests,
      'prompts': prompts,
      if (heightCm != null) 'height_cm': heightCm,
      if (relationshipGoals != null) 'relationship_goals': relationshipGoals,
      'languages': languages,
      if (zodiacSign != null) 'zodiac_sign': zodiacSign,
      if (educationLevel != null) 'education_level': educationLevel,
      if (familyPlans != null) 'family_plans': familyPlans,
      if (personalityType != null) 'personality_type': personalityType,
      if (workout != null) 'workout': workout,
      if (socialMedia != null) 'social_media': socialMedia,
      if (sleepingHabits != null) 'sleeping_habits': sleepingHabits,
      if (smoking != null) 'smoking': smoking,
      if (drinking != null) 'drinking': drinking,
      if (diet != null) 'diet': diet,
      if (exercise != null) 'exercise': exercise,
      if (pets != null) 'pets': pets,
      if (jobTitle != null) 'job_title': jobTitle,
      if (company != null) 'company': company,
      if (school != null) 'school': school,
      'country': country,
      'city': city,
      if (livingIn != null) 'living_in': livingIn,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'favorite_songs': favoriteSongs,
      if (favoriteSinger != null) 'favorite_singer': favoriteSinger,
      'is_verified': isVerified,
      if (verificationBadge != null) 'verification_badge': verificationBadge,
      if (preferences != null) 'preferences': preferences,
      if (privacySettings != null) 'privacy_settings': privacySettings,
    };
  }

  /// Convert to domain model.
  Profile toDomain() {
    return Profile(
      id: id,
      name: name,
      age: age,
      gender: gender,
      sexualOrientation: sexualOrientation,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      lastNameChangeAt: lastNameChangeAt != null ? DateTime.tryParse(lastNameChangeAt!) : null,
      photoUrls: photoUrls,
      videoUrls: videoUrls,
      primaryPhotoIndex: primaryPhotoIndex,
      bio: bio,
      interests: interests,
      prompts: prompts,
      heightCm: heightCm,
      relationshipGoals: relationshipGoals,
      languages: languages,
      zodiacSign: zodiacSign,
      educationLevel: educationLevel,
      familyPlans: familyPlans,
      personalityType: personalityType,
      workout: workout,
      socialMedia: socialMedia,
      sleepingHabits: sleepingHabits,
      smoking: smoking,
      drinking: drinking,
      diet: diet,
      exercise: exercise,
      pets: pets,
      jobTitle: jobTitle,
      company: company,
      school: school,
      country: country,
      city: city,
      livingIn: livingIn,
      latitude: latitude,
      longitude: longitude,
      favoriteSongs: favoriteSongs,
      favoriteSinger: favoriteSinger,
      isVerified: isVerified,
      verificationBadge: verificationBadge,
      preferences: _parsePreferences(preferences),
      privacySettings: _parsePrivacySettings(privacySettings),
    );
  }

  /// Create from domain model.
  factory ProfileDto.fromDomain(Profile profile) {
    return ProfileDto(
      id: profile.id,
      name: profile.name,
      age: profile.age,
      gender: profile.gender,
      sexualOrientation: profile.sexualOrientation,
      dateOfBirth: profile.dateOfBirth?.toIso8601String(),
      lastNameChangeAt: profile.lastNameChangeAt?.toIso8601String(),
      photoUrls: profile.photoUrls,
      videoUrls: profile.videoUrls,
      primaryPhotoIndex: profile.primaryPhotoIndex,
      bio: profile.bio,
      interests: profile.interests,
      // ignore: deprecated_member_use_from_same_package
      prompts: profile.prompts, // Keep for backwards compatibility
      heightCm: profile.heightCm,
      relationshipGoals: profile.relationshipGoals,
      languages: profile.languages,
      zodiacSign: profile.zodiacSign,
      educationLevel: profile.educationLevel,
      familyPlans: profile.familyPlans,
      personalityType: profile.personalityType,
      workout: profile.workout,
      socialMedia: profile.socialMedia,
      sleepingHabits: profile.sleepingHabits,
      smoking: profile.smoking,
      drinking: profile.drinking,
      diet: profile.diet,
      exercise: profile.exercise,
      pets: profile.pets,
      jobTitle: profile.jobTitle,
      company: profile.company,
      school: profile.school,
      country: profile.country,
      city: profile.city,
      livingIn: profile.livingIn,
      latitude: profile.latitude,
      longitude: profile.longitude,
      favoriteSongs: profile.favoriteSongs,
      favoriteSinger: profile.favoriteSinger,
      isVerified: profile.isVerified,
      verificationBadge: profile.verificationBadge,
      preferences: _preferencesToJson(profile.preferences),
      privacySettings: _privacySettingsToJson(profile.privacySettings),
    );
  }

  // Helper methods
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  static DiscoveryPreferences _parsePreferences(Map<String, dynamic>? json) {
    if (json == null) {
      return const DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 50,
        showMeGenders: [],
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      );
    }
    return DiscoveryPreferences(
      minAge: json['min_age'] as int? ?? json['minAge'] as int? ?? 18,
      maxAge: json['max_age'] as int? ?? json['maxAge'] as int? ?? 50,
      maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble() ??
                     (json['maxDistanceKm'] as num?)?.toDouble() ?? 50,
      showMeGenders: _parseStringList(json['show_me_genders'] ?? json['showMeGenders']),
      showMyDistance: json['show_my_distance'] as bool? ??
                      json['showMyDistance'] as bool? ?? true,
      showMyAge: json['show_my_age'] as bool? ??
                 json['showMyAge'] as bool? ?? true,
      hideFromDiscovery: json['hide_from_discovery'] as bool? ??
                         json['hideFromDiscovery'] as bool? ?? false,
      incognitoMode: json['incognito_mode'] as bool? ??
                     json['incognitoMode'] as bool? ?? false,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  static ProfilePrivacySettings _parsePrivacySettings(Map<String, dynamic>? json) {
    // ProfilePrivacySettings has its own fromJson factory
    return ProfilePrivacySettings.fromJson(json);
  }

  static Map<String, dynamic> _preferencesToJson(DiscoveryPreferences prefs) {
    return {
      'min_age': prefs.minAge,
      'max_age': prefs.maxAge,
      'max_distance_km': prefs.maxDistanceKm,
      'show_me_genders': prefs.showMeGenders,
      'show_my_distance': prefs.showMyDistance,
      'show_my_age': prefs.showMyAge,
      'hide_from_discovery': prefs.hideFromDiscovery,
      'incognito_mode': prefs.incognitoMode,
      'country': prefs.country,
      'city': prefs.city,
    };
  }

  static Map<String, dynamic> _privacySettingsToJson(ProfilePrivacySettings settings) {
    // ProfilePrivacySettings has its own toJson method
    return settings.toJson();
  }
}
