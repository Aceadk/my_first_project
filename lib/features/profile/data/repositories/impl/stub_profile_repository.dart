import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/favourites.dart';
import '../profile_repository.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';

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
      name: sanitizedName,
      lastName: sanitizedLastName.isNotEmpty ? sanitizedLastName : existingProfile?.lastName,
      age: sanitizedAge,
      gender: sanitizedGender,
      sexualOrientation: sanitizedOrientation ?? existingProfile?.sexualOrientation,
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
      preferences: existingProfile?.preferences ?? const DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 100,
        showMeGenders: ['All'],
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      ),
    );

    final updatedUser = currentUser.copyWith(
      username: sanitizedUsername ?? currentUser.username,
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
        ? InputSanitizer.sanitizeJobField(company, maxLength: InputSanitizer.maxCompanyLength)
        : null;
    final sanitizedSchool = school != null
        ? InputSanitizer.sanitizeText(school, maxLength: InputSanitizer.maxSchoolLength)
        : null;
    final sanitizedInterests = InputSanitizer.sanitizeInterests(interests);

    final newProfile = existingProfile.copyWith(
      bio: sanitizedBio,
      photoUrls: sanitizedPhotoUrls,
      videoUrls: sanitizedVideoUrls,
      jobTitle: sanitizedJobTitle,
      company: sanitizedCompany,
      school: sanitizedSchool,
      interests: sanitizedInterests,
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

    final updatedUser = currentUser.copyWith(
      username: sanitizedUsername,
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

    final updatedUser = currentUser.copyWith(
      hasSkippedProfileSetup: true,
    );

    await _saveUser(updatedUser);
    return updatedUser;
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
        profilePrompts: (p['profilePrompts'] as List<dynamic>?)
            ?.map((e) => ProfilePrompt.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
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
          showMeGenders: List<String>.from(p['preferences']?['showMeGenders'] ?? ['All']),
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
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isIdVerified: json['isIdVerified'] ?? false,
      plan: json['plan'] == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free,
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
      'isEmailVerified': user.isEmailVerified,
      'isPhoneVerified': user.isPhoneVerified,
      'isIdVerified': user.isIdVerified,
      'plan': user.plan == SubscriptionPlan.plus ? 'plus' : 'free',
      'profile': profileJson,
      'hasAcceptedTerms': user.hasAcceptedTerms,
      'hasSkippedBasicInfo': user.hasSkippedBasicInfo,
      'hasSkippedProfileSetup': user.hasSkippedProfileSetup,
    };
  }
}
