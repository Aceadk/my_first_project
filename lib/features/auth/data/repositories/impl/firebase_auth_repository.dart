import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/errors/auth_failures.dart';
import 'package:crushhour/core/security/input_sanitizer.dart';
import 'package:crushhour/core/security/secure_logger.dart';
import 'package:crushhour/core/utils/result.dart' as app_result;
import 'package:crushhour/data/models/favourites.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/profile_prompt.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../auth_repository.dart';

/// Firebase implementation of AuthRepository with Email Link Authentication.
class FirebaseAuthRepository
    implements
        AuthRepository,
        GoogleSignInAuthRepository,
        LinkedAccountsRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authStateController = StreamController<CrushUser?>.broadcast();
  final _secureStorage = const FlutterSecureStorage();
  bool _isGoogleSignInInitialized = false;

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
    _firebaseAuthSubscription = _firebaseAuth.authStateChanges().listen(
      _onFirebaseAuthStateChanged,
    );
  }

  Future<void> _onFirebaseAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _authStateController.add(null);
    } else {
      final cachedTermsAccepted = await _readCachedTermsAccepted(
        firebaseUser.uid,
      );
      _currentUser = _mapFirebaseUser(
        firebaseUser,
      ).copyWith(hasAcceptedTerms: cachedTermsAccepted);

      await _checkAndUpdateFirestoreVerification(firebaseUser);
      _authStateController.add(_currentUser);
    }
  }

  /// Checks Firestore for OTP-based email verification, developer status, and terms acceptance.
  /// Always syncs hasAcceptedTerms from Firestore to ensure permanent T&C acceptance.
  Future<bool> _checkAndUpdateFirestoreVerification(
    fb.User firebaseUser,
  ) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      final userData = userDoc.data();
      if (userData == null) return false;

      // CR-AUD-010: Check for pending deletion and auto-recover within grace period
      final isPendingDeletion = userData['isPendingDeletion'] as bool? ?? false;
      final isDeactivated = userData['isDeactivated'] as bool? ?? false;
      if (isPendingDeletion || isDeactivated) {
        await _recoverAccountIfWithinGracePeriod(firebaseUser.uid, userData);
      }

      final firestoreEmailVerified =
          userData['isEmailVerified'] as bool? ?? false;
      final emailVerifiedViaOtp =
          userData['emailVerifiedViaOtp'] as bool? ?? false;
      // Read phone verification status from Firestore
      final firestorePhoneVerified =
          userData['isPhoneVerified'] as bool? ?? false;
      final hasAcceptedTerms = userData['hasAcceptedTerms'] as bool? ?? false;
      await _cacheTermsAccepted(firebaseUser.uid, hasAcceptedTerms);
      // Read skip flags for onboarding steps
      final hasSkippedBasicInfo =
          userData['hasSkippedBasicInfo'] as bool? ?? false;
      final hasSkippedProfileSetup =
          userData['hasSkippedProfileSetup'] as bool? ?? false;
      final plan = userData['plan'] == 'plus'
          ? SubscriptionPlan.plus
          : SubscriptionPlan.free;
      final themePreference =
          userData['themePreference'] ?? userData['theme_preference'];
      final profile = _profileFromFirestore(firebaseUser.uid, userData);

      // Determine if we need to update email verification status
      final needsEmailVerificationUpdate =
          !firebaseUser.emailVerified &&
          (firestoreEmailVerified || emailVerifiedViaOtp);

      // Check if any state differs from current user
      final currentTermsStatus = _currentUser?.hasAcceptedTerms ?? false;
      final currentSkippedBasicInfo =
          _currentUser?.hasSkippedBasicInfo ?? false;
      final currentSkippedProfileSetup =
          _currentUser?.hasSkippedProfileSetup ?? false;
      final currentProfile = _currentUser?.profile;
      final currentThemePreference = _currentUser?.themePreference;
      final needsProfileUpdate = profile != null && profile != currentProfile;
      final needsUpdate =
          needsEmailVerificationUpdate ||
          hasAcceptedTerms != currentTermsStatus ||
          hasSkippedBasicInfo != currentSkippedBasicInfo ||
          hasSkippedProfileSetup != currentSkippedProfileSetup ||
          needsProfileUpdate ||
          themePreference != currentThemePreference;

      if (needsUpdate) {
        _currentUser = CrushUser(
          id: firebaseUser.uid,
          phoneNumber: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          username: firebaseUser.displayName,
          // Use Firestore verification if not verified via Firebase SDK
          isEmailVerified:
              firebaseUser.emailVerified ||
              firestoreEmailVerified ||
              emailVerifiedViaOtp,
          // Phone verification should come from Firestore or Firebase Auth
          isPhoneVerified:
              firestorePhoneVerified || firebaseUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          themePreference: themePreference,
          profile: profile ?? currentProfile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
        );
        AppLogger.info(
          '[FirebaseAuthRepo] Updated user state from Firestore (terms: $hasAcceptedTerms, skippedBasic: $hasSkippedBasicInfo, skippedSetup: $hasSkippedProfileSetup)',
        );
        return true;
      }
      return false;
    } catch (e) {
      // Don't log error for expected document-not-found cases
      AppLogger.info(
        '[FirebaseAuthRepo] Could not check Firestore verification: $e',
      );
      return false;
    }
  }

  /// CR-AUD-010: Auto-recover account if user signs in during grace period.
  /// Clears isPendingDeletion/isDeactivated flags so the account is restored.
  Future<void> _recoverAccountIfWithinGracePeriod(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    try {
      final isPendingDeletion = userData['isPendingDeletion'] as bool? ?? false;
      final isDeactivated = userData['isDeactivated'] as bool? ?? false;

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPendingDeletion) {
        // Check if within 14-day grace period
        final scheduledAt =
            userData['deletionScheduledAt'] ??
            userData['scheduledPermanentDeletionAt'];
        final scheduledDate = scheduledAt is Timestamp
            ? scheduledAt.toDate()
            : (scheduledAt is DateTime ? scheduledAt : null);

        if (scheduledDate != null && DateTime.now().isBefore(scheduledDate)) {
          updates['isPendingDeletion'] = false;
          updates['deletionRequestedAt'] = FieldValue.delete();
          updates['deletionScheduledAt'] = FieldValue.delete();
          updates['scheduledPermanentDeletionAt'] = FieldValue.delete();
          updates['deletionReason'] = FieldValue.delete();
          AppLogger.info(
            '[FirebaseAuthRepo] Recovered account from pending deletion: $uid',
          );
        }
      }

      if (isDeactivated) {
        updates['isDeactivated'] = false;
        updates['deactivatedAt'] = FieldValue.delete();
        updates['deactivationReason'] = FieldValue.delete();
        updates['scheduledDeletionAt'] = FieldValue.delete();
        AppLogger.info(
          '[FirebaseAuthRepo] Reactivated deactivated account: $uid',
        );
      }

      if (updates.length > 1) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      AppLogger.error('[FirebaseAuthRepo] Account recovery failed: $e');
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
      themePreference: _currentUser?.themePreference,
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
    AppLogger.info(
      '[FirebaseAuthRepo] Ensuring user document exists for: $userId',
    );

    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      if (!doc.exists) {
        AppLogger.info('[FirebaseAuthRepo] Creating new user document');
        final displayName =
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User';
        final username = InputSanitizer.sanitizeUsername(
          firebaseUser.displayName,
        );

        await docRef.set({
          'phoneNumber': firebaseUser.phoneNumber ?? '',
          'email': firebaseUser.email,
          'username': username.isEmpty ? null : username,
          'usernameLower': username.isEmpty ? null : username,
          'isEmailVerified': firebaseUser.emailVerified,
          'isPhoneVerified': firebaseUser.phoneNumber != null,
          'isIdVerified': false,
          'plan': 'free',
          'themePreference': 'system',
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
        AppLogger.info('[FirebaseAuthRepo] User document created successfully');
      } else {
        AppLogger.info('[FirebaseAuthRepo] User document already exists');
      }
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Error ensuring user document',
        error: e,
      );
      // Don't throw - auth succeeded, document creation is secondary
    }
  }

  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  bool get supportsGoogleSignIn {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  @override
  bool get supportsAppleSignIn => true;

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
        final cachedTermsAccepted = await _readCachedTermsAccepted(
          firebaseUser.uid,
        );
        _currentUser = _mapFirebaseUser(
          firebaseUser,
        ).copyWith(hasAcceptedTerms: cachedTermsAccepted);

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
          SecureLogger.error(
            'Phone OTP Error: code=${e.code}, message=${e.message}',
            e,
          );
          if (!completer.isCompleted) {
            String errorMessage = e.message ?? 'Verification failed';
            // Provide more helpful error messages based on Firebase error codes
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage =
                    'Invalid phone number format. Use format: +1234567890';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many requests. Please try again later.';
                break;
              case 'app-not-authorized':
                errorMessage =
                    'Phone auth not configured. Please enable it in Firebase Console.';
                break;
              case 'missing-client-identifier':
                errorMessage =
                    'Missing SHA fingerprint. Add SHA-1 and SHA-256 to Firebase Console for this app.';
                break;
              case 'quota-exceeded':
                errorMessage = 'SMS quota exceeded. Please try again tomorrow.';
                break;
              case 'network-request-failed':
                errorMessage =
                    'Network error. Please check your internet connection.';
                break;
              case 'captcha-check-failed':
                errorMessage =
                    'reCAPTCHA verification failed. Please try again.';
                break;
              case 'invalid-app-credential':
                errorMessage =
                    'App credentials invalid. Check Firebase configuration.';
                break;
              case 'web-context-cancelled':
                errorMessage = 'Verification was cancelled.';
                break;
              default:
                // Include the error code for debugging unknown errors
                errorMessage =
                    'Phone verification failed (${e.code}): ${e.message ?? "Unknown error"}';
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
        AppLogger.info(
          '[FirebaseAuthRepo] User not found, creating account for: $email',
        );
        try {
          final credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          firebaseUser = credential.user;

          // Send email verification for new accounts
          if (firebaseUser != null && !firebaseUser.emailVerified) {
            await firebaseUser.sendEmailVerification();
            AppLogger.info(
              '[FirebaseAuthRepo] Verification email sent to: $email',
            );
          }
        } catch (createError) {
          AppLogger.error(
            '[FirebaseAuthRepo] Failed to create account',
            error: createError,
          );
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
  Future<CrushUser> signInWithGoogle() async {
    if (!supportsGoogleSignIn) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }

    try {
      final fb.UserCredential authResult;
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        authResult = await _firebaseAuth.signInWithPopup(provider);
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final provider = fb.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        authResult = await _firebaseAuth.signInWithProvider(provider);
      } else {
        final credential = await _buildGoogleCredential();
        authResult = await _firebaseAuth.signInWithCredential(credential);
      }

      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        throw Exception('Google Sign-In failed.');
      }

      await _ensureUserDocumentExists(firebaseUser);
      return _mapFirebaseUser(firebaseUser);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'An account already exists with the same email but different sign-in method.',
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw Exception('Google Sign-In is not enabled for this project yet.');
      }
      if (e.code == 'invalid-credential') {
        throw Exception('Google Sign-In credentials are invalid or expired.');
      }
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google Sign-In was cancelled.');
      }
      AppLogger.error('[FirebaseAuthRepo] Google sign-in failed', error: e);
      throw Exception(e.description ?? 'Google Sign-In failed.');
    } catch (e) {
      AppLogger.error('[FirebaseAuthRepo] Google sign-in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<CrushUser> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device.');
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple Sign-In failed. Missing identity token.');
      }

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: idToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final authResult = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        throw Exception('Apple Sign-In failed.');
      }

      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((value) => value?.trim().isNotEmpty ?? false).join(' ');

      if (fullName.isNotEmpty) {
        await firebaseUser.updateDisplayName(fullName);
      }

      await _ensureUserDocumentExists(firebaseUser);
      return _mapFirebaseUser(firebaseUser);
    } catch (e) {
      AppLogger.error('[FirebaseAuthRepo] Apple sign-in failed', error: e);
      rethrow;
    }
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
    await _secureStorage.write(
      key: _emailOtpIdentifierKey,
      value: normalizedIdentifier,
    );
    await _secureStorage.write(key: _emailOtpPurposeKey, value: purpose.value);

    // Call Cloud Function to send OTP
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'requestEmailOtp',
      );
      await callable.call<Map<String, dynamic>>({
        'identifier': normalizedIdentifier,
        'purpose': purpose.value,
        'email': ?email,
      });

      AppLogger.info('Email OTP requested for $normalizedIdentifier');
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('requestEmailOtp', error: e);
      // Rethrow with user-friendly message
      throw Exception(
        e.message ?? 'Failed to send verification code. Please try again.',
      );
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
      final callable = FirebaseFunctions.instance.httpsCallable(
        'verifyEmailOtp',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'identifier': normalizedIdentifier,
        'otp': otp.trim(),
        'purpose': purpose.value,
        'newEmail': ?newEmail,
        'newPassword': ?newPassword,
      });

      final data = result.data;

      // If Cloud Function returns a custom token, sign in with it
      final customToken = data['customToken'] as String?;
      if (customToken != null) {
        final credential = await _firebaseAuth.signInWithCustomToken(
          customToken,
        );
        final firebaseUser = credential.user;
        if (firebaseUser != null) {
          await _ensureUserDocumentExists(firebaseUser);
          return _mapFirebaseUser(firebaseUser);
        }
      }

      // For non-login purposes, return current user
      return _currentUser;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('verifyEmailOtp', error: e);
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
      AppLogger.info('[FirebaseAuthRepo] Email already verified');
      return;
    }

    AppLogger.info('[FirebaseAuthRepo] Sending email verification');
    await firebaseUser.sendEmailVerification();
    AppLogger.info('[FirebaseAuthRepo] Email verification sent');
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

    AppLogger.info(
      '[FirebaseAuthRepo] Firebase emailVerified: ${updatedUser.emailVerified}',
    );

    // Check Firebase SDK verification first
    if (updatedUser.emailVerified) {
      // Update Firestore document with verified status
      try {
        await _firestore.collection('users').doc(updatedUser.uid).update({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info(
          '[FirebaseAuthRepo] Updated Firestore isEmailVerified to true',
        );
      } catch (e) {
        AppLogger.error(
          '[FirebaseAuthRepo] Error updating Firestore verification status',
          error: e,
        );
      }

      // Update the stored user and emit new state
      _currentUser = _mapFirebaseUser(updatedUser);
      _authStateController.add(_currentUser);
      return _currentUser;
    }

    // Also check Firestore for OTP-verified users
    // Users who verified via email OTP have isEmailVerified in Firestore but not in Firebase SDK
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .get();
      final userData = userDoc.data();
      final firestoreEmailVerified =
          userData?['isEmailVerified'] as bool? ?? false;
      final emailVerifiedViaOtp =
          userData?['emailVerifiedViaOtp'] as bool? ?? false;
      // Read phone verification status from Firestore
      final firestorePhoneVerified =
          userData?['isPhoneVerified'] as bool? ?? false;
      // Read terms acceptance from Firestore (permanent per account)
      final hasAcceptedTerms = userData?['hasAcceptedTerms'] as bool? ?? false;
      final hasSkippedBasicInfo =
          userData?['hasSkippedBasicInfo'] as bool? ?? false;
      final hasSkippedProfileSetup =
          userData?['hasSkippedProfileSetup'] as bool? ?? false;
      final plan = userData?['plan'] == 'plus'
          ? SubscriptionPlan.plus
          : SubscriptionPlan.free;
      final themePreference =
          userData?['themePreference'] ?? userData?['theme_preference'];
      final profile = userData != null
          ? _profileFromFirestore(updatedUser.uid, userData)
          : _currentUser?.profile;

      AppLogger.info(
        '[FirebaseAuthRepo] Firestore isEmailVerified: $firestoreEmailVerified, viaOtp: $emailVerifiedViaOtp',
      );

      if (firestoreEmailVerified || emailVerifiedViaOtp) {
        // User verified via OTP - create user with verified status
        _currentUser = CrushUser(
          id: updatedUser.uid,
          phoneNumber: updatedUser.phoneNumber ?? '',
          email: updatedUser.email,
          username: updatedUser.displayName,
          isEmailVerified: true, // Override with Firestore value
          // Phone verification should come from Firestore or Firebase Auth
          isPhoneVerified:
              firestorePhoneVerified || updatedUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          themePreference: themePreference,
          profile: profile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
        );
        _authStateController.add(_currentUser);
        AppLogger.info(
          '[FirebaseAuthRepo] User verified via OTP, returning verified status',
        );
        return _currentUser;
      }
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Error checking Firestore verification status',
        error: e,
      );
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
    final userDoc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final userData = userDoc.data();
    final phoneNumber = userData?['phoneNumber'] as String?;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('No phone number to delete');
    }

    AppLogger.info(
      '[FirebaseAuthRepo] Scheduling phone deletion for user: ${firebaseUser.uid}',
    );

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

    AppLogger.info(
      '[FirebaseAuthRepo] Phone deletion scheduled, will complete at: $deletionTime',
    );

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
  Future<void> verifyPassword(String password) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No user logged in');
    }

    final email = firebaseUser.email;
    if (email == null) {
      throw Exception('No email associated with account');
    }

    // Re-authenticate with current password
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Password verification failed',
        error: e,
      );
      throw Exception('Incorrect password');
    }
  }

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

    AppLogger.info(
      '[FirebaseAuthRepo] Changing password for user: ${firebaseUser.uid}',
    );

    // Re-authenticate with current password
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.error('[FirebaseAuthRepo] Re-authentication failed', error: e);
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
      message:
          'Your password was successfully changed. If you did not make this change, please contact support immediately.',
    );

    AppLogger.info('[FirebaseAuthRepo] Password changed successfully');
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

    AppLogger.info(
      '[FirebaseAuthRepo] Deactivating account for user: ${firebaseUser.uid}',
    );

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
      message:
          'Your account has been deactivated. Sign in anytime to reactivate. '
          'If you don\'t sign in within 6 months, your account will be permanently deleted.',
    );

    AppLogger.info(
      '[FirebaseAuthRepo] Account deactivated, scheduled deletion at: $autoDeletionDate',
    );

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

    AppLogger.info(
      '[FirebaseAuthRepo] Scheduling account deletion for user: ${firebaseUser.uid}',
    );

    // Re-authenticate with password
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await firebaseUser.reauthenticateWithCredential(credential);
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Re-authentication failed for deletion',
        error: e,
      );
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
      message:
          'Your account is scheduled for permanent deletion on '
          '${permanentDeletionDate.day}/${permanentDeletionDate.month}/${permanentDeletionDate.year}. '
          'Sign in within 14 days to cancel the deletion and recover your account.',
    );

    AppLogger.info(
      '[FirebaseAuthRepo] Account deletion scheduled for: $permanentDeletionDate',
    );

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
        'channels': {'email': email, 'phone': phoneNumber},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        '[FirebaseAuthRepo] Account notification queued for user: $userId',
      );
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Error sending notification',
        error: e,
      );
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
      AppLogger.error(
        '[FirebaseAuthRepo] Error checking email existence',
        error: e,
      );
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
        showMeGenders.any(
          (g) => g.toLowerCase() == 'all' || g.toLowerCase() == 'everyone',
        )) {
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
            AppLogger.error(
              '[FirebaseAuthRepo] Error parsing prompt',
              error: e,
            );
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
      _currentUser =
          _currentUser?.copyWith(hasAcceptedTerms: true) ??
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
      AppLogger.info(
        '[FirebaseAuthRepo] Terms and conditions accepted for user: ${firebaseUser.uid}',
      );
      return _currentUser!;
    } catch (e) {
      AppLogger.error('[FirebaseAuthRepo] Error accepting terms', error: e);
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
      final userDoc = await _firestore
          .collection('users')
          .doc(updatedFirebaseUser.uid)
          .get();
      final userData = userDoc.data();

      if (userData != null) {
        final firestoreEmailVerified =
            userData['isEmailVerified'] as bool? ?? false;
        final emailVerifiedViaOtp =
            userData['emailVerifiedViaOtp'] as bool? ?? false;
        final firestorePhoneVerified =
            userData['isPhoneVerified'] as bool? ?? false;
        final hasAcceptedTerms = userData['hasAcceptedTerms'] as bool? ?? false;
        await _cacheTermsAccepted(updatedFirebaseUser.uid, hasAcceptedTerms);
        final hasSkippedBasicInfo =
            userData['hasSkippedBasicInfo'] as bool? ?? false;
        final hasSkippedProfileSetup =
            userData['hasSkippedProfileSetup'] as bool? ?? false;
        final plan = userData['plan'] == 'plus'
            ? SubscriptionPlan.plus
            : SubscriptionPlan.free;
        final themePreference =
            userData['themePreference'] ?? userData['theme_preference'];
        final profile = _profileFromFirestore(
          updatedFirebaseUser.uid,
          userData,
        );

        _currentUser = CrushUser(
          id: updatedFirebaseUser.uid,
          phoneNumber: updatedFirebaseUser.phoneNumber ?? '',
          email: updatedFirebaseUser.email,
          username: updatedFirebaseUser.displayName,
          isEmailVerified:
              updatedFirebaseUser.emailVerified ||
              firestoreEmailVerified ||
              emailVerifiedViaOtp,
          isPhoneVerified:
              firestorePhoneVerified || updatedFirebaseUser.phoneNumber != null,
          isIdVerified: false,
          plan: plan,
          themePreference: themePreference,
          profile: profile,
          hasAcceptedTerms: hasAcceptedTerms,
          hasSkippedBasicInfo: hasSkippedBasicInfo,
          hasSkippedProfileSetup: hasSkippedProfileSetup,
        );
        _authStateController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      AppLogger.error(
        '[FirebaseAuthRepo] Error refreshing user from Firestore',
        error: e,
      );
    }

    // Fall back to basic Firebase user
    _currentUser = _mapFirebaseUser(updatedFirebaseUser);
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<Set<String>> getLinkedProviderIds() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const <String>{};

    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    if (refreshed == null) return const <String>{};

    return refreshed.providerData
        .map((provider) => provider.providerId)
        .where((id) => id != 'firebase')
        .toSet();
  }

  @override
  Future<void> linkProvider(LinkedAuthProvider provider) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Please sign in again to link accounts.');
    }

    final providerId = provider.providerId;
    final linkedProviders = user.providerData.map((p) => p.providerId).toSet();
    if (linkedProviders.contains(providerId)) {
      throw Exception('${provider.displayName} is already linked.');
    }

    try {
      switch (provider) {
        case LinkedAuthProvider.google:
          if (kIsWeb) {
            await user.linkWithProvider(fb.GoogleAuthProvider());
            break;
          }

          if (defaultTargetPlatform == TargetPlatform.windows) {
            await user.linkWithProvider(fb.GoogleAuthProvider());
            break;
          }

          final credential = await _buildGoogleCredential();
          await user.linkWithCredential(credential);
          break;
        case LinkedAuthProvider.apple:
          final isAvailable = await SignInWithApple.isAvailable();
          if (!isAvailable) {
            throw Exception('Apple Sign-In is not available on this device.');
          }

          final rawNonce = _generateNonce();
          final nonce = _sha256ofString(rawNonce);
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: const [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

          final idToken = appleCredential.identityToken;
          if (idToken == null || idToken.isEmpty) {
            throw Exception('Apple Sign-In failed. Missing identity token.');
          }

          final oauthCredential = fb.OAuthProvider('apple.com').credential(
            idToken: idToken,
            accessToken: appleCredential.authorizationCode,
            rawNonce: rawNonce,
          );
          await user.linkWithCredential(oauthCredential);
          break;
      }

      await refreshCurrentUser();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw Exception('${provider.displayName} is already linked.');
      }
      if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This ${provider.displayName} account is already linked to another user.',
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw Exception(
          '${provider.displayName} sign-in is not enabled for this project.',
        );
      }
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google Sign-In was cancelled.');
      }
      throw Exception(e.description ?? 'Google Sign-In failed.');
    }
  }

  @override
  Future<void> unlinkProvider(LinkedAuthProvider provider) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Please sign in again to unlink accounts.');
    }

    final providerId = provider.providerId;
    final linkedProviders = user.providerData
        .map((p) => p.providerId)
        .where((id) => id != 'firebase')
        .toSet();
    if (!linkedProviders.contains(providerId)) {
      return;
    }
    if (linkedProviders.length <= 1) {
      throw Exception(
        'Cannot unlink the last recovery method. Add another provider first.',
      );
    }

    await user.unlink(providerId);
    await refreshCurrentUser();
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    await GoogleSignIn.instance.initialize();
    _isGoogleSignInInitialized = true;
  }

  Future<fb.AuthCredential> _buildGoogleCredential() async {
    await _ensureGoogleSignInInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate(
      scopeHint: const <String>['email', 'profile'],
    );

    final idToken = googleUser.authentication.idToken;
    String? accessToken;
    if (idToken == null || idToken.isEmpty) {
      final existingAuthorization = await googleUser.authorizationClient
          .authorizationForScopes(const <String>['email', 'profile']);
      accessToken = existingAuthorization?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        final promptedAuthorization = await googleUser.authorizationClient
            .authorizeScopes(const <String>['email', 'profile']);
        accessToken = promptedAuthorization.accessToken;
      }
    }

    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw Exception('Google Sign-In failed. Missing auth tokens.');
    }

    return fb.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT-RETURNING METHODS (CR-AUD-035)
  //
  // These methods return Result<T> instead of throwing exceptions, making
  // error handling explicit at the call site. They wrap the existing throwing
  // methods so both APIs can coexist during incremental migration.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<app_result.Result<CrushUser>> signInWithEmailPasswordResult({
    required String email,
    required String password,
  }) {
    return _guardAuthResult(
      () => signInWithEmailPassword(email: email, password: password),
      logLabel: 'FirebaseAuthRepository.signInWithEmailPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
      fallbackType: AuthFailureType.invalidCredentials,
    );
  }

  Future<app_result.Result<CrushUser>> loginWithPasswordResult({
    required String identifier,
    required String password,
  }) {
    return _guardAuthResult(
      () => loginWithPassword(identifier: identifier, password: password),
      logLabel: 'FirebaseAuthRepository.loginWithPasswordResult',
      fallbackError: 'Unable to sign in. Please check your credentials.',
      fallbackType: AuthFailureType.invalidCredentials,
    );
  }

  Future<app_result.Result<CrushUser>> signUpWithPasswordResult({
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
      logLabel: 'FirebaseAuthRepository.signUpWithPasswordResult',
      fallbackError: 'Unable to create account. Please try again.',
      fallbackType: AuthFailureType.unknown,
    );
  }

  Future<app_result.Result<void>> signOutResult() {
    return _guardAuthResult(
      () => signOut(),
      logLabel: 'FirebaseAuthRepository.signOutResult',
      fallbackError: 'Unable to sign out. Please try again.',
      fallbackType: AuthFailureType.sessionMissing,
    );
  }

  Future<app_result.Result<CrushUser>> signInWithAppleResult() {
    return _guardAuthResult(
      () => signInWithApple(),
      logLabel: 'FirebaseAuthRepository.signInWithAppleResult',
      fallbackError: 'Apple Sign-In failed. Please try again.',
      fallbackType: AuthFailureType.unsupportedProvider,
    );
  }

  Future<app_result.Result<CrushUser>> signInWithGoogleResult() {
    return _guardAuthResult(
      () => signInWithGoogle(),
      logLabel: 'FirebaseAuthRepository.signInWithGoogleResult',
      fallbackError: 'Google Sign-In failed. Please try again.',
      fallbackType: AuthFailureType.unsupportedProvider,
    );
  }

  Future<app_result.Result<T>> _guardAuthResult<T>(
    Future<T> Function() run, {
    required String logLabel,
    required String fallbackError,
    required AuthFailureType fallbackType,
  }) {
    return app_result.Result.guard(
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

  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateController.close();
  }
}
