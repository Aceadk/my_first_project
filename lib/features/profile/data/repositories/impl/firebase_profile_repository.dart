import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile_repository.dart';
import 'profile_prompt_migration.dart';

/// Firebase implementation of ProfileRepository.
class FirebaseProfileRepository
    implements ProfileRepository, UsernameAvailabilityProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  int _calculateAgeFromDate(DateTime dateOfBirth) {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    final hasNotHadBirthdayThisYear =
        now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day);
    if (hasNotHadBirthdayThisYear) {
      age--;
    }
    return age.clamp(18, 120);
  }

  @override
  Future<bool> isUsernameAvailable({
    required String username,
    String? excludingUserId,
  }) async {
    final sanitizedUsername = InputSanitizer.sanitizeUsername(username);
    if (sanitizedUsername.isEmpty) return false;

    final excludedUserId = excludingUserId ?? _currentUserId;
    final usersCollection = _firestore.collection('users');

    // Primary lookup against normalized field.
    final normalizedSnapshot = await usersCollection
        .where('usernameLower', isEqualTo: sanitizedUsername)
        .limit(5)
        .get();
    final normalizedTaken = normalizedSnapshot.docs.any(
      (doc) => doc.id != excludedUserId,
    );
    if (normalizedTaken) return false;

    // Fallback for older docs that may only have `username`.
    final legacySnapshot = await usersCollection
        .where('username', isEqualTo: sanitizedUsername)
        .limit(5)
        .get();
    final legacyTaken = legacySnapshot.docs.any(
      (doc) => doc.id != excludedUserId,
    );
    return !legacyTaken;
  }

  @override
  Future<CrushUser?> getCurrentUser() async {
    AppLogger.info('[FirebaseProfileRepo] getCurrentUser() called');

    final userId = _currentUserId;
    AppLogger.info(
      '[FirebaseProfileRepo] Current Firebase Auth userId: $userId',
    );

    if (userId == null) {
      AppLogger.info(
        '[FirebaseProfileRepo] No authenticated user - returning null',
      );
      return null;
    }

    AppLogger.info(
      '[FirebaseProfileRepo] Fetching Firestore doc: users/$userId',
    );
    final doc = await _firestore.collection('users').doc(userId).get();

    AppLogger.info('[FirebaseProfileRepo] Doc exists: ${doc.exists}');

    if (!doc.exists) {
      AppLogger.info(
        '[FirebaseProfileRepo] User document does not exist in Firestore - creating minimal profile from auth data',
      );
      // User is authenticated but has no Firestore document yet
      // Return a CrushUser with a minimal profile from auth data so they can see their profile screen
      final firebaseUser = _auth.currentUser!;
      final displayName =
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User';

      return CrushUser(
        id: userId,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email,
        username: firebaseUser.displayName,
        isEmailVerified: firebaseUser.emailVerified,
        isPhoneVerified: firebaseUser.phoneNumber != null,
        isIdVerified: false,
        tier: SubscriptionTier.free,
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
          privacySettings: const ProfilePrivacySettings(),
        ),
      );
    }

    final data = doc.data()!;
    AppLogger.info(
      '[FirebaseProfileRepo] Doc data keys: ${data.keys.toList()}',
    );
    AppLogger.info(
      '[FirebaseProfileRepo] Has profile field: ${data.containsKey('profile')}',
    );

    if (data.containsKey('profile')) {
      final profileData = data['profile'];
      AppLogger.info(
        '[FirebaseProfileRepo] Profile data type: ${profileData.runtimeType}',
      );
      if (profileData is Map) {
        AppLogger.info(
          '[FirebaseProfileRepo] Profile keys: ${profileData.keys.toList()}',
        );
        AppLogger.info(
          '[FirebaseProfileRepo] Profile name: ${profileData['name']}, age: ${profileData['age']}',
        );
      }
    }

    final user = _userFromFirestore(userId, data);
    AppLogger.info(
      '[FirebaseProfileRepo] Parsed user: id=${user.id}, hasProfile=${user.profile != null}',
    );

    return user;
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
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    // Sanitize input
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

    if (sanitizedAge == null) throw Exception('Invalid age');

    final existingUser = await getCurrentUser();
    final existingPrivacy =
        existingUser?.profile?.privacySettings ??
        const ProfilePrivacySettings();
    final updatedPrivacy = existingPrivacy.copyWith(
      showFirstName: showFirstName ?? existingPrivacy.showFirstName,
      showLastName: showLastName ?? existingPrivacy.showLastName,
    );

    // Build the profile data to save
    final profileData = <String, dynamic>{
      'name': sanitizedName,
      'age': sanitizedAge,
      'gender': sanitizedGender,
      'privacySettings': updatedPrivacy.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (sanitizedLastName.isNotEmpty) {
      profileData['lastName'] = sanitizedLastName;
    }

    // Add optional fields
    if (sanitizedOrientation != null) {
      profileData['sexualOrientation'] = sanitizedOrientation;
    }
    if (dateOfBirth != null) {
      profileData['birthDate'] = Timestamp.fromDate(dateOfBirth);
      profileData['age'] = _calculateAgeFromDate(dateOfBirth);
    }

    // Build the document data
    final docData = <String, dynamic>{
      'profile': profileData,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Handle username changes with 28-day cooldown
    if (sanitizedUsername != null) {
      final existingUsername = existingUser?.username;
      final usernameChanged = existingUsername != sanitizedUsername;

      if (usernameChanged) {
        // Check cooldown - if they had a username before, enforce 28-day wait
        if (existingUsername != null && existingUsername.isNotEmpty) {
          if (!existingUser!.canChangeUsername) {
            throw Exception(
              'You can change your username again in ${existingUser.daysUntilUsernameChange} days',
            );
          }
        }
        // Set the new username and update the change timestamp
        docData['username'] = sanitizedUsername;
        docData['usernameLower'] = sanitizedUsername;
        docData['lastUsernameChangeAt'] = FieldValue.serverTimestamp();
        AppLogger.info(
          '[FirebaseProfileRepo] saveBasicInfo: Username changed from "$existingUsername" to "$sanitizedUsername"',
        );
      } else {
        // Username unchanged, just include it without updating timestamp
        docData['username'] = sanitizedUsername;
        docData['usernameLower'] = sanitizedUsername;
      }
    }

    // Always use set with merge to ensure nested structure is created properly
    final docRef = _firestore.collection('users').doc(userId);
    AppLogger.info(
      '[FirebaseProfileRepo] saveBasicInfo: Saving to users/$userId with profile data: $profileData',
    );
    await docRef.set(docData, SetOptions(merge: true));
    AppLogger.info(
      '[FirebaseProfileRepo] saveBasicInfo: Firestore write completed, now fetching user',
    );

    final user = await getCurrentUser();
    AppLogger.info(
      '[FirebaseProfileRepo] saveBasicInfo: getCurrentUser returned user=${user != null}, profile=${user?.profile != null}',
    );
    if (user?.profile != null) {
      AppLogger.info(
        '[FirebaseProfileRepo] saveBasicInfo: profile firstName=${user!.profile!.name}, lastName=${user.profile!.lastName}, age=${user.profile!.age}, gender=${user.profile!.gender}',
      );
    }
    return user!;
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
    String? city,
    String? country,
    ProfileFavourites? favourites,
    List<String>? showMeGenders,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    // Sanitize input
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
      'lastActive': FieldValue.serverTimestamp(),
      'onboardingComplete': true,
      'profileComplete': true,
      // Set default discovery preferences to make user discoverable
      // hideFromDiscovery: false means user appears in other users' discovery feed
      // incognitoMode: false means user is visible to others
      'profile.preferences.hideFromDiscovery': false,
      'profile.preferences.incognitoMode': false,
      'profile.preferences.minAge': 18,
      'profile.preferences.maxAge': 50,
      'profile.preferences.maxDistanceKm': 100,
      'profile.preferences.showMeGenders': showMeGenders ?? ['male', 'female'],
      'profile.preferences.showMyDistance': true,
      'profile.preferences.showMyAge': true,
    };

    // Add optional fields with dot notation
    if (sanitizedJobTitle != null) {
      updateData['profile.jobTitle'] = sanitizedJobTitle;
    }
    if (sanitizedCompany != null) {
      updateData['profile.company'] = sanitizedCompany;
    }
    if (sanitizedSchool != null) updateData['profile.school'] = sanitizedSchool;
    if (sanitizedCity != null) updateData['profile.city'] = sanitizedCity;
    if (sanitizedCountry != null) {
      updateData['profile.country'] = sanitizedCountry;
    }
    if (favourites != null) {
      updateData['profile.favourites'] = favourites.toJson();
    }
    // CRITICAL: Save location for discovery distance filtering
    // Without lat/lon, users won't appear in other users' discovery decks
    if (latitude != null) updateData['profile.latitude'] = latitude;
    if (longitude != null) updateData['profile.longitude'] = longitude;

    final docRef = _firestore.collection('users').doc(userId);

    try {
      final docSnapshot = await docRef.get();
      AppLogger.info(
        '[FirebaseProfileRepo] saveProfileDetails: docExists=${docSnapshot.exists}, userId=$userId',
      );
      AppLogger.info(
        '[FirebaseProfileRepo] saveProfileDetails: photoUrls=${sanitizedPhotoUrls.length}, city=$sanitizedCity, country=$sanitizedCountry',
      );

      if (docSnapshot.exists) {
        AppLogger.info(
          '[FirebaseProfileRepo] Updating existing document with dot notation',
        );
        await docRef.update(updateData);
        AppLogger.info('[FirebaseProfileRepo] Update successful');
      } else {
        // Fallback: create document if it doesn't exist (shouldn't happen in normal flow)
        AppLogger.info(
          '[FirebaseProfileRepo] Document does not exist, creating with set()',
        );
        await docRef.set({
          'onboardingComplete': true,
          'profileComplete': true,
          'lastActive': FieldValue.serverTimestamp(),
          'profile': {
            'bio': sanitizedBio,
            'photoUrls': sanitizedPhotoUrls,
            'videoUrls': sanitizedVideoUrls,
            'interests': sanitizedInterests,
            'jobTitle': ?sanitizedJobTitle,
            'company': ?sanitizedCompany,
            'school': ?sanitizedSchool,
            'city': ?sanitizedCity,
            'country': ?sanitizedCountry,
            if (favourites != null) 'favourites': favourites.toJson(),
            'latitude': ?latitude,
            'longitude': ?longitude,
            'preferences': {
              'hideFromDiscovery': false,
              'incognitoMode': false,
              'minAge': 18,
              'maxAge': 50,
              'maxDistanceKm': 100,
              'showMeGenders': showMeGenders ?? ['male', 'female'],
              'showMyDistance': true,
              'showMyAge': true,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        AppLogger.info('[FirebaseProfileRepo] Set successful');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[FirebaseProfileRepo] saveProfileDetails FAILED',
        error: e,
      );
      AppLogger.info('[FirebaseProfileRepo] Stack trace: $stackTrace');
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

    await _firestore.collection('users').doc(userId).set({
      'profile': profileData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return (await getCurrentUser())!;
  }

  @override
  Future<void> updateThemePreference(String preference) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(userId).set({
      'themePreference': preference,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');

    final sanitizedUsername = InputSanitizer.sanitizeUsername(username);
    if (sanitizedUsername.isEmpty) {
      throw Exception('Username is required');
    }

    // Check if user already has a username and enforce cooldown
    final existingUser = await getCurrentUser();
    final existingUsername = existingUser?.username;
    final usernameChanged = existingUsername != sanitizedUsername;

    final docData = <String, dynamic>{
      'username': sanitizedUsername,
      'usernameLower': sanitizedUsername,
      'hasSkippedBasicInfo': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only update lastUsernameChangeAt if username actually changed
    if (usernameChanged) {
      if (existingUsername != null && existingUsername.isNotEmpty) {
        if (!existingUser!.canChangeUsername) {
          throw Exception(
            'You can change your username again in ${existingUser.daysUntilUsernameChange} days',
          );
        }
      }
      docData['lastUsernameChangeAt'] = FieldValue.serverTimestamp();
    }

    final docRef = _firestore.collection('users').doc(userId);
    await docRef.set(docData, SetOptions(merge: true));

    AppLogger.info(
      '[FirebaseProfileRepo] skipBasicInfo: username=$sanitizedUsername, changed=$usernameChanged',
    );

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

    AppLogger.info('[FirebaseProfileRepo] skipProfileSetup');

    return (await getCurrentUser())!;
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
      logLabel: 'FirebaseProfileRepository.saveBasicInfoResult',
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
        city: city,
        country: country,
        favourites: favourites,
        showMeGenders: showMeGenders,
        latitude: latitude,
        longitude: longitude,
      ),
      logLabel: 'FirebaseProfileRepository.saveProfileDetailsResult',
    );
  }

  @override
  Future<Result<CrushUser>> markIdVerifiedResult() async {
    return Result.guard(
      () => markIdVerified(),
      logLabel: 'FirebaseProfileRepository.markIdVerifiedResult',
    );
  }

  @override
  Future<Result<CrushUser>> updateProfileResult(Profile profile) async {
    return Result.guard(
      () => updateProfile(profile),
      logLabel: 'FirebaseProfileRepository.updateProfileResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipBasicInfoResult({
    required String username,
  }) async {
    return Result.guard(
      () => skipBasicInfo(username: username),
      logLabel: 'FirebaseProfileRepository.skipBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipProfileSetupResult() async {
    return Result.guard(
      () => skipProfileSetup(),
      logLabel: 'FirebaseProfileRepository.skipProfileSetupResult',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  CrushUser _userFromFirestore(String id, Map<String, dynamic> data) {
    Profile? profile;
    final profileData = data['profile'] as Map<String, dynamic>?;

    if (profileData != null) {
      final parsedBirthDate =
          _parseTimestamp(profileData['birthDate']) ??
          _parseTimestamp(profileData['dateOfBirth']);
      final parsedAge = (profileData['age'] as num?)?.toInt();
      final normalizedAge = parsedBirthDate != null
          ? _calculateAgeFromDate(parsedBirthDate)
          : (parsedAge ?? 0);
      final legacyPromptAnswers = parseLegacyPromptAnswers(
        profileData['prompts'],
      );
      final parsedProfilePrompts = parseProfilePrompts(
        profileData['profilePrompts'],
        legacyPromptAnswers: legacyPromptAnswers,
      );

      profile = Profile(
        id: id,
        username: data['username'], // Username is stored at user document level
        name: profileData['name'] ?? '',
        lastName: profileData['lastName'],
        age: normalizedAge,
        gender: profileData['gender'] ?? '',
        sexualOrientation: profileData['sexualOrientation'],
        dateOfBirth: parsedBirthDate,
        lastDobChangeAt: _parseTimestamp(profileData['lastDobChangeAt']),
        lastNameChangeAt: _parseTimestamp(profileData['lastNameChangeAt']),
        bio: profileData['bio'] ?? '',
        // Filter to only include valid remote URLs (exclude any accidentally saved local paths)
        photoUrls: List<String>.from(
          profileData['photoUrls'] ?? [],
        ).where(_isRemoteUrl).toList(),
        videoUrls: List<String>.from(
          profileData['videoUrls'] ?? [],
        ).where(_isRemoteUrl).toList(),
        primaryPhotoIndex: profileData['primaryPhotoIndex'] ?? 0,
        interests: List<String>.from(profileData['interests'] ?? []),
        profilePrompts: parsedProfilePrompts,
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
                profileData['favourites'] as Map<String, dynamic>,
              )
            : const ProfileFavourites(),
        chatSettings: ChatSettings.fromJson(
          profileData['chatSettings'] as Map<String, dynamic>?,
        ),
      );
    }

    return CrushUser(
      id: id,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      username: data['username'],
      lastUsernameChangeAt: _parseTimestamp(data['lastUsernameChangeAt']),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isIdVerified: data['isIdVerified'] ?? false,
      tier: data['plan'] == 'plus'
          ? SubscriptionTier.plus
          : SubscriptionTier.free,
      themePreference: data['themePreference'] ?? data['theme_preference'],
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
        showMeGenders: ['male', 'female'], // Default to show all binary genders
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      );
    }

    // Handle legacy 'All' value by converting to proper defaults
    List<String> showMeGenders = List<String>.from(data['showMeGenders'] ?? []);
    if (showMeGenders.isEmpty ||
        showMeGenders.any(
          (g) => g.toLowerCase() == 'all' || g.toLowerCase() == 'everyone',
        )) {
      showMeGenders = ['male', 'female'];
    }

    return DiscoveryPreferences(
      minAge: data['minAge'] ?? 18,
      maxAge: data['maxAge'] ?? 50,
      maxDistanceKm: (data['maxDistanceKm'] ?? 100).toDouble(),
      showMeGenders: showMeGenders,
      showMyDistance: data['showMyDistance'] ?? true,
      showMyAge: data['showMyAge'] ?? true,
      hideFromDiscovery: data['hideFromDiscovery'] ?? false,
      incognitoMode: data['incognitoMode'] ?? false,
      country: data['country'] ?? '',
      city: data['city'] ?? '',
    );
  }

  /// Checks if a URL is a valid remote URL (not a local file path).
  bool _isRemoteUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Map<String, dynamic> _profileToFirestore(Profile p) {
    // CRITICAL: Only save remote URLs, not local file paths.
    // Local paths can become invalid if files are deleted from device.
    final remotePhotoUrls = p.photoUrls.where(_isRemoteUrl).toList();
    final remoteVideoUrls = p.videoUrls.where(_isRemoteUrl).toList();

    // Log warning if local paths were filtered out (for debugging)
    if (remotePhotoUrls.length != p.photoUrls.length) {
      AppLogger.warning(
        '[FirebaseProfileRepo] Filtered out ${p.photoUrls.length - remotePhotoUrls.length} local photo path(s) - only remote URLs are saved',
      );
    }
    if (remoteVideoUrls.length != p.videoUrls.length) {
      AppLogger.warning(
        '[FirebaseProfileRepo] Filtered out ${p.videoUrls.length - remoteVideoUrls.length} local video path(s) - only remote URLs are saved',
      );
    }

    final canonicalAge = p.dateOfBirth != null
        ? _calculateAgeFromDate(p.dateOfBirth!)
        : p.age;
    final canonicalProfilePrompts = p.profilePrompts;

    return {
      'name': p.name,
      'lastName': p.lastName,
      'age': canonicalAge,
      'gender': p.gender,
      'sexualOrientation': p.sexualOrientation,
      'birthDate': p.dateOfBirth,
      'lastDobChangeAt': p.lastDobChangeAt,
      'lastNameChangeAt': p.lastNameChangeAt,
      'bio': p.bio,
      'photoUrls': remotePhotoUrls,
      'videoUrls': remoteVideoUrls,
      'primaryPhotoIndex': p.primaryPhotoIndex,
      'interests': p.interests,
      'profilePrompts': canonicalProfilePrompts
          .map((prompt) => prompt.toJson())
          .toList(),
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
}
