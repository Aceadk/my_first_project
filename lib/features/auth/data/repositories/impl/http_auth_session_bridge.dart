import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'firebase_auth_repository.dart';

abstract class HttpAuthSessionBridge {
  Stream<CrushUser?> authStateChanges();

  Future<String?> getIdToken({bool forceRefresh = false});

  Future<void> signInWithCustomToken(String customToken);

  Future<void> sendOtp(String phoneNumber);

  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> sendEmailSignInLink(String email);

  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  Future<CrushUser> signInWithGoogle();

  Future<CrushUser> signInWithApple();

  Future<void> signOut();

  Future<void> sendEmailVerification();

  Future<CrushUser?> checkEmailVerification();

  Future<void> schedulePhoneDeletion();

  Future<void> deactivateAccount({required String reason});

  Future<CrushUser> acceptTermsAndConditions();

  Future<CrushUser?> refreshCurrentUser();

  void dispose();
}

class FirebaseHttpAuthSessionBridge implements HttpAuthSessionBridge {
  FirebaseHttpAuthSessionBridge({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FlutterSecureStorage? secureStorage,
  }) : _firebaseAuthOverride = firebaseAuth,
       _firestoreOverride = firestore,
       _functionsOverride = functions,
       _secureStorageOverride = secureStorage;

  final fb.FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final FlutterSecureStorage? _secureStorageOverride;

  // Lazily resolved so that constructing the DI graph (e.g. http mode in
  // tests) does not require Firebase.initializeApp to have run.
  late final fb.FirebaseAuth _firebaseAuth =
      _firebaseAuthOverride ?? fb.FirebaseAuth.instance;
  late final FirebaseAuthRepository _delegate = FirebaseAuthRepository(
    firebaseAuth: _firebaseAuthOverride ?? fb.FirebaseAuth.instance,
    firestore: _firestoreOverride ?? FirebaseFirestore.instance,
    functions: _functionsOverride ?? FirebaseFunctions.instance,
    secureStorage: _secureStorageOverride,
  );

  @override
  Stream<CrushUser?> authStateChanges() => _delegate.authStateChanges();

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return firebaseUser.getIdToken(forceRefresh);
  }

  @override
  Future<void> signInWithCustomToken(String customToken) async {
    await _firebaseAuth.signInWithCustomToken(customToken);
    await _delegate.refreshCurrentUser();
  }

  @override
  Future<void> sendOtp(String phoneNumber) => _delegate.sendOtp(phoneNumber);

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return _delegate.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }

  @override
  Future<void> sendEmailSignInLink(String email) {
    return _delegate.sendEmailSignInLink(email);
  }

  @override
  Future<CrushUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _delegate.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  @override
  Future<CrushUser> signInWithGoogle() => _delegate.signInWithGoogle();

  @override
  Future<CrushUser> signInWithApple() => _delegate.signInWithApple();

  @override
  Future<void> signOut() => _delegate.signOut();

  @override
  Future<void> sendEmailVerification() => _delegate.sendEmailVerification();

  @override
  Future<CrushUser?> checkEmailVerification() {
    return _delegate.checkEmailVerification();
  }

  @override
  Future<void> schedulePhoneDeletion() => _delegate.schedulePhoneDeletion();

  @override
  Future<void> deactivateAccount({required String reason}) {
    return _delegate.deactivateAccount(reason: reason);
  }

  @override
  Future<CrushUser> acceptTermsAndConditions() {
    return _delegate.acceptTermsAndConditions();
  }

  @override
  Future<CrushUser?> refreshCurrentUser() => _delegate.refreshCurrentUser();

  @override
  void dispose() {
    _delegate.dispose();
  }
}
