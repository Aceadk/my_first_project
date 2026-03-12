import 'dart:async';
import 'dart:convert';

import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/firebase_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAnalyticsMocks();

  group('StubAuthRepository hotspot branches', () {
    late StubAuthRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clearSecureStorageMock();
      repo = StubAuthRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('supports email-link sign-in creation and reuse', () async {
      const email = 'magic.link@example.com';

      await repo.sendEmailSignInLink(email);
      final first = await repo.signInWithEmailLink(
        email: email,
        emailLink: 'https://example.com/link',
      );
      expect(first.email, email);
      expect(first.isEmailVerified, isTrue);

      await repo.signOut();
      final second = await repo.signInWithEmailLink(
        email: email,
        emailLink: 'https://example.com/link-again',
      );
      expect(second.id, first.id);
    });

    test(
      'signInWithEmailPassword validates account existence and password',
      () async {
        await expectLater(
          () => repo.signInWithEmailPassword(
            email: 'missing@example.com',
            password: 'pw',
          ),
          throwsA(isA<Exception>()),
        );

        await repo.signUpWithPassword(
          username: 'mailpass',
          email: 'mailpass@example.com',
          password: 'secret-1',
        );
        await repo.signOut();

        await expectLater(
          () => repo.signInWithEmailPassword(
            email: 'mailpass@example.com',
            password: 'wrong',
          ),
          throwsA(isA<Exception>()),
        );

        final user = await repo.signInWithEmailPassword(
          email: 'mailpass@example.com',
          password: 'secret-1',
        );
        expect(user.username, 'mailpass');
      },
    );

    test(
      'loginWithPassword resolves by username and phone identifier',
      () async {
        final emailUser = await repo.signUpWithPassword(
          username: 'username_login',
          email: 'username.login@example.com',
          password: 'username-pass',
        );
        await repo.signOut();

        final viaUsername = await repo.loginWithPassword(
          identifier: emailUser.username!,
          password: 'username-pass',
        );
        expect(viaUsername.id, emailUser.id);
        await repo.signOut();

        const phone = '+15550000001';
        await repo.sendOtp(phone);
        final phoneUser = await repo.verifyOtp(
          phoneNumber: phone,
          otp: '123456',
        );
        const storage = FlutterSecureStorage();
        await storage.write(key: 'pwd_${phoneUser.id}', value: 'phone-pass');
        await repo.signOut();

        final viaPhone = await repo.loginWithPassword(
          identifier: phone,
          password: 'phone-pass',
        );
        expect(viaPhone.id, phoneUser.id);

        await expectLater(
          () => repo.loginWithPassword(identifier: 'not-found', password: 'pw'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('signInWithApple returns verified relay account', () async {
      final user = await repo.signInWithApple();
      expect(user.isEmailVerified, isTrue);
      expect(user.email, contains('@privaterelay.appleid.com'));
      expect(user.username, startsWith('apple'));
    });

    test('signInWithGoogle returns verified gmail account', () async {
      final user = await repo.signInWithGoogle();
      expect(user.isEmailVerified, isTrue);
      expect(user.email, contains('@gmail.com'));
      expect(user.username, startsWith('google'));
    });

    test(
      'verifyEmailOtp covers login, addEmail, newDevice and resetPassword',
      () async {
        final created = await repo.signUpWithPassword(
          username: 'otp_user',
          email: 'otp.user@example.com',
          password: 'otp-pass',
        );
        await repo.signOut();

        await repo.requestEmailOtp(
          identifier: created.username!,
          purpose: EmailOtpPurpose.login,
        );
        final loggedInViaOtp = await repo.verifyEmailOtp(
          identifier: created.username!,
          otp: '123456',
          purpose: EmailOtpPurpose.login,
        );
        expect(loggedInViaOtp?.id, created.id);

        await repo.requestEmailOtp(
          identifier: created.id,
          purpose: EmailOtpPurpose.addEmail,
        );
        final withAddedEmail = await repo.verifyEmailOtp(
          identifier: created.id,
          otp: '123456',
          purpose: EmailOtpPurpose.addEmail,
          newEmail: 'new.email@example.com',
        );
        expect(withAddedEmail?.email, 'new.email@example.com');
        expect(withAddedEmail?.isEmailVerified, isTrue);

        await repo.requestEmailOtp(
          identifier: created.id,
          purpose: EmailOtpPurpose.newDevice,
        );
        final newDeviceUser = await repo.verifyEmailOtp(
          identifier: created.id,
          otp: '123456',
          purpose: EmailOtpPurpose.newDevice,
        );
        expect(newDeviceUser?.id, created.id);

        await repo.requestEmailOtp(
          identifier: created.id,
          purpose: EmailOtpPurpose.resetPassword,
        );
        final resetResult = await repo.verifyEmailOtp(
          identifier: created.id,
          otp: '123456',
          purpose: EmailOtpPurpose.resetPassword,
        );
        expect(resetResult?.id, created.id);
      },
    );

    test('verifyEmailOtp throws for missing and invalid codes', () async {
      await expectLater(
        () => repo.verifyEmailOtp(
          identifier: 'any',
          otp: '123456',
          purpose: EmailOtpPurpose.login,
        ),
        throwsA(isA<Exception>()),
      );

      await repo.signUpWithPassword(
        username: 'otp_invalid',
        email: 'otp.invalid@example.com',
        password: 'pw',
      );
      await repo.requestEmailOtp(
        identifier: 'otp_invalid',
        purpose: EmailOtpPurpose.login,
      );

      await expectLater(
        () => repo.verifyEmailOtp(
          identifier: 'otp_invalid',
          otp: '000000',
          purpose: EmailOtpPurpose.login,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('password reset enforces request + OTP + token validation', () async {
      await repo.signUpWithPassword(
        username: 'reset_hotspot',
        email: 'reset.hotspot@example.com',
        password: 'old-pass',
      );
      await repo.signOut();

      await repo.requestPasswordReset(email: 'unknown@example.com');

      await expectLater(
        () => repo.verifyPasswordResetOtp(
          email: 'unknown@example.com',
          otp: '123456',
        ),
        throwsA(isA<Exception>()),
      );

      await repo.requestPasswordReset(email: 'reset.hotspot@example.com');
      await expectLater(
        () => repo.verifyPasswordResetOtp(
          email: 'reset.hotspot@example.com',
          otp: '000000',
        ),
        throwsA(isA<Exception>()),
      );

      final token = await repo.verifyPasswordResetOtp(
        email: 'reset.hotspot@example.com',
        otp: '123456',
      );

      await expectLater(
        () => repo.resetPasswordWithToken(
          email: 'reset.hotspot@example.com',
          resetToken: 'bad-token',
          newPassword: 'new-pass',
        ),
        throwsA(isA<Exception>()),
      );

      await repo.resetPasswordWithToken(
        email: 'reset.hotspot@example.com',
        resetToken: token,
        newPassword: 'new-pass',
      );
      final user = await repo.signInWithEmailPassword(
        email: 'reset.hotspot@example.com',
        password: 'new-pass',
      );
      expect(user.email, 'reset.hotspot@example.com');
    });

    test('changePassword validates session and current password', () async {
      await expectLater(
        () => repo.changePassword(currentPassword: 'none', newPassword: 'new'),
        throwsA(isA<Exception>()),
      );

      await repo.signUpWithPassword(
        username: 'changepw',
        email: 'changepw@example.com',
        password: 'right',
      );

      await expectLater(
        () => repo.changePassword(currentPassword: 'wrong', newPassword: 'new'),
        throwsA(isA<Exception>()),
      );

      await repo.changePassword(currentPassword: 'right', newPassword: 'new');
      await repo.signOut();
      final user = await repo.loginWithPassword(
        identifier: 'changepw@example.com',
        password: 'new',
      );
      expect(user.username, 'changepw');
    });

    test(
      'deactivateAccount and deleteAccount enforce auth and password',
      () async {
        await expectLater(
          () => repo.deactivateAccount(reason: 'test'),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          () => repo.deleteAccount(password: 'pw', reason: 'test'),
          throwsA(isA<Exception>()),
        );

        await repo.signUpWithPassword(
          username: 'delete-me',
          email: 'delete.me@example.com',
          password: 'delete-pass',
        );

        await expectLater(
          () => repo.deleteAccount(password: 'wrong', reason: 'cleanup'),
          throwsA(isA<Exception>()),
        );

        await repo.deactivateAccount(reason: 'taking a break');
        expect(await repo.refreshCurrentUser(), isNull);
      },
    );

    test(
      'deleteAccount works for OTP-created account without stored password',
      () async {
        const phone = '+15550000002';
        await repo.sendOtp(phone);
        final user = await repo.verifyOtp(phoneNumber: phone, otp: '123456');

        await repo.deleteAccount(password: 'ignored', reason: 'cleanup');
        expect(await repo.refreshCurrentUser(), isNull);
        expect(await repo.isEmailRegistered(user.email ?? ''), isFalse);
      },
    );

    test('schedulePhoneDeletion clears current user phone number', () async {
      const phone = '+15550000003';
      await repo.sendOtp(phone);
      final user = await repo.verifyOtp(phoneNumber: phone, otp: '123456');
      expect(user.phoneNumber, phone);

      await repo.schedulePhoneDeletion();
      final refreshed = await repo.refreshCurrentUser();
      expect(refreshed?.phoneNumber, isEmpty);
    });

    test('checkEmailVerification returns null when signed out', () async {
      expect(await repo.checkEmailVerification(), isNull);
    });

    test('isEmailRegistered reflects storage state', () async {
      expect(await repo.isEmailRegistered('new@example.com'), isFalse);

      await repo.signUpWithPassword(
        username: 'registered',
        email: 'registered@example.com',
        password: 'pw',
      );
      expect(await repo.isEmailRegistered('registered@example.com'), isTrue);
    });

    test('bootstrapSession emits restored user from secure storage', () async {
      final created = await repo.signUpWithPassword(
        username: 'bootstrapper',
        email: 'bootstrap@example.com',
        password: 'pw',
      );
      repo.dispose();

      final restoredRepo = StubAuthRepository();
      addTearDown(restoredRepo.dispose);

      final event = Completer<String?>();
      final sub = restoredRepo.authStateChanges().listen((user) {
        if (!event.isCompleted) {
          event.complete(user?.id);
        }
      });
      addTearDown(sub.cancel);

      await restoredRepo.bootstrapSession();
      final emittedId = await event.future.timeout(const Duration(seconds: 2));
      expect(emittedId, created.id);
    });

    test(
      'acceptTermsAndConditions restores user from storage when needed',
      () async {
        final created = await repo.signUpWithPassword(
          username: 'terms-hotspot',
          email: 'terms.hotspot@example.com',
          password: 'pw',
        );
        repo.dispose();

        final restoredRepo = StubAuthRepository();
        addTearDown(restoredRepo.dispose);

        final accepted = await restoredRepo.acceptTermsAndConditions();
        expect(accepted.id, created.id);
        expect(accepted.hasAcceptedTerms, isTrue);
      },
    );

    test(
      'acceptTermsAndConditions throws when storage has no current user',
      () async {
        await expectLater(
          () => repo.acceptTermsAndConditions(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'refreshCurrentUser returns null when current user key is absent',
      () async {
        expect(await repo.refreshCurrentUser(), isNull);
      },
    );

    test(
      'profile serialization/deserialization handles rich profile payload',
      () async {
        const userId = 'seed_user_1';
        await _seedProfileBackedUser(userId: userId);

        final restored = await repo.refreshCurrentUser();
        expect(restored, isNotNull);
        expect(restored!.id, userId);
        expect(restored.tier.name, 'plus');
        expect(restored.profile, isNotNull);
        expect(restored.profile!.name, 'Ava');
        expect(
          restored.profile!.preferences.showMeGenders,
          containsAll(<String>['male', 'female']),
        );
        expect(restored.profile!.profilePrompts.length, 1);
        expect(restored.profile!.profilePrompts.first.answer, 'prompt 1');
        expect(restored.profile!.privacySettings.showEmail, isTrue);

        final accepted = await repo.acceptTermsAndConditions();
        expect(accepted.hasAcceptedTerms, isTrue);

        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('mock_users');
        expect(usersJson, isNotNull);
        final usersMap = jsonDecode(usersJson!) as Map<String, dynamic>;
        final persisted = usersMap[userId] as Map<String, dynamic>;
        expect(persisted['hasAcceptedTerms'], isTrue);
        final persistedProfile = persisted['profile'] as Map<String, dynamic>;
        expect(persistedProfile['name'], 'Ava');
        expect((persistedProfile['profilePrompts'] as List).length, 1);
        expect(persistedProfile['privacySettings']['showEmail'], isTrue);
        expect(persistedProfile['preferences']['maxDistanceKm'], 42.5);
      },
    );
  });
}

Future<void> _seedProfileBackedUser({required String userId}) async {
  final users = <String, dynamic>{
    userId: <String, dynamic>{
      'id': userId,
      'phoneNumber': '+15559990000',
      'email': 'seeded@example.com',
      'username': 'seeded-user',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'isIdVerified': true,
      'plan': 'plus',
      'hasAcceptedTerms': false,
      'hasSkippedBasicInfo': false,
      'hasSkippedProfileSetup': false,
      'profile': <String, dynamic>{
        'id': 'profile_seed_1',
        'name': 'Ava',
        'lastName': 'Stone',
        'age': 29,
        'gender': 'female',
        'sexualOrientation': 'straight',
        'dateOfBirth': DateTime(1996, 1, 2).toIso8601String(),
        'lastNameChangeAt': DateTime(2025, 12, 31).toIso8601String(),
        'bio': 'Hello world',
        'photoUrls': <String>['https://example.com/1.jpg'],
        'videoUrls': <String>['https://example.com/1.mp4'],
        'primaryPhotoIndex': 0,
        'interests': <String>['hiking', 'music'],
        'prompts': <String>['prompt 1'],
        'country': 'US',
        'city': 'Austin',
        'livingIn': 'Austin',
        'latitude': 30.2672,
        'longitude': -97.7431,
        'isVerified': true,
        'verificationBadge': 'gold',
        'heightCm': 170,
        'relationshipGoals': 'long_term',
        'languages': <String>['English', 'Spanish'],
        'zodiacSign': 'capricorn',
        'educationLevel': 'college',
        'familyPlans': 'someday',
        'personalityType': 'INTJ',
        'workout': 'often',
        'socialMedia': '@seed',
        'sleepingHabits': 'early_bird',
        'smoking': 'never',
        'drinking': 'socially',
        'diet': 'balanced',
        'exercise': 'regular',
        'pets': 'dog',
        'jobTitle': 'Engineer',
        'company': 'Crush',
        'school': 'UT',
        'favoriteSongs': <String>['Song A'],
        'favoriteSinger': 'Singer A',
        'preferences': <String, dynamic>{
          'minAge': 25,
          'maxAge': 35,
          'maxDistanceKm': 42.5,
          'showMeGenders': <String>['male', 'female'],
          'showMyDistance': true,
          'showMyAge': false,
          'hideFromDiscovery': false,
          'incognitoMode': true,
          'country': 'US',
          'city': 'Austin',
        },
        'privacySettings': <String, dynamic>{
          'showFirstName': true,
          'showLastName': false,
          'showAge': true,
          'showDateOfBirth': false,
          'showEmail': true,
          'showPhoneNumber': false,
          'showExactLocation': false,
          'showHeight': true,
          'showZodiacSign': true,
          'showEducation': true,
          'showFamilyPlans': true,
          'showPersonality': true,
          'showReligion': false,
          'showRelationshipGoals': true,
          'showWorkout': true,
          'showSmoking': true,
          'showDrinking': true,
          'showDiet': true,
          'showSleepingHabits': true,
          'showPets': true,
          'showJobTitle': true,
          'showCompany': true,
          'showSchool': true,
          'showFavoriteSongs': true,
          'showFavoriteSinger': true,
          'showSocialMedia': true,
          'showLanguages': true,
          'showOnlineStatus': true,
          'showLastActive': true,
        },
      },
    },
  };

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('mock_users', jsonEncode(users));

  const storage = FlutterSecureStorage();
  await storage.write(key: 'mock_current_user_id', value: userId);
}
