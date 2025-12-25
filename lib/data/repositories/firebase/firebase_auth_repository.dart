import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_env.dart';
import '../../../core/app_logger.dart';
import '../../../core/constants.dart';
import '../../../core/errors.dart';
import '../../models/user.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/subscription.dart';
import '../auth_repository.dart';
import '../../../firebase_options.dart';
import '../../services/auth_session_manager.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AuthSessionManager _sessionManager;

  String? _verificationId;
  int? _resendToken;
  static const _emailLinkKey = 'auth_email_link_email';
  static const _androidPackageName = 'com.example.crushhour';
  static const _iosBundleId = 'com.example.myFirstProject';
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AuthSessionManager? sessionManager,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _sessionManager = sessionManager ?? AuthSessionManager() {
    AppEnvConfig.logBypassIfActive();
  }

  @override
  bool get isVerificationBypassEnabled => AppEnvConfig.bypassVerification;

  bool _shouldBypassEmailVerification(String? email) {
    return isVerificationBypassEnabled && email != null && email.isNotEmpty;
  }

  bool _shouldBypassPhoneVerification(String phoneNumber) {
    return isVerificationBypassEnabled && phoneNumber.isNotEmpty;
  }

  bool _effectiveEmailVerified(String? email, bool firebaseVerified) {
    return _shouldBypassEmailVerification(email) ? true : firebaseVerified;
  }

  bool _effectivePhoneVerified(String phoneNumber, bool phoneVerified) {
    return _shouldBypassPhoneVerification(phoneNumber) ? true : phoneVerified;
  }

  void _logBypass(String action) {
    if (!isVerificationBypassEnabled) return;
    AppLogger.logInfo('DEV auth bypass: $action');
  }

  @override
  Future<void> bootstrapSession() async {
    await _sessionManager.validateOrRefresh();
  }

  @override
  Stream<CrushUser?> authStateChanges() {
    return _auth.userChanges().asyncMap((fb.User? fbUser) async {
      if (fbUser == null) return null;
      final emailVerified =
          _effectiveEmailVerified(fbUser.email, fbUser.emailVerified);
      final phoneNumber = fbUser.phoneNumber ?? '';
      final phoneVerified =
          _effectivePhoneVerified(phoneNumber, fbUser.phoneNumber != null);
      final userDoc =
          await _firestore.collection('users').doc(fbUser.uid).get();
      if (!userDoc.exists) {
        // create basic doc with defaults
        final user = CrushUser(
          id: fbUser.uid,
          phoneNumber: phoneNumber,
          email: fbUser.email,
          username: null,
          isEmailVerified: emailVerified,
          profile: null,
          isPhoneVerified: phoneVerified,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
        );
        await _firestore.collection('users').doc(fbUser.uid).set({
          'phoneNumber': user.phoneNumber,
          'email': user.email,
          'emailLower': user.email?.toLowerCase(),
          'isEmailVerified': user.isEmailVerified,
          'isPhoneVerified': user.isPhoneVerified,
          'isIdVerified': user.isIdVerified,
          'plan': 'free',
        });
        return user;
      } else {
        var user = _fromDoc(userDoc);
        if (isVerificationBypassEnabled) {
          user = user.copyWith(
            isEmailVerified: _shouldBypassEmailVerification(user.email)
                ? true
                : user.isEmailVerified,
            isPhoneVerified: _shouldBypassPhoneVerification(user.phoneNumber)
                ? true
                : user.isPhoneVerified,
          );
        }
        return user;
      }
    });
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    if (isVerificationBypassEnabled) {
      _logBypass('phone_otp_send');
      await _devSignInWithPhone(phoneNumber);
      return;
    }
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto verification on some devices
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        } on fb.FirebaseAuthException catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(
              RepositoryException(e.code, _friendlyAuthError(e)),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            RepositoryException(e.code, _friendlyAuthError(e)),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
    );

    return completer.future;
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (isVerificationBypassEnabled) {
      _logBypass('phone_otp_verify');
      return _devSignInWithPhone(phoneNumber);
    }
    if (_verificationId == null) {
      throw Exception('No verification in progress.');
    }
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    final result = await _auth.signInWithCredential(credential);
    final fbUser = result.user;
    if (fbUser == null) {
      throw Exception('Failed to sign in user.');
    }
    await _sessionManager.persistFromUser(fbUser);
    return _getOrCreateUserDoc(
      fbUser: fbUser,
      phoneNumber: phoneNumber,
      email: fbUser.email,
      isPhoneVerified: true,
    );
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    final authDomain = DefaultFirebaseOptions.web.authDomain;
    final actionCodeSettings = fb.ActionCodeSettings(
      url: authDomain != null && authDomain.isNotEmpty
          ? 'https://$authDomain'
          : 'https://crushhour-40c2d.firebaseapp.com',
      handleCodeInApp: true,
      iOSBundleId: _iosBundleId,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailLinkKey, email);
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw Exception('Invalid email sign-in link.');
    }
    final prefs = await SharedPreferences.getInstance();
    final resolvedEmail = email.isNotEmpty
        ? email
        : (prefs.getString(_emailLinkKey) ?? '');
    if (resolvedEmail.isEmpty) {
      throw Exception('Missing email for sign-in.');
    }
    final result = await _auth.signInWithEmailLink(
      email: resolvedEmail,
      emailLink: emailLink,
    );
    final fbUser = result.user;
    if (fbUser == null) {
      throw Exception('Failed to sign in user.');
    }
    await _sessionManager.persistFromUser(fbUser);
    await prefs.remove(_emailLinkKey);
    return _getOrCreateUserDoc(
      fbUser: fbUser,
      email: resolvedEmail,
    );
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
    final callable = _functions.httpsCallable('loginWithPassword');
    HttpsCallableResult result;
    try {
      result = await callable.call({
        'identifier': identifier,
        'password': password,
      });
    } on FirebaseFunctionsException catch (e) {
      throw RepositoryException(
        e.code,
        e.message ?? 'Could not sign in. Please try again.',
      );
    }
    final data = result.data;
    final token = data is Map ? data['customToken'] as String? : null;
    if (token == null || token.isEmpty) {
      throw Exception('Missing authentication token.');
    }
    final credential = await _auth.signInWithCustomToken(token);
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Failed to sign in user.');
    }
    await _sessionManager.persistFromUser(fbUser);
    return _getOrCreateUserDoc(
      fbUser: fbUser,
      email: fbUser.email,
      phoneNumber: fbUser.phoneNumber,
      isPhoneVerified: fbUser.phoneNumber != null,
    );
  }

  @override
  Future<CrushUser> signUpWithPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final callable = _functions.httpsCallable('signUpWithPassword');
    HttpsCallableResult result;
    try {
      result = await callable.call({
        'username': username,
        'email': email,
        'password': password,
      });
    } on FirebaseFunctionsException catch (e) {
      throw RepositoryException(
        e.code,
        e.message ?? 'Could not create account. Please try again.',
      );
    }
    final data = result.data;
    final token = data is Map ? data['customToken'] as String? : null;
    if (token == null || token.isEmpty) {
      throw Exception('Missing authentication token.');
    }
    final credential = await _auth.signInWithCustomToken(token);
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Failed to create user session.');
    }
    await _sessionManager.persistFromUser(fbUser);
    return _getOrCreateUserDoc(
      fbUser: fbUser,
      email: fbUser.email,
      phoneNumber: fbUser.phoneNumber,
      isPhoneVerified: fbUser.phoneNumber != null,
    );
  }

  @override
  Future<void> requestEmailOtp({
    required String identifier,
    required EmailOtpPurpose purpose,
    String? email,
  }) async {
    final callable = _functions.httpsCallable('requestEmailOtp');
    await callable.call({
      'identifier': identifier,
      'purpose': purpose.value,
      'email': email,
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
    final callable = _functions.httpsCallable('verifyEmailOtp');
    final result = await callable.call({
      'identifier': identifier,
      'otp': otp,
      'purpose': purpose.value,
      'newEmail': newEmail,
      'newPassword': newPassword,
    });

    if (purpose == EmailOtpPurpose.login) {
      final data = result.data;
      final token = data is Map ? data['customToken'] as String? : null;
      if (token == null || token.isEmpty) {
        throw Exception('Missing authentication token.');
      }
      final credential = await _auth.signInWithCustomToken(token);
      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Failed to sign in user.');
      }
      await _sessionManager.persistFromUser(fbUser);
      return _getOrCreateUserDoc(
        fbUser: fbUser,
        email: fbUser.email,
        phoneNumber: fbUser.phoneNumber,
        isPhoneVerified: fbUser.phoneNumber != null,
      );
    }

    final current = _auth.currentUser;
    if (current == null) {
      return null;
    }
    await current.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) {
      return null;
    }
    return _getOrCreateUserDoc(
      fbUser: refreshed,
      email: refreshed.email,
      phoneNumber: refreshed.phoneNumber,
      isPhoneVerified: refreshed.phoneNumber != null,
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final callable = _functions.httpsCallable('requestPasswordReset');
    try {
      await callable.call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      throw RepositoryException(
        e.code,
        e.message ?? 'Could not send code. Please try again.',
      );
    }
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final callable = _functions.httpsCallable('verifyPasswordResetOtp');
    HttpsCallableResult result;
    try {
      result = await callable.call({'email': email, 'otp': otp});
    } on FirebaseFunctionsException catch (e) {
      throw RepositoryException(
        e.code,
        e.message ?? 'Invalid or expired code. Please try again.',
      );
    }
    final data = result.data;
    final resetToken = data is Map
        ? (data['resetToken'] as String? ?? data['reset_token'] as String?)
        : null;
    if (resetToken == null || resetToken.isEmpty) {
      throw RepositoryException(
        'forgot_password_verify',
        'Invalid or expired code. Please try again.',
      );
    }
    return resetToken;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable('resetPasswordWithToken');
    try {
      await callable.call({
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (e) {
      throw RepositoryException(
        e.code,
        e.message ?? 'Could not reset password. Please try again.',
      );
    }
  }

  CrushUser _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final profileData = data['profile'] as Map<String, dynamic>?;

    Profile? profile;
    if (profileData != null) {
      final prefsData =
          (profileData['preferences'] as Map<String, dynamic>? ?? {});
      final prefs = DiscoveryPreferences(
        minAge: prefsData['minAge'] ?? CrushConstants.minAge,
        maxAge: prefsData['maxAge'] ?? 45,
        maxDistanceKm:
            (prefsData['maxDistanceKm'] ?? 50).toDouble(),
        showMeGenders:
            List<String>.from(prefsData['showMeGenders'] ?? ['female', 'male']),
        showMyDistance: prefsData['showMyDistance'] ?? true,
        showMyAge: prefsData['showMyAge'] ?? true,
        hideFromDiscovery: prefsData['hideFromDiscovery'] ?? false,
        incognitoMode: prefsData['incognitoMode'] ?? false,
        country: prefsData['country'] ?? 'Unknown',
        city: prefsData['city'] ?? 'Unknown',
      );

      profile = Profile(
        id: doc.id,
        name: profileData['name'] ?? '',
        age: (profileData['age'] ?? 18) as int,
        gender: profileData['gender'] ?? '',
        sexualOrientation: profileData['sexualOrientation'],
        bio: profileData['bio'] ?? '',
        photoUrls: List<String>.from(profileData['photoUrls'] ?? []),
        videoUrls: List<String>.from(profileData['videoUrls'] ?? []),
        prompts: List<String>.from(profileData['prompts'] ?? []),
        isVerified: profileData['isVerified'] ?? (data['isIdVerified'] ?? false),
        jobTitle: profileData['jobTitle'],
        company: profileData['company'],
        school: profileData['school'],
        interests: List<String>.from(profileData['interests'] ?? []),
        country: profileData['country'] ?? 'Unknown',
        city: profileData['city'] ?? 'Unknown',
        latitude: (profileData['latitude'] as num?)?.toDouble(),
        longitude: (profileData['longitude'] as num?)?.toDouble(),
        preferences: prefs,
      );
    }

    final planStr = data['plan'] as String? ?? 'free';
    final plan =
        planStr == 'plus' ? SubscriptionPlan.plus : SubscriptionPlan.free;

    return CrushUser(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      username: data['username'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      profile: profile,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isIdVerified: data['isIdVerified'] ?? false,
      plan: plan,
    );
  }

  @override
  Future<void> signOut() async {
    await _sessionManager.clear();
    await _auth.signOut();
  }

  Future<CrushUser> _getOrCreateUserDoc({
    required fb.User fbUser,
    String? email,
    String? phoneNumber,
    bool? isPhoneVerified,
  }) async {
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    final resolvedEmail = email ?? fbUser.email;
    final resolvedPhone = phoneNumber ?? fbUser.phoneNumber ?? '';
    final resolvedPhoneVerified =
        isPhoneVerified ?? resolvedPhone.isNotEmpty;
    final emailVerified =
        _effectiveEmailVerified(resolvedEmail, fbUser.emailVerified);
    final phoneVerified =
        _effectivePhoneVerified(resolvedPhone, resolvedPhoneVerified);

    if (!doc.exists) {
      await docRef.set({
        'phoneNumber': resolvedPhone,
        'email': resolvedEmail,
        'emailLower': resolvedEmail?.toLowerCase(),
        'isEmailVerified': emailVerified,
        'isPhoneVerified': phoneVerified,
        'isIdVerified': false,
        'plan': 'free',
      });
      return CrushUser(
        id: fbUser.uid,
        phoneNumber: resolvedPhone,
        email: resolvedEmail,
        username: null,
        isEmailVerified: emailVerified,
        profile: null,
        isPhoneVerified: phoneVerified,
        isIdVerified: false,
        plan: SubscriptionPlan.free,
      );
    }

    final user = _fromDoc(doc);
    final updates = <String, Object?>{};
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      updates['email'] = resolvedEmail;
      updates['emailLower'] = resolvedEmail.toLowerCase();
      updates['isEmailVerified'] = emailVerified;
    }
    if (resolvedPhone.isNotEmpty) {
      updates['phoneNumber'] = resolvedPhone;
      updates['isPhoneVerified'] = phoneVerified;
    }
    if (updates.isNotEmpty) {
      await docRef.update(updates);
    }

    return user.copyWith(
      email: resolvedEmail ?? user.email,
      isEmailVerified:
          resolvedEmail != null ? emailVerified : user.isEmailVerified,
      phoneNumber:
          resolvedPhone.isNotEmpty ? resolvedPhone : user.phoneNumber,
      isPhoneVerified:
          resolvedPhone.isNotEmpty ? phoneVerified : user.isPhoneVerified,
    );
  }

  Future<CrushUser> _devSignInWithPhone(String phoneNumber) async {
    final existing = _auth.currentUser;
    final fb.User fbUser;
    if (existing != null) {
      fbUser = existing;
    } else {
      final credential = await _auth.signInAnonymously();
      final created = credential.user;
      if (created == null) {
        throw Exception('Failed to create a dev session.');
      }
      fbUser = created;
    }
    await _sessionManager.persistFromUser(fbUser);
    return _getOrCreateUserDoc(
      fbUser: fbUser,
      phoneNumber: phoneNumber,
      isPhoneVerified: true,
    );
  }

  String _friendlyAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number.';
      case 'missing-phone-number':
        return 'Enter your phone number.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'weak-password':
        return 'Password should be at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      case 'operation-not-allowed':
        return 'Phone sign-in is disabled. Contact support.';
      case 'invalid-app-credential':
        return 'This app is not authorized. Check Firebase config.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Auth.';
      case 'missing-client-identifier':
        return 'Firebase Auth is not configured. Check SHA and config.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Could not send code. Please try again.';
    }
  }

}
