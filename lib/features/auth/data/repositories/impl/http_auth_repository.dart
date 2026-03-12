import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/network/dto/auth_dto.dart';
import 'package:crushhour/core/network/mappers/auth_mapper.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../auth_repository.dart';

/// HTTP-based implementation of AuthRepository.
///
/// Uses REST API for authentication operations with secure token storage.
class HttpAuthRepository implements AuthRepository, GoogleSignInAuthRepository {
  HttpAuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _apiClient =
           apiClient ??
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
  bool get supportsAppleSignIn =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  bool get supportsGoogleSignIn => true;

  bool _isGoogleSignInInitialized = false;

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
        result.error?.message ?? 'Failed to sign in with email link',
      );
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
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device.');
      }

      // PKCE: Generate code_verifier and code_challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _sha256Base64Url(codeVerifier);

      // Generate nonce for replay-attack protection
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple Sign-In failed. Missing identity token.');
      }

      // Send to backend with PKCE parameters
      final result = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.authOAuthApple,
        body: {
          'id_token': idToken,
          'authorization_code': appleCredential.authorizationCode,
          'nonce': rawNonce,
          'code_verifier': codeVerifier,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          if (appleCredential.givenName != null)
            'given_name': appleCredential.givenName,
          if (appleCredential.familyName != null)
            'family_name': appleCredential.familyName,
          if (appleCredential.email != null) 'email': appleCredential.email,
        },
        requiresAuth: false,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (result.isFailure) {
        throw Exception(
          result.error?.message ?? 'Apple Sign-In failed on server.',
        );
      }

      final response = VerifyOtpResponseDto.fromJson(result.data!);
      if (!response.success ||
          response.user == null ||
          response.tokens == null) {
        throw Exception(response.message ?? 'Apple Sign-In failed.');
      }

      await _storeTokens(response.tokens!);
      _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
      _emitAuthState(_currentUser);
      return _currentUser!;
    } catch (e) {
      AppLogger.error('[HttpAuthRepo] Apple sign-in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<CrushUser> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // PKCE: Generate code_verifier and code_challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _sha256Base64Url(codeVerifier);

      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );

      final idToken = googleUser.authentication.idToken;
      String? accessToken;
      if (idToken == null || idToken.isEmpty) {
        final existingAuth = await googleUser.authorizationClient
            .authorizationForScopes(const <String>['email', 'profile']);
        accessToken = existingAuth?.accessToken;

        if (accessToken == null || accessToken.isEmpty) {
          final promptedAuth = await googleUser.authorizationClient
              .authorizeScopes(const <String>['email', 'profile']);
          accessToken = promptedAuth.accessToken;
        }
      }

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Google Sign-In failed. Missing auth tokens.');
      }

      // Send to backend with PKCE parameters
      final result = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.authOAuthGoogle,
        body: {
          if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
          if (accessToken != null && accessToken.isNotEmpty)
            'access_token': accessToken,
          'code_verifier': codeVerifier,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
        requiresAuth: false,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (result.isFailure) {
        throw Exception(
          result.error?.message ?? 'Google Sign-In failed on server.',
        );
      }

      final response = VerifyOtpResponseDto.fromJson(result.data!);
      if (!response.success ||
          response.user == null ||
          response.tokens == null) {
        throw Exception(response.message ?? 'Google Sign-In failed.');
      }

      await _storeTokens(response.tokens!);
      _currentUser = AuthMapper.userFromVerifyOtpResponse(response);
      _emitAuthState(_currentUser);
      return _currentUser!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google Sign-In was cancelled.');
      }
      AppLogger.error('[HttpAuthRepo] Google sign-in failed', error: e);
      throw Exception(e.description ?? 'Google Sign-In failed.');
    } catch (e) {
      AppLogger.error('[HttpAuthRepo] Google sign-in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/signup',
      body: {'username': username, 'email': email, 'password': password},
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
      final userDto = UserDto.fromJson(
        result.data!['user'] as Map<String, dynamic>,
      );
      _currentUser = AuthMapper.userFromDto(userDto, tier: _currentUser?.tier);
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
        result.error?.message ?? 'Failed to request password reset',
      );
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
        result.error?.message ?? 'Failed to verify password reset OTP',
      );
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
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/auth/check-email-verification',
    );
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
      key: _refreshTokenKey,
      value: tokens.refreshToken,
    );
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
        result.error?.message ?? 'Failed to schedule phone deletion',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _apiClient.post<void>(
      '/auth/password/change',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Failed to change password');
    }
  }

  @override
  Future<void> verifyPassword(String password) async {
    final result = await _apiClient.post<void>(
      '/auth/password/verify',
      body: {'password': password},
    );

    if (result.isFailure) {
      throw Exception(result.error?.message ?? 'Incorrect password');
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
      body: {'password': password, 'reason': reason},
    );

    if (result.isFailure) {
      throw Exception(
        result.error?.message ?? 'Failed to schedule account deletion',
      );
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
    return _guardAuthResult(
      () => signInWithEmailPassword(email: email, password: password),
      logLabel: 'HttpAuthRepository.signInWithEmailPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
      fallbackType: AuthFailureType.invalidCredentials,
    );
  }

  Future<Result<CrushUser>> loginWithPasswordResult({
    required String identifier,
    required String password,
  }) {
    return _guardAuthResult(
      () => loginWithPassword(identifier: identifier, password: password),
      logLabel: 'HttpAuthRepository.loginWithPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
      fallbackType: AuthFailureType.invalidCredentials,
    );
  }

  Future<Result<CrushUser>> signUpWithPasswordResult({
    required String username,
    required String email,
    required String password,
  }) {
    return _guardAuthResult(
      () => signUpWithPassword(
        username: username,
        email: email,
        password: password,
      ),
      logLabel: 'HttpAuthRepository.signUpWithPasswordResult',
      fallbackError: 'Unable to create account. Please try again.',
      fallbackType: AuthFailureType.unknown,
    );
  }

  Future<Result<void>> signOutResult() {
    return _guardAuthResult(
      () => signOut(),
      logLabel: 'HttpAuthRepository.signOutResult',
      fallbackError: 'Unable to sign out. Please try again.',
      fallbackType: AuthFailureType.sessionMissing,
    );
  }

  Future<Result<CrushUser>> signInWithAppleResult() {
    return _guardAuthResult(
      () => signInWithApple(),
      logLabel: 'HttpAuthRepository.signInWithAppleResult',
      fallbackError: 'Apple Sign-In failed. Please try again.',
      fallbackType: AuthFailureType.unsupportedProvider,
    );
  }

  Future<Result<CrushUser>> signInWithGoogleResult() {
    return _guardAuthResult(
      () => signInWithGoogle(),
      logLabel: 'HttpAuthRepository.signInWithGoogleResult',
      fallbackError: 'Google Sign-In failed. Please try again.',
      fallbackType: AuthFailureType.unsupportedProvider,
    );
  }

  Future<Result<T>> _guardAuthResult<T>(
    Future<T> Function() run, {
    required String logLabel,
    required String fallbackError,
    required AuthFailureType fallbackType,
  }) {
    return Result.guard(
      () async {
        try {
          return await run();
        } catch (error) {
          throw AuthFailureMapper.from(
            error,
            fallbackType: fallbackType,
            fallbackMessage: fallbackError,
          );
        }
      },
      logLabel: logLabel,
      fallbackError: fallbackError,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PKCE & OAUTH HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _isGoogleSignInInitialized = true;
  }

  /// Generate a cryptographically random PKCE code_verifier (43–128 chars).
  static String _generateCodeVerifier([int length = 64]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// S256 code_challenge = BASE64URL(SHA256(code_verifier)).
  static String _sha256Base64Url(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generate a random nonce for replay-attack protection.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA-256 hash of a string, returned as hex.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Dispose resources.
  void dispose() {
    _authStateController.close();
  }
}
