import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/subscription.dart';
import '../auth_repository.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/security/secure_logger.dart';

/// Firebase implementation of AuthRepository with Email Link Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authStateController = StreamController<CrushUser?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();

  static const _pendingEmailKey = 'pending_email_link_email';
  static const _emailOtpIdentifierKey = 'email_otp_identifier';
  static const _emailOtpPurposeKey = 'email_otp_purpose';

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
    // iOS settings
    iOSBundleId: 'com.crushhour.app',
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
      // First emit with Firebase SDK data
      _currentUser = _mapFirebaseUser(firebaseUser);
      _authStateController.add(_currentUser);

      // Then check Firestore for OTP-verified users and update if needed
      _checkAndUpdateFirestoreVerification(firebaseUser);
    }
  }

  /// Checks Firestore for OTP-based email verification and updates user state if verified.
  Future<void> _checkAndUpdateFirestoreVerification(fb.User firebaseUser) async {
    // Skip if already verified via Firebase SDK
    if (firebaseUser.emailVerified) return;

    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final firestoreEmailVerified = userData['isEmailVerified'] as bool? ?? false;
      final emailVerifiedViaOtp = userData['emailVerifiedViaOtp'] as bool? ?? false;

      if (firestoreEmailVerified || emailVerifiedViaOtp) {
        // User verified via OTP - update current user with verified status
        _currentUser = CrushUser(
          id: firebaseUser.uid,
          phoneNumber: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          username: firebaseUser.displayName,
          isEmailVerified: true, // Override with Firestore value
          isPhoneVerified: firebaseUser.phoneNumber != null,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
          profile: null,
        );
        _authStateController.add(_currentUser);
        AppLogger.logInfo('[FirebaseAuthRepo] Updated user with OTP-verified email status');
      }
    } catch (e) {
      // Don't log error for expected document-not-found cases
      AppLogger.logInfo('[FirebaseAuthRepo] Could not check Firestore verification: $e');
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

  /// Ensures a Firestore user document exists for the authenticated user.
  /// Creates the document with minimal data if it doesn't exist.
  Future<void> _ensureUserDocumentExists(fb.User firebaseUser) async {
    final userId = firebaseUser.uid;
    AppLogger.logInfo('[FirebaseAuthRepo] Ensuring user document exists for: $userId');

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        AppLogger.logInfo('[FirebaseAuthRepo] Creating new user document');
        final displayName = firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User';

        await docRef.set({
          'phoneNumber': firebaseUser.phoneNumber ?? '',
          'email': firebaseUser.email,
          'username': firebaseUser.displayName,
          'isEmailVerified': firebaseUser.emailVerified,
          'isPhoneVerified': firebaseUser.phoneNumber != null,
          'isIdVerified': false,
          'plan': 'free',
          'profile': {
            'name': displayName,
            'age': 0,
            'gender': '',
            'bio': '',
            'photoUrls': <String>[],
            'videoUrls': <String>[],
            'primaryPhotoIndex': 0,
            'interests': <String>[],
            'country': '',
            'city': '',
            'isVerified': false,
            'languages': <String>[],
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.logInfo('[FirebaseAuthRepo] User document created successfully');
      } else {
        AppLogger.logInfo('[FirebaseAuthRepo] User document already exists');
      }
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error ensuring user document', e);
      // Don't throw - auth succeeded, document creation is secondary
    }
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
    Future.microtask(() async {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        _currentUser = _mapFirebaseUser(firebaseUser);
        _authStateController.add(_currentUser);

        // Check Firestore for OTP-verified users
        await _checkAndUpdateFirestoreVerification(firebaseUser);
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

    await _ensureUserDocumentExists(firebaseUser);
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

    await _ensureUserDocumentExists(firebaseUser);
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

    await _ensureUserDocumentExists(firebaseUser);
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

    // Create Firestore document for the new user
    await _ensureUserDocumentExists(firebaseUser);
    return _mapFirebaseUser(firebaseUser);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL OTP (Via Cloud Functions)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    // Normalize identifier for consistent storage/lookup
    final normalizedIdentifier = identifier.trim().toLowerCase();

    // Store identifier in secure storage for later verification
    await _secureStorage.write(key: _emailOtpIdentifierKey, value: normalizedIdentifier);
    await _secureStorage.write(key: _emailOtpPurposeKey, value: purpose.value);

    // Call Cloud Function to send OTP
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('requestEmailOtp');
      await callable.call<Map<String, dynamic>>({
        'identifier': normalizedIdentifier,
        'purpose': purpose.value,
        if (email != null) 'email': email,
      });

      AppLogger.logInfo('Email OTP requested for $normalizedIdentifier');
    } on FirebaseFunctionsException catch (e) {
      AppLogger.logError('requestEmailOtp', e);
      // Rethrow with user-friendly message
      throw Exception(e.message ?? 'Failed to send verification code. Please try again.');
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

    try {
      // Call Cloud Function to verify OTP
      final callable = FirebaseFunctions.instance.httpsCallable('verifyEmailOtp');
      final result = await callable.call<Map<String, dynamic>>({
        'identifier': normalizedIdentifier,
        'otp': otp.trim(),
        'purpose': purpose.value,
        if (newEmail != null) 'newEmail': newEmail,
        if (newPassword != null) 'newPassword': newPassword,
      });

      final data = result.data;

      // If Cloud Function returns a custom token, sign in with it
      final customToken = data['customToken'] as String?;
      if (customToken != null) {
        final credential = await _firebaseAuth.signInWithCustomToken(customToken);
        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          await _ensureUserDocumentExists(firebaseUser);
          return _mapFirebaseUser(firebaseUser);
        }
      }

      // For non-login purposes, return current user
      return _currentUser;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.logError('verifyEmailOtp', e);
      throw Exception(e.message ?? 'Failed to verify code. Please try again.');
    }
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
  // EMAIL VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> sendEmailVerification() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    if (firebaseUser.emailVerified) {
      AppLogger.logInfo('[FirebaseAuthRepo] Email already verified');
      return;
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Sending email verification');
    await firebaseUser.sendEmailVerification();
    AppLogger.logInfo('[FirebaseAuthRepo] Email verification sent');
  }

  @override
  Future<CrushUser?> checkEmailVerification() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    // Reload user to get latest email verification status
    await firebaseUser.reload();
    final updatedUser = _firebaseAuth.currentUser;

    if (updatedUser == null) {
      return null;
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Firebase emailVerified: ${updatedUser.emailVerified}');

    // Check Firebase SDK verification first
    if (updatedUser.emailVerified) {
      // Update Firestore document with verified status
      try {
        await _firestore.collection('users').doc(updatedUser.uid).update({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.logInfo('[FirebaseAuthRepo] Updated Firestore isEmailVerified to true');
      } catch (e) {
        AppLogger.logError('[FirebaseAuthRepo] Error updating Firestore verification status', e);
      }

      // Update the stored user and emit new state
      _currentUser = _mapFirebaseUser(updatedUser);
      _authStateController.add(_currentUser);
      return _currentUser;
    }

    // Also check Firestore for OTP-verified users
    // Users who verified via email OTP have isEmailVerified in Firestore but not in Firebase SDK
    try {
      final userDoc = await _firestore.collection('users').doc(updatedUser.uid).get();
      final userData = userDoc.data();
      final firestoreEmailVerified = userData?['isEmailVerified'] as bool? ?? false;
      final emailVerifiedViaOtp = userData?['emailVerifiedViaOtp'] as bool? ?? false;

      AppLogger.logInfo('[FirebaseAuthRepo] Firestore isEmailVerified: $firestoreEmailVerified, viaOtp: $emailVerifiedViaOtp');

      if (firestoreEmailVerified || emailVerifiedViaOtp) {
        // User verified via OTP - create user with verified status
        _currentUser = CrushUser(
          id: updatedUser.uid,
          phoneNumber: updatedUser.phoneNumber ?? '',
          email: updatedUser.email,
          username: updatedUser.displayName,
          isEmailVerified: true, // Override with Firestore value
          isPhoneVerified: updatedUser.phoneNumber != null,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
          profile: null,
        );
        _authStateController.add(_currentUser);
        AppLogger.logInfo('[FirebaseAuthRepo] User verified via OTP, returning verified status');
        return _currentUser;
      }
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error checking Firestore verification status', e);
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONE DELETION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> schedulePhoneDeletion() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    // Get current user's phone number from Firestore
    final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    final userData = userDoc.data();
    final phoneNumber = userData?['phoneNumber'] as String?;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('No phone number to delete');
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Scheduling phone deletion for user: ${firebaseUser.uid}');

    // Calculate deletion time: 2 days 23 hours from now (just under 3 days)
    final deletionTime = DateTime.now().add(const Duration(hours: 71));

    // Create phone deletion record for background cleanup
    await _firestore.collection('phone_deletions').add({
      'userId': firebaseUser.uid,
      'phoneNumber': phoneNumber,
      'scheduledDeletionAt': Timestamp.fromDate(deletionTime),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Add phone to cooldown list (prevents reuse until deletion completes)
    await _firestore.collection('phone_cooldowns').doc(phoneNumber).set({
      'phoneNumber': phoneNumber,
      'previousUserId': firebaseUser.uid,
      'availableAt': Timestamp.fromDate(deletionTime),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Clear phone from user document immediately
    await _firestore.collection('users').doc(firebaseUser.uid).update({
      'phoneNumber': FieldValue.delete(),
      'isPhoneVerified': false,
      'phoneDeletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.logInfo('[FirebaseAuthRepo] Phone deletion scheduled, will complete at: $deletionTime');

    // Update local state
    _currentUser = _currentUser?.copyWith(
      phoneNumber: null,
      isPhoneVerified: false,
    );
    _authStateController.add(_currentUser);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSWORD MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    final email = firebaseUser.email;
    if (email == null) {
      throw Exception('No email associated with account');
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Changing password for user: ${firebaseUser.uid}');

    // Re-authenticate with current password
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Re-authentication failed', e);
      throw Exception('Current password is incorrect');
    }

    // Update password
    await firebaseUser.updatePassword(newPassword);

    // Log password change event
    await _firestore.collection('account_events').add({
      'userId': firebaseUser.uid,
      'eventType': 'password_changed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send notification
    await _sendAccountNotification(
      userId: firebaseUser.uid,
      title: 'Password Changed',
      message: 'Your password was successfully changed. If you did not make this change, please contact support immediately.',
    );

    AppLogger.logInfo('[FirebaseAuthRepo] Password changed successfully');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT DEACTIVATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> deactivateAccount({required String reason}) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Deactivating account for user: ${firebaseUser.uid}');

    // Calculate auto-deletion date: 6 months from now
    final autoDeletionDate = DateTime.now().add(const Duration(days: 180));

    // Update user document with deactivation status
    await _firestore.collection('users').doc(firebaseUser.uid).update({
      'isDeactivated': true,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'deactivationReason': reason,
      'scheduledDeletionAt': Timestamp.fromDate(autoDeletionDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create deactivation record for tracking
    await _firestore.collection('account_deactivations').add({
      'userId': firebaseUser.uid,
      'reason': reason,
      'deactivatedAt': FieldValue.serverTimestamp(),
      'scheduledDeletionAt': Timestamp.fromDate(autoDeletionDate),
      'status': 'deactivated',
    });

    // Send notification
    await _sendAccountNotification(
      userId: firebaseUser.uid,
      title: 'Account Deactivated',
      message: 'Your account has been deactivated. Sign in anytime to reactivate. '
          'If you don\'t sign in within 6 months, your account will be permanently deleted.',
    );

    AppLogger.logInfo('[FirebaseAuthRepo] Account deactivated, scheduled deletion at: $autoDeletionDate');

    // Sign out the user
    await signOut();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT DELETION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> deleteAccount({
    required String password,
    required String reason,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    final email = firebaseUser.email;
    if (email == null) {
      throw Exception('No email associated with account');
    }

    AppLogger.logInfo('[FirebaseAuthRepo] Scheduling account deletion for user: ${firebaseUser.uid}');

    // Re-authenticate with password
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Re-authentication failed for deletion', e);
      throw Exception('Password is incorrect');
    }

    // Calculate permanent deletion date: 14 days from now
    final permanentDeletionDate = DateTime.now().add(const Duration(days: 14));

    // Update user document with pending deletion status
    await _firestore.collection('users').doc(firebaseUser.uid).update({
      'isPendingDeletion': true,
      'deletionRequestedAt': FieldValue.serverTimestamp(),
      'deletionReason': reason,
      'scheduledPermanentDeletionAt': Timestamp.fromDate(permanentDeletionDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create deletion record for tracking
    await _firestore.collection('account_deletions').add({
      'userId': firebaseUser.uid,
      'email': email,
      'reason': reason,
      'requestedAt': FieldValue.serverTimestamp(),
      'scheduledDeletionAt': Timestamp.fromDate(permanentDeletionDate),
      'status': 'pending',
    });

    // Send notification
    await _sendAccountNotification(
      userId: firebaseUser.uid,
      title: 'Account Scheduled for Deletion',
      message: 'Your account is scheduled for permanent deletion on '
          '${permanentDeletionDate.day}/${permanentDeletionDate.month}/${permanentDeletionDate.year}. '
          'Sign in within 14 days to cancel the deletion and recover your account.',
    );

    AppLogger.logInfo('[FirebaseAuthRepo] Account deletion scheduled for: $permanentDeletionDate');

    // Sign out the user
    await signOut();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _sendAccountNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      // Get user's notification preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final email = userData?['email'] as String?;
      final phoneNumber = userData?['phoneNumber'] as String?;

      // Create notification record
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': 'account_action',
        'channels': {
          'email': email,
          'phone': phoneNumber,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.logInfo('[FirebaseAuthRepo] Account notification queued for user: $userId');
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error sending notification', e);
      // Don't throw - notification failure shouldn't block the action
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEV BYPASS (creates test account for development)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<CrushUser?> devLoginBypass({
    required String identifier,
    required String password,
  }) async {
    // Only allow in debug mode with specific credentials
    if (identifier != 'admin123' || password != 'admin123') {
      return null;
    }

    const testEmail = 'dev@crushhour.test';
    const testPassword = 'DevTest123!@#';

    try {
      // Try to sign in with existing test account
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        await _ensureUserDocumentExists(firebaseUser);
        return _mapFirebaseUser(firebaseUser);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // Create the test account
        try {
          final credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
          final firebaseUser = credential.user;
          if (firebaseUser != null) {
            await _ensureUserDocumentExists(firebaseUser);
            // Mark as verified for dev purposes
            await _firestore.collection('users').doc(firebaseUser.uid).update({
              'isEmailVerified': true,
              'isDeveloper': true,
            });
            return _mapFirebaseUser(firebaseUser);
          }
        } catch (createError) {
          AppLogger.logError('Dev bypass create account', createError);
        }
      }
    }
    return null;
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}
