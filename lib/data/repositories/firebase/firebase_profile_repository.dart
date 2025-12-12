import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../models/user.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/subscription.dart';
import '../../../core/constants.dart';
import '../profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseProfileRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_uid);

  @override
  Future<CrushUser?> getCurrentUser() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  @override
  Future<CrushUser> saveBasicInfo({
    required String name,
    required int age,
    required String gender,
    String? sexualOrientation,
  }) async {
    if (age < CrushConstants.minAge) {
      throw Exception('User must be at least ${CrushConstants.minAge}.');
    }

    final doc = await _userDoc.get();
    if (!doc.exists) {
      throw Exception('User document missing.');
    }

    const prefs = DiscoveryPreferences(
      minAge: CrushConstants.minAge,
      maxAge: 45,
      maxDistanceKm: 50,
      showMeGenders: ['women', 'men'],
      showMyDistance: true,
      showMyAge: true,
      hideFromDiscovery: false,
      incognitoMode: false,
      country: 'Unknown',
      city: 'Unknown',
    );

    final profile = {
      'name': name,
      'age': age,
      'gender': gender,
      'sexualOrientation': sexualOrientation,
      'bio': '',
      'photoUrls': <String>[],
      'videoUrls': <String>[],
      'isVerified': false,
      'jobTitle': null,
      'company': null,
      'school': null,
      'interests': <String>[],
      'country': prefs.country,
      'city': prefs.city,
      'latitude': null,
      'longitude': null,
      'preferences': {
        'minAge': prefs.minAge,
        'maxAge': prefs.maxAge,
        'maxDistanceKm': prefs.maxDistanceKm,
        'showMeGenders': prefs.showMeGenders,
        'showMyDistance': prefs.showMyDistance,
        'showMyAge': prefs.showMyAge,
        'hideFromDiscovery': prefs.hideFromDiscovery,
        'incognitoMode': prefs.incognitoMode,
        'country': prefs.country,
        'city': prefs.city,
      },
    };

    await _userDoc.update({'profile': profile});

    final updatedDoc = await _userDoc.get();
    return _fromDoc(updatedDoc);
  }

  @override
  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    required List<String> videoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
  }) async {
    final doc = await _userDoc.get();
    if (!doc.exists) throw Exception('User document missing.');

    final data = doc.data()!;
    final profile = (data['profile'] as Map<String, dynamic>? ?? {});

    profile['bio'] = bio;
    profile['photoUrls'] = photoUrls;
    profile['videoUrls'] = videoUrls;
    profile['isVerified'] = data['isIdVerified'] ?? profile['isVerified'] ?? false;
    profile['jobTitle'] = jobTitle;
    profile['company'] = company;
    profile['school'] = school;
    profile['interests'] = interests;

    await _userDoc.update({'profile': profile});

    final updated = await _userDoc.get();
    return _fromDoc(updated);
  }

  @override
  Future<void> uploadIdDocument(/* you can pass File here later */) async {
    // Example: upload a placeholder file.
    // In real app, pass a File, upload to storage, then record metadata.
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<CrushUser> markIdVerified() async {
    await _userDoc.update({
      'isIdVerified': true,
      'profile.isVerified': true,
    });
    final updated = await _userDoc.get();
    return _fromDoc(updated);
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    final profileMap = {
      'name': profile.name,
      'age': profile.age,
      'gender': profile.gender,
      'sexualOrientation': profile.sexualOrientation,
      'bio': profile.bio,
      'photoUrls': profile.photoUrls,
      'videoUrls': profile.videoUrls,
      'isVerified': profile.isVerified,
      'jobTitle': profile.jobTitle,
      'company': profile.company,
      'school': profile.school,
      'interests': profile.interests,
      'country': profile.country,
      'city': profile.city,
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'preferences': {
        'minAge': profile.preferences.minAge,
        'maxAge': profile.preferences.maxAge,
        'maxDistanceKm': profile.preferences.maxDistanceKm,
        'showMeGenders': profile.preferences.showMeGenders,
        'showMyDistance': profile.preferences.showMyDistance,
        'showMyAge': profile.preferences.showMyAge,
        'hideFromDiscovery': profile.preferences.hideFromDiscovery,
        'incognitoMode': profile.preferences.incognitoMode,
        'country': profile.preferences.country,
        'city': profile.preferences.city,
      },
    };

    await _userDoc.update({'profile': profileMap});
    final updated = await _userDoc.get();
    return _fromDoc(updated);
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
        age: (profileData['age'] ?? CrushConstants.minAge) as int,
        gender: profileData['gender'] ?? '',
        sexualOrientation: profileData['sexualOrientation'],
        bio: profileData['bio'] ?? '',
        photoUrls: List<String>.from(profileData['photoUrls'] ?? []),
        videoUrls: List<String>.from(profileData['videoUrls'] ?? []),
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
}
