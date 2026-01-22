import 'package:equatable/equatable.dart';

/// Privacy settings that control what information is visible to other users.
/// By default, most fields are public (true), but sensitive fields are private (false).
class ProfilePrivacySettings extends Equatable {
  // Sensitive fields - private by default
  final bool showFirstName;
  final bool showLastName;
  final bool showAge;
  final bool showDateOfBirth;
  final bool showEmail;
  final bool showPhoneNumber;
  final bool showExactLocation;

  // Personal details - user's choice
  final bool showHeight;
  final bool showZodiacSign;
  final bool showEducation;
  final bool showFamilyPlans;
  final bool showPersonality;
  final bool showReligion;
  final bool showRelationshipGoals;

  // Lifestyle - user's choice
  final bool showWorkout;
  final bool showSmoking;
  final bool showDrinking;
  final bool showDiet;
  final bool showSleepingHabits;
  final bool showPets;

  // Work & Education - user's choice
  final bool showJobTitle;
  final bool showCompany;
  final bool showSchool;

  // Music preferences
  final bool showFavoriteSongs;
  final bool showFavoriteSinger;

  // Social
  final bool showSocialMedia;
  final bool showLanguages;

  // Online status
  final bool showOnlineStatus;
  final bool showLastActive;

  const ProfilePrivacySettings({
    // Sensitive - private by default
    this.showFirstName = false, // Real name privacy
    this.showLastName = false, // Last name is sensitive
    this.showAge = true, // Age is usually shown on dating apps
    this.showDateOfBirth = false, // Exact DOB is sensitive
    this.showEmail = false, // Email is sensitive
    this.showPhoneNumber = false, // Phone is very sensitive
    this.showExactLocation = false, // Only show city, not exact

    // Personal details - public by default
    this.showHeight = true,
    this.showZodiacSign = true,
    this.showEducation = true,
    this.showFamilyPlans = true,
    this.showPersonality = true,
    this.showReligion = true,
    this.showRelationshipGoals = true,

    // Lifestyle - public by default
    this.showWorkout = true,
    this.showSmoking = true,
    this.showDrinking = true,
    this.showDiet = true,
    this.showSleepingHabits = true,
    this.showPets = true,

    // Work - public by default
    this.showJobTitle = true,
    this.showCompany = true,
    this.showSchool = true,

    // Music - public by default
    this.showFavoriteSongs = true,
    this.showFavoriteSinger = true,

    // Social - public by default
    this.showSocialMedia = true,
    this.showLanguages = true,

    // Online status - private by default
    this.showOnlineStatus = false,
    this.showLastActive = false,
  });

  /// Create settings where everything is public
  factory ProfilePrivacySettings.allPublic() {
    return const ProfilePrivacySettings(
      showFirstName: true,
      showLastName: true,
      showAge: true,
      showDateOfBirth: true,
      showEmail: true,
      showPhoneNumber: true,
      showExactLocation: true,
      showHeight: true,
      showZodiacSign: true,
      showEducation: true,
      showFamilyPlans: true,
      showPersonality: true,
      showReligion: true,
      showRelationshipGoals: true,
      showWorkout: true,
      showSmoking: true,
      showDrinking: true,
      showDiet: true,
      showSleepingHabits: true,
      showPets: true,
      showJobTitle: true,
      showCompany: true,
      showSchool: true,
      showFavoriteSongs: true,
      showFavoriteSinger: true,
      showSocialMedia: true,
      showLanguages: true,
      showOnlineStatus: true,
      showLastActive: true,
    );
  }

  /// Create settings where everything is private
  factory ProfilePrivacySettings.allPrivate() {
    return const ProfilePrivacySettings(
      showFirstName: false,
      showLastName: false,
      showAge: false,
      showDateOfBirth: false,
      showEmail: false,
      showPhoneNumber: false,
      showExactLocation: false,
      showHeight: false,
      showZodiacSign: false,
      showEducation: false,
      showFamilyPlans: false,
      showPersonality: false,
      showReligion: false,
      showRelationshipGoals: false,
      showWorkout: false,
      showSmoking: false,
      showDrinking: false,
      showDiet: false,
      showSleepingHabits: false,
      showPets: false,
      showJobTitle: false,
      showCompany: false,
      showSchool: false,
      showFavoriteSongs: false,
      showFavoriteSinger: false,
      showSocialMedia: false,
      showLanguages: false,
      showOnlineStatus: false,
      showLastActive: false,
    );
  }

  ProfilePrivacySettings copyWith({
    bool? showFirstName,
    bool? showLastName,
    bool? showAge,
    bool? showDateOfBirth,
    bool? showEmail,
    bool? showPhoneNumber,
    bool? showExactLocation,
    bool? showHeight,
    bool? showZodiacSign,
    bool? showEducation,
    bool? showFamilyPlans,
    bool? showPersonality,
    bool? showReligion,
    bool? showRelationshipGoals,
    bool? showWorkout,
    bool? showSmoking,
    bool? showDrinking,
    bool? showDiet,
    bool? showSleepingHabits,
    bool? showPets,
    bool? showJobTitle,
    bool? showCompany,
    bool? showSchool,
    bool? showFavoriteSongs,
    bool? showFavoriteSinger,
    bool? showSocialMedia,
    bool? showLanguages,
    bool? showOnlineStatus,
    bool? showLastActive,
  }) {
    return ProfilePrivacySettings(
      showFirstName: showFirstName ?? this.showFirstName,
      showLastName: showLastName ?? this.showLastName,
      showAge: showAge ?? this.showAge,
      showDateOfBirth: showDateOfBirth ?? this.showDateOfBirth,
      showEmail: showEmail ?? this.showEmail,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showExactLocation: showExactLocation ?? this.showExactLocation,
      showHeight: showHeight ?? this.showHeight,
      showZodiacSign: showZodiacSign ?? this.showZodiacSign,
      showEducation: showEducation ?? this.showEducation,
      showFamilyPlans: showFamilyPlans ?? this.showFamilyPlans,
      showPersonality: showPersonality ?? this.showPersonality,
      showReligion: showReligion ?? this.showReligion,
      showRelationshipGoals: showRelationshipGoals ?? this.showRelationshipGoals,
      showWorkout: showWorkout ?? this.showWorkout,
      showSmoking: showSmoking ?? this.showSmoking,
      showDrinking: showDrinking ?? this.showDrinking,
      showDiet: showDiet ?? this.showDiet,
      showSleepingHabits: showSleepingHabits ?? this.showSleepingHabits,
      showPets: showPets ?? this.showPets,
      showJobTitle: showJobTitle ?? this.showJobTitle,
      showCompany: showCompany ?? this.showCompany,
      showSchool: showSchool ?? this.showSchool,
      showFavoriteSongs: showFavoriteSongs ?? this.showFavoriteSongs,
      showFavoriteSinger: showFavoriteSinger ?? this.showFavoriteSinger,
      showSocialMedia: showSocialMedia ?? this.showSocialMedia,
      showLanguages: showLanguages ?? this.showLanguages,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastActive: showLastActive ?? this.showLastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showFirstName': showFirstName,
      'showLastName': showLastName,
      'showAge': showAge,
      'showDateOfBirth': showDateOfBirth,
      'showEmail': showEmail,
      'showPhoneNumber': showPhoneNumber,
      'showExactLocation': showExactLocation,
      'showHeight': showHeight,
      'showZodiacSign': showZodiacSign,
      'showEducation': showEducation,
      'showFamilyPlans': showFamilyPlans,
      'showPersonality': showPersonality,
      'showReligion': showReligion,
      'showRelationshipGoals': showRelationshipGoals,
      'showWorkout': showWorkout,
      'showSmoking': showSmoking,
      'showDrinking': showDrinking,
      'showDiet': showDiet,
      'showSleepingHabits': showSleepingHabits,
      'showPets': showPets,
      'showJobTitle': showJobTitle,
      'showCompany': showCompany,
      'showSchool': showSchool,
      'showFavoriteSongs': showFavoriteSongs,
      'showFavoriteSinger': showFavoriteSinger,
      'showSocialMedia': showSocialMedia,
      'showLanguages': showLanguages,
      'showOnlineStatus': showOnlineStatus,
      'showLastActive': showLastActive,
    };
  }

  factory ProfilePrivacySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProfilePrivacySettings();
    return ProfilePrivacySettings(
      showFirstName: json['showFirstName'] ?? false,
      showLastName: json['showLastName'] ?? false,
      showAge: json['showAge'] ?? true,
      showDateOfBirth: json['showDateOfBirth'] ?? false,
      showEmail: json['showEmail'] ?? false,
      showPhoneNumber: json['showPhoneNumber'] ?? false,
      showExactLocation: json['showExactLocation'] ?? false,
      showHeight: json['showHeight'] ?? true,
      showZodiacSign: json['showZodiacSign'] ?? true,
      showEducation: json['showEducation'] ?? true,
      showFamilyPlans: json['showFamilyPlans'] ?? true,
      showPersonality: json['showPersonality'] ?? true,
      showReligion: json['showReligion'] ?? true,
      showRelationshipGoals: json['showRelationshipGoals'] ?? true,
      showWorkout: json['showWorkout'] ?? true,
      showSmoking: json['showSmoking'] ?? true,
      showDrinking: json['showDrinking'] ?? true,
      showDiet: json['showDiet'] ?? true,
      showSleepingHabits: json['showSleepingHabits'] ?? true,
      showPets: json['showPets'] ?? true,
      showJobTitle: json['showJobTitle'] ?? true,
      showCompany: json['showCompany'] ?? true,
      showSchool: json['showSchool'] ?? true,
      showFavoriteSongs: json['showFavoriteSongs'] ?? true,
      showFavoriteSinger: json['showFavoriteSinger'] ?? true,
      showSocialMedia: json['showSocialMedia'] ?? true,
      showLanguages: json['showLanguages'] ?? true,
      showOnlineStatus: json['showOnlineStatus'] ?? false,
      showLastActive: json['showLastActive'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    showFirstName,
    showLastName,
    showAge,
    showDateOfBirth,
    showEmail,
    showPhoneNumber,
    showExactLocation,
    showHeight,
    showZodiacSign,
    showEducation,
    showFamilyPlans,
    showPersonality,
    showReligion,
    showRelationshipGoals,
    showWorkout,
    showSmoking,
    showDrinking,
    showDiet,
    showSleepingHabits,
    showPets,
    showJobTitle,
    showCompany,
    showSchool,
    showFavoriteSongs,
    showFavoriteSinger,
    showSocialMedia,
    showLanguages,
    showOnlineStatus,
    showLastActive,
  ];
}
