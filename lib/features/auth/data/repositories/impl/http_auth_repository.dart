import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/network/api_client.dart';
import 'package:crushhour/core/network/api_version.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'apple_sign_in_failure_mapper.dart';
import 'auth_secure_storage.dart';
import 'google_sign_in_failure_mapper.dart';
import 'http_auth_session_bridge.dart';
import '../auth_repository.dart';

/// HTTP-oriented implementation of AuthRepository.
///
/// Uses Firebase session bridging for auth state and bearer tokens, Cloud
/// Functions callables for backend-managed auth flows, and the remaining live
/// REST endpoints for API-mode account operations.
class HttpAuthRepository implements AuthRepository, GoogleSignInAuthRepository {
  HttpAuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
    FirebaseFunctions? functions,
    HttpAuthSessionBridge? sessionBridge,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> payload,
    )?
    callableInvoker,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             config: ApiConfig.production,
             authTokenProvider: null, // Set after initialization
           ),
       _functions = functions,
       _authStorage = AuthSecureStorage(
         secureStorage: secureStorage,
         logPrefix: 'HttpAuthRepo',
       ),
       _sessionBridge =
           sessionBridge ??
           FirebaseHttpAuthSessionBridge(
             functions: functions,
             secureStorage: secureStorage,
           ),
       _callableInvoker = callableInvoker {
    _bridgeSubscription = _sessionBridge.authStateChanges().listen((user) {
      _currentUser = user;
      _emitAuthState(user);
    });
  }

  final ApiClient _apiClient;
  final FirebaseFunctions? _functions;
  final AuthSecureStorage _authStorage;
  final HttpAuthSessionBridge _sessionBridge;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> payload,
  )?
  _callableInvoker;

  // Legacy storage keys retained only for cleanup/migration.
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';

  // State
  CrushUser? _currentUser;
  final _authStateController = StreamController<CrushUser?>.broadcast();
  StreamSubscription<CrushUser?>? _bridgeSubscription;

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

  @override
  Stream<CrushUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> bootstrapSession() async {
    try {
      final user = await _sessionBridge.refreshCurrentUser();
      if (user == null) {
        await _clearTokens();
        _currentUser = null;
        _emitAuthState(null);
        return;
      }
      _currentUser = user;
      _emitAuthState(user);
    } catch (e) {
      AppLogger.error('HttpAuthRepository: Bootstrap failed - $e');
      _emitAuthState(null);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendOtp(String phoneNumber) =>
      _sessionBridge.sendOtp(phoneNumber);

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) => _sessionBridge.verifyOtp(phoneNumber: phoneNumber, otp: otp);

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailSignInLink(String email) {
    return _sessionBridge.sendEmailSignInLink(email);
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) => _sessionBridge.signInWithEmailLink(email: email, emailLink: emailLink);

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
    final result = await _invokeAuthCallable(
      'loginWithPassword',
      <String, dynamic>{'identifier': identifier, 'password': password},
    );
    return _completeCustomTokenSignIn(result, fallbackError: 'Login failed');
  }

  @override
  Future<CrushUser> signInWithApple() async {
    try {
      return await _sessionBridge.signInWithApple();
    } catch (error, stackTrace) {
      final mappedFailure = mapAppleSignInFailure(error);
      AppLogger.error(
        '[HttpAuthRepo] Apple sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw mappedFailure;
    }
  }

  @override
  Future<CrushUser> signInWithGoogle() async {
    try {
      return await _sessionBridge.signInWithGoogle();
    } catch (error, stackTrace) {
      final mappedFailure = mapGoogleSignInFailure(error);
      AppLogger.error(
        '[HttpAuthRepo] Google sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw mappedFailure;
    }
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _invokeAuthCallable(
      'signUpWithPassword',
      <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return _completeCustomTokenSignIn(result, fallbackError: 'Sign up failed');
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
    await _invokeAuthCallable('requestEmailOtp', <String, dynamic>{
      'identifier': identifier,
      'purpose': purpose.value,
      'email': ?email,
    });
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    final result =
        await _invokeAuthCallable('verifyEmailOtp', <String, dynamic>{
          'identifier': identifier,
          'otp': otp,
          'purpose': purpose.value,
          'newEmail': ?newEmail,
          'newPassword': ?newPassword,
        });

    final customToken = _extractCustomToken(result);
    if (customToken != null && customToken.isNotEmpty) {
      return _completeCustomTokenSignIn(
        result,
        fallbackError: 'Failed to verify email OTP',
      );
    }

    return _sessionBridge.refreshCurrentUser();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await _invokeAuthCallable('requestPasswordReset', <String, dynamic>{
      'email': email,
    });
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _invokeAuthCallable(
      'verifyPasswordResetOtp',
      <String, dynamic>{'email': email, 'otp': otp},
    );

    final resetToken =
        result['resetToken'] as String? ?? result['reset_token'] as String?;
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
    await _invokeAuthCallable('resetPasswordWithToken', <String, dynamic>{
      'email': email,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
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

    await _sessionBridge.signOut();
    await _clearTokens();
    _currentUser = null;
    _emitAuthState(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailVerification() =>
      _sessionBridge.sendEmailVerification();

  @override
  Future<CrushUser?> checkEmailVerification() {
    return _sessionBridge.checkEmailVerification();
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

  Future<void> _clearTokens() async {
    await _authStorage.delete(_accessTokenKey);
    await _authStorage.delete(_refreshTokenKey);
    await _authStorage.delete(_userIdKey);
  }

  /// Get current access token (for API client).
  Future<String?> getAccessToken() async {
    return _sessionBridge.getIdToken();
  }

  /// Refresh the access token.
  Future<bool> refreshToken() async {
    final refreshedToken = await _sessionBridge.getIdToken(forceRefresh: true);
    return refreshedToken != null && refreshedToken.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> schedulePhoneDeletion() =>
      _sessionBridge.schedulePhoneDeletion();

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
    final identifier =
        _currentUser?.email?.trim() ?? _currentUser?.username?.trim() ?? '';
    if (identifier.isEmpty) {
      throw Exception(
        'No password-based sign-in is configured for this account',
      );
    }

    await _invokeAuthCallable('loginWithPassword', <String, dynamic>{
      'identifier': identifier,
      'password': password,
    });
  }

  @override
  Future<void> deactivateAccount({required String reason}) {
    return _sessionBridge.deactivateAccount(reason: reason);
  }

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {
    await verifyPassword(password);
    await _invokeAuthCallable('requestAccountDeletion', <String, dynamic>{
      'reason': reason,
    });
    await signOut();
  }

  void _emitAuthState(CrushUser? user) {
    _authStateController.add(user);
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() {
    return _sessionBridge.acceptTermsAndConditions();
  }

  @override
  Future<CrushUser?> refreshCurrentUser() =>
      _sessionBridge.refreshCurrentUser();

  Future<Map<String, dynamic>> _invokeAuthCallable(
    String name,
    Map<String, dynamic> payload,
  ) async {
    if (_callableInvoker != null) {
      return _callableInvoker(name, payload);
    }

    final functions = _functions;
    if (functions == null) {
      throw Exception(
        'No callable transport configured for auth request $name',
      );
    }

    try {
      final callable = functions.httpsCallable(name);
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      AppLogger.error('[HttpAuthRepo] Callable $name failed', error: error);
      throw Exception(error.message ?? 'Authentication request failed');
    }
  }

  String? _extractCustomToken(Map<String, dynamic> data) {
    return data['customToken'] as String? ??
        data['custom_token'] as String? ??
        data['access_token'] as String?;
  }

  Future<CrushUser> _completeCustomTokenSignIn(
    Map<String, dynamic> data, {
    required String fallbackError,
  }) async {
    final customToken = _extractCustomToken(data);
    if (customToken == null || customToken.isEmpty) {
      throw Exception(fallbackError);
    }

    await _sessionBridge.signInWithCustomToken(customToken);

    final refreshedUser = await _sessionBridge.refreshCurrentUser();
    if (refreshedUser != null) {
      _currentUser = refreshedUser;
      _emitAuthState(refreshedUser);
      return refreshedUser;
    }

    final mirroredUser = _currentUser;
    if (mirroredUser != null) {
      return mirroredUser;
    }

    throw Exception(fallbackError);
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

  /// Dispose resources.
  void dispose() {
    _bridgeSubscription?.cancel();
    _sessionBridge.dispose();
    _authStateController.close();
  }
}
