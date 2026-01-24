import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/favourites.dart';
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
  static const _termsAcceptedKeyPrefix = 'terms_accepted_';

  CrushUser? _currentUser;
  StreamSubscription<fb.User?>? _firebaseAuthSubscription;

  // ActionCodeSettings for Email Link Authentication
  static final _actionCodeSettings = fb.ActionCodeSettings(
    // Use Firebase default domain (automatically authorized)
    url: 'https://crush-265f7.firebaseapp.com/finishSignIn',
    // This must be true for email link sign-in
    handleCodeInApp: true,
    // Android settings
    androidPackageName: 'com.ace.crush',
    androidInstallApp: true,
    androidMinimumVersion: '21',
    // iOS settings
    iOSBundleId: 'com.ace.crush',
  );

  FirebaseAuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance {
    // Listen to Firebase auth state changes
    _firebaseAuthSubscription =
        _firebaseAuth.authStateChanges().listen(_onFirebaseAuthStateChanged);
  }

  Future<void> _onFirebaseAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _authStateController.add(null);
    } else {
      final cachedTermsAccepted =
          await _readCachedTermsAccepted(firebaseUser.uid);
      _currentUser = _mapFirebaseUser(firebaseUser).copyWith(
        hasAcceptedTerms: cachedTermsAccepted,
      );

      await _checkAndUpdateFirestoreVerification(firebaseUser);
      _authStateController.add(_currentUser);
    }
  }

  /// Checks Firestore for OTP-based email verification, developer status, and terms acceptance.
  /// Always syncs hasAcceptedTerms from Firestore to ensure permanent T&C acceptance.
  Future<bool> _checkAndUpdateFirestoreVerification(fb.User firebaseUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final firestoreEmailVerified = userData['isEmailVerified'] as bool? ?? false;
      final emailVerifiedViaOtp = userData['emailVerifiedViaOtp'] as bool? ?? false;
      // Read phone verification status from Firestore
      final firestorePhoneVerified = userData['isPhoneVerified'] as bool? ?? false;
      final hasAcceptedTerms = userData['hasAcceptedTerms'] as bool? ?? false;
      await _cacheTermsAccepted(firebaseUser.uid, hasAcceptedTerms);
      // Read skip flags for onboarding steps
      final hasSkippedBasicInfo = userData['hasSkippedBasicInfo'] as bool? ?? false;
      final hasSkippedProfileSetup = userData['hasSkippedProfileSetup'] as bool? ?? false;
      final plan =
          userData['plan'] == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
      final profile = _profileFromFirestore(firebaseUser.uid, userData);

      // Determine if we need to update email verification status
      final needsEmailVerificationUpdate = !firebaseUser.emailVerified &&
          (firestoreEmailVerified || emailVerifiedViaOtp);

      // Check if any state differs from current user
      final currentTermsStatus = _currentUser?.hasAcceptedTerms ?? false;
      final currentSkippedBasicInfo = _currentUser?.hasSkippedBasicInfo ?? false;
      final currentSkippedProfileSetup = _currentUser?.hasSkippedProfileSetup ?? false;
      final currentProfile = _currentUser?.profile;
      final needsProfileUpdate = profile != null && profile != currentProfile;
      final needsUpdate = needsEmailVerificationUpdate ||
          hasAcceptedTerms != currentTermsStatus ||
          hasSkippedBasicInfo != currentSkippedBasicInfo ||
          hasSkippedProfileSetup != currentSkippedProfileSetup ||
          needsProfileUpdate;

      if (needsUpdate) {
        _currentUser = CrushUser(
          id: firebaseUser.uid,
          phoneNumber: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          username: firebaseUser.displayName,
          // Use Firestore verification if not verified via Firebase SDK
          isEmailVerified: firebaseUser.emailVerified || firestoreEmailVerified || emailVerifiedViaOtp,
          // Phone verification should come from Firestore or Firebase Auth
          isPhoneVerified: firestorePhoneVerified || firebaseUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          profile: profile ?? currentProfile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
        );
        AppLogger.logInfo('[FirebaseAuthRepo] Updated user state from Firestore (terms: $hasAcceptedTerms, skippedBasic: $hasSkippedBasicInfo, skippedSetup: $hasSkippedProfileSetup)');
        return true;
      }
      return false;
    } catch (e) {
      // Don't log error for expected document-not-found cases
      AppLogger.logInfo('[FirebaseAuthRepo] Could not check Firestore verification: $e');
      return false;
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

  String _termsAcceptedKey(String userId) => '$_termsAcceptedKeyPrefix$userId';

  Future<bool> _readCachedTermsAccepted(String userId) async {
    final value = await _secureStorage.read(key: _termsAcceptedKey(userId));
    return value == 'true';
  }

  Future<void> _cacheTermsAccepted(String userId, bool accepted) async {
    final key = _termsAcceptedKey(userId);
    if (accepted) {
      await _secureStorage.write(key: key, value: 'true');
    } else {
      await _secureStorage.delete(key: key);
    }
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
            'lastName': '',
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
            'privacySettings': const ProfilePrivacySettings().toJson(),
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
  bool get supportsUsernameLogin => false;

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
        final cachedTermsAccepted =
            await _readCachedTermsAccepted(firebaseUser.uid);
        _currentUser = _mapFirebaseUser(firebaseUser).copyWith(
          hasAcceptedTerms: cachedTermsAccepted,
        );

        await _checkAndUpdateFirestoreVerification(firebaseUser);
        _authStateController.add(_currentUser);
      } else {
        // No user logged in - emit null to trigger unauthenticated state
        _currentUser = null;
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
          SecureLogger.error('Phone OTP Error: code=${e.code}, message=${e.message}', e);
          if (!completer.isCompleted) {
            String errorMessage = e.message ?? 'Verification failed';
            // Provide more helpful error messages based on Firebase error codes
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = 'Invalid phone number format. Use format: +1234567890';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many requests. Please try again later.';
                break;
              case 'app-not-authorized':
                errorMessage = 'Phone auth not configured. Please enable it in Firebase Console.';
                break;
              case 'missing-client-identifier':
                errorMessage = 'Missing SHA fingerprint. Add SHA-1 and SHA-256 to Firebase Console for this app.';
                break;
              case 'quota-exceeded':
                errorMessage = 'SMS quota exceeded. Please try again tomorrow.';
                break;
              case 'network-request-failed':
                errorMessage = 'Network error. Please check your internet connection.';
                break;
              case 'captcha-check-failed':
                errorMessage = 'reCAPTCHA verification failed. Please try again.';
                break;
              case 'invalid-app-credential':
                errorMessage = 'App credentials invalid. Check Firebase configuration.';
                break;
              case 'web-context-cancelled':
                errorMessage = 'Verification was cancelled.';
                break;
              default:
                // Include the error code for debugging unknown errors
                errorMessage = 'Phone verification failed (${e.code}): ${e.message ?? "Unknown error"}';
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
    fb.User? firebaseUser;

    try {
      // Try to sign in with existing account
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = credential.user;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // User doesn't exist - create account automatically
        AppLogger.logInfo('[FirebaseAuthRepo] User not found, creating account for: $email');
        try {
          final credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = credential.user;

          // Send email verification for new accounts
          if (firebaseUser != null && !firebaseUser.emailVerified) {
            await firebaseUser.sendEmailVerification();
            AppLogger.logInfo('[FirebaseAuthRepo] Verification email sent to: $email');
          }
        } catch (createError) {
          AppLogger.logError('[FirebaseAuthRepo] Failed to create account', createError);
          rethrow;
        }
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password. Please try again.');
      } else {
        rethrow;
      }
    }

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
    try {
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

      // Create Firestore document for the new user
      await _ensureUserDocumentExists(firebaseUser);
      return _mapFirebaseUser(firebaseUser);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'An account with this email already exists. Please sign in instead, or use a different email address.',
        );
      }
      rethrow;
    }
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
      // Read phone verification status from Firestore
      final firestorePhoneVerified = userData?['isPhoneVerified'] as bool? ?? false;
      // Read terms acceptance from Firestore (permanent per account)
      final hasAcceptedTerms = userData?['hasAcceptedTerms'] as bool? ?? false;
      final hasSkippedBasicInfo = userData?['hasSkippedBasicInfo'] as bool? ?? false;
      final hasSkippedProfileSetup = userData?['hasSkippedProfileSetup'] as bool? ?? false;
      final plan =
          userData?['plan'] == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
      final profile = userData != null
          ? _profileFromFirestore(updatedUser.uid, userData)
          : _currentUser?.profile;

      AppLogger.logInfo('[FirebaseAuthRepo] Firestore isEmailVerified: $firestoreEmailVerified, viaOtp: $emailVerifiedViaOtp');

      if (firestoreEmailVerified || emailVerifiedViaOtp) {
        // User verified via OTP - create user with verified status
        _currentUser = CrushUser(
          id: updatedUser.uid,
          phoneNumber: updatedUser.phoneNumber ?? '',
          email: updatedUser.email,
          username: updatedUser.displayName,
          isEmailVerified: true, // Override with Firestore value
          // Phone verification should come from Firestore or Firebase Auth
          isPhoneVerified: firestorePhoneVerified || updatedUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          profile: profile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
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
  // EMAIL EXISTENCE CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Check Firestore for existing user with this email
      final normalizedEmail = email.trim().toLowerCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }

      // Also check with original casing in case email was stored differently
      final querySnapshot2 = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return querySnapshot2.docs.isNotEmpty;
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error checking email existence', e);
      return false;
    }
  }

  Profile? _profileFromFirestore(String userId, Map<String, dynamic> data) {
    final profileData = data['profile'] as Map<String, dynamic>?;
    if (profileData == null) return null;
    final preferencesData = profileData['preferences'];
    final privacyData = profileData['privacySettings'];
    final favouritesData = profileData['favourites'];

    return Profile(
      id: userId,
      name: profileData['name'] ?? '',
      lastName: profileData['lastName'],
      age: profileData['age'] ?? 0,
      gender: profileData['gender'] ?? '',
      sexualOrientation: profileData['sexualOrientation'],
      dateOfBirth: _parseTimestamp(profileData['dateOfBirth']),
      lastDobChangeAt: _parseTimestamp(profileData['lastDobChangeAt']),
      lastNameChangeAt: _parseTimestamp(profileData['lastNameChangeAt']),
      bio: profileData['bio'] ?? '',
      photoUrls: List<String>.from(profileData['photoUrls'] ?? []),
      videoUrls: List<String>.from(profileData['videoUrls'] ?? []),
      primaryPhotoIndex: profileData['primaryPhotoIndex'] ?? 0,
      interests: List<String>.from(profileData['interests'] ?? []),
      profilePrompts: _parseProfilePrompts(profileData['profilePrompts']),
      country: profileData['country'] ?? '',
      city: profileData['city'] ?? '',
      latitude: (profileData['latitude'] as num?)?.toDouble(),
      longitude: (profileData['longitude'] as num?)?.toDouble(),
      livingIn: profileData['livingIn'],
      isVerified: profileData['isVerified'] ?? false,
      heightCm: profileData['heightCm'],
      relationshipGoals: profileData['relationshipGoals'],
      languages: List<String>.from(profileData['languages'] ?? []),
      zodiacSign: profileData['zodiacSign'],
      educationLevel: profileData['educationLevel'],
      familyPlans: profileData['familyPlans'],
      personalityType: profileData['personalityType'],
      religion: profileData['religion'],
      workout: profileData['workout'],
      socialMedia: profileData['socialMedia'],
      sleepingHabits: profileData['sleepingHabits'],
      smoking: profileData['smoking'],
      drinking: profileData['drinking'],
      pets: profileData['pets'],
      favoriteSongs: List<String>.from(profileData['favoriteSongs'] ?? []),
      favoriteSinger: profileData['favoriteSinger'],
      jobTitle: profileData['jobTitle'],
      company: profileData['company'],
      school: profileData['school'],
      preferences: _preferencesFromFirestore(
        preferencesData is Map<String, dynamic> ? preferencesData : null,
      ),
      privacySettings: ProfilePrivacySettings.fromJson(
        privacyData is Map<String, dynamic> ? privacyData : null,
      ),
      favourites: favouritesData is Map<String, dynamic>
          ? ProfileFavourites.fromJson(favouritesData)
          : const ProfileFavourites(),
    );
  }

  DiscoveryPreferences _preferencesFromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return const DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 100,
        showMeGenders: ['male', 'female'], // Default to show all binary genders
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      );
    }

    // Handle legacy 'All' value by converting to proper defaults
    List<String> showMeGenders = List<String>.from(data['showMeGenders'] ?? []);
    if (showMeGenders.isEmpty ||
        showMeGenders.any((g) => g.toLowerCase() == 'all' || g.toLowerCase() == 'everyone')) {
      showMeGenders = ['male', 'female'];
    }

    return DiscoveryPreferences(
      minAge: data['minAge'] ?? 18,
      maxAge: data['maxAge'] ?? 50,
      maxDistanceKm: (data['maxDistanceKm'] ?? 100).toDouble(),
      showMeGenders: showMeGenders,
      showMyDistance: data['showMyDistance'] ?? true,
      showMyAge: data['showMyAge'] ?? true,
      hideFromDiscovery: data['hideFromDiscovery'] ?? false,
      incognitoMode: data['incognitoMode'] ?? false,
      country: data['country'] ?? '',
      city: data['city'] ?? '',
    );
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  List<ProfilePrompt> _parseProfilePrompts(dynamic value) {
    if (value == null) return const [];
    if (value is! List) return const [];

    return value
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return ProfilePrompt.fromJson(json);
          } catch (e) {
            AppLogger.logError('[FirebaseAuthRepo] Error parsing prompt', e);
            return null;
          }
        })
        .whereType<ProfilePrompt>()
        .toList();
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    try {
      // Update Firestore with terms acceptance
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'hasAcceptedTerms': true,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _cacheTermsAccepted(firebaseUser.uid, true);

      // Update current user state
      _currentUser = _currentUser?.copyWith(hasAcceptedTerms: true) ??
          CrushUser(
            id: firebaseUser.uid,
            phoneNumber: firebaseUser.phoneNumber ?? '',
            email: firebaseUser.email,
            username: firebaseUser.displayName,
            isEmailVerified: firebaseUser.emailVerified,
            isPhoneVerified: firebaseUser.phoneNumber != null,
            isIdVerified: false,
            plan: SubscriptionPlan.free,
            hasAcceptedTerms: true,
          );

      _authStateController.add(_currentUser);
      AppLogger.logInfo('[FirebaseAuthRepo] Terms and conditions accepted for user: ${firebaseUser.uid}');
      return _currentUser!;
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error accepting terms', e);
      throw Exception('Failed to accept terms. Please try again.');
    }
  }

  @override
  Future<CrushUser?> refreshCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    // Reload Firebase user to get latest state
    await firebaseUser.reload();
    final updatedFirebaseUser = _firebaseAuth.currentUser;
    if (updatedFirebaseUser == null) return null;

    // Check Firestore for full user data including skip flags
    try {
      final userDoc = await _firestore.collection('users').doc(updatedFirebaseUser.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final firestoreEmailVerified = userData['isEmailVerified'] as bool? ?? false;
        final emailVerifiedViaOtp = userData['emailVerifiedViaOtp'] as bool? ?? false;
        final firestorePhoneVerified = userData['isPhoneVerified'] as bool? ?? false;
        final hasAcceptedTerms = userData['hasAcceptedTerms'] as bool? ?? false;
        await _cacheTermsAccepted(updatedFirebaseUser.uid, hasAcceptedTerms);
        final hasSkippedBasicInfo = userData['hasSkippedBasicInfo'] as bool? ?? false;
        final hasSkippedProfileSetup = userData['hasSkippedProfileSetup'] as bool? ?? false;
        final plan =
            userData['plan'] == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;
        final profile = _profileFromFirestore(updatedFirebaseUser.uid, userData);

        _currentUser = CrushUser(
          id: updatedFirebaseUser.uid,
          phoneNumber: updatedFirebaseUser.phoneNumber ?? '',
          email: updatedFirebaseUser.email,
          username: updatedFirebaseUser.displayName,
          isEmailVerified: updatedFirebaseUser.emailVerified || firestoreEmailVerified || emailVerifiedViaOtp,
          isPhoneVerified: firestorePhoneVerified || updatedFirebaseUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          profile: profile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
        );
        _authStateController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      AppLogger.logError('[FirebaseAuthRepo] Error refreshing user from Firestore', e);
    }

    // Fall back to basic Firebase user
    _currentUser = _mapFirebaseUser(updatedFirebaseUser);
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}
