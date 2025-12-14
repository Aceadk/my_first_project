import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../../models/user.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/subscription.dart';
import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? _verificationId;
  int? _resendToken;

  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<CrushUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fb.User? fbUser) async {
      if (fbUser == null) return null;
      final userDoc =
          await _firestore.collection('users').doc(fbUser.uid).get();
      if (!userDoc.exists) {
        // create basic doc with defaults
        final user = CrushUser(
          id: fbUser.uid,
          phoneNumber: fbUser.phoneNumber ?? '',
          email: fbUser.email,
          profile: null,
          isPhoneVerified: fbUser.phoneNumber != null,
          isIdVerified: false,
          plan: SubscriptionPlan.free,
        );
        await _firestore.collection('users').doc(fbUser.uid).set({
          'phoneNumber': user.phoneNumber,
          'email': user.email,
          'isPhoneVerified': user.isPhoneVerified,
          'isIdVerified': user.isIdVerified,
          'plan': 'free',
        });
        return user;
      } else {
        return _fromDoc(userDoc);
      }
    });
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto verification on some devices
        await _auth.signInWithCredential(credential);
        completer.complete();
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        completer.complete();
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

    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      // Create new user doc
      await docRef.set({
        'phoneNumber': phoneNumber,
        'email': fbUser.email,
        'isPhoneVerified': true,
        'isIdVerified': false,
        'plan': 'free',
      });
      return CrushUser(
        id: fbUser.uid,
        phoneNumber: phoneNumber,
        email: fbUser.email,
        profile: null,
        isPhoneVerified: true,
        isIdVerified: false,
        plan: SubscriptionPlan.free,
      );
    } else {
      final user = _fromDoc(doc);
      // Ensure phone is set + verified
      await docRef.update({
        'phoneNumber': phoneNumber,
        'isPhoneVerified': true,
      });
      return user.copyWith(
        phoneNumber: phoneNumber,
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
            List<String>.from(prefsData['showMeGenders'] ?? ['women', 'men']),
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
      profile: profile,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isIdVerified: data['isIdVerified'] ?? false,
      plan: plan,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
