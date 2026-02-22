import 'dart:convert';

import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile_repository.dart';

/// Mock implementation of ProfileRepository with local storage.
/// This allows the app to function for development/demo without a backend.
class StubProfileRepository implements ProfileRepository {
  static const _usersKey = 'mock_users';
  static const _currentUserKey = 'mock_current_user_id';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<CrushUser?> getCurrentUser() async {
    final userId = await _secureStorage.read(key: _currentUserKey);
    if (userId == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return null;

    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    final userData = users[userId];
    if (userData == null) return null;

    return _userFromJson(userData);
  }

  @override
  Future<CrushUser> saveBasicInfo({
    String? username,
    required String name,
    String? lastName,
    required int age,
    required String gender,
    String? sexualOrientation,
    DateTime? dateOfBirth,
    bool? showFirstName,
    bool? showLastName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Sanitize input data
    final sanitizedName = InputSanitizer.sanitizeName(name);
    final sanitizedLastName = InputSanitizer.sanitizeName(lastName);
    final sanitizedUsername = username != null
        ? InputSanitizer.sanitizeUsername(username)
        : null;
    final sanitizedAge = InputSanitizer.sanitizeAge(age);
    final sanitizedGender = InputSanitizer.sanitizeText(gender, maxLength: 50);
    final sanitizedOrientation = sexualOrientation != null
        ? InputSanitizer.sanitizeText(sexualOrientation, maxLength: 50)
        : null;

    if (sanitizedAge == null) {
      throw Exception('Invalid age');
    }

    // Create or update profile
    final existingProfile = currentUser.profile;
    final existingPrivacy =
        existingProfile?.privacySettings ?? const ProfilePrivacySettings();
    final updatedPrivacy = existingPrivacy.copyWith(
      showFirstName: showFirstName ?? existingPrivacy.showFirstName,
      showLastName: showLastName ?? existingPrivacy.showLastName,
    );

    final newProfile = Profile(
      id: existingProfile?.id ?? 'profile_${currentUser.id}',
      username: username ?? existingProfile?.username ?? currentUser.username,
      name: sanitizedName,
      lastName: sanitizedLastName.isNotEmpty
          ? sanitizedLastName
          : existingProfile?.lastName,
      age: sanitizedAge,
      gender: sanitizedGender,
      sexualOrientation:
          sanitizedOrientation ?? existingProfile?.sexualOrientation,
      dateOfBirth: dateOfBirth ?? existingProfile?.dateOfBirth,
      bio: existingProfile?.bio ?? '',
      photoUrls: existingProfile?.photoUrls ?? [],
      videoUrls: existingProfile?.videoUrls ?? [],
      interests: existingProfile?.interests ?? [],
      profilePrompts: existingProfile?.profilePrompts ?? [],
      country: existingProfile?.country ?? '',
      city: existingProfile?.city ?? '',
      livingIn: existingProfile?.livingIn,
      isVerified: existingProfile?.isVerified ?? false,
      heightCm: existingProfile?.heightCm,
      relationshipGoals: existingProfile?.relationshipGoals,
      languages: existingProfile?.languages ?? [],
      zodiacSign: existingProfile?.zodiacSign,
      educationLevel: existingProfile?.educationLevel,
      familyPlans: existingProfile?.familyPlans,
      personalityType: existingProfile?.personalityType,
      religion: existingProfile?.religion,
      workout: existingProfile?.workout,
      smoking: existingProfile?.smoking,
      drinking: existingProfile?.drinking,
      pets: existingProfile?.pets,
      jobTitle: existingProfile?.jobTitle,
      company: existingProfile?.company,
      school: existingProfile?.school,
      privacySettings: updatedPrivacy,
      preferences:
          existingProfile?.preferences ??
          const DiscoveryPreferences(
            minAge: 18,
            maxAge: 50,
            maxDistanceKm: 100,
            showMeGenders: [
              'male',
              'female',
            ], // Default to show all binary genders
            showMyDistance: true,
            showMyAge: true,
            hideFromDiscovery: false,
            incognitoMode: false,
            country: '',
            city: '',
          ),
    );

    // Handle username changes with 28-day cooldown
    final existingUsername = currentUser.username;
    final usernameChanged =
        sanitizedUsername != null && existingUsername != sanitizedUsername;

    DateTime? newLastUsernameChangeAt = currentUser.lastUsernameChangeAt;
    String? newUsername = sanitizedUsername ?? currentUser.username;

    if (usernameChanged) {
      // Check cooldown - if they had a username before, enforce 28-day wait
      if (existingUsername != null && existingUsername.isNotEmpty) {
        if (!currentUser.canChangeUsername) {
          throw Exception(
            'You can change your username again in ${currentUser.daysUntilUsernameChange} days',
          );
        }
      }
      // Update the change timestamp
      newLastUsernameChangeAt = DateTime.now();
    }

    final updatedUser = currentUser.copyWith(
      username: newUsername,
      lastUsernameChangeAt: newLastUsernameChangeAt,
      profile: newProfile,
    );

    await _saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    List<String>? prompts,
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude,
    double? longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final existingProfile = currentUser.profile;
    if (existingProfile == null) {
      throw Exception('Basic info must be saved first');
    }

    // Sanitize input data
    final sanitizedBio = InputSanitizer.sanitizeBio(bio);
    final sanitizedPhotoUrls = InputSanitizer.sanitizeUrls(photoUrls);
    final sanitizedVideoUrls = InputSanitizer.sanitizeUrls(videoUrls);
    final sanitizedJobTitle = jobTitle != null
        ? InputSanitizer.sanitizeJobField(jobTitle)
        : null;
    final sanitizedCompany = company != null
        ? InputSanitizer.sanitizeJobField(
            company,
            maxLength: InputSanitizer.maxCompanyLength,
          )
        : null;
    final sanitizedSchool = school != null
        ? InputSanitizer.sanitizeText(
            school,
            maxLength: InputSanitizer.maxSchoolLength,
          )
        : null;
    final sanitizedInterests = InputSanitizer.sanitizeInterests(interests);

    // Update preferences with showMeGenders if provided
    final updatedPreferences = showMeGenders != null
        ? existingProfile.preferences.copyWith(showMeGenders: showMeGenders)
        : existingProfile.preferences;

    final newProfile = existingProfile.copyWith(
      bio: sanitizedBio,
      photoUrls: sanitizedPhotoUrls,
      videoUrls: sanitizedVideoUrls,
      jobTitle: sanitizedJobTitle,
      company: sanitizedCompany,
      school: sanitizedSchool,
      interests: sanitizedInterests,
      preferences: updatedPreferences,
      city: city ?? existingProfile.city,
      country: country ?? existingProfile.country,
      latitude: latitude ?? existingProfile.latitude,
      longitude: longitude ?? existingProfile.longitude,
    );

    final updatedUser = currentUser.copyWith(profile: newProfile);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> uploadIdDocument(/* e.g. File or bytes type */) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // In mock mode, we just simulate the upload
    // The actual verification happens in markIdVerified
  }

  @override
  Future<CrushUser> markIdVerified() async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final existingProfile = currentUser.profile;
    if (existingProfile == null) {
      throw Exception('Profile must be created first');
    }

    final newProfile = existingProfile.copyWith(isVerified: true);
    final updatedUser = currentUser.copyWith(
      isIdVerified: true,
      profile: newProfile,
    );

    await _saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final updatedUser = currentUser.copyWith(profile: profile);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> updateThemePreference(String preference) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final updatedUser = currentUser.copyWith(themePreference: preference);
    await _saveUser(updatedUser);
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final sanitizedUsername = InputSanitizer.sanitizeUsername(username);
    if (sanitizedUsername.isEmpty) {
      throw Exception('Username is required');
    }

    // Check if username is changing and enforce cooldown
    final existingUsername = currentUser.username;
    final usernameChanged = existingUsername != sanitizedUsername;

    DateTime? newLastUsernameChangeAt = currentUser.lastUsernameChangeAt;

    if (usernameChanged) {
      if (existingUsername != null && existingUsername.isNotEmpty) {
        if (!currentUser.canChangeUsername) {
          throw Exception(
            'You can change your username again in ${currentUser.daysUntilUsernameChange} days',
          );
        }
      }
      newLastUsernameChangeAt = DateTime.now();
    }

    final updatedUser = currentUser.copyWith(
      username: sanitizedUsername,
      lastUsernameChangeAt: newLastUsernameChangeAt,
      hasSkippedBasicInfo: true,
    );

    await _saveUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    await Future.delayed(const Duration(milliseconds: 50));

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final updatedUser = currentUser.copyWith(hasSkippedProfileSetup: true);

    await _saveUser(updatedUser);
    return updatedUser;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT-RETURNING METHODS (CR-AUD-035)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CrushUser>> saveBasicInfoResult({
    String? username,
    required String name,
    String? lastName,
    required int age,
    required String gender,
    String? sexualOrientation,
    DateTime? dateOfBirth,
    bool? showFirstName,
    bool? showLastName,
  }) async {
    return Result.guard(
      () => saveBasicInfo(
        username: username,
        name: name,
        lastName: lastName,
        age: age,
        gender: gender,
        sexualOrientation: sexualOrientation,
        dateOfBirth: dateOfBirth,
        showFirstName: showFirstName,
        showLastName: showLastName,
      ),
      logLabel: 'StubProfileRepository.saveBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> saveProfileDetailsResult({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
    List<String>? prompts,
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude,
    double? longitude,
  }) async {
    return Result.guard(
      () => saveProfileDetails(
        bio: bio,
        photoUrls: photoUrls,
        videoUrls: videoUrls,
        jobTitle: jobTitle,
        company: company,
        school: school,
        interests: interests,
        prompts: prompts,
        city: city,
        country: country,
        favourites: favourites,
        showMeGenders: showMeGenders,
        latitude: latitude,
        longitude: longitude,
      ),
      logLabel: 'StubProfileRepository.saveProfileDetailsResult',
    );
  }

  @override
  Future<Result<CrushUser>> markIdVerifiedResult() async {
    return Result.guard(
      () => markIdVerified(),
      logLabel: 'StubProfileRepository.markIdVerifiedResult',
    );
  }

  @override
  Future<Result<CrushUser>> updateProfileResult(Profile profile) async {
    return Result.guard(
      () => updateProfile(profile),
      logLabel: 'StubProfileRepository.updateProfileResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipBasicInfoResult({
    required String username,
  }) async {
    return Result.guard(
      () => skipBasicInfo(username: username),
      logLabel: 'StubProfileRepository.skipBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipProfileSetupResult() async {
    return Result.guard(
      () => skipProfileSetup(),
      logLabel: 'StubProfileRepository.skipProfileSetupResult',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveUser(CrushUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final users = usersJson != null
        ? Map<String, dynamic>.from(jsonDecode(usersJson))
        : <String, dynamic>{};

    users[user.id] = _userToJson(user);
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  CrushUser _userFromJson(Map<String, dynamic> json) {
    Profile? profile;
    if (json['profile'] != null) {
      final p = json['profile'] as Map<String, dynamic>;
      profile = Profile(
        id: p['id'] ?? '',
        username: json['username'], // Username is at user level
        name: p['name'] ?? '',
        lastName: p['lastName'],
        age: p['age'] ?? 0,
        gender: p['gender'] ?? '',
        sexualOrientation: p['sexualOrientation'],
        dateOfBirth: p['dateOfBirth'] != null
            ? DateTime.parse(p['dateOfBirth'])
            : null,
        lastDobChangeAt: p['lastDobChangeAt'] != null
            ? DateTime.parse(p['lastDobChangeAt'])
            : null,
        lastNameChangeAt: p['lastNameChangeAt'] != null
            ? DateTime.parse(p['lastNameChangeAt'])
            : null,
        bio: p['bio'] ?? '',
        photoUrls: List<String>.from(p['photoUrls'] ?? []),
        videoUrls: List<String>.from(p['videoUrls'] ?? []),
        primaryPhotoIndex: p['primaryPhotoIndex'] ?? 0,
        interests: List<String>.from(p['interests'] ?? []),
        profilePrompts:
            (p['profilePrompts'] as List<dynamic>?)
                ?.map((e) => ProfilePrompt.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        country: p['country'] ?? '',
        city: p['city'] ?? '',
        livingIn: p['livingIn'],
        isVerified: p['isVerified'] ?? false,
        heightCm: p['heightCm'],
        relationshipGoals: p['relationshipGoals'],
        languages: List<String>.from(p['languages'] ?? []),
        zodiacSign: p['zodiacSign'],
        educationLevel: p['educationLevel'],
        familyPlans: p['familyPlans'],
        personalityType: p['personalityType'],
        religion: p['religion'],
        workout: p['workout'],
        smoking: p['smoking'],
        drinking: p['drinking'],
        pets: p['pets'],
        jobTitle: p['jobTitle'],
        company: p['company'],
        school: p['school'],
        preferences: DiscoveryPreferences(
          minAge: p['preferences']?['minAge'] ?? 18,
          maxAge: p['preferences']?['maxAge'] ?? 50,
          maxDistanceKm: (p['preferences']?['maxDistanceKm'] ?? 100).toDouble(),
          showMeGenders: List<String>.from(
            p['preferences']?['showMeGenders'] ?? ['male', 'female'],
          ),
          showMyDistance: p['preferences']?['showMyDistance'] ?? true,
          showMyAge: p['preferences']?['showMyAge'] ?? true,
          hideFromDiscovery: p['preferences']?['hideFromDiscovery'] ?? false,
          incognitoMode: p['preferences']?['incognitoMode'] ?? false,
          country: p['preferences']?['country'] ?? '',
          city: p['preferences']?['city'] ?? '',
        ),
        privacySettings: ProfilePrivacySettings.fromJson(
          p['privacySettings'] as Map<String, dynamic>?,
        ),
      );
    }

    return CrushUser(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      username: json['username'],
      lastUsernameChangeAt: json['lastUsernameChangeAt'] != null
          ? DateTime.parse(json['lastUsernameChangeAt'])
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isIdVerified: json['isIdVerified'] ?? false,
      plan: json['plan'] == 'plus'
          ? SubscriptionPlan.plus
          : SubscriptionPlan.free,
      themePreference: json['themePreference'] ?? json['theme_preference'],
      profile: profile,
      hasAcceptedTerms: json['hasAcceptedTerms'] ?? false,
      hasSkippedBasicInfo: json['hasSkippedBasicInfo'] ?? false,
      hasSkippedProfileSetup: json['hasSkippedProfileSetup'] ?? false,
    );
  }

  Map<String, dynamic> _userToJson(CrushUser user) {
    Map<String, dynamic>? profileJson;
    if (user.profile != null) {
      final p = user.profile!;
      profileJson = {
        'id': p.id,
        'name': p.name,
        'lastName': p.lastName,
        'age': p.age,
        'gender': p.gender,
        'sexualOrientation': p.sexualOrientation,
        'dateOfBirth': p.dateOfBirth?.toIso8601String(),
        'lastDobChangeAt': p.lastDobChangeAt?.toIso8601String(),
        'lastNameChangeAt': p.lastNameChangeAt?.toIso8601String(),
        'bio': p.bio,
        'photoUrls': p.photoUrls,
        'videoUrls': p.videoUrls,
        'primaryPhotoIndex': p.primaryPhotoIndex,
        'interests': p.interests,
        'profilePrompts': p.profilePrompts.map((e) => e.toJson()).toList(),
        'country': p.country,
        'city': p.city,
        'livingIn': p.livingIn,
        'isVerified': p.isVerified,
        'heightCm': p.heightCm,
        'relationshipGoals': p.relationshipGoals,
        'languages': p.languages,
        'zodiacSign': p.zodiacSign,
        'educationLevel': p.educationLevel,
        'familyPlans': p.familyPlans,
        'personalityType': p.personalityType,
        'religion': p.religion,
        'workout': p.workout,
        'smoking': p.smoking,
        'drinking': p.drinking,
        'pets': p.pets,
        'jobTitle': p.jobTitle,
        'company': p.company,
        'school': p.school,
        'preferences': {
          'minAge': p.preferences.minAge,
          'maxAge': p.preferences.maxAge,
          'maxDistanceKm': p.preferences.maxDistanceKm,
          'showMeGenders': p.preferences.showMeGenders,
          'showMyDistance': p.preferences.showMyDistance,
          'showMyAge': p.preferences.showMyAge,
          'hideFromDiscovery': p.preferences.hideFromDiscovery,
          'incognitoMode': p.preferences.incognitoMode,
          'country': p.preferences.country,
          'city': p.preferences.city,
        },
        'privacySettings': p.privacySettings.toJson(),
      };
    }

    return {
      'id': user.id,
      'phoneNumber': user.phoneNumber,
      'email': user.email,
      'username': user.username,
      'lastUsernameChangeAt': user.lastUsernameChangeAt?.toIso8601String(),
      'isEmailVerified': user.isEmailVerified,
      'isPhoneVerified': user.isPhoneVerified,
      'isIdVerified': user.isIdVerified,
      'plan': user.plan == SubscriptionPlan.plus ? 'plus' : 'free',
      'themePreference': user.themePreference,
      'profile': profileJson,
      'hasAcceptedTerms': user.hasAcceptedTerms,
      'hasSkippedBasicInfo': user.hasSkippedBasicInfo,
      'hasSkippedProfileSetup': user.hasSkippedProfileSetup,
    };
  }
}
