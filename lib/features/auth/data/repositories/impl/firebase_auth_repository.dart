import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/subscription.dart';
import '../auth_repository.dart';
import 'package:crushhour/core/services/email_service.dart';
import 'package:crushhour/core/security/secure_logger.dart';

/// Firebase implementation of AuthRepository with Email Link Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final _authStateController = StreamController<CrushUser?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();

  static const _pendingEmailKey = 'pending_email_link_email';
  static const _emailOtpKey = 'email_otp_code';
  static const _emailOtpIdentifierKey = 'email_otp_identifier';
  static const _emailOtpTimestampKey = 'email_otp_timestamp';
  static const _emailOtpPurposeKey = 'email_otp_purpose';

  // Pending OTP data stored in memory for quick access
  final Map<String, _PendingEmailOtp> _pendingEmailOtps = {};

  CrushUser? _currentUser;
  StreamSubscription<fb.User?>? _firebaseAuthSubscription;

  // ActionCodeSettings for Email Link Authentication
  static final _actionCodeSettings = fb.ActionCodeSettings(
    // Use Firebase default domain (automatically authorized)
    url: 'https://crush-265f7.firebaseapp.com/finishSignIn',
    // This must be true for email link sign-in
    handleCodeInApp: true,
    // Android settings
    androidPackageName: 'com.example.crushhour',
    androidInstallApp: true,
    androidMinimumVersion: '21',
    // iOS settings (update when adding iOS support)
    iOSBundleId: 'com.example.crushhour',
  );

  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance {
    // Listen to Firebase auth state changes
    _firebaseAuthSubscription =
        _firebaseAuth.authStateChanges().listen(_onFirebaseAuthStateChanged);
  }

  void _onFirebaseAuthStateChanged(fb.User? firebaseUser) {
    if (firebaseUser == null) {
      _currentUser = null;
      _authStateController.add(null);
    } else {
      _currentUser = _mapFirebaseUser(firebaseUser);
      _authStateController.add(_currentUser);
    }
  }

  CrushUser _mapFirebaseUser(fb.User firebaseUser) {
    return CrushUser(
      id: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      username: firebaseUser.displayName,
      isEmailVerified: firebaseUser.emailVerified,
      isPhoneVerified: firebaseUser.phoneNumber != null,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
      profile: null,
    );
  }

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  Future<void> bootstrapSession() async {
    // Firebase handles session restoration automatically
    // Check for pending email link sign-in
    final pendingEmail = await _secureStorage.read(key: _pendingEmailKey);
    if (pendingEmail != null) {
      // There's a pending email link sign-in
      // The app should check for incoming links on startup
    }

    // Emit current state after a microtask to ensure stream subscription is ready
    Future.microtask(() {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        _currentUser = _mapFirebaseUser(firebaseUser);
        _authStateController.add(_currentUser);
      } else {
        _authStateController.add(null);
      }
    });
  }

  @override
  Stream<CrushUser?> authStateChanges() => _authStateController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL LINK AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailSignInLink(String email) async {
    // Send the email link using Firebase
    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: _actionCodeSettings,
    );

    // Store the email locally to complete sign-in when link is clicked
    await _secureStorage.write(key: _pendingEmailKey, value: email);
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    // Verify this is a valid sign-in link
    if (!_firebaseAuth.isSignInWithEmailLink(emailLink)) {
      throw Exception('Invalid sign-in link');
    }

    // Complete sign-in with email link
    final credential = await _firebaseAuth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    // Clear the pending email
    await _secureStorage.delete(key: _pendingEmailKey);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Sign-in failed');
    }

    return _mapFirebaseUser(firebaseUser);
  }

  /// Check if a link is a valid Firebase email sign-in link
  bool isSignInWithEmailLink(String link) {
    return _firebaseAuth.isSignInWithEmailLink(link);
  }

  /// Get the pending email for email link sign-in (if any)
  Future<String?> getPendingEmail() async {
    return _secureStorage.read(key: _pendingEmailKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE OTP AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  String? _verificationId;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    SecureLogger.logOtp(
      type: 'PHONE (sending)',
      recipient: phoneNumber,
      code: '******',
    );

    final completer = Completer<void>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          SecureLogger.debug('Phone OTP: Auto-verification completed');
          await _firebaseAuth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete();
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          SecureLogger.error('Phone OTP Error: ${e.code}', e.message);
          if (!completer.isCompleted) {
            String errorMessage = e.message ?? 'Verification failed';
            // Provide more helpful error messages
            if (e.code == 'invalid-phone-number') {
              errorMessage = 'Invalid phone number format. Use format: +1234567890';
            } else if (e.code == 'too-many-requests') {
              errorMessage = 'Too many requests. Please try again later.';
            } else if (e.code == 'app-not-authorized') {
              errorMessage = 'Phone auth not configured. Please enable it in Firebase Console.';
            } else if (e.code == 'missing-client-identifier') {
              errorMessage = 'Missing SHA fingerprint. Add SHA-1 to Firebase Console.';
            }
            completer.completeError(Exception(errorMessage));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          SecureLogger.debug('Phone OTP: Code sent successfully');
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          SecureLogger.debug('Phone OTP: Auto-retrieval timeout');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      SecureLogger.error('Phone OTP Exception', e);
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to send OTP: $e'));
      }
    }

    return completer.future;
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (_verificationId == null) {
      throw Exception('No verification in progress');
    }

    final credential = fb.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Verification failed');
    }

    return _mapFirebaseUser(firebaseUser);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL/PASSWORD AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<CrushUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Sign-in failed');
    }

    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<CrushUser> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    // Firebase only supports email-based password auth
    // Assume identifier is email
    return signInWithEmailPassword(email: identifier, password: password);
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Sign-up failed');
    }

    // Update display name
    await firebaseUser.updateDisplayName(username);

    // Send email verification
    await firebaseUser.sendEmailVerification();

    return _mapFirebaseUser(firebaseUser);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL OTP (Custom implementation - Firebase doesn't have native email OTP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a random 6-digit OTP
  String _generateOtp() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    // Generate OTP
    final otp = _generateOtp();
    final now = DateTime.now();

    // Normalize identifier for consistent storage/lookup
    final normalizedIdentifier = identifier.trim().toLowerCase();

    // Store OTP in memory and secure storage
    final key = '${normalizedIdentifier}_${purpose.value}';
    _pendingEmailOtps[key] = _PendingEmailOtp(
      identifier: normalizedIdentifier,
      code: otp,
      purpose: purpose,
      createdAt: now,
    );

    // Also persist to secure storage for app restart scenarios
    await _secureStorage.write(key: _emailOtpKey, value: otp);
    await _secureStorage.write(key: _emailOtpIdentifierKey, value: normalizedIdentifier);
    await _secureStorage.write(key: _emailOtpTimestampKey, value: now.toIso8601String());
    await _secureStorage.write(key: _emailOtpPurposeKey, value: purpose.value);

    // Determine recipient email
    final recipientEmail = email ?? identifier;

    // Log OTP securely - only in debug mode with proper security warnings
    SecureLogger.logOtp(
      type: 'EMAIL',
      recipient: recipientEmail,
      code: otp,
    );

    // Send OTP via email if email service is configured
    final isEmailConfigured = await EmailService.isConfigured;
    if (isEmailConfigured) {
      final sent = await EmailService.sendOtpEmail(
        recipientEmail: recipientEmail,
        otpCode: otp,
      );
      if (!sent) {
        SecureLogger.warning('Email sending failed, but OTP is logged above.');
      }
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
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final key = '${normalizedIdentifier}_${purpose.value}';
    var pending = _pendingEmailOtps[key];

    // Also try with original identifier key (for backwards compatibility)
    if (pending == null) {
      final altKey = '${identifier}_${purpose.value}';
      pending = _pendingEmailOtps[altKey];
    }

    // Try to restore from secure storage if not in memory
    if (pending == null) {
      final storedOtp = await _secureStorage.read(key: _emailOtpKey);
      final storedIdentifier = await _secureStorage.read(key: _emailOtpIdentifierKey);
      final storedTimestamp = await _secureStorage.read(key: _emailOtpTimestampKey);
      final storedPurpose = await _secureStorage.read(key: _emailOtpPurposeKey);

      SecureLogger.debug('OTP Verify: checking stored values for ${purpose.value}');

      // Compare identifiers case-insensitively and trimmed
      final storedNormalized = storedIdentifier?.trim().toLowerCase();
      if (storedOtp != null && storedNormalized == normalizedIdentifier && storedPurpose == purpose.value) {
        pending = _PendingEmailOtp(
          identifier: storedIdentifier!,
          code: storedOtp,
          purpose: purpose,
          createdAt: DateTime.tryParse(storedTimestamp ?? '') ?? DateTime.now(),
        );
      }
    }

    if (pending == null) {
      throw Exception('No OTP requested for this identifier');
    }

    // Check if OTP matches
    if (otp.trim() != pending.code) {
      throw Exception('Invalid OTP code');
    }

    // Check if OTP is expired (10 minutes)
    if (DateTime.now().difference(pending.createdAt).inMinutes > 10) {
      _pendingEmailOtps.remove(key);
      await _clearEmailOtpStorage();
      throw Exception('OTP expired. Please request a new code.');
    }

    // Clear OTP data
    _pendingEmailOtps.remove(key);
    await _clearEmailOtpStorage();

    // Handle different purposes
    switch (purpose) {
      case EmailOtpPurpose.login:
        // For login, sign in with email link as fallback or create anonymous user
        // Since Firebase doesn't support email OTP natively, we sign in anonymously
        // and link the email later, OR use a custom token from your backend
        final credential = await _firebaseAuth.signInAnonymously();
        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          // Update display name with identifier
          await firebaseUser.updateDisplayName(identifier);
          return _mapFirebaseUser(firebaseUser);
        }
        break;

      case EmailOtpPurpose.addEmail:
      case EmailOtpPurpose.changeEmail:
        // Update email in Firebase if user is logged in
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null && newEmail != null) {
          try {
            await firebaseUser.verifyBeforeUpdateEmail(newEmail);
          } catch (e) {
            SecureLogger.warning('Could not update email in Firebase: $e');
          }
        }
        // Return current user or create a placeholder to indicate success
        return _currentUser ?? CrushUser(
          id: firebaseUser?.uid ?? 'verified',
          phoneNumber: '',
          email: newEmail,
          isEmailVerified: true,
          isPhoneVerified: false,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
        );

      case EmailOtpPurpose.resetPassword:
      case EmailOtpPurpose.newDevice:
      case EmailOtpPurpose.sensitiveAction:
        // Just verify, return current user
        return _currentUser;
    }

    return _currentUser;
  }

  Future<void> _clearEmailOtpStorage() async {
    await _secureStorage.delete(key: _emailOtpKey);
    await _secureStorage.delete(key: _emailOtpIdentifierKey);
    await _secureStorage.delete(key: _emailOtpTimestampKey);
    await _secureStorage.delete(key: _emailOtpPurposeKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    // Firebase handles password reset via email link, not OTP
    // This method is not directly applicable
    throw Exception('Firebase uses email links for password reset');
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    // Firebase handles this via confirmPasswordReset with the oobCode from the link
    await _firebaseAuth.confirmPasswordReset(
      code: resetToken,
      newPassword: newPassword,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: _pendingEmailKey);
    _currentUser = null;
    _authStateController.add(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEV BYPASS (disabled for Firebase)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<CrushUser?> devLoginBypass({
    required String identifier,
    required String password,
  }) async {
    // Dev bypass is disabled for Firebase implementation
    return null;
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _PendingEmailOtp {
  final String identifier;
  final String code;
  final EmailOtpPurpose purpose;
  final DateTime createdAt;

  _PendingEmailOtp({
    required this.identifier,
    required this.code,
    required this.purpose,
    required this.createdAt,
  });
}
