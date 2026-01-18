import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/favourites.dart';
import '../profile_repository.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/app_logger.dart';

/// Firebase implementation of ProfileRepository.
class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Future<CrushUser?> getCurrentUser() async {
    AppLogger.logInfo('[FirebaseProfileRepo] getCurrentUser() called');

    final userId = _currentUserId;
    AppLogger.logInfo('[FirebaseProfileRepo] Current Firebase Auth userId: $userId');

    if (userId == null) {
      AppLogger.logInfo('[FirebaseProfileRepo] No authenticated user - returning null');
      return null;
    }

    AppLogger.logInfo('[FirebaseProfileRepo] Fetching Firestore doc: users/$userId');
    final doc = await _firestore.collection('users').doc(userId).get();

    AppLogger.logInfo('[FirebaseProfileRepo] Doc exists: ${doc.exists}');

    if (!doc.exists) {
      AppLogger.logInfo('[FirebaseProfileRepo] User document does not exist in Firestore - creating minimal profile from auth data');
      // User is authenticated but has no Firestore document yet
      // Return a CrushUser with a minimal profile from auth data so they can see their profile screen
      final firebaseUser = _auth.currentUser!;
      final displayName = firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User';

      return CrushUser(
        id: userId,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email,
        username: firebaseUser.displayName,
        isEmailVerified: firebaseUser.emailVerified,
        isPhoneVerified: firebaseUser.phoneNumber != null,
        isIdVerified: false,
        plan: SubscriptionPlan.free,
        profile: Profile(
          id: userId,
          name: displayName,
          age: 0, // Will prompt user to complete
          gender: '',
          bio: '',
          photoUrls: const [],
          videoUrls: const [],
          primaryPhotoIndex: 0,
          interests: const [],
          country: '',
          city: '',
          isVerified: false,
          languages: const [],
          preferences: const DiscoveryPreferences(
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
          privacySettings: const ProfilePrivacySettings(),
        ),
      );
    }

    final data = doc.data()!;
    AppLogger.logInfo('[FirebaseProfileRepo] Doc data keys: ${data.keys.toList()}');
    AppLogger.logInfo('[FirebaseProfileRepo] Has profile field: ${data.containsKey('profile')}');

    if (data.containsKey('profile')) {
      final profileData = data['profile'];
      AppLogger.logInfo('[FirebaseProfileRepo] Profile data type: ${profileData.runtimeType}');
      if (profileData is Map) {
        AppLogger.logInfo('[FirebaseProfileRepo] Profile keys: ${profileData.keys.toList()}');
        AppLogger.logInfo('[FirebaseProfileRepo] Profile name: ${profileData['name']}, age: ${profileData['age']}');
      }
    }

    final user = _userFromFirestore(userId, data);
    AppLogger.logInfo('[FirebaseProfileRepo] Parsed user: id=${user.id}, hasProfile=${user.profile != null}');

    return user;
  }

  @override
  Future<CrushUser> saveBasicInfo({
    String? username,
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
    DateTime? dateOfBirth,
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

    // Use dot notation to update nested fields without overwriting existing profile data
    final updateData = <String, dynamic>{
      'profile.name': sanitizedName,
      'profile.age': sanitizedAge,
      'profile.gender': sanitizedGender,
      'profile.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add optional fields
    if (sanitizedOrientation != null) {
      updateData['profile.sexualOrientation'] = sanitizedOrientation;
    }
    if (dateOfBirth != null) {
      updateData['profile.dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    }
    if (sanitizedUsername != null) {
      updateData['username'] = sanitizedUsername;
    }

    // Check if document exists first - use set with merge for new users
    final docRef = _firestore.collection('users').doc(userId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update(updateData);
    } else {
      // For new users, create the document with nested structure
      await docRef.set({
        'profile': {
          'name': sanitizedName,
          'age': sanitizedAge,
          'gender': sanitizedGender,
          if (sanitizedOrientation != null)
            'sexualOrientation': sanitizedOrientation,
          if (dateOfBirth != null)
            'dateOfBirth': Timestamp.fromDate(dateOfBirth),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        if (sanitizedUsername != null) 'username': sanitizedUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

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
    String? city,
    String? country,
    ProfileFavourites? favourites,
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
    final sanitizedCity = city != null
        ? InputSanitizer.sanitizeText(city, maxLength: 100)
        : null;
    final sanitizedCountry = country != null
        ? InputSanitizer.sanitizeText(country, maxLength: 100)
        : null;

    // Use dot notation to update nested fields without overwriting existing profile data
    // This preserves name, age, gender from basic info while adding profile details
    final updateData = <String, dynamic>{
      'profile.bio': sanitizedBio,
      'profile.photoUrls': sanitizedPhotoUrls,
      'profile.videoUrls': sanitizedVideoUrls,
      'profile.interests': sanitizedInterests,
      'profile.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add optional fields with dot notation
    if (sanitizedJobTitle != null) updateData['profile.jobTitle'] = sanitizedJobTitle;
    if (sanitizedCompany != null) updateData['profile.company'] = sanitizedCompany;
    if (sanitizedSchool != null) updateData['profile.school'] = sanitizedSchool;
    if (prompts != null) updateData['profile.prompts'] = prompts;
    if (sanitizedCity != null) updateData['profile.city'] = sanitizedCity;
    if (sanitizedCountry != null) updateData['profile.country'] = sanitizedCountry;
    if (favourites != null) updateData['profile.favourites'] = favourites.toJson();

    final docRef = _firestore.collection('users').doc(userId);

    try {
      final docSnapshot = await docRef.get();
      AppLogger.logInfo('[FirebaseProfileRepo] saveProfileDetails: docExists=${docSnapshot.exists}, userId=$userId');
      AppLogger.logInfo('[FirebaseProfileRepo] saveProfileDetails: photoUrls=${sanitizedPhotoUrls.length}, city=$sanitizedCity, country=$sanitizedCountry');

      if (docSnapshot.exists) {
        AppLogger.logInfo('[FirebaseProfileRepo] Updating existing document with dot notation');
        await docRef.update(updateData);
        AppLogger.logInfo('[FirebaseProfileRepo] Update successful');
      } else {
        // Fallback: create document if it doesn't exist (shouldn't happen in normal flow)
        AppLogger.logInfo('[FirebaseProfileRepo] Document does not exist, creating with set()');
        await docRef.set({
          'profile': {
            'bio': sanitizedBio,
            'photoUrls': sanitizedPhotoUrls,
            'videoUrls': sanitizedVideoUrls,
            'interests': sanitizedInterests,
            if (sanitizedJobTitle != null) 'jobTitle': sanitizedJobTitle,
            if (sanitizedCompany != null) 'company': sanitizedCompany,
            if (sanitizedSchool != null) 'school': sanitizedSchool,
            if (prompts != null) 'prompts': prompts,
            if (sanitizedCity != null) 'city': sanitizedCity,
            if (sanitizedCountry != null) 'country': sanitizedCountry,
            if (favourites != null) 'favourites': favourites.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        AppLogger.logInfo('[FirebaseProfileRepo] Set successful');
      }
    } catch (e, stackTrace) {
      AppLogger.logError('[FirebaseProfileRepo] saveProfileDetails FAILED', e);
      AppLogger.logInfo('[FirebaseProfileRepo] Stack trace: $stackTrace');
      rethrow;
    }

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

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final sanitizedUsername = InputSanitizer.sanitizeUsername(username);
    if (sanitizedUsername.isEmpty) {
      throw Exception('Username is required');
    }

    final docRef = _firestore.collection('users').doc(userId);

    await docRef.set({
      'username': sanitizedUsername,
      'hasSkippedBasicInfo': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppLogger.logInfo('[FirebaseProfileRepo] skipBasicInfo: username=$sanitizedUsername');

    return (await getCurrentUser())!;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final docRef = _firestore.collection('users').doc(userId);

    await docRef.set({
      'hasSkippedProfileSetup': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppLogger.logInfo('[FirebaseProfileRepo] skipProfileSetup');

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
        profilePrompts: _parseProfilePrompts(profileData['profilePrompts']),
        country: profileData['country'] ?? '',
        city: profileData['city'] ?? '',
        latitude: (profileData['latitude'] as num?)?.toDouble(),
        longitude: (profileData['longitude'] as num?)?.toDouble(),
        livingIn: profileData['livingIn'],
        isVerified: profileData['isVerified'] ?? false,
        heightCm: profileData['heightCm'],
        relationshipGoals: profileData['relationshipGoals'],
        languages: List<String>.from(profileData['languages'] ?? []),
        zodiacSign: profileData['zodiacSign'],
        educationLevel: profileData['educationLevel'],
        familyPlans: profileData['familyPlans'],
        personalityType: profileData['personalityType'],
        religion: profileData['religion'],
        workout: profileData['workout'],
        socialMedia: profileData['socialMedia'],
        sleepingHabits: profileData['sleepingHabits'],
        smoking: profileData['smoking'],
        drinking: profileData['drinking'],
        pets: profileData['pets'],
        favoriteSongs: List<String>.from(profileData['favoriteSongs'] ?? []),
        favoriteSinger: profileData['favoriteSinger'],
        jobTitle: profileData['jobTitle'],
        company: profileData['company'],
        school: profileData['school'],
        preferences: _preferencesFromFirestore(profileData['preferences']),
        privacySettings: ProfilePrivacySettings.fromJson(
          profileData['privacySettings'] as Map<String, dynamic>?,
        ),
        favourites: profileData['favourites'] != null
            ? ProfileFavourites.fromJson(
                profileData['favourites'] as Map<String, dynamic>)
            : const ProfileFavourites(),
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
      hasAcceptedTerms: data['hasAcceptedTerms'] ?? false,
      hasSkippedBasicInfo: data['hasSkippedBasicInfo'] ?? false,
      hasSkippedProfileSetup: data['hasSkippedProfileSetup'] ?? false,
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
      'lastDobChangeAt': p.lastDobChangeAt,
      'lastNameChangeAt': p.lastNameChangeAt,
      'bio': p.bio,
      'photoUrls': p.photoUrls,
      'videoUrls': p.videoUrls,
      'primaryPhotoIndex': p.primaryPhotoIndex,
      'interests': p.interests,
      'profilePrompts': p.profilePrompts.map((prompt) => prompt.toJson()).toList(),
      'country': p.country,
      'city': p.city,
      'latitude': p.latitude,
      'longitude': p.longitude,
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
      'socialMedia': p.socialMedia,
      'sleepingHabits': p.sleepingHabits,
      'smoking': p.smoking,
      'drinking': p.drinking,
      'pets': p.pets,
      'favoriteSongs': p.favoriteSongs,
      'favoriteSinger': p.favoriteSinger,
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
      'favourites': p.favourites.toJson(),
    };
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<ProfilePrompt> _parseProfilePrompts(dynamic value) {
    if (value == null) return const [];
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return ProfilePrompt.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<ProfilePrompt>()
        .toList();
  }
}
