import 'dart:async';

import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('reads initial theme from local storage', () async {
      SharedPreferences.setMockInitialValues({'crush_theme_mode': 'luxury'});
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _AuthRepositoryStub();
      final profileRepository = _ProfileRepositoryStub();
      final cubit = ThemeCubit(
        preferences: prefs,
        authRepository: authRepository,
        profileRepository: profileRepository,
      );

      expect(cubit.state, AppThemeMode.darkLuxury);

      await cubit.close();
      authRepository.dispose();
    });

    test('setTheme persists and syncs account preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _AuthRepositoryStub();
      final profileRepository = _ProfileRepositoryStub();
      final cubit = ThemeCubit(
        preferences: prefs,
        authRepository: authRepository,
        profileRepository: profileRepository,
      );

      await cubit.setTheme(AppThemeMode.dark);

      expect(cubit.state, AppThemeMode.dark);
      expect(prefs.getString('crush_theme_mode'), 'dark');
      expect(profileRepository.updatedThemePreferences, ['dark']);

      await cubit.close();
      authRepository.dispose();
    });

    test('setTheme is a no-op when mode is unchanged', () async {
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _AuthRepositoryStub();
      final profileRepository = _ProfileRepositoryStub();
      final cubit = ThemeCubit(
        preferences: prefs,
        authRepository: authRepository,
        profileRepository: profileRepository,
      );

      await cubit.setTheme(AppThemeMode.system);

      expect(cubit.state, AppThemeMode.system);
      expect(profileRepository.updatedThemePreferences, isEmpty);
      expect(prefs.getString('crush_theme_mode'), isNull);

      await cubit.close();
      authRepository.dispose();
    });

    test('remote auth update syncs theme to local state and storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _AuthRepositoryStub();
      final profileRepository = _ProfileRepositoryStub();
      final cubit = ThemeCubit(
        preferences: prefs,
        authRepository: authRepository,
        profileRepository: profileRepository,
      );

      authRepository.emit(_testUser(themePreference: 'modern'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state, AppThemeMode.darkLuxuryModern);
      expect(prefs.getString('crush_theme_mode'), 'luxury_modern');

      await cubit.close();
      authRepository.dispose();
    });

    test('sync failure does not break local theme update', () async {
      final prefs = await SharedPreferences.getInstance();
      final authRepository = _AuthRepositoryStub();
      final profileRepository = _ProfileRepositoryStub(throwOnUpdate: true);
      final cubit = ThemeCubit(
        preferences: prefs,
        authRepository: authRepository,
        profileRepository: profileRepository,
      );

      await cubit.setTheme(AppThemeMode.light);

      expect(cubit.state, AppThemeMode.light);
      expect(prefs.getString('crush_theme_mode'), 'light');

      await cubit.close();
      authRepository.dispose();
    });
  });
}

CrushUser _testUser({String? themePreference}) {
  return CrushUser(
    id: 'user-1',
    phoneNumber: '+10000000000',
    isEmailVerified: true,
    isPhoneVerified: true,
    isIdVerified: false,
    tier: SubscriptionTier.free,
    hasAcceptedTerms: true,
    themePreference: themePreference,
  );
}

class _ProfileRepositoryStub implements ProfileRepository {
  _ProfileRepositoryStub({this.throwOnUpdate = false});

  final bool throwOnUpdate;
  final List<String> updatedThemePreferences = [];

  @override
  Future<CrushUser?> getCurrentUser() async => _testUser();

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
  }) async => _testUser();

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
  }) async => _testUser();

  @override
  Future<void> uploadIdDocument() async {}

  @override
  Future<CrushUser> markIdVerified() async => _testUser();

  @override
  Future<CrushUser> updateProfile(Profile profile) async => _testUser();

  @override
  Future<void> updateThemePreference(String preference) async {
    if (throwOnUpdate) {
      throw Exception('sync failed');
    }
    updatedThemePreferences.add(preference);
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async =>
      _testUser();

  @override
  Future<CrushUser> skipProfileSetup() async => _testUser();

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
  }) async => Result.success(_testUser());

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
  }) async => Result.success(_testUser());

  @override
  Future<Result<CrushUser>> markIdVerifiedResult() async =>
      Result.success(_testUser());

  @override
  Future<Result<CrushUser>> updateProfileResult(Profile profile) async =>
      Result.success(_testUser());

  @override
  Future<Result<CrushUser>> skipBasicInfoResult({
    required String username,
  }) async => Result.success(_testUser());

  @override
  Future<Result<CrushUser>> skipProfileSetupResult() async =>
      Result.success(_testUser());
}

class _AuthRepositoryStub implements AuthRepository {
  final StreamController<CrushUser?> _controller =
      StreamController<CrushUser?>.broadcast();

  void emit(CrushUser? user) => _controller.add(user);

  void dispose() {
    _controller.close();
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
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<CrushUser> signInWithApple() async => throw UnimplementedError();

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
  Future<void> signOut() async => _controller.add(null);

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
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<CrushUser> acceptTermsAndConditions() async => _testUser();

  @override
  Future<CrushUser?> refreshCurrentUser() async => _testUser();
}
