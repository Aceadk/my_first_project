import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crushhour/core/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/security/secure_logger.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../models/preferences.dart';
import '../models/privacy_settings.dart';
import '../models/match.dart';
import '../models/message.dart';
import '../models/message_request.dart';
import '../models/subscription.dart';
import '../models/promo_code.dart';
import '../models/favourites.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/core/utils/constants.dart';

const _uuid = Uuid();
const _backendBaseUrl = String.fromEnvironment(
  'CRUSH_API_BASE_URL',
  defaultValue: 'https://api.crushhour.dev',
);

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<CrushUser?>.broadcast();
  CrushUser? _current;
  final _otpStore = <String, _OtpEntry>{};
  final _emailLinkStore = <String, _OtpEntry>{};
  final _emailOtpStore = <String, _OtpEntry>{};
  final _passwordResetTokens = <String, _OtpEntry>{};
  final _usersByEmail = <String, CrushUser>{};
  final _usersByUsername = <String, CrushUser>{};
  final _passwordsByEmail = <String, String>{};
  final _passwordsByUserId = <String, String>{};
  final _rand = Random.secure();

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {}

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    final otp = (_rand.nextInt(900000) + 100000).toString(); // 6-digit
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    _otpStore[phoneNumber] = _OtpEntry(code: otp, expiresAt: expiresAt);

    // Attempt to hit backend if available; ignore failures for local dev.
    try {
      final uri = Uri.parse('$_backendBaseUrl/auth/otp/send');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      AppLogger.error(
          'FakeAuthRepository: Backend OTP send failed (expected in local dev): $e');
    }

    // Use secure logger for OTP (redacted by default)
    SecureLogger.logOtp(type: 'PHONE', recipient: phoneNumber, code: otp);
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    final otp = (_rand.nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _emailLinkStore[email] = _OtpEntry(code: otp, expiresAt: expiresAt);
    // Use secure logger for email link (redacted by default)
    SecureLogger.logOtp(type: 'EMAIL_LINK', recipient: email, code: otp);
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final entry = _emailLinkStore[email];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      throw Exception('Email link expired or not requested.');
    }
    final uri = Uri.tryParse(emailLink);
    final code = uri?.queryParameters['code'];
    if (code == null || code != entry.code) {
      throw Exception('Invalid email link.');
    }
    _emailLinkStore.remove(email);
    final user = _usersByEmail[email] ??
        CrushUser(
          id: _uuid.v4(),
          phoneNumber: '',
          email: email,
          username: null,
          isEmailVerified: true,
          profile: null,
          isPhoneVerified: false,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
        );
    _usersByEmail[email] = user;
    _current = user;
    _controller.add(_current);
    return user;
  }

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return loginWithPassword(identifier: email, password: password);
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final normalized = identifier.trim().toLowerCase();
    final user = normalized.contains('@')
        ? _usersByEmail[normalized]
        : _usersByUsername[normalized];
    if (user == null) {
      throw Exception('Invalid credentials.');
    }
    final stored = _passwordsByUserId[user.id];
    if (stored == null || stored != password) {
      throw Exception('Invalid credentials.');
    }
    _current = user;
    _controller.add(_current);
    return user;
  }

  @override
  Future<CrushUser> signInWithApple() async {
    final uniqueId = _uuid.v4().substring(0, 8);
    final email = 'apple_$uniqueId@privaterelay.appleid.com';
    final username = 'apple_$uniqueId';

    final existing = _usersByEmail[email];
    if (existing != null) {
      _current = existing;
      _controller.add(_current);
      return existing;
    }

    final user = CrushUser(
      id: _uuid.v4(),
      phoneNumber: '',
      email: email,
      username: username,
      isEmailVerified: true,
      profile: null,
      isPhoneVerified: false,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
    );
    _usersByEmail[email] = user;
    _usersByUsername[username] = user;
    _passwordsByUserId[user.id] = _uuid.v4();
    _passwordsByEmail[email] = _uuid.v4();
    _current = user;
    _controller.add(_current);
    return user;
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail) ||
        _usersByUsername.containsKey(normalizedUsername)) {
      throw Exception('Could not create account.');
    }
    final user = CrushUser(
      id: _uuid.v4(),
      phoneNumber: '',
      email: normalizedEmail,
      username: normalizedUsername,
      isEmailVerified: false,
      profile: null,
      isPhoneVerified: false,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
    );
    _usersByEmail[normalizedEmail] = user;
    _usersByUsername[normalizedUsername] = user;
    _passwordsByUserId[user.id] = password;
    _passwordsByEmail[normalizedEmail] = password;
    _current = user;
    _controller.add(_current);
    return user;
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    final normalized = identifier.trim().toLowerCase();
    final key = '${purpose.value}:$normalized';
    final otp = (_rand.nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _emailOtpStore[key] = _OtpEntry(code: otp, expiresAt: expiresAt);
    // Use secure logger (redacted by default)
    SecureLogger.logOtp(
        type: 'EMAIL_${purpose.value.toUpperCase()}',
        recipient: identifier,
        code: otp);
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    final normalized = identifier.trim().toLowerCase();
    final key = '${purpose.value}:$normalized';
    final entry = _emailOtpStore[key];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      throw Exception('Invalid or expired code.');
    }
    if (entry.code != otp) {
      throw Exception('Invalid or expired code.');
    }
    _emailOtpStore.remove(key);

    switch (purpose) {
      case EmailOtpPurpose.login:
        final isEmail = normalized.contains('@');
        if (isEmail) {
          final user = _usersByEmail[normalized] ??
              CrushUser(
                id: _uuid.v4(),
                phoneNumber: '',
                email: normalized,
                username: null,
                isEmailVerified: true,
                profile: null,
                isPhoneVerified: false,
                isIdVerified: false,
                plan: SubscriptionPlan.free,
              );
          _usersByEmail[normalized] = user;
          _current = user;
          _controller.add(_current);
          return user;
        }
        final user = _usersByUsername[normalized] ??
            CrushUser(
              id: _uuid.v4(),
              phoneNumber: '',
              email: null,
              username: normalized,
              isEmailVerified: false,
              profile: null,
              isPhoneVerified: false,
              isIdVerified: false,
              plan: SubscriptionPlan.free,
            );
        _usersByUsername[normalized] = user;
        _current = user;
        _controller.add(_current);
        return user;
      case EmailOtpPurpose.addEmail:
      case EmailOtpPurpose.changeEmail:
        if (_current == null) return null;
        final resolvedEmail = (newEmail ?? identifier).trim().toLowerCase();
        final updated = _current!.copyWith(
          email: resolvedEmail,
          isEmailVerified: true,
        );
        _current = updated;
        _usersByEmail[resolvedEmail] = updated;
        _controller.add(_current);
        return updated;
      case EmailOtpPurpose.resetPassword:
        final email = normalized;
        final user = _usersByEmail[email];
        if (newPassword != null && newPassword.isNotEmpty && user != null) {
          _passwordsByUserId[user.id] = newPassword;
          _passwordsByEmail[email] = newPassword;
        }
        return null;
      case EmailOtpPurpose.newDevice:
      case EmailOtpPurpose.sensitiveAction:
        return null;
    }
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final stored = _otpStore[phoneNumber];
    if (stored == null || DateTime.now().isAfter(stored.expiresAt)) {
      throw Exception(
          'OTP expired or not requested. Please request a new code.');
    }
    if (stored.code != otp) {
      throw Exception('Invalid OTP.');
    }
    _otpStore.remove(phoneNumber);
    await Future.delayed(const Duration(milliseconds: 500));
    _current ??= CrushUser(
      id: _uuid.v4(),
      phoneNumber: phoneNumber,
      email: null,
      username: null,
      isEmailVerified: false,
      profile: null,
      isPhoneVerified: true,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
    );
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendEmailVerification() async {
    // Fake: do nothing
  }

  @override
  Future<CrushUser?> checkEmailVerification() async {
    // Fake: always return verified user
    if (_current != null) {
      _current = _current!.copyWith(isEmailVerified: true);
      _controller.add(_current);
      return _current;
    }
    return null;
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async {
    if (_current == null) {
      throw Exception('No user logged in');
    }
    _current = _current!.copyWith(hasAcceptedTerms: true);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async {
    if (_current != null) {
      _controller.add(_current);
    }
    return _current;
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final normalized = email.trim().toLowerCase();
    return _usersByEmail.containsKey(normalized);
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final normalized = email.trim().toLowerCase();
    final otp = (_rand.nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _emailOtpStore['forgot_password:$normalized'] =
        _OtpEntry(code: otp, expiresAt: expiresAt);
    // Use secure logger (redacted by default)
    SecureLogger.logOtp(
        type: 'PASSWORD_RESET', recipient: normalized, code: otp);
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final normalized = email.trim().toLowerCase();
    final key = 'forgot_password:$normalized';
    final entry = _emailOtpStore[key];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      throw Exception('Invalid or expired code.');
    }
    if (entry.code != otp) {
      throw Exception('Invalid or expired code.');
    }
    _emailOtpStore.remove(key);
    final resetToken = _uuid.v4();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    _passwordResetTokens[normalized] =
        _OtpEntry(code: resetToken, expiresAt: expiresAt);
    return resetToken;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final normalized = email.trim().toLowerCase();
    final entry = _passwordResetTokens[normalized];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      throw Exception('Invalid reset request.');
    }
    if (entry.code != resetToken) {
      throw Exception('Invalid reset request.');
    }
    _passwordResetTokens.remove(normalized);
    final user = _usersByEmail[normalized];
    if (user != null) {
      _passwordsByUserId[user.id] = newPassword;
      _passwordsByEmail[normalized] = newPassword;
    }
  }

  @override
  Future<void> schedulePhoneDeletion() async {
    // Fake: just clear the phone number after a delay simulation
    if (_current != null && _current!.phoneNumber.isNotEmpty) {
      // In real app, this would schedule deletion after ~3 days
      // For fake, we just mark it as pending deletion
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_current == null) {
      throw Exception('No user logged in');
    }
    final stored = _passwordsByUserId[_current!.id];
    if (stored != currentPassword) {
      throw Exception('Current password is incorrect');
    }
    _passwordsByUserId[_current!.id] = newPassword;
    if (_current!.email != null) {
      _passwordsByEmail[_current!.email!.toLowerCase()] = newPassword;
    }
  }

  @override
  Future<void> deactivateAccount({required String reason}) async {
    if (_current == null) {
      throw Exception('No user logged in');
    }
    // Fake: just sign out (real app would hide profile)
    await signOut();
  }

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {
    if (_current == null) {
      throw Exception('No user logged in');
    }
    final stored = _passwordsByUserId[_current!.id];
    if (stored != null && stored != password) {
      throw Exception('Password is incorrect');
    }
    // Remove user data
    final userId = _current!.id;
    final email = _current!.email?.toLowerCase();
    final username = _current!.username?.toLowerCase();

    _passwordsByUserId.remove(userId);
    if (email != null) {
      _usersByEmail.remove(email);
      _passwordsByEmail.remove(email);
    }
    if (username != null) {
      _usersByUsername.remove(username);
    }
    await signOut();
  }

  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}

class _OtpEntry {
  final String code;
  final DateTime expiresAt;

  _OtpEntry({required this.code, required this.expiresAt});
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<SubscriptionPlan>.broadcast()
    ..add(SubscriptionPlan.free);
  SubscriptionPlan _current = SubscriptionPlan.free;
  final List<PromoCode> _redeemedCodes = [];

  static const Map<String, PromoCode> _baseCodes = {
    'WELCOME50': PromoCode(
      code: 'WELCOME50',
      type: PromoCodeType.discount,
      description: '50% off your first month of Plus',
      discountPercent: 50,
    ),
    'FREEWEEK': PromoCode(
      code: 'FREEWEEK',
      type: PromoCodeType.freeTrial,
      description: '7 days free trial of Plus',
      freeTrialDays: 7,
    ),
    'CRUSH2024': PromoCode(
      code: 'CRUSH2024',
      type: PromoCodeType.combined,
      description: 'Special launch offer: 30% off + 10 bonus likes',
      discountPercent: 30,
      bonusLikes: 10,
    ),
    'SUPERLOVE': PromoCode(
      code: 'SUPERLOVE',
      type: PromoCodeType.bonusSuperLikes,
      description: '5 bonus Super Likes',
      bonusSuperLikes: 5,
    ),
    'CRUSHFREE': PromoCode(
      code: 'CRUSHFREE',
      type: PromoCodeType.discount,
      description: '100% off - Completely free Plus membership!',
      discountPercent: 100,
    ),
  };

  static final Map<String, PromoCode> _demoCodes = {
    ..._baseCodes,
    'EXPIRED': PromoCode(
      code: 'EXPIRED',
      type: PromoCodeType.discount,
      description: 'Expired code for testing',
      discountPercent: 20,
      expiresAt: DateTime(2023, 1, 1),
    ),
  };

  @override
  Stream<SubscriptionPlan> watchPlan() => _controller.stream;

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => _current;

  @override
  Future<String> startPlusCheckout() async {
    return 'https://example.com/checkout/plus';
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    if (url.isEmpty) throw Exception('Invalid checkout URL');
  }

  @override
  Future<void> purchasePlusPlan() async {
    final uri = Uri.parse('$_backendBaseUrl/billing/plus/purchase');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'plan': 'plus'}),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to complete billing (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final plan = decoded['plan'] as String?;
        if (plan != null && plan.toLowerCase() != 'plus') {
          throw Exception('Billing responded with unexpected plan: $plan');
        }
      }
    }

    _current = SubscriptionPlan.plus;
    _controller.add(_current);
  }

  @override
  Future<SubscriptionStatus> refreshStatus() async {
    return SubscriptionStatus(
      plan: _current,
      status: _current.isPlus ? 'active' : 'none',
      nextRenewal: DateTime.now().add(const Duration(days: 30)),
      cancelAtPeriodEnd: false,
    );
  }

  @override
  Future<PromoCode?> validatePromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final normalizedCode = code.trim().toUpperCase();
    final promoCode = _demoCodes[normalizedCode];
    if (promoCode == null) {
      return null;
    }

    if (_redeemedCodes.any((c) => c.code == normalizedCode)) {
      return null;
    }

    return promoCode.isValid ? promoCode : null;
  }

  @override
  Future<PromoCodeRedemptionResult> redeemPromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedCode = code.trim().toUpperCase();
    final promoCode = _demoCodes[normalizedCode];

    if (promoCode == null) {
      return PromoCodeRedemptionResult.failure(
        'Invalid promo code. Please check and try again.',
      );
    }

    if (promoCode.isExpired) {
      return PromoCodeRedemptionResult.failure(
        'This promo code has expired.',
      );
    }

    if (promoCode.isMaxedOut) {
      return PromoCodeRedemptionResult.failure(
        'This promo code has reached its maximum redemptions.',
      );
    }

    if (_redeemedCodes.any((c) => c.code == normalizedCode)) {
      return PromoCodeRedemptionResult.failure(
        'You have already redeemed this promo code.',
      );
    }

    final benefits = <String>[];

    if (promoCode.discountPercent != null) {
      benefits.add('${promoCode.discountPercent}% discount applied');
      if (promoCode.discountPercent == 100) {
        _current = SubscriptionPlan.plus;
        _controller.add(_current);
        benefits.add('Plus membership activated!');
      }
    }

    if (promoCode.freeTrialDays != null) {
      benefits.add('${promoCode.freeTrialDays} day free trial activated');
      _current = SubscriptionPlan.plus;
      _controller.add(_current);
    }

    if (promoCode.bonusLikes != null) {
      benefits.add('${promoCode.bonusLikes} bonus likes added');
    }

    if (promoCode.bonusSuperLikes != null) {
      benefits.add('${promoCode.bonusSuperLikes} bonus Super Likes added');
    }

    _redeemedCodes.add(promoCode);

    return PromoCodeRedemptionResult.success(
      promoCode: promoCode,
      appliedBenefits: benefits,
    );
  }

  @override
  Future<List<PromoCode>> getRedeemedCodes() async {
    return List.unmodifiable(_redeemedCodes);
  }

  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}

class FakeProfileRepository implements ProfileRepository {
  CrushUser? _user;

  @override
  Future<CrushUser?> getCurrentUser() async => _user;

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
    if (age < CrushConstants.minAge) {
      throw Exception('User must be at least ${CrushConstants.minAge}.');
    }

    const prefs = DiscoveryPreferences(
      minAge: 18,
      maxAge: 45,
      maxDistanceKm: 50,
      showMeGenders: ['female', 'male'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'Unknown',
      city: 'Unknown',
    );

    final privacy = const ProfilePrivacySettings().copyWith(
      showFirstName: showFirstName ?? false,
      showLastName: showLastName ?? false,
    );
    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      lastName: lastName,
      age: age,
      gender: gender,
      sexualOrientation: sexualOrientation,
      dateOfBirth: dateOfBirth,
      bio: '',
      photoUrls: const [],
      videoUrls: const [],
      isVerified: false,
      jobTitle: null,
      company: null,
      school: null,
      interests: const [],
      country: prefs.country,
      city: prefs.city,
      latitude: null,
      longitude: null,
      preferences: prefs,
      privacySettings: privacy,
    );

    _user = (_user ??
            CrushUser(
              id: _uuid.v4(),
              phoneNumber: '',
              email: null,
              username: null,
              isEmailVerified: false,
              profile: null,
              isPhoneVerified: true,
              isIdVerified: false,
              plan: SubscriptionPlan.free,
            ))
        .copyWith(profile: profile);
    return _user!;
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
    final profile = _user!.profile!;
    final updatedPreferences = showMeGenders != null
        ? profile.preferences.copyWith(showMeGenders: showMeGenders)
        : profile.preferences;
    final updated = profile.copyWith(
      bio: bio,
      photoUrls: photoUrls,
      videoUrls: videoUrls,
      isVerified: _user?.isIdVerified ?? profile.isVerified,
      jobTitle: jobTitle,
      company: company,
      school: school,
      interests: interests,
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
      preferences: updatedPreferences,
    );
    _user = _user!.copyWith(profile: updated);
    return _user!;
  }

  @override
  Future<void> uploadIdDocument() async {
    final user = _user;
    if (user == null) {
      throw Exception('No user available to upload ID for.');
    }

    final uri = Uri.parse('$_backendBaseUrl/verification/id/upload');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': user.id,
            'document': 'demo-id-document', // Placeholder payload for demo.
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to upload ID (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<CrushUser> markIdVerified() async {
    _user = _user!.copyWith(isIdVerified: true);
    return _user!;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    _user = _user!.copyWith(profile: profile);
    return _user!;
  }

  @override
  Future<void> updateThemePreference(String preference) async {
    if (_user == null) {
      _user = CrushUser(
        id: _uuid.v4(),
        phoneNumber: '',
        email: null,
        username: null,
        isEmailVerified: false,
        profile: null,
        isPhoneVerified: true,
        isIdVerified: false,
        plan: SubscriptionPlan.free,
        themePreference: preference,
      );
    } else {
      _user = _user!.copyWith(themePreference: preference);
    }
  }

  @override
  Future<CrushUser> skipBasicInfo({required String username}) async {
    _user = (_user ??
            CrushUser(
              id: _uuid.v4(),
              phoneNumber: '',
              email: null,
              username: null,
              isEmailVerified: false,
              profile: null,
              isPhoneVerified: true,
              isIdVerified: false,
              plan: SubscriptionPlan.free,
            ))
        .copyWith(
      username: username,
      hasSkippedBasicInfo: true,
    );
    return _user!;
  }

  @override
  Future<CrushUser> skipProfileSetup() async {
    _user = _user!.copyWith(hasSkippedProfileSetup: true);
    return _user!;
  }
}

class FakeDiscoveryRepository implements DiscoveryRepository {
  final FakeProfileRepository profileRepo;
  final FakeSubscriptionRepository subRepo;

  FakeDiscoveryRepository(this.profileRepo, this.subRepo);

  final Map<String, List<Profile>> _fakeDecks = {};
  final Map<String, Set<String>> _dislikesByUser = {};
  final Map<String, List<CrushMatch>> _matchesByUser = {};
  final Map<String, Map<String, Profile>> _incomingRightSwipes = {};

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async {
    final user = await profileRepo.getCurrentUser();
    final prefs = user?.profile?.preferences ??
        const DiscoveryPreferences(
          minAge: CrushConstants.minAge,
          maxAge: 45,
          maxDistanceKm: CrushConstants.defaultMaxDistanceKm,
          showMeGenders: ['female', 'male'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'Unknown',
          city: 'Unknown',
        );

    final genders = prefs.showMeGenders.isEmpty
        ? const ['female', 'male']
        : prefs.showMeGenders;
    const names = [
      'Alex',
      'Jordan',
      'Taylor',
      'Casey',
      'Riley',
      'Sam',
      'Jamie',
      'Cameron',
      'Morgan',
      'Drew',
      'Harper',
      'Charlie',
      'Avery',
      'Quinn',
      'Reese',
      'Parker',
      'Rowan',
      'Hayden',
      'Logan',
      'Skyler',
    ];
    const interestsPool = [
      'music',
      'travel',
      'coffee',
      'fitness',
      'reading',
      'movies',
      'hiking',
      'cooking',
    ];
    const cityPool = [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
      'Dallas',
      'Austin',
    ];

    final ageSpan = prefs.maxAge - prefs.minAge;
    final safeSpan = ageSpan < 0 ? 0 : ageSpan;

    // Determine effective distance limit
    final maxDistanceKm =
        filter.maxDistanceKm ?? CrushConstants.defaultMaxDistanceKm;
    final isPassportMode = filter.passportModeEnabled;

    // Generate profiles with varying distances
    final generated = List<Profile>.generate(20, (index) {
      final gender = genders[index % genders.length];
      final age = prefs.minAge + (safeSpan == 0 ? 0 : index % (safeSpan + 1));
      final interests = List<String>.generate(
        3,
        (i) => interestsPool[(index + i) % interestsPool.length],
      );

      // Generate fake distance - first 10 within 220km, next 10 beyond
      double fakeDistance;
      if (isPassportMode) {
        // Passport mode: random global distances
        fakeDistance = 50.0 + (index * 500.0);
      } else if (index < 10) {
        // First 10 profiles: within default limit (10-200 km)
        fakeDistance = 10.0 + (index * 20.0);
      } else {
        // Next 10 profiles: beyond default limit (250-500 km)
        fakeDistance = 250.0 + ((index - 10) * 25.0);
      }

      final city = cityPool[index % cityPool.length];

      // Simulate some users being active and some being new
      final isActive = index % 3 == 0; // Every 3rd user is active
      final isNewUser = index % 5 == 0; // Every 5th user is new
      final createdAt = isNewUser
          ? DateTime.now().subtract(Duration(days: index % 7))
          : DateTime.now().subtract(Duration(days: 30 + index));

      return Profile(
        id: _uuid.v4(),
        name: '${names[index % names.length]} ${index + 1}',
        age: age,
        gender: gender,
        sexualOrientation: null,
        bio: 'Loves ${interests.first} and meeting new people.',
        photoUrls: [
          'https://picsum.photos/seed/${userId}_$index/400/600',
          'https://picsum.photos/seed/${userId}_${index}b/400/600',
        ],
        videoUrls: const [],
        isVerified: false,
        isActive: isActive,
        createdAt: createdAt,
        jobTitle: null,
        company: null,
        school: null,
        interests: interests,
        country: prefs.country,
        city: city,
        latitude: null,
        longitude: null,
        distance: fakeDistance,
        distanceUnit: 'km',
        preferences: prefs,
      );
    });

    // Filter by distance unless passport mode is enabled
    final filtered = isPassportMode
        ? generated
        : generated.where((p) => (p.distance ?? 0) <= maxDistanceKm).toList();

    // Cache the filtered deck
    _fakeDecks[userId] = filtered;
    return filtered;
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    CrushMatch? mutualForTarget;
    final targetMatches = _matchesByUser[targetUserId];
    if (targetMatches != null) {
      for (var i = 0; i < targetMatches.length; i++) {
        final match = targetMatches[i];
        if (match.otherUserId == userId &&
            match.status == MatchStatus.pending) {
          final updated = match.copyWith(status: MatchStatus.mutual);
          targetMatches[i] = updated;
          mutualForTarget = updated;
          break;
        }
      }
    }

    if (mutualForTarget != null) {
      _incomingRightSwipes[userId]?.remove(targetUserId);
      _incomingRightSwipes[targetUserId]?.remove(userId);

      final userMatch = CrushMatch(
        id: mutualForTarget.id,
        userId: userId,
        otherUserId: targetUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount:
            mutualForTarget.preMatchMessageRequestsCount,
        pinnedForUser: false,
      );
      final userMatches = _matchesByUser.putIfAbsent(userId, () => []);
      final existingIndex =
          userMatches.indexWhere((m) => m.otherUserId == targetUserId);
      if (existingIndex == -1) {
        userMatches.add(userMatch);
      } else {
        userMatches[existingIndex] = userMatch;
      }
      return userMatch;
    }

    final pendingMatch = CrushMatch(
      id: _uuid.v4(),
      userId: userId,
      otherUserId: targetUserId,
      status: MatchStatus.pending,
      preMatchMessageRequestsCount: attachedMessage == null ? 0 : 1,
      pinnedForUser: false,
    );
    final userMatches = _matchesByUser.putIfAbsent(userId, () => []);
    final existingIndex =
        userMatches.indexWhere((m) => m.otherUserId == targetUserId);
    if (existingIndex == -1) {
      userMatches.add(pendingMatch);
    } else {
      userMatches[existingIndex] = pendingMatch;
    }

    final likerProfile = (await profileRepo.getCurrentUser())?.profile;
    if (likerProfile != null) {
      final likesForTarget =
          _incomingRightSwipes.putIfAbsent(targetUserId, () => {});
      likesForTarget[userId] = likerProfile;
    }

    return null;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    _dislikesByUser.putIfAbsent(userId, () => <String>{}).add(targetUserId);
    final deck = _fakeDecks[userId];
    deck?.removeWhere((profile) => profile.name == targetUserId);
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    final deck = _fakeDecks[userId] ?? [];
    if (deck.isEmpty) return deck;

    final user = await profileRepo.getCurrentUser();
    final profile = user?.profile;
    final prefs = profile?.preferences;
    final interests = profile?.interests ?? const [];

    if (prefs == null) {
      return deck.take(10).toList();
    }

    final showMe = prefs.showMeGenders.map((g) => g.toLowerCase()).toSet();
    final targetAgeCenter = (prefs.minAge + prefs.maxAge) / 2;
    final country = prefs.country.toLowerCase();
    final city = prefs.city.toLowerCase();

    bool matchesPrefs(Profile p) {
      if (p.age < prefs.minAge || p.age > prefs.maxAge) return false;
      if (showMe.isNotEmpty && !showMe.contains(p.gender.toLowerCase())) {
        return false;
      }
      return true;
    }

    double score(Profile p) {
      final sharedInterests =
          p.interests.where((i) => interests.contains(i)).length;
      final ageScore = -((p.age - targetAgeCenter).abs());
      final locationBoost = (p.city.toLowerCase() == city ? 5 : 0) +
          (p.country.toLowerCase() == country ? 2 : 0);
      return sharedInterests * 10 + ageScore + locationBoost;
    }

    final filtered = deck.where(matchesPrefs).toList();
    filtered.sort((a, b) => score(b).compareTo(score(a)));
    return filtered.take(10).toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    final likes = _incomingRightSwipes[userId];
    if (likes == null || likes.isEmpty) return const [];
    return List.unmodifiable(likes.values);
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    return _matchesByUser[userId] ?? [];
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    // Search through cached decks
    for (final deck in _fakeDecks.values) {
      for (final profile in deck) {
        if (profile.id == profileId) return profile;
      }
    }
    return null;
  }

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async {
    // Simulate super like - higher match probability
    await Future.delayed(const Duration(milliseconds: 100));
    return null; // No match for fake repo
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    // Not implemented in fake repo
    return null;
  }
}

class FakeChatRepository implements ChatRepository {
  final FakeSubscriptionRepository subRepo;
  final DiscoveryRepository discoveryRepo;

  FakeChatRepository(this.subRepo, this.discoveryRepo);

  final Map<String, List<Message>> _messagesByMatch = {};
  final Map<String, Set<String>> _blockedByUser = {};
  final _streams = <String, StreamController<List<Message>>>{};
  final Map<String, Set<String>> _typingByMatch = {};
  final _typingStreams = <String, StreamController<Set<String>>>{};
  final Map<String, bool> _presence = {};
  final _presenceStreams = <String, StreamController<bool>>{};
  final Map<String, bool> _mediaEnabledByMatch = {};
  final _mediaStreams = <String, StreamController<bool>>{};
  final Map<String, MessageRequest> _messageRequestsByPair = {};

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    _streams.putIfAbsent(
      matchId,
      () => StreamController<List<Message>>.broadcast(),
    );
    _streams[matchId]!.add(_messagesByMatch[matchId] ?? []);
    return _streams[matchId]!.stream;
  }

  @override
  Future<PaginatedResult<Message>> fetchMessagesPaginated(
    String matchId, {
    int limit = 30,
    DateTime? beforeTimestamp,
  }) async {
    var messages = _messagesByMatch[matchId] ?? [];
    messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    if (beforeTimestamp != null) {
      messages =
          messages.where((m) => m.sentAt.isBefore(beforeTimestamp)).toList();
    }
    final hasMore = messages.length > limit;
    final items = messages.take(limit).toList();
    return PaginatedResult(
      items: items.reversed.toList(),
      total: messages.length,
      hasMore: hasMore,
    );
  }

  @override
  Stream<List<Message>> watchNewMessages(
    String matchId, {
    required DateTime afterTimestamp,
  }) {
    return watchMessages(matchId).map((messages) =>
        messages.where((m) => m.sentAt.isAfter(afterTimestamp)).toList());
  }

  @override
  Stream<Set<String>> watchTyping(String matchId) {
    _typingStreams.putIfAbsent(
      matchId,
      () => StreamController<Set<String>>.broadcast(),
    );
    _typingStreams[matchId]!.add(_typingByMatch[matchId] ?? <String>{});
    return _typingStreams[matchId]!.stream;
  }

  @override
  Future<void> setTyping({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    final set = _typingByMatch.putIfAbsent(matchId, () => <String>{});
    if (isTyping) {
      set.add(userId);
    } else {
      set.remove(userId);
    }
    _typingStreams[matchId]?.add(Set.unmodifiable(set));
  }

  @override
  Stream<bool> watchPresence(String userId) {
    _presenceStreams.putIfAbsent(
      userId,
      () => StreamController<bool>.broadcast(),
    );
    _presenceStreams[userId]!.add(_presence[userId] ?? false);
    return _presenceStreams[userId]!.stream;
  }

  @override
  Future<void> setPresence({
    required String userId,
    required bool isOnline,
  }) async {
    _presence[userId] = isOnline;
    _presenceStreams[userId]?.add(isOnline);
  }

  @override
  Stream<bool> watchMediaSendingEnabled(String matchId) {
    _mediaStreams.putIfAbsent(
      matchId,
      () => StreamController<bool>.broadcast(),
    );
    _mediaStreams[matchId]!.add(_mediaEnabledByMatch[matchId] ?? true);
    return _mediaStreams[matchId]!.stream;
  }

  @override
  Future<void> setMediaSendingEnabled({
    required String matchId,
    required bool enabled,
    required String requesterId,
  }) async {
    _mediaEnabledByMatch[matchId] = enabled;
    _mediaStreams[matchId]?.add(enabled);
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      matchId: matchId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
    );
    final list = _messagesByMatch.putIfAbsent(matchId, () => []);
    list.add(message);
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<String> uploadMedia({
    required String matchId,
    required String filePath,
    required MessageType type,
  }) async {
    // In fake repo, just return the local path to simulate an upload.
    return filePath;
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      if (list[i].toUserId == userId) {
        list[i] = list[i].copyWith(isRead: true);
      }
    }
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    // In real app, allow only sender + premium plan to unsend.
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      list[index] = list[index].copyWith(isDeletedForSender: true);
      _streams[matchId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String newContent,
  }) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final m = list[index];
      list[index] = Message(
        id: m.id,
        matchId: m.matchId,
        fromUserId: m.fromUserId,
        toUserId: m.toUserId,
        content: newContent,
        type: m.type,
        sentAt: m.sentAt,
        isRead: m.isRead,
        isDeletedForSender: m.isDeletedForSender,
        reactions: m.reactions,
        moderationStatus: m.moderationStatus,
        moderationReason: m.moderationReason,
        moderationAction: m.moderationAction,
        isFlagged: m.isFlagged,
      );
      _streams[matchId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      if (list[index].fromUserId != userId) {
        throw Exception('Only the sender can delete this message.');
      }
      list[index] = list[index].copyWith(isDeletedForSender: true);
      _streams[matchId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? matchId,
    String? messageId,
    String? source,
    String? description,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/moderation/report');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'reporterId': reporterId,
            'reportedId': reportedId,
            'reason': reason,
            'matchId': matchId,
            'messageId': messageId,
            'source': source,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to report user (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _blockedByUser.putIfAbsent(blockerId, () => <String>{}).add(blockedId);
  }

  @override
  Future<void> addReaction({
    required String matchId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final reactions = Map<String, String>.from(list[index].reactions);
    reactions[userId] = emoji;
    list[index] = list[index].copyWith(reactions: reactions);
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    // Immutable pattern: filter out the user's reaction instead of mutating
    final reactions = Map.fromEntries(
      list[index].reactions.entries.where((e) => e.key != userId),
    );
    list[index] = list[index].copyWith(reactions: reactions);
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _blockedByUser[blockerId]?.remove(blockedId);
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    final userMatches = await discoveryRepo.fetchMatches(userId);
    CrushMatch? updatedForUser;

    for (var i = 0; i < userMatches.length; i++) {
      if (userMatches[i].id == matchId) {
        final updated = userMatches[i].copyWith(status: MatchStatus.unmatched);
        userMatches[i] = updated;
        updatedForUser = updated;
        break;
      }
    }

    if (updatedForUser != null) {
      final otherMatches =
          await discoveryRepo.fetchMatches(updatedForUser.otherUserId);
      for (var i = 0; i < otherMatches.length; i++) {
        if (otherMatches[i].id == matchId) {
          otherMatches[i] =
              otherMatches[i].copyWith(status: MatchStatus.unmatched);
          break;
        }
      }
    }

    _messagesByMatch.remove(matchId);
    _typingByMatch.remove(matchId);
    _mediaEnabledByMatch.remove(matchId);
    _streams[matchId]?.add(const []);
    _typingStreams[matchId]?.add(const {});
    _mediaStreams[matchId]?.add(true);
  }

  @override
  Future<void> submitSafetyAppeal({
    required String userId,
    required String reason,
    String? targetType,
    String? targetId,
  }) async {
    // Record appeal for tests; no-op for now.
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    return discoveryRepo.fetchMatches(userId);
  }

  @override
  Future<PaginatedResult<CrushMatch>> fetchUserMatchesPaginated(
    String userId, {
    int offset = 0,
    int limit = 20,
  }) async {
    final allMatches = await discoveryRepo.fetchMatches(userId);
    final total = allMatches.length;
    final end = (offset + limit).clamp(0, total);
    final items =
        offset < total ? allMatches.sublist(offset, end) : <CrushMatch>[];
    return PaginatedResult(
      items: items,
      total: total,
      hasMore: end < total,
    );
  }

  @override
  Future<MessageRequest?> sendMessageRequest({
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? toUserName,
    String? toUserPhotoUrl,
  }) async {
    final pairKey = _pairKey(fromUserId, toUserId);
    final existing = _messageRequestsByPair[pairKey];
    if (existing != null && !existing.isExpired) {
      return null;
    }
    final now = DateTime.now();
    final request = MessageRequest(
      id: pairKey,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: now,
      expiresAt: now.add(const Duration(hours: 48)),
      fromUserName: fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl,
      toUserName: toUserName,
      toUserPhotoUrl: toUserPhotoUrl,
    );
    _messageRequestsByPair[pairKey] = request;
    return request;
  }

  @override
  Future<List<MessageRequest>> fetchMessageRequests(String userId) async {
    _pruneExpiredRequests();
    final requests = _messageRequestsByPair.values
        .where((r) => r.fromUserId == userId || r.toUserId == userId)
        .toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return requests;
  }

  @override
  Future<bool> hasPendingMessageRequest({
    required String userId,
    required String otherUserId,
  }) async {
    _pruneExpiredRequests();
    final pairKey = _pairKey(userId, otherUserId);
    final request = _messageRequestsByPair[pairKey];
    return request != null && !request.isExpired;
  }

  @override
  Future<int> migrateMessageRequestsForMatches({
    required String userId,
    required List<CrushMatch> matches,
  }) async {
    if (matches.isEmpty) return 0;
    _pruneExpiredRequests();
    var migrated = 0;

    for (final match in matches) {
      final pairKey = _pairKey(userId, match.otherUserId);
      final request = _messageRequestsByPair[pairKey];
      if (request == null || request.isExpired) continue;

      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        matchId: match.id,
        fromUserId: request.fromUserId,
        toUserId: request.toUserId,
        content: request.content,
        type: request.type,
        sentAt: request.sentAt,
        isRead: false,
        isDeletedForSender: false,
        reactions: const {},
      );

      final list = _messagesByMatch.putIfAbsent(match.id, () => []);
      list.add(message);
      _streams[match.id]?.add(List<Message>.from(list));
      _messageRequestsByPair.remove(pairKey);
      migrated++;
    }

    return migrated;
  }

  String _pairKey(String userA, String userB) {
    return userA.compareTo(userB) <= 0 ? '$userA|$userB' : '$userB|$userA';
  }

  void _pruneExpiredRequests() {
    final now = DateTime.now();
    _messageRequestsByPair.removeWhere(
      (_, request) => request.expiresAt.isBefore(now),
    );
  }

  /// Clean up all stream controllers
  void dispose() {
    for (final controller in _streams.values) {
      controller.close();
    }
    for (final controller in _typingStreams.values) {
      controller.close();
    }
    for (final controller in _presenceStreams.values) {
      controller.close();
    }
    for (final controller in _mediaStreams.values) {
      controller.close();
    }
  }

  // ── E2EE stubs (not supported in fake implementation) ───────────────

  @override
  bool get isE2eeEnabled => false;

  @override
  void setE2eeEnabled(bool enabled) {}

  @override
  bool isEncryptedContent(String content) => false;

  @override
  Future<Message> decryptMessage(Message message) async => message;
}
