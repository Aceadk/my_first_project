import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/features/profile/presentation/models/profile_edit_form_model.dart';

void main() {
  group('ProfileEditFormModel validation', () {
    test('enforces minimum selected photo count', () {
      final invalid = ProfileEditFormModel.validateSelectedPhotos(const []);
      expect(invalid.isValid, isFalse);
      expect(invalid.error, ProfileEditFormError.minPhotosRequired);

      final valid = ProfileEditFormModel.validateSelectedPhotos(const <String>[
        'local/photo.jpg',
      ]);
      expect(valid.isValid, isTrue);
      expect(valid.error, isNull);
    });

    test('enforces minimum uploaded photo count', () {
      final invalid = ProfileEditFormModel.validateUploadedPhotos(const []);
      expect(invalid.isValid, isFalse);
      expect(invalid.error, ProfileEditFormError.minPhotosRequired);

      final valid = ProfileEditFormModel.validateUploadedPhotos(const <String>[
        'https://cdn.example.com/photo.jpg',
      ]);
      expect(valid.isValid, isTrue);
      expect(valid.error, isNull);
    });

    test('resolves user id with state priority and validates presence', () {
      expect(
        ProfileEditFormModel.resolveUserId(
          stateUserId: 'state-user',
          stateProfileId: 'profile-id',
          authUserId: 'auth-id',
        ),
        equals('state-user'),
      );
      expect(
        ProfileEditFormModel.resolveUserId(
          stateUserId: null,
          stateProfileId: 'profile-id',
          authUserId: 'auth-id',
        ),
        equals('profile-id'),
      );
      expect(
        ProfileEditFormModel.resolveUserId(
          stateUserId: null,
          stateProfileId: null,
          authUserId: 'auth-id',
        ),
        equals('auth-id'),
      );

      final invalid = ProfileEditFormModel.validateUserId(null);
      expect(invalid.isValid, isFalse);
      expect(invalid.error, ProfileEditFormError.userNotSignedIn);

      final valid = ProfileEditFormModel.validateUserId('user-123');
      expect(valid.isValid, isTrue);
      expect(valid.error, isNull);
    });
  });

  group('ProfileEditFormModel transforms', () {
    test('buildFallbackProfile keeps defaults and applies form overrides', () {
      final existing = _baseProfile(id: 'existing-user', gender: 'female');
      final form = _baseForm(
        photos: const <String>['local/new_photo.jpg'],
        videos: const <String>['local/new_video.mp4'],
        company: 'New Company',
        jobTitle: '',
        interests: const <String>['music', 'travel'],
        favoriteSongs: const <String>[],
        favoriteSinger: '',
        gender: 'male',
      );

      final fallback = ProfileEditFormModel.buildFallbackProfile(
        form: form,
        stateUserId: null,
        authUserId: 'auth-user',
        existingProfile: existing,
      );

      expect(fallback.id, equals('auth-user'));
      expect(fallback.gender, equals('male'));
      expect(fallback.photoUrls, equals(const <String>['local/new_photo.jpg']));
      expect(fallback.videoUrls, equals(const <String>['local/new_video.mp4']));
      expect(fallback.company, equals('New Company'));
      expect(fallback.jobTitle, equals(existing.jobTitle));
      expect(fallback.interests, equals(const <String>['music', 'travel']));
      expect(fallback.favoriteSongs, equals(existing.favoriteSongs));
      expect(fallback.favoriteSinger, equals(existing.favoriteSinger));
      expect(fallback.country, equals(existing.country));
      expect(fallback.city, equals(existing.city));
    });

    test('buildUpdatedProfile trims fields and updates change timestamps', () {
      final base = _baseProfile(
        name: 'Alice',
        lastName: 'Smith',
        dateOfBirth: DateTime(1990, 1, 1),
        lastNameChangeAt: DateTime(2025, 1, 1),
        lastDobChangeAt: DateTime(2025, 1, 2),
        country: 'USA',
        city: 'Boston',
        favoriteSinger: 'Adele',
      );
      final form = _baseForm(
        firstName: '  Alicia  ',
        lastName: '   ',
        bio: '  Updated bio  ',
        jobTitle: '  ',
        company: '  New Company  ',
        school: '   ',
        livingIn: '  Manhattan  ',
        favoriteSinger: '   ',
        country: '  Canada  ',
        city: '   ',
        lookingFor: 'everyone',
        showFirstName: true,
        showLastName: true,
        languages: const <String>['English', 'Spanish'],
        interests: const <String>['music', 'travel'],
        favoriteSongs: const <String>['Song A', 'Song B'],
        dateOfBirth: DateTime(1991, 2, 2),
      );
      final now = DateTime(2026, 3, 8, 12, 0, 0);

      final updated = ProfileEditFormModel.buildUpdatedProfile(
        base: base,
        form: form,
        uploadedPhotoUrls: const <String>['https://cdn.example.com/photo.jpg'],
        uploadedVideoUrls: const <String>['https://cdn.example.com/video.mp4'],
        now: () => now,
      );

      expect(updated.name, equals('Alicia'));
      expect(updated.lastName, isNull);
      expect(updated.bio, equals('Updated bio'));
      expect(
        updated.photoUrls,
        equals(const <String>['https://cdn.example.com/photo.jpg']),
      );
      expect(
        updated.videoUrls,
        equals(const <String>['https://cdn.example.com/video.mp4']),
      );
      expect(updated.jobTitle, isNull);
      expect(updated.company, equals('New Company'));
      expect(updated.school, isNull);
      expect(updated.livingIn, equals('Manhattan'));
      expect(updated.favoriteSinger, equals('Adele'));
      expect(updated.country, equals('Canada'));
      expect(updated.city, equals('Boston'));
      expect(updated.privacySettings.showFirstName, isTrue);
      expect(updated.privacySettings.showLastName, isTrue);
      expect(
        updated.preferences.showMeGenders,
        containsAll(const <String>['male', 'female', 'non_binary']),
      );
      expect(updated.lastNameChangeAt, equals(now));
      expect(updated.lastDobChangeAt, equals(now));
    });

    test(
      'buildUpdatedProfile keeps change timestamps when fields unchanged',
      () {
        final oldNameTimestamp = DateTime(2025, 2, 1);
        final oldDobTimestamp = DateTime(2025, 2, 2);
        final dateOfBirth = DateTime(1994, 4, 4);
        final base = _baseProfile(
          name: 'Alice',
          lastName: 'Smith',
          dateOfBirth: dateOfBirth,
          lastNameChangeAt: oldNameTimestamp,
          lastDobChangeAt: oldDobTimestamp,
        );
        final form = _baseForm(
          firstName: 'Alice',
          lastName: '  Smith  ',
          dateOfBirth: dateOfBirth,
          lookingFor: null,
        );

        final updated = ProfileEditFormModel.buildUpdatedProfile(
          base: base,
          form: form,
          uploadedPhotoUrls: const <String>[
            'https://cdn.example.com/photo.jpg',
          ],
          uploadedVideoUrls: const <String>[],
          now: () => DateTime(2026, 3, 8),
        );

        expect(updated.lastNameChangeAt, equals(oldNameTimestamp));
        expect(updated.lastDobChangeAt, equals(oldDobTimestamp));
        expect(
          updated.preferences.showMeGenders,
          equals(base.preferences.showMeGenders),
        );
      },
    );
  });
}

Profile _baseProfile({
  String id = 'user-1',
  String name = 'Alice',
  String? lastName = 'Smith',
  String gender = 'female',
  DateTime? dateOfBirth,
  DateTime? lastNameChangeAt,
  DateTime? lastDobChangeAt,
  String country = 'USA',
  String city = 'New York',
  String? favoriteSinger = 'Sia',
}) {
  return Profile(
    id: id,
    name: name,
    lastName: lastName,
    age: 29,
    gender: gender,
    dateOfBirth: dateOfBirth,
    lastNameChangeAt: lastNameChangeAt,
    lastDobChangeAt: lastDobChangeAt,
    bio: 'Base bio',
    photoUrls: const <String>['https://cdn.example.com/base_photo.jpg'],
    videoUrls: const <String>['https://cdn.example.com/base_video.mp4'],
    primaryPhotoIndex: 0,
    isVerified: true,
    jobTitle: 'Engineer',
    company: 'Base Company',
    school: 'Base School',
    interests: const <String>['music'],
    profilePrompts: const <ProfilePrompt>[],
    heightCm: 170,
    relationshipGoals: 'long_term',
    languages: const <String>['English'],
    zodiacSign: 'aries',
    educationLevel: 'bachelors',
    familyPlans: 'open',
    personalityType: 'intj',
    religion: 'agnostic',
    workout: 'often',
    socialMedia: 'active',
    sleepingHabits: 'night_owl',
    smoking: 'never',
    drinking: 'socially',
    pets: 'dog',
    livingIn: 'Brooklyn',
    favoriteSongs: const <String>['Song A'],
    favoriteSinger: favoriteSinger,
    country: country,
    city: city,
    preferences: const DiscoveryPreferences(
      minAge: 18,
      maxAge: 45,
      maxDistanceKm: 50,
      showMeGenders: <String>['female', 'male'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'USA',
      city: 'New York',
    ),
    privacySettings: const ProfilePrivacySettings(),
  );
}

ProfileEditFormSnapshot _baseForm({
  String firstName = 'Alice',
  String lastName = 'Smith',
  String bio = 'Bio',
  String jobTitle = 'Engineer',
  String company = 'Company',
  String school = 'School',
  String livingIn = 'Living In',
  String favoriteSinger = 'Singer',
  String country = 'USA',
  String city = 'New York',
  List<String> photos = const <String>['local/photo.jpg'],
  List<String> videos = const <String>[],
  int primaryPhotoIndex = 0,
  bool showFirstName = false,
  bool showLastName = false,
  int? heightCm = 170,
  String? relationshipGoals = 'long_term',
  List<String> languages = const <String>['English'],
  String? zodiacSign = 'aries',
  String? educationLevel = 'bachelors',
  String? familyPlans = 'open',
  String? personalityType = 'intj',
  String? religion = 'agnostic',
  String? workout = 'often',
  String? socialMedia = 'active',
  String? sleepingHabits = 'night_owl',
  String? smoking = 'never',
  String? drinking = 'socially',
  String? pets = 'dog',
  List<String> favoriteSongs = const <String>['Song A'],
  List<String> interests = const <String>['music'],
  DateTime? dateOfBirth,
  String? gender = 'female',
  String? sexualOrientation = 'straight',
  String? lookingFor = 'male',
  List<ProfilePrompt> profilePrompts = const <ProfilePrompt>[],
}) {
  return ProfileEditFormSnapshot(
    firstName: firstName,
    lastName: lastName,
    bio: bio,
    jobTitle: jobTitle,
    company: company,
    school: school,
    livingIn: livingIn,
    favoriteSinger: favoriteSinger,
    country: country,
    city: city,
    photos: photos,
    videos: videos,
    primaryPhotoIndex: primaryPhotoIndex,
    showFirstName: showFirstName,
    showLastName: showLastName,
    heightCm: heightCm,
    relationshipGoals: relationshipGoals,
    languages: languages,
    zodiacSign: zodiacSign,
    educationLevel: educationLevel,
    familyPlans: familyPlans,
    personalityType: personalityType,
    religion: religion,
    workout: workout,
    socialMedia: socialMedia,
    sleepingHabits: sleepingHabits,
    smoking: smoking,
    drinking: drinking,
    pets: pets,
    favoriteSongs: favoriteSongs,
    interests: interests,
    dateOfBirth: dateOfBirth,
    gender: gender,
    sexualOrientation: sexualOrientation,
    lookingFor: lookingFor,
    profilePrompts: profilePrompts,
  );
}
