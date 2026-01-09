import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user.dart';
import '../../models/subscription.dart';
import '../auth_repository.dart';

/// Firebase implementation of AuthRepository with Email Link Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final _authStateController = StreamController<CrushUser?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();

  static const _pendingEmailKey = 'pending_email_link_email';

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
    final completer = Completer<void>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-verification (Android only)
        await _firebaseAuth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'Verification failed'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

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
  // EMAIL OTP (Not directly supported by Firebase - using email link instead)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    // Firebase doesn't have native email OTP - redirect to email link
    await sendEmailSignInLink(email ?? identifier);
  }

  @override
  Future<CrushUser?> verifyEmailOtp({
    required String identifier,
    required String otp,
    required EmailOtpPurpose purpose,
    String? newEmail,
    String? newPassword,
  }) async {
    // This would need to be handled differently with Firebase
    // For now, throw an error indicating to use email link
    throw Exception('Use email link authentication instead');
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
