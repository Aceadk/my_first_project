import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import '../profile_repository.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';

/// Firebase implementation of ProfileRepository.
class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Future<CrushUser?> getCurrentUser() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    return _userFromFirestore(userId, doc.data()!);
  }

  @override
  Future<CrushUser> saveBasicInfo({
    String? username,
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    // Sanitize input
    final sanitizedName = InputSanitizer.sanitizeName(name);
    final sanitizedUsername =
        username != null ? InputSanitizer.sanitizeUsername(username) : null;
    final sanitizedAge = InputSanitizer.sanitizeAge(age);
    final sanitizedGender = InputSanitizer.sanitizeText(gender, maxLength: 50);
    final sanitizedOrientation = sexualOrientation != null
        ? InputSanitizer.sanitizeText(sexualOrientation, maxLength: 50)
        : null;

    if (sanitizedAge == null) throw Exception('Invalid age');

    final profileData = <String, dynamic>{
      'name': sanitizedName,
      'age': sanitizedAge,
      'gender': sanitizedGender,
      if (sanitizedOrientation != null)
        'sexualOrientation': sanitizedOrientation,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final userData = <String, dynamic>{
      'profile': profileData,
      if (sanitizedUsername != null) 'username': sanitizedUsername,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(userId).set(
          userData,
          SetOptions(merge: true),
        );

    return (await getCurrentUser())!;
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
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    // Sanitize input
    final sanitizedBio = InputSanitizer.sanitizeBio(bio);
    final sanitizedPhotoUrls = InputSanitizer.sanitizeUrls(photoUrls);
    final sanitizedVideoUrls = InputSanitizer.sanitizeUrls(videoUrls);
    final sanitizedJobTitle =
        jobTitle != null ? InputSanitizer.sanitizeJobField(jobTitle) : null;
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

    final profileData = <String, dynamic>{
      'bio': sanitizedBio,
      'photoUrls': sanitizedPhotoUrls,
      'videoUrls': sanitizedVideoUrls,
      'interests': sanitizedInterests,
      if (sanitizedJobTitle != null) 'jobTitle': sanitizedJobTitle,
      if (sanitizedCompany != null) 'company': sanitizedCompany,
      if (sanitizedSchool != null) 'school': sanitizedSchool,
      if (prompts != null) 'prompts': prompts,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(userId).set(
          {'profile': profileData},
          SetOptions(merge: true),
        );

    return (await getCurrentUser())!;
  }

  @override
  Future<void> uploadIdDocument(/* e.g. File or bytes type */) async {
    // ID verification is typically handled server-side
    // This would upload to Firebase Storage and trigger verification
  }

  @override
  Future<CrushUser> markIdVerified() async {
    // Note: isIdVerified should only be set by the server after verification
    // This is a client-side stub - actual verification happens server-side
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    return (await getCurrentUser())!;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final profileData = _profileToFirestore(profile);

    await _firestore.collection('users').doc(userId).set(
          {'profile': profileData, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );

    return (await getCurrentUser())!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  CrushUser _userFromFirestore(String id, Map<String, dynamic> data) {
    Profile? profile;
    final profileData = data['profile'] as Map<String, dynamic>?;

    if (profileData != null) {
      profile = Profile(
        id: id,
        name: profileData['name'] ?? '',
        age: profileData['age'] ?? 0,
        gender: profileData['gender'] ?? '',
        sexualOrientation: profileData['sexualOrientation'],
        dateOfBirth: _parseTimestamp(profileData['dateOfBirth']),
        lastDobChangeAt: _parseTimestamp(profileData['lastDobChangeAt']),
        lastNameChangeAt: _parseTimestamp(profileData['lastNameChangeAt']),
        bio: profileData['bio'] ?? '',
        photoUrls: List<String>.from(profileData['photoUrls'] ?? []),
        videoUrls: List<String>.from(profileData['videoUrls'] ?? []),
        primaryPhotoIndex: profileData['primaryPhotoIndex'] ?? 0,
        interests: List<String>.from(profileData['interests'] ?? []),
        country: profileData['country'] ?? '',
        city: profileData['city'] ?? '',
        isVerified: profileData['isVerified'] ?? false,
        heightCm: profileData['heightCm'],
        relationshipGoals: profileData['relationshipGoals'],
        languages: List<String>.from(profileData['languages'] ?? []),
        zodiacSign: profileData['zodiacSign'],
        educationLevel: profileData['educationLevel'],
        familyPlans: profileData['familyPlans'],
        personalityType: profileData['personalityType'],
        workout: profileData['workout'],
        smoking: profileData['smoking'],
        drinking: profileData['drinking'],
        pets: profileData['pets'],
        jobTitle: profileData['jobTitle'],
        company: profileData['company'],
        school: profileData['school'],
        preferences: _preferencesFromFirestore(profileData['preferences']),
        privacySettings: ProfilePrivacySettings.fromJson(
          profileData['privacySettings'] as Map<String, dynamic>?,
        ),
      );
    }

    return CrushUser(
      id: id,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      username: data['username'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isIdVerified: data['isIdVerified'] ?? false,
      plan: data['plan'] == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free,
      profile: profile,
    );
  }

  DiscoveryPreferences _preferencesFromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return const DiscoveryPreferences(
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
      );
    }

    return DiscoveryPreferences(
      minAge: data['minAge'] ?? 18,
      maxAge: data['maxAge'] ?? 50,
      maxDistanceKm: (data['maxDistanceKm'] ?? 100).toDouble(),
      showMeGenders: List<String>.from(data['showMeGenders'] ?? ['All']),
      showMyDistance: data['showMyDistance'] ?? true,
      showMyAge: data['showMyAge'] ?? true,
      hideFromDiscovery: data['hideFromDiscovery'] ?? false,
      incognitoMode: data['incognitoMode'] ?? false,
      country: data['country'] ?? '',
      city: data['city'] ?? '',
    );
  }

  Map<String, dynamic> _profileToFirestore(Profile p) {
    return {
      'name': p.name,
      'age': p.age,
      'gender': p.gender,
      'sexualOrientation': p.sexualOrientation,
      'dateOfBirth': p.dateOfBirth,
      'bio': p.bio,
      'photoUrls': p.photoUrls,
      'videoUrls': p.videoUrls,
      'primaryPhotoIndex': p.primaryPhotoIndex,
      'interests': p.interests,
      'country': p.country,
      'city': p.city,
      'isVerified': p.isVerified,
      'heightCm': p.heightCm,
      'relationshipGoals': p.relationshipGoals,
      'languages': p.languages,
      'zodiacSign': p.zodiacSign,
      'educationLevel': p.educationLevel,
      'familyPlans': p.familyPlans,
      'personalityType': p.personalityType,
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

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
