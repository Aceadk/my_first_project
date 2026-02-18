import 'dart:convert';

import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAnalyticsMocks();

  group('StubProfileRepository hotspot branches', () {
    late StubProfileRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clearSecureStorageMock();
      repository = StubProfileRepository();
    });

    test(
      'getCurrentUser handles missing secure and shared-preferences state',
      () async {
        expect(await repository.getCurrentUser(), isNull);

        const storage = FlutterSecureStorage();
        await storage.write(key: 'mock_current_user_id', value: 'user_1');
        expect(await repository.getCurrentUser(), isNull);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_users', jsonEncode(<String, dynamic>{}));
        expect(await repository.getCurrentUser(), isNull);
      },
    );

    test(
      'getCurrentUser hydrates legacy theme key and profile defaults',
      () async {
        await _seedCurrentUser(
          userId: 'user_legacy_theme',
          username: 'legacy_user',
          legacyThemePreference: 'darkLuxury',
          profile: <String, dynamic>{
            'id': 'profile_user_legacy_theme',
            'name': 'Legacy',
            'age': 30,
            'gender': 'female',
            'bio': 'About me',
            'photoUrls': <String>[],
            'videoUrls': <String>[],
            'interests': <String>['music'],
            'country': 'US',
            'city': 'Austin',
          },
        );

        final user = await repository.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.themePreference, 'darkLuxury');
        expect(user.profile, isNotNull);
        expect(user.profile!.preferences.maxDistanceKm, 100);
        expect(
          user.profile!.preferences.showMeGenders,
          containsAll(<String>['male', 'female']),
        );
        expect(user.profile!.privacySettings.showFirstName, isFalse);
      },
    );

    test('saveBasicInfo enforces auth and valid age', () async {
      await expectLater(
        () => repository.saveBasicInfo(
          username: 'new_user',
          name: 'Ava',
          age: 27,
          gender: 'female',
        ),
        throwsA(isA<Exception>()),
      );

      await _seedCurrentUser(
        userId: 'user_invalid_age',
        username: 'existing_user',
      );

      await expectLater(
        () => repository.saveBasicInfo(
          username: 'new_user',
          name: 'Ava',
          age: 15,
          gender: 'female',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('saveBasicInfo enforces username cooldown on changes', () async {
      await _seedCurrentUser(
        userId: 'user_cooldown',
        username: 'existing_user',
        lastUsernameChangeAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      await expectLater(
        () => repository.saveBasicInfo(
          username: 'different_user',
          name: 'Ava',
          age: 28,
          gender: 'female',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'saveBasicInfo sanitizes and persists profile fields with privacy updates',
      () async {
        await _seedCurrentUser(
          userId: 'user_save_basic',
          username: null,
          profile: _baseProfile(userId: 'user_save_basic'),
        );

        final updated = await repository.saveBasicInfo(
          username: ' New__User! ',
          name: '<b>Alice</b>',
          lastName: '<i> O\'Neil </i>',
          age: 27,
          gender: 'female',
          sexualOrientation: 'straight',
          dateOfBirth: DateTime(1998, 3, 1),
          showFirstName: true,
          showLastName: false,
        );

        expect(updated.username, 'new__user');
        expect(updated.lastUsernameChangeAt, isNotNull);
        expect(updated.profile, isNotNull);
        expect(updated.profile!.name, 'Alice');
        expect(updated.profile!.lastName, "O'Neil");
        expect(updated.profile!.privacySettings.showFirstName, isTrue);
        expect(updated.profile!.privacySettings.showLastName, isFalse);
        expect(updated.profile!.dateOfBirth, DateTime(1998, 3, 1));
        expect(
          updated.profile!.preferences.showMeGenders,
          equals(const <String>['male']),
        );
      },
    );

    test(
      'saveProfileDetails enforces preconditions and persists sanitized fields',
      () async {
        await expectLater(
          () => repository.saveProfileDetails(
            bio: 'bio',
            photoUrls: const <String>[],
            videoUrls: const <String>[],
            interests: const <String>[],
          ),
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_no_profile',
          username: 'user_no_profile',
          profile: null,
        );
        await expectLater(
          () => repository.saveProfileDetails(
            bio: 'bio',
            photoUrls: const <String>[],
            videoUrls: const <String>[],
            interests: const <String>[],
          ),
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_profile_details',
          username: 'user_profile_details',
          profile: _baseProfile(userId: 'user_profile_details'),
        );
        final updated = await repository.saveProfileDetails(
          bio: '<script>alert(1)</script>Hello & welcome',
          photoUrls: const <String>[
            'https://cdn.example.com/photo.jpg',
            'javascript:alert(1)',
          ],
          videoUrls: const <String>[
            'https://cdn.example.com/video.mp4',
            'ftp://bad.example.com/video.mp4',
          ],
          jobTitle: 'Dev <b>Lead</b>',
          company: 'Crush & Co<script>',
          school: '<i>Uni</i>',
          interests: const <String>['music', ' travel!! ', '<b>hiking</b>'],
          showMeGenders: const <String>['female'],
          city: 'Boston',
          country: 'US',
          latitude: 42.36,
          longitude: -71.06,
        );

        expect(updated.profile, isNotNull);
        expect(updated.profile!.bio, contains('&amp;'));
        expect(updated.profile!.bio, isNot(contains('<script>')));
        expect(
          updated.profile!.photoUrls,
          equals(const <String>['https://cdn.example.com/photo.jpg']),
        );
        expect(
          updated.profile!.videoUrls,
          equals(const <String>['https://cdn.example.com/video.mp4']),
        );
        expect(updated.profile!.jobTitle, 'Dev Lead');
        expect(updated.profile!.company, 'Crush & Co');
        expect(updated.profile!.school, '<i>Uni</i>');
        expect(
          updated.profile!.interests,
          equals(const <String>['music', 'travel', 'hiking']),
        );
        expect(
          updated.profile!.preferences.showMeGenders,
          equals(const <String>['female']),
        );
        expect(updated.profile!.city, 'Boston');
        expect(updated.profile!.country, 'US');
        expect(updated.profile!.latitude, 42.36);
        expect(updated.profile!.longitude, -71.06);
      },
    );

    test(
      'markIdVerified validates user/profile state and updates verification flags',
      () async {
        await expectLater(repository.markIdVerified, throwsA(isA<Exception>()));

        await _seedCurrentUser(
          userId: 'user_missing_profile',
          username: 'user_missing_profile',
          profile: null,
        );
        await expectLater(repository.markIdVerified, throwsA(isA<Exception>()));

        await _seedCurrentUser(
          userId: 'user_verify_id',
          username: 'user_verify_id',
          isIdVerified: false,
          profile: _baseProfile(userId: 'user_verify_id', isVerified: false),
        );
        final verified = await repository.markIdVerified();
        expect(verified.isIdVerified, isTrue);
        expect(verified.profile!.isVerified, isTrue);
      },
    );

    test(
      'updateProfile and updateThemePreference enforce auth and persist updates',
      () async {
        final profileSeed = _baseProfile(userId: 'user_update_profile');

        await expectLater(
          () => repository.updateProfile(_standaloneProfile()),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          () => repository.updateThemePreference('darkLuxury'),
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_update_profile',
          username: 'user_update_profile',
          profile: profileSeed,
        );
        final current = await repository.getCurrentUser();
        expect(current, isNotNull);

        final updatedProfile = current!.profile!.copyWith(
          bio: 'Updated profile bio',
          city: 'Seattle',
        );
        final updatedUser = await repository.updateProfile(updatedProfile);
        expect(updatedUser.profile!.bio, 'Updated profile bio');
        expect(updatedUser.profile!.city, 'Seattle');

        await repository.updateThemePreference('darkLuxuryModern');
        final persisted = await repository.getCurrentUser();
        expect(persisted, isNotNull);
        expect(persisted!.themePreference, 'darkLuxuryModern');
      },
    );

    test(
      'skipBasicInfo and skipProfileSetup enforce auth/cooldown and persist flags',
      () async {
        await expectLater(
          () => repository.skipBasicInfo(username: 'new_user'),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          repository.skipProfileSetup,
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_skip_invalid',
          username: 'skip_invalid',
          profile: _baseProfile(userId: 'user_skip_invalid'),
        );
        await expectLater(
          () => repository.skipBasicInfo(username: '!!!'),
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_skip_cooldown',
          username: 'skip_cooldown',
          lastUsernameChangeAt: DateTime.now().subtract(
            const Duration(days: 1),
          ),
          profile: _baseProfile(userId: 'user_skip_cooldown'),
        );
        await expectLater(
          () => repository.skipBasicInfo(username: 'different_user'),
          throwsA(isA<Exception>()),
        );

        await _seedCurrentUser(
          userId: 'user_skip_success',
          username: 'skip_success',
          lastUsernameChangeAt: DateTime.now().subtract(
            const Duration(days: 40),
          ),
          profile: _baseProfile(userId: 'user_skip_success'),
        );
        final skippedBasic = await repository.skipBasicInfo(
          username: ' Fresh_Name ',
        );
        expect(skippedBasic.username, 'fresh_name');
        expect(skippedBasic.lastUsernameChangeAt, isNotNull);
        expect(skippedBasic.hasSkippedBasicInfo, isTrue);

        final skippedProfile = await repository.skipProfileSetup();
        expect(skippedProfile.hasSkippedProfileSetup, isTrue);
      },
    );
  });
}

Future<void> _seedCurrentUser({
  required String userId,
  required String? username,
  DateTime? lastUsernameChangeAt,
  bool isIdVerified = false,
  String? themePreference,
  String? legacyThemePreference,
  Map<String, dynamic>? profile,
}) async {
  final user = <String, dynamic>{
    'id': userId,
    'phoneNumber': '+15550000000',
    'email': '$userId@example.com',
    'username': username,
    'lastUsernameChangeAt': lastUsernameChangeAt?.toIso8601String(),
    'isEmailVerified': true,
    'isPhoneVerified': true,
    'isIdVerified': isIdVerified,
    'plan': 'free',
    'hasAcceptedTerms': true,
    'hasSkippedBasicInfo': false,
    'hasSkippedProfileSetup': false,
    'profile': profile,
  };
  if (themePreference != null) {
    user['themePreference'] = themePreference;
  }
  if (legacyThemePreference != null) {
    user['theme_preference'] = legacyThemePreference;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'mock_users',
    jsonEncode(<String, dynamic>{userId: user}),
  );

  const storage = FlutterSecureStorage();
  await storage.write(key: 'mock_current_user_id', value: userId);
}

Map<String, dynamic> _baseProfile({
  required String userId,
  bool isVerified = false,
}) {
  return <String, dynamic>{
    'id': 'profile_$userId',
    'name': 'Existing',
    'lastName': 'User',
    'age': 29,
    'gender': 'female',
    'sexualOrientation': 'straight',
    'dateOfBirth': DateTime(1996, 1, 1).toIso8601String(),
    'bio': 'Existing bio',
    'photoUrls': <String>['https://cdn.example.com/existing_photo.jpg'],
    'videoUrls': <String>[],
    'primaryPhotoIndex': 0,
    'interests': <String>['music'],
    'profilePrompts': <Map<String, dynamic>>[
      <String, dynamic>{
        'questionId': 'fun_fact',
        'answer': 'I collect vinyl records',
      },
    ],
    'country': 'US',
    'city': 'Austin',
    'isVerified': isVerified,
    'preferences': <String, dynamic>{
      'minAge': 22,
      'maxAge': 40,
      'maxDistanceKm': 55.0,
      'showMeGenders': <String>['male'],
      'showMyDistance': true,
      'showMyAge': true,
      'hideFromDiscovery': false,
      'incognitoMode': false,
      'country': 'US',
      'city': 'Austin',
    },
    'privacySettings': <String, dynamic>{
      'showFirstName': false,
      'showLastName': true,
      'showAge': true,
      'showOnlineStatus': false,
      'showLastActive': false,
    },
  };
}

Profile _standaloneProfile() {
  return const Profile(
    id: 'standalone_profile',
    username: 'standalone_user',
    name: 'Standalone',
    age: 25,
    gender: 'female',
    bio: 'Standalone profile',
    photoUrls: <String>[],
    videoUrls: <String>[],
    interests: <String>['music'],
    country: 'US',
    city: 'Austin',
    isVerified: false,
    preferences: DiscoveryPreferences(
      minAge: 18,
      maxAge: 40,
      maxDistanceKm: 100,
      showMeGenders: <String>['male', 'female'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: '',
      city: '',
    ),
  );
}
