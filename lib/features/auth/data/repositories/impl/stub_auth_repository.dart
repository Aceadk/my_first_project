import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import '../auth_repository.dart';

/// Mock implementation of AuthRepository with local storage.
/// This allows the app to function for development/demo without a backend.
/// Replace with your actual backend implementation when ready.
class StubAuthRepository implements AuthRepository {
  final _authStateController = StreamController<CrushUser?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();

  static const _usersKey = 'mock_users';
  static const _currentUserKey = 'mock_current_user_id';
  static const _mockOtpCode = '123456'; // Mock OTP for development

  CrushUser? _currentUser;

  // Store pending OTP verifications
  final Map<String, _PendingOtp> _pendingOtps = {};

  @override
  bool get isVerificationBypassEnabled => true;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => true;

  @override
  Future<void> bootstrapSession() async {
    // Try to restore session from secure storage
    final userId = await _secureStorage.read(key: _currentUserKey);
    CrushUser? user;
    if (userId != null) {
      user = await _getUserById(userId);
      if (user != null) {
        _currentUser = user;
      }
    }
    // Emit after a microtask to ensure stream subscription is ready
    Future.microtask(() {
      _authStateController.add(user);
    });
  }

  @override
  Stream<CrushUser?> authStateChanges() => _authStateController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE OTP AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Store pending OTP
    _pendingOtps[phoneNumber] = _PendingOtp(
      identifier: phoneNumber,
      code: _mockOtpCode,
      type: _OtpType.phone,
      createdAt: DateTime.now(),
    );

    // In a real app, this would send an SMS
    // For development, the OTP is always 123456
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final pending = _pendingOtps[phoneNumber];
    if (pending == null) {
      throw Exception('No OTP requested for this phone number');
    }

    if (otp != _mockOtpCode && otp != pending.code) {
      throw Exception('Invalid OTP code');
    }

    // Check if OTP is expired (5 minutes)
    if (DateTime.now().difference(pending.createdAt).inMinutes > 5) {
      _pendingOtps.remove(phoneNumber);
      throw Exception('OTP expired. Please request a new code.');
    }

    _pendingOtps.remove(phoneNumber);

    // Check if user exists or create new one
    var user = await _getUserByPhone(phoneNumber);
    user ??= await _createUser(
      phoneNumber: phoneNumber,
      isPhoneVerified: true,
    );

    await _setCurrentUser(user);
    return user;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL LINK AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailSignInLink(String email) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Store pending email verification
    _pendingOtps[email] = _PendingOtp(
      identifier: email,
      code: _mockOtpCode,
      type: _OtpType.emailLink,
      createdAt: DateTime.now(),
    );

    // In a real app, this would send an email with a magic link
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    // For mock, accept any link with the email
    var user = await _getUserByEmail(email);
    user ??= await _createUser(
      email: email,
      isEmailVerified: true,
    );

    await _setCurrentUser(user);
    return user;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL/PASSWORD AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final user = await _getUserByEmail(email);
    if (user == null) {
      throw Exception('No account found with this email');
    }

    // Check password (stored in secure storage)
    final storedPassword = await _secureStorage.read(key: 'pwd_${user.id}');
    if (storedPassword != password) {
      throw Exception('Incorrect password');
    }

    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Try to find user by email, username, or phone
    CrushUser? user = await _getUserByEmail(identifier);
    user ??= await _getUserByUsername(identifier);
    user ??= await _getUserByPhone(identifier);

    if (user == null) {
      throw Exception('No account found with this identifier');
    }

    // Check password
    final storedPassword = await _secureStorage.read(key: 'pwd_${user.id}');
    if (storedPassword != password) {
      throw Exception('Incorrect password');
    }

    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<CrushUser> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 120));

    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final email = 'apple_user_$uniqueId@privaterelay.appleid.com';
    final username = 'apple$uniqueId';

    final existing = await _getUserByEmail(email);
    final user = existing ??
        await _createUser(
          email: email,
          username: username,
          isEmailVerified: true,
        );

    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if email already exists
    final existingEmail = await _getUserByEmail(email);
    if (existingEmail != null) {
      throw Exception('An account with this email already exists');
    }

    // Check if username already exists
    final existingUsername = await _getUserByUsername(username);
    if (existingUsername != null) {
      throw Exception('This username is already taken');
    }

    // Create new user (auto-verified in stub mode for development testing)
    final user = await _createUser(
      email: email,
      username: username,
      isEmailVerified: true,
    );

    // Store password securely
    await _secureStorage.write(key: 'pwd_${user.id}', value: password);

    await _setCurrentUser(user);
    return user;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL OTP (for verification, password reset, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final key = '${identifier}_${purpose.value}';
    _pendingOtps[key] = _PendingOtp(
      identifier: identifier,
      code: _mockOtpCode,
      type: _OtpType.email,
      purpose: purpose,
      createdAt: DateTime.now(),
    );

    // In a real app, this would send an email with the OTP
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final key = '${identifier}_${purpose.value}';
    final pending = _pendingOtps[key];

    if (pending == null) {
      throw Exception('No OTP requested');
    }

    if (otp != _mockOtpCode && otp != pending.code) {
      throw Exception('Invalid OTP code');
    }

    if (DateTime.now().difference(pending.createdAt).inMinutes > 10) {
      _pendingOtps.remove(key);
      throw Exception('OTP expired');
    }

    _pendingOtps.remove(key);

    // Handle different purposes
    switch (purpose) {
      case EmailOtpPurpose.login:
        var user = await _getUserByEmail(identifier);
        user ??= await _getUserByUsername(identifier);
        if (user != null) {
          await _setCurrentUser(user);
          return user;
        }
        break;

      case EmailOtpPurpose.addEmail:
      case EmailOtpPurpose.changeEmail:
        if (_currentUser != null && newEmail != null) {
          final updatedUser = _currentUser!.copyWith(
            email: newEmail,
            isEmailVerified: true,
          );
          await _updateUser(updatedUser);
          return updatedUser;
        }
        break;

      case EmailOtpPurpose.resetPassword:
        // Password reset is handled separately
        break;

      case EmailOtpPurpose.newDevice:
      case EmailOtpPurpose.sensitiveAction:
        // Just verify, no action needed
        return _currentUser;
    }

    return _currentUser;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final user = await _getUserByEmail(email);
    if (user == null) {
      // Don't reveal if email exists for security
      return;
    }

    _pendingOtps['reset_$email'] = _PendingOtp(
      identifier: email,
      code: _mockOtpCode,
      type: _OtpType.passwordReset,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final pending = _pendingOtps['reset_$email'];
    if (pending == null) {
      throw Exception('No password reset requested');
    }

    if (otp != _mockOtpCode && otp != pending.code) {
      throw Exception('Invalid OTP code');
    }

    // Return a mock reset token
    final token = 'reset_token_${DateTime.now().millisecondsSinceEpoch}';

    // Store token for verification
    await _secureStorage.write(key: 'reset_token_$email', value: token);

    return token;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final storedToken = await _secureStorage.read(key: 'reset_token_$email');
    if (storedToken != resetToken) {
      throw Exception('Invalid reset token');
    }

    final user = await _getUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }

    // Update password
    await _secureStorage.write(key: 'pwd_${user.id}', value: newPassword);

    // Clean up
    await _secureStorage.delete(key: 'reset_token_$email');
    _pendingOtps.remove('reset_$email');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _secureStorage.delete(key: _currentUserKey);
    _authStateController.add(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailVerification() async {
    // Stub: simulate sending email verification
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<CrushUser?> checkEmailVerification() async {
    // Stub: always return verified user for testing
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isEmailVerified: true);
      _authStateController.add(_currentUser);
      return _currentUser;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL EXISTENCE CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isEmailRegistered(String email) async {
    final existingUser = await _getUserByEmail(email);
    return existingUser != null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return {};
    return Map<String, dynamic>.from(jsonDecode(usersJson));
  }

  Future<void> _saveAllUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<CrushUser?> _getUserById(String id) async {
    final users = await _getAllUsers();
    final userData = users[id];
    if (userData == null) return null;
    return _userFromJson(userData);
  }

  Future<CrushUser?> _getUserByEmail(String email) async {
    final users = await _getAllUsers();
    for (final userData in users.values) {
      if (userData['email']?.toString().toLowerCase() == email.toLowerCase()) {
        return _userFromJson(userData);
      }
    }
    return null;
  }

  Future<CrushUser?> _getUserByPhone(String phone) async {
    final users = await _getAllUsers();
    for (final userData in users.values) {
      if (userData['phoneNumber'] == phone) {
        return _userFromJson(userData);
      }
    }
    return null;
  }

  Future<CrushUser?> _getUserByUsername(String username) async {
    final users = await _getAllUsers();
    for (final userData in users.values) {
      if (userData['username']?.toString().toLowerCase() ==
          username.toLowerCase()) {
        return _userFromJson(userData);
      }
    }
    return null;
  }

  Future<CrushUser> _createUser({
    String? email,
    String? phoneNumber,
    String? username,
    bool isEmailVerified = false,
    bool isPhoneVerified = false,
  }) async {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final user = CrushUser(
      id: id,
      phoneNumber: phoneNumber ?? '',
      email: email,
      username: username,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
      profile: null,
    );

    final users = await _getAllUsers();
    users[id] = _userToJson(user);
    await _saveAllUsers(users);

    return user;
  }

  Future<void> _updateUser(CrushUser user) async {
    final users = await _getAllUsers();
    users[user.id] = _userToJson(user);
    await _saveAllUsers(users);

    if (_currentUser?.id == user.id) {
      _currentUser = user;
      _authStateController.add(user);
    }
  }

  Future<void> _setCurrentUser(CrushUser user) async {
    _currentUser = user;
    await _secureStorage.write(key: _currentUserKey, value: user.id);

    // Make sure user is saved
    final users = await _getAllUsers();
    users[user.id] = _userToJson(user);
    await _saveAllUsers(users);

    _authStateController.add(user);
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
        dateOfBirth:
            p['dateOfBirth'] != null ? DateTime.parse(p['dateOfBirth']) : null,
        lastNameChangeAt: p['lastNameChangeAt'] != null
            ? DateTime.parse(p['lastNameChangeAt'])
            : null,
        bio: p['bio'] ?? '',
        photoUrls: List<String>.from(p['photoUrls'] ?? []),
        videoUrls: List<String>.from(p['videoUrls'] ?? []),
        primaryPhotoIndex: p['primaryPhotoIndex'] ?? 0,
        interests: List<String>.from(p['interests'] ?? []),
        prompts: List<String>.from(p['prompts'] ?? []),
        country: p['country'] ?? '',
        city: p['city'] ?? '',
        livingIn: p['livingIn'],
        latitude: p['latitude']?.toDouble(),
        longitude: p['longitude']?.toDouble(),
        isVerified: p['isVerified'] ?? false,
        verificationBadge: p['verificationBadge'],
        heightCm: p['heightCm'],
        relationshipGoals: p['relationshipGoals'],
        languages: List<String>.from(p['languages'] ?? []),
        zodiacSign: p['zodiacSign'],
        educationLevel: p['educationLevel'],
        familyPlans: p['familyPlans'],
        personalityType: p['personalityType'],
        workout: p['workout'],
        socialMedia: p['socialMedia'],
        sleepingHabits: p['sleepingHabits'],
        smoking: p['smoking'],
        drinking: p['drinking'],
        diet: p['diet'],
        exercise: p['exercise'],
        pets: p['pets'],
        jobTitle: p['jobTitle'],
        company: p['company'],
        school: p['school'],
        favoriteSongs: List<String>.from(p['favoriteSongs'] ?? []),
        favoriteSinger: p['favoriteSinger'],
        preferences: DiscoveryPreferences(
          minAge: p['preferences']?['minAge'] ?? 18,
          maxAge: p['preferences']?['maxAge'] ?? 50,
          maxDistanceKm: (p['preferences']?['maxDistanceKm'] ?? 100).toDouble(),
          showMeGenders: List<String>.from(
              p['preferences']?['showMeGenders'] ?? ['male', 'female']),
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
      plan: json['plan'] == 'plus'
          ? SubscriptionPlan.plus
          : SubscriptionPlan.free,
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
        'lastNameChangeAt': p.lastNameChangeAt?.toIso8601String(),
        'bio': p.bio,
        'photoUrls': p.photoUrls,
        'videoUrls': p.videoUrls,
        'primaryPhotoIndex': p.primaryPhotoIndex,
        'interests': p.interests,
        // ignore: deprecated_member_use_from_same_package
        'prompts': p.prompts, // Keep for backwards compatibility
        'country': p.country,
        'city': p.city,
        'livingIn': p.livingIn,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'isVerified': p.isVerified,
        'verificationBadge': p.verificationBadge,
        'heightCm': p.heightCm,
        'relationshipGoals': p.relationshipGoals,
        'languages': p.languages,
        'zodiacSign': p.zodiacSign,
        'educationLevel': p.educationLevel,
        'familyPlans': p.familyPlans,
        'personalityType': p.personalityType,
        'workout': p.workout,
        'socialMedia': p.socialMedia,
        'sleepingHabits': p.sleepingHabits,
        'smoking': p.smoking,
        'drinking': p.drinking,
        'diet': p.diet,
        'exercise': p.exercise,
        'pets': p.pets,
        'jobTitle': p.jobTitle,
        'company': p.company,
        'school': p.school,
        'favoriteSongs': p.favoriteSongs,
        'favoriteSinger': p.favoriteSinger,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> schedulePhoneDeletion() async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (_currentUser != null && _currentUser!.phoneNumber.isNotEmpty) {
      // In stub, we just clear the phone immediately for testing
      _currentUser = _currentUser!.copyWith(phoneNumber: '');
      await _updateUser(_currentUser!);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Verify current password
    final storedPassword =
        await _secureStorage.read(key: 'pwd_${_currentUser!.id}');
    if (storedPassword != currentPassword) {
      throw Exception('Current password is incorrect');
    }

    // Update password
    await _secureStorage.write(
        key: 'pwd_${_currentUser!.id}', value: newPassword);
  }

  @override
  Future<void> deactivateAccount({required String reason}) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // In stub, just sign out (real app would hide profile but preserve data)
    await signOut();
  }

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Verify password
    final storedPassword =
        await _secureStorage.read(key: 'pwd_${_currentUser!.id}');
    if (storedPassword != null && storedPassword != password) {
      throw Exception('Password is incorrect');
    }

    // Remove user data
    final userId = _currentUser!.id;
    final users = await _getAllUsers();
    users.remove(userId);
    await _saveAllUsers(users);

    // Clean up password
    await _secureStorage.delete(key: 'pwd_$userId');

    await signOut();
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Try to restore user from storage if not in memory
    if (_currentUser == null) {
      final userId = await _secureStorage.read(key: _currentUserKey);
      if (userId != null) {
        final user = await _getUserById(userId);
        if (user != null) {
          _currentUser = user;
        }
      }
    }

    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    _currentUser = _currentUser!.copyWith(hasAcceptedTerms: true);
    await _updateUser(_currentUser!);
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async {
    final userId = await _secureStorage.read(key: _currentUserKey);
    if (userId == null) return null;

    final user = await _getUserById(userId);
    if (user != null) {
      _currentUser = user;
      _authStateController.add(user);
    }
    return user;
  }

  void dispose() {
    _authStateController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

enum _OtpType { phone, email, emailLink, passwordReset }

class _PendingOtp {
  final String identifier;
  final String code;
  final _OtpType type;
  final EmailOtpPurpose? purpose;
  final DateTime createdAt;

  _PendingOtp({
    required this.identifier,
    required this.code,
    required this.type,
    this.purpose,
    required this.createdAt,
  });
}
