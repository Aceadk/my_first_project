import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:crushhour/core/network/mappers/auth_mapper.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import '../auth_repository.dart';

/// HTTP-based implementation of AuthRepository.
///
/// Uses REST API for authentication operations with secure token storage.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient ??
            ApiClient(
              config: ApiConfig.production,
              authTokenProvider: null, // Set after initialization
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';

  // State
  CrushUser? _currentUser;
  String? _pendingVerificationId;
  final _authStateController = StreamController<CrushUser?>.broadcast();

  @override
  bool get isVerificationBypassEnabled => kDebugMode;

  @override
  bool get supportsUsernameLogin => true;

  @override
  bool get supportsAppleSignIn => false;

  @override
  Stream<CrushUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> bootstrapSession() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if (accessToken == null) {
        _emitAuthState(null);
        return;
      }

      // Validate token by fetching current user
      final result = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profileMe,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (result.isSuccess && result.data != null) {
        final userDto = UserDto.fromJson(result.data!);
        _currentUser = AuthMapper.userFromDto(userDto);
        _emitAuthState(_currentUser);
      } else {
        // Token invalid, clear storage
        await _clearTokens();
        _emitAuthState(null);
      }
    } catch (e) {
      AppLogger.error('HttpAuthRepository: Bootstrap failed - $e');
      _emitAuthState(null);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendOtp(String phoneNumber) async {
    final request = SendOtpRequestDto(phoneNumber: phoneNumber);

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authSendOtp,
      dto: request,
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to send OTP');
    }

    final response = SendOtpResponseDto.fromJson(result.data!);
    _pendingVerificationId = response.verificationId;
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final request = VerifyOtpRequestDto(
      phoneNumber: phoneNumber,
      otp: otp,
      verificationId: _pendingVerificationId,
    );

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authVerifyOtp,
      dto: request,
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to verify OTP');
    }

    final response = VerifyOtpResponseDto.fromJson(result.data!);

    if (!response.success || response.user == null || response.tokens == null) {
      throw Exception(response.message ?? 'Verification failed');
    }

    // Store tokens
    await _storeTokens(response.tokens!);

    // Create user
    _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
    _emitAuthState(_currentUser);
    _pendingVerificationId = null;

    return _currentUser!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailSignInLink(String email) async {
    final result = await _apiClient.post<void>(
      '/auth/email/send-link',
      body: {'email': email},
      requiresAuth: false,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to send sign-in link');
    }
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/email/verify-link',
      body: {'email': email, 'link': emailLink},
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to sign in with email link');
    }

    final response = VerifyOtpResponseDto.fromJson(result.data!);

    if (!response.success || response.user == null || response.tokens == null) {
      throw Exception(response.message ?? 'Sign in failed');
    }

    await _storeTokens(response.tokens!);
    _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
    _emitAuthState(_currentUser);

    return _currentUser!;
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
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Login failed');
    }

    final response = VerifyOtpResponseDto.fromJson(result.data!);

    if (!response.success || response.user == null || response.tokens == null) {
      throw Exception(response.message ?? 'Login failed');
    }

    await _storeTokens(response.tokens!);
    _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
    _emitAuthState(_currentUser);

    return _currentUser!;
  }

  @override
  Future<CrushUser> signInWithApple() async {
    throw UnimplementedError(
      'Apple Sign-In is not supported for the HTTP backend yet.',
    );
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/signup',
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Sign up failed');
    }

    final response = VerifyOtpResponseDto.fromJson(result.data!);

    if (!response.success || response.user == null || response.tokens == null) {
      throw Exception(response.message ?? 'Sign up failed');
    }

    await _storeTokens(response.tokens!);
    _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
    _emitAuthState(_currentUser);

    return _currentUser!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL OTP
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    final result = await _apiClient.post<void>(
      '/auth/email-otp/send',
      body: {
        'identifier': identifier,
        'purpose': purpose.value,
        'email': ?email,
      },
      requiresAuth: purpose != EmailOtpPurpose.login,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to send email OTP');
    }
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/email-otp/verify',
      body: {
        'identifier': identifier,
        'otp': otp,
        'purpose': purpose.value,
        'new_email': ?newEmail,
        'new_password': ?newPassword,
      },
      requiresAuth: purpose != EmailOtpPurpose.login,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to verify email OTP');
    }

    // For login purpose, we get tokens back
    if (purpose == EmailOtpPurpose.login) {
      final response = VerifyOtpResponseDto.fromJson(result.data!);

      if (response.user != null && response.tokens != null) {
        await _storeTokens(response.tokens!);
        _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
        _emitAuthState(_currentUser);
        return _currentUser;
      }
    }

    // For other purposes, update current user if needed
    if (result.data?['user'] != null) {
      final userDto =
          UserDto.fromJson(result.data!['user'] as Map<String, dynamic>);
      _currentUser = AuthMapper.userFromDto(userDto, plan: _currentUser?.plan);
      _emitAuthState(_currentUser);
      return _currentUser;
    }

    return _currentUser;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final result = await _apiClient.post<void>(
      '/auth/password-reset/request',
      body: {'email': email},
      requiresAuth: false,
    );

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to request password reset');
    }
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/password-reset/verify',
      body: {'email': email, 'otp': otp},
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to verify password reset OTP');
    }

    final resetToken = result.data?['reset_token'] as String?;
    if (resetToken == null) {
      throw Exception('Reset token not received');
    }

    return resetToken;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final result = await _apiClient.post<void>(
      '/auth/password-reset/confirm',
      body: {
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      requiresAuth: false,
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to reset password');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> signOut() async {
    try {
      await _apiClient.post<void>(ApiEndpoints.authLogout);
    } catch (e) {
      AppLogger.error('HttpAuthRepository: Logout API call failed - $e');
    }

    await _clearTokens();
    _currentUser = null;
    _emitAuthState(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailVerification() async {
    await _apiClient.post<void>('/auth/send-email-verification');
  }

  @override
  Future<CrushUser?> checkEmailVerification() async {
    final result = await _apiClient
        .get<Map<String, dynamic>>('/auth/check-email-verification');
    if (result.isSuccess && result.data != null) {
      final verified = result.data!['email_verified'] as bool? ?? false;
      if (verified && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        _emitAuthState(_currentUser);
        return _currentUser;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL EXISTENCE CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isEmailRegistered(String email) async {
    // HTTP API doesn't have a dedicated check endpoint.
    // The signup endpoint will return an error if email already exists.
    // Return false to allow the signup flow to proceed and handle the error.
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _storeTokens(AuthTokensDto tokens) async {
    await _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _secureStorage.write(
        key: _refreshTokenKey, value: tokens.refreshToken);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  /// Get current access token (for API client).
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Refresh the access token.
  Future<bool> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    final request = RefreshTokenRequestDto(refreshToken: refreshToken);

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authRefreshToken,
      dto: request,
      requiresAuth: false,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      final tokens = AuthTokensDto.fromJson(result.data!);
      await _storeTokens(tokens);
      return true;
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> schedulePhoneDeletion() async {
    final result = await _apiClient.post<void>('/auth/phone/schedule-deletion');

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to schedule phone deletion');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _apiClient.post<void>(
      '/auth/password/change',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to change password');
    }
  }

  @override
  Future<void> deactivateAccount({required String reason}) async {
    final result = await _apiClient.post<void>(
      '/auth/account/deactivate',
      body: {'reason': reason},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to deactivate account');
    }

    await _clearTokens();
    _currentUser = null;
    _emitAuthState(null);
  }

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {
    final result = await _apiClient.post<void>(
      '/auth/account/delete',
      body: {
        'password': password,
        'reason': reason,
      },
    );

    if (result.isFailure) {
      throw Exception(
          result.error?.message ?? 'Failed to schedule account deletion');
    }

    await _clearTokens();
    _currentUser = null;
    _emitAuthState(null);
  }

  void _emitAuthState(CrushUser? user) {
    _authStateController.add(user);
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/accept-terms',
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to accept terms');
    }

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(hasAcceptedTerms: true);
      _emitAuthState(_currentUser);
      return _currentUser!;
    }

    throw Exception('No user logged in');
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.profileMe,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (result.isSuccess && result.data != null) {
      final userDto = UserDto.fromJson(result.data!);
      _currentUser = AuthMapper.userFromDto(userDto);
      _emitAuthState(_currentUser);
      return _currentUser;
    }

    return _currentUser;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT-RETURNING METHODS (CR-AUD-035)
  //
  // These methods return Result<T> instead of throwing exceptions, making
  // error handling explicit at the call site. They wrap the existing throwing
  // methods so both APIs can coexist during incremental migration.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Result<CrushUser>> signInWithEmailPasswordResult({
    required String email,
    required String password,
  }) {
    return Result.guard(
      () => signInWithEmailPassword(email: email, password: password),
      logLabel: 'HttpAuthRepository.signInWithEmailPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
    );
  }

  Future<Result<CrushUser>> loginWithPasswordResult({
    required String identifier,
    required String password,
  }) {
    return Result.guard(
      () => loginWithPassword(identifier: identifier, password: password),
      logLabel: 'HttpAuthRepository.loginWithPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
    );
  }

  Future<Result<CrushUser>> signUpWithPasswordResult({
    required String username,
    required String email,
    required String password,
  }) {
    return Result.guard(
      () => signUpWithPassword(
        username: username,
        email: email,
        password: password,
      ),
      logLabel: 'HttpAuthRepository.signUpWithPasswordResult',
      fallbackError: 'Unable to create account. Please try again.',
    );
  }

  Future<Result<void>> signOutResult() {
    return Result.guard(
      () => signOut(),
      logLabel: 'HttpAuthRepository.signOutResult',
      fallbackError: 'Unable to sign out. Please try again.',
    );
  }

  Future<Result<CrushUser>> signInWithAppleResult() {
    return Result.guard(
      () => signInWithApple(),
      logLabel: 'HttpAuthRepository.signInWithAppleResult',
      fallbackError: 'Apple Sign-In failed. Please try again.',
    );
  }

  /// Dispose resources.
  void dispose() {
    _authStateController.close();
  }
}
