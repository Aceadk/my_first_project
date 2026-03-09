import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/validators.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';

/// Domain-level facade for auth flow operations that mutate auth/session state.
///
/// This keeps repository orchestration and input normalization out of UI code.
class AuthFlowUseCases {
  AuthFlowUseCases(this._authRepository);

  final AuthRepository _authRepository;

  bool get isVerificationBypassEnabled =>
      _authRepository.isVerificationBypassEnabled;
  bool get supportsUsernameLogin => _authRepository.supportsUsernameLogin;
  bool get supportsGoogleSignIn => _authRepository.supportsGoogleSignIn;
  bool get supportsAppleSignIn => _authRepository.supportsAppleSignIn;

  Stream<CrushUser?> authStateChanges() => _authRepository.authStateChanges();

  Future<Result<void>> bootstrapSession() {
    return _guardWithMappedFailure(
      () => _authRepository.bootstrapSession(),
      logLabel: 'AuthFlowUseCases.bootstrapSession',
      fallbackType: AuthFailureType.sessionMissing,
      fallbackError: 'Could not connect to authentication. Please try again.',
    );
  }

  Future<Result<void>> sendOtp({required String phoneNumber}) {
    return _guardWithMappedFailure(
      () => _authRepository.sendOtp(phoneNumber.trim()),
      logLabel: 'AuthFlowUseCases.sendOtp',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not send code. Please try again.',
    );
  }

  Future<Result<CrushUser>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.verifyOtp(
        phoneNumber: phoneNumber.trim(),
        otp: otp.trim(),
      ),
      logLabel: 'AuthFlowUseCases.verifyOtp',
      fallbackType: AuthFailureType.invalidOtp,
      fallbackError: 'Invalid code. Please try again.',
    );
  }

  Future<Result<void>> sendEmailSignInLink({required String email}) {
    return _guardWithMappedFailure(
      () => _authRepository.sendEmailSignInLink(normalizeEmail(email)),
      logLabel: 'AuthFlowUseCases.sendEmailSignInLink',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not send sign-in link. Please try again.',
    );
  }

  Future<Result<CrushUser>> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.signInWithEmailLink(
        email: normalizeEmail(email),
        emailLink: emailLink,
      ),
      logLabel: 'AuthFlowUseCases.signInWithEmailLink',
      fallbackType: AuthFailureType.invalidEmailLink,
      fallbackError: 'Invalid or expired email link.',
    );
  }

  Future<Result<CrushUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.signInWithEmailPassword(
        email: normalizeEmail(email),
        password: password,
      ),
      logLabel: 'AuthFlowUseCases.signInWithEmailPassword',
      fallbackType: AuthFailureType.invalidCredentials,
      fallbackError: 'Could not sign in. Please try again.',
    );
  }

  Future<Result<void>> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.requestEmailOtp(
        identifier: identifier.trim(),
        purpose: purpose,
        email: email == null ? null : normalizeEmail(email),
      ),
      logLabel: 'AuthFlowUseCases.requestEmailOtp',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not send code. Please try again.',
    );
  }

  Future<Result<CrushUser?>> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.verifyEmailOtp(
        identifier: identifier.trim(),
        otp: otp.trim(),
        purpose: purpose,
        newEmail: newEmail == null ? null : normalizeEmail(newEmail),
        newPassword: newPassword,
      ),
      logLabel: 'AuthFlowUseCases.verifyEmailOtp',
      fallbackType: AuthFailureType.invalidOtp,
      fallbackError: 'Invalid or expired code. Please try again.',
    );
  }

  Future<Result<CrushUser>> loginWithPassword({
    required String identifier,
    required String password,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.loginWithPassword(
        identifier: _normalizeLoginIdentifier(identifier),
        password: password,
      ),
      logLabel: 'AuthFlowUseCases.loginWithPassword',
      fallbackType: AuthFailureType.invalidCredentials,
      fallbackError: 'Invalid credentials. Please try again.',
    );
  }

  Future<Result<CrushUser>> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) {
    return _guardWithMappedFailure(
      () => _authRepository.signUpWithPassword(
        username: username.trim(),
        email: normalizeEmail(email),
        password: password,
      ),
      logLabel: 'AuthFlowUseCases.signUpWithPassword',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not create account. Please try again.',
    );
  }

  Future<Result<CrushUser>> signInWithGoogle() {
    return _guardWithMappedFailure(
      () => _authRepository.signInWithGoogle(),
      logLabel: 'AuthFlowUseCases.signInWithGoogle',
      fallbackType: AuthFailureType.unsupportedProvider,
      fallbackError: 'Google Sign-In failed. Please try again.',
    );
  }

  Future<Result<CrushUser>> signInWithApple() {
    return _guardWithMappedFailure(
      () => _authRepository.signInWithApple(),
      logLabel: 'AuthFlowUseCases.signInWithApple',
      fallbackType: AuthFailureType.unsupportedProvider,
      fallbackError: 'Apple Sign-In failed. Please try again.',
    );
  }

  Future<Result<void>> sendEmailVerification() {
    return _guardWithMappedFailure(
      () => _authRepository.sendEmailVerification(),
      logLabel: 'AuthFlowUseCases.sendEmailVerification',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not send verification email. Please try again.',
    );
  }

  Future<Result<CrushUser?>> checkEmailVerification() {
    return _guardWithMappedFailure(
      () => _authRepository.checkEmailVerification(),
      logLabel: 'AuthFlowUseCases.checkEmailVerification',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not check email verification status.',
    );
  }

  Future<Result<bool>> isEmailRegistered(String email) {
    return _guardWithMappedFailure(
      () => _authRepository.isEmailRegistered(normalizeEmail(email)),
      logLabel: 'AuthFlowUseCases.isEmailRegistered',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not validate email availability. Please try again.',
    );
  }

  Future<Result<CrushUser>> acceptTermsAndConditions() {
    return _guardWithMappedFailure(
      () => _authRepository.acceptTermsAndConditions(),
      logLabel: 'AuthFlowUseCases.acceptTermsAndConditions',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not save your acceptance. Please try again.',
    );
  }

  Future<Result<CrushUser?>> refreshCurrentUser() {
    return _guardWithMappedFailure(
      () => _authRepository.refreshCurrentUser(),
      logLabel: 'AuthFlowUseCases.refreshCurrentUser',
      fallbackType: AuthFailureType.sessionMissing,
      fallbackError: 'Could not refresh your account. Please try again.',
    );
  }

  Future<Result<void>> signOut() {
    return _guardWithMappedFailure(
      () => _authRepository.signOut(),
      logLabel: 'AuthFlowUseCases.signOut',
      fallbackType: AuthFailureType.sessionMissing,
      fallbackError: 'Could not sign out. Try again.',
    );
  }

  Future<Result<void>> requestPasswordReset({required String email}) {
    return _guardWithMappedFailure(
      () => _authRepository.requestPasswordReset(email: normalizeEmail(email)),
      logLabel: 'AuthFlowUseCases.requestPasswordReset',
      fallbackType: AuthFailureType.unknown,
      fallbackError: 'Could not send reset instructions. Please try again.',
    );
  }

  String _normalizeLoginIdentifier(String identifier) {
    final trimmed = identifier.trim();
    if (!supportsUsernameLogin || trimmed.contains('@')) {
      return normalizeEmail(trimmed);
    }
    return trimmed;
  }

  Future<Result<T>> _guardWithMappedFailure<T>(
    Future<T> Function() run, {
    required String logLabel,
    required AuthFailureType fallbackType,
    required String fallbackError,
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
}
