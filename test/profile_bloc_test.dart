import 'dart:async';

import 'package:crushhour/core/errors.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_event.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('ProfileBloc', () {
    group('Initial State', () {
      test('has correct initial values', () {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(),
          authRepository: authRepo,
        );

        expect(bloc.state.status, ProfileStatus.initial);
        expect(bloc.state.user, isNull);
        expect(bloc.state.profile, isNull);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.isSaving, false);
        expect(bloc.state.errorMessage, isNull);

        bloc.close();
      });
    });

    group('ProfileLoadRequested', () {
      test('loads profile successfully', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>()
                .having((s) => s.isLoading, 'loading', true)
                .having((s) => s.status, 'status', ProfileStatus.loading),
            isA<ProfileState>()
                .having((s) => s.isLoading, 'loading', false)
                .having((s) => s.status, 'status', ProfileStatus.loaded)
                .having((s) => s.user, 'user', isNotNull)
                .having((s) => s.profile, 'profile', isNotNull),
          ]),
        );

        await bloc.close();
      });

      test('emits empty status when no profile exists', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: null),
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ProfileState>().having(
              (s) => s.status,
              'status',
              ProfileStatus.empty,
            ),
          ),
        );

        await bloc.close();
      });

      test('emits error on load failure', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(shouldFailLoad: true),
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ProfileState>()
                .having((s) => s.status, 'status', ProfileStatus.error)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });
    });

    group('ProfileBasicInfoSubmitted', () {
      test('saves basic info successfully', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(
          ProfileBasicInfoSubmitted(
            name: 'John',
            lastName: 'Doe',
            age: 25,
            gender: 'male',
          ),
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>().having((s) => s.isSaving, 'saving', true),
            isA<ProfileState>()
                .having((s) => s.isSaving, 'saving', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        await bloc.close();
      });

      test('handles save error', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(shouldFailSave: true),
          authRepository: authRepo,
        );

        bloc.add(
          ProfileBasicInfoSubmitted(name: 'John', age: 25, gender: 'male'),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<ProfileState>()
                .having((s) => s.isSaving, 'saving', false)
                .having((s) => s.errorMessage, 'error', isNotNull),
          ),
        );

        await bloc.close();
      });
    });

    group('ProfileDetailsSubmitted', () {
      test('saves details successfully', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(
          ProfileDetailsSubmitted(
            bio: 'Hello, I am John!',
            photoUrls: const ['https://example.com/photo.jpg'],
            videoUrls: const [],
            interests: const ['music', 'travel'],
          ),
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>().having((s) => s.isSaving, 'saving', true),
            isA<ProfileState>()
                .having((s) => s.isSaving, 'saving', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('ProfileSaveRequested', () {
      test('updates profile successfully', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(ProfileSaveRequested(profile: _testProfile));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>().having((s) => s.isSaving, 'saving', true),
            isA<ProfileState>()
                .having((s) => s.isSaving, 'saving', false)
                .having((s) => s.status, 'status', ProfileStatus.loaded),
          ]),
        );

        await bloc.close();
      });
    });

    group('ProfileResetRequested', () {
      test('resets state to initial', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        // Load profile first
        bloc.add(ProfileLoadRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.user, isNotNull);

        // Reset
        bloc.add(ProfileResetRequested());

        await expectLater(
          bloc.stream,
          emits(
            isA<ProfileState>()
                .having((s) => s.status, 'status', ProfileStatus.initial)
                .having((s) => s.user, 'user', isNull)
                .having((s) => s.profile, 'profile', isNull),
          ),
        );

        await bloc.close();
      });
    });

    group('ProfileBasicInfoSkipped', () {
      test('skips basic info with username only', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(ProfileBasicInfoSkipped(username: 'johndoe'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>().having((s) => s.isSaving, 'saving', true),
            isA<ProfileState>()
                .having((s) => s.isSaving, 'saving', false)
                .having((s) => s.errorMessage, 'error', isNull),
          ]),
        );

        await bloc.close();
      });
    });

    group('ProfileSetupSkipped', () {
      test('skips profile setup', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        bloc.add(ProfileSetupSkipped());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ProfileState>().having((s) => s.isSaving, 'saving', true),
            isA<ProfileState>().having((s) => s.isSaving, 'saving', false),
          ]),
        );

        await bloc.close();
      });
    });

    group('Hotspot branches', () {
      test('treats no-profile load errors as empty state', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(
          shouldFailLoad: true,
          loadFailureMessage: 'No profile found for this user',
          loadFailureAsRepositoryException: true,
        );
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.getCurrentUserCallCount, 1);
        expect(bloc.state.status, ProfileStatus.empty);
        expect(bloc.state.errorMessage, isNull);

        await bloc.close();
      });

      test('auto-retries transient load failures', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(
          shouldFailLoad: true,
          loadFailureMessage: 'Temporary backend failure',
        );
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        expect(repo.getCurrentUserCallCount, greaterThanOrEqualTo(2));
        expect(
          bloc.state.status,
          anyOf(ProfileStatus.error, ProfileStatus.empty),
        );

        await bloc.close();
      });

      test('manualRefresh triggers a fresh load request', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(userToReturn: _testUser);
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.manualRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.getCurrentUserCallCount, 1);
        expect(bloc.state.status, ProfileStatus.loaded);

        await bloc.close();
      });

      test('ProfileDetailsSubmitted executes photo-removed branch', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        const existingProfile = Profile(
          id: 'profile-existing',
          name: 'Jane',
          age: 27,
          gender: 'female',
          photoUrls: ['a.jpg', 'b.jpg'],
          videoUrls: [],
          bio: 'Existing bio',
          interests: ['music'],
          country: 'US',
          city: 'New York',
          isVerified: false,
          preferences: _testPreferences,
        );
        final seededUser = _testUser.copyWith(profile: existingProfile);
        final repo = _StubProfileRepository(userToReturn: seededUser);
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(bloc.state.profile?.photoUrls.length, 2);

        bloc.add(
          ProfileDetailsSubmitted(
            bio: 'Updated bio',
            photoUrls: const ['a.jpg'],
            videoUrls: const [],
            interests: const ['music'],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(bloc.state.isSaving, isFalse);
        expect(bloc.state.errorMessage, isNull);

        await bloc.close();
      });

      test('ProfileIdDocumentUploaded handles upload failure', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(shouldFailUploadId: true);
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileIdDocumentUploaded());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.uploadIdDocumentCallCount, 1);
        expect(repo.markIdVerifiedCallCount, 0);
        expect(bloc.state.isSaving, isFalse);
        expect(bloc.state.errorMessage, isNotNull);

        await bloc.close();
      });

      test('ProfileIdDocumentUploaded handles mark-id failure', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(shouldFailMarkId: true);
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileIdDocumentUploaded());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.uploadIdDocumentCallCount, 1);
        expect(repo.markIdVerifiedCallCount, 1);
        expect(bloc.state.isSaving, isFalse);
        expect(bloc.state.errorMessage, isNotNull);

        await bloc.close();
      });

      test('ProfileIdVerifiedMarked records repository failures', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final repo = _StubProfileRepository(shouldFailMarkId: true);
        final bloc = ProfileBloc(
          profileRepository: repo,
          authRepository: authRepo,
        );

        bloc.add(ProfileIdVerifiedMarked());
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(repo.markIdVerifiedCallCount, 1);
        expect(bloc.state.errorMessage, isNotNull);

        await bloc.close();
      });

      test(
        'ProfileSaveRequested keeps loaded status on update failure',
        () async {
          final authRepo = _StubAuthRepository();
          addTearDown(authRepo.dispose);
          final repo = _StubProfileRepository(shouldFailUpdateProfile: true);
          final bloc = ProfileBloc(
            profileRepository: repo,
            authRepository: authRepo,
          );

          bloc.add(ProfileSaveRequested(profile: _testProfile));
          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(repo.updateProfileCallCount, 1);
          expect(bloc.state.status, ProfileStatus.loaded);
          expect(bloc.state.errorMessage, isNotNull);

          await bloc.close();
        },
      );

      test(
        'ProfileLocationUpdateRequested returns early with no profile',
        () async {
          final authRepo = _StubAuthRepository();
          addTearDown(authRepo.dispose);
          final repo = _StubProfileRepository(userToReturn: _testUser);
          final bloc = ProfileBloc(
            profileRepository: repo,
            authRepository: authRepo,
          );

          bloc.add(
            ProfileLocationUpdateRequested(
              latitude: 40.7128,
              longitude: -74.0060,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));

          expect(repo.updateProfileCallCount, 0);

          await bloc.close();
        },
      );

      test(
        'ProfileLocationUpdateRequested updates and persists location',
        () async {
          final authRepo = _StubAuthRepository();
          addTearDown(authRepo.dispose);
          final repo = _StubProfileRepository(userToReturn: _testUser);
          final bloc = ProfileBloc(
            profileRepository: repo,
            authRepository: authRepo,
          );

          bloc.add(ProfileLoadRequested());
          await Future<void>.delayed(const Duration(milliseconds: 100));

          bloc.add(
            ProfileLocationUpdateRequested(
              latitude: 34.0522,
              longitude: -118.2437,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(repo.updateProfileCallCount, 1);
          expect(repo.lastUpdatedProfile, isNotNull);
          expect(repo.lastUpdatedProfile!.latitude, closeTo(34.0522, 0.0001));
          expect(
            repo.lastUpdatedProfile!.longitude,
            closeTo(-118.2437, 0.0001),
          );
          expect(repo.lastUpdatedProfile!.city, _testProfile.city);
          expect(repo.lastUpdatedProfile!.country, _testProfile.country);
          expect(bloc.state.profile?.latitude, closeTo(34.0522, 0.0001));
          expect(bloc.state.profile?.longitude, closeTo(-118.2437, 0.0001));

          await bloc.close();
        },
      );
    });

    group('Auth State Changes', () {
      test('resets state when user logs out', () async {
        final authRepo = _StubAuthRepository();
        addTearDown(authRepo.dispose);
        final bloc = ProfileBloc(
          profileRepository: _StubProfileRepository(userToReturn: _testUser),
          authRepository: authRepo,
        );

        // Load profile first
        bloc.add(ProfileLoadRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        // Trigger logout
        authRepo.emitLogout();

        await expectLater(
          bloc.stream,
          emits(
            isA<ProfileState>()
                .having((s) => s.status, 'status', ProfileStatus.initial)
                .having((s) => s.user, 'user', isNull),
          ),
        );

        await bloc.close();
      });
    });
  });
}

// =============================================================================
// Test Data
// =============================================================================

const _testPreferences = DiscoveryPreferences(
  minAge: 18,
  maxAge: 50,
  maxDistanceKm: 100,
  showMeGenders: ['female'],
  showMyDistance: true,
  showMyAge: true,
  hideFromDiscovery: false,
  incognitoMode: false,
  country: 'US',
  city: 'New York',
);

const _testProfile = Profile(
  id: 'profile-1',
  name: 'John',
  lastName: 'Doe',
  age: 25,
  gender: 'male',
  photoUrls: [],
  videoUrls: [],
  bio: 'Hello!',
  interests: [],
  country: 'US',
  city: 'New York',
  isVerified: false,
  preferences: _testPreferences,
);

const _testUser = CrushUser(
  id: 'user-1',
  phoneNumber: '+1234567890',
  isEmailVerified: true,
  isPhoneVerified: true,
  isIdVerified: false,
  plan: SubscriptionPlan.free,
  hasAcceptedTerms: true,
  hasSkippedBasicInfo: false,
  hasSkippedProfileSetup: false,
  profile: _testProfile,
);

// =============================================================================
// Stub Repositories
// =============================================================================

class _StubProfileRepository implements ProfileRepository {
  _StubProfileRepository({
    this.userToReturn,
    this.shouldFailLoad = false,
    this.shouldFailSave = false,
    this.loadFailureMessage,
    this.loadFailureAsRepositoryException = false,
    this.shouldFailUploadId = false,
    this.shouldFailMarkId = false,
    this.shouldFailUpdateProfile = false,
  });

  final CrushUser? userToReturn;
  final bool shouldFailLoad;
  final bool shouldFailSave;
  final String? loadFailureMessage;
  final bool loadFailureAsRepositoryException;
  final bool shouldFailUploadId;
  final bool shouldFailMarkId;
  final bool shouldFailUpdateProfile;
  int getCurrentUserCallCount = 0;
  int uploadIdDocumentCallCount = 0;
  int markIdVerifiedCallCount = 0;
  int updateProfileCallCount = 0;
  Profile? lastUpdatedProfile;

  @override
  Future<CrushUser?> getCurrentUser() async {
    getCurrentUserCallCount++;
    if (shouldFailLoad) {
      if (loadFailureAsRepositoryException) {
        throw RepositoryException(
          'profile_not_found',
          loadFailureMessage ?? 'Failed to load profile',
        );
      }
      throw Exception(loadFailureMessage ?? 'Failed to load profile');
    }
    return userToReturn;
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
    if (shouldFailSave) {
      throw Exception('Failed to save');
    }
    return userToReturn ?? _testUser;
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
    if (shouldFailSave) {
      throw Exception('Failed to save');
    }
    return userToReturn ?? _testUser;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    updateProfileCallCount++;
    lastUpdatedProfile = profile;
    if (shouldFailSave || shouldFailUpdateProfile) {
      throw Exception('Failed to save');
    }
    return (userToReturn ?? _testUser).copyWith(profile: profile);
  }

  @override
  Future<void> uploadIdDocument() async {
    uploadIdDocumentCallCount++;
    if (shouldFailUploadId) {
      throw Exception('Failed to upload ID');
    }
  }

  @override
  Future<void> updateThemePreference(String preference) async {
    // No-op for testing
  }

  @override
  Future<CrushUser> markIdVerified() async {
    markIdVerifiedCallCount++;
    if (shouldFailMarkId) {
      throw Exception('Failed to mark ID');
    }
    return userToReturn ?? _testUser;
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    if (shouldFailSave) {
      throw Exception('Failed to skip');
    }
    return userToReturn ?? _testUser;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    if (shouldFailSave) {
      throw Exception('Failed to skip');
    }
    return userToReturn ?? _testUser;
  }

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
      logLabel: 'saveBasicInfoResult',
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
      logLabel: 'saveProfileDetailsResult',
    );
  }

  @override
  Future<Result<CrushUser>> markIdVerifiedResult() async {
    return Result.guard(
      () => markIdVerified(),
      logLabel: 'markIdVerifiedResult',
    );
  }

  @override
  Future<Result<CrushUser>> updateProfileResult(Profile profile) async {
    return Result.guard(
      () => updateProfile(profile),
      logLabel: 'updateProfileResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipBasicInfoResult({
    required String username,
  }) async {
    return Result.guard(
      () => skipBasicInfo(username: username),
      logLabel: 'skipBasicInfoResult',
    );
  }

  @override
  Future<Result<CrushUser>> skipProfileSetupResult() async {
    return Result.guard(
      () => skipProfileSetup(),
      logLabel: 'skipProfileSetupResult',
    );
  }
}

class _StubAuthRepository implements AuthRepository {
  final StreamController<CrushUser?> _controller =
      StreamController<CrushUser?>.broadcast();

  void emitLogout() {
    _controller.add(null);
  }

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  void dispose() {
    _controller.close();
  }

  @override
  Future<void> sendOtp(String phoneNumber) async => throw UnimplementedError();

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendEmailSignInLink(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async => throw UnimplementedError();

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<CrushUser> signInWithApple() async => throw UnimplementedError();

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async => throw UnimplementedError();

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async =>
      throw UnimplementedError();

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async => throw UnimplementedError();

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }

  @override
  Future<void> sendEmailVerification() async => throw UnimplementedError();

  @override
  Future<CrushUser?> checkEmailVerification() async =>
      throw UnimplementedError();

  @override
  Future<void> schedulePhoneDeletion() async => throw UnimplementedError();

  @override
  @override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<void> deactivateAccount({required String reason}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async => throw UnimplementedError();

  @override
  Future<bool> isEmailRegistered(String email) async =>
      throw UnimplementedError();

  @override
  Future<CrushUser> acceptTermsAndConditions() async =>
      throw UnimplementedError();

  @override
  Future<CrushUser?> refreshCurrentUser() async => null;
}
