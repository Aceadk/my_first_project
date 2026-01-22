import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import '../discovery_repository.dart';

/// Firebase implementation of DiscoveryRepository.
class FirebaseDiscoveryRepository implements DiscoveryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
  }) async {
    final callable = _functions.httpsCallable('fetchDiscoveryCandidates');
    final result = await callable.call<Map<String, dynamic>>({
      if (filter.maxDistanceKm != null) 'maxDistanceKm': filter.maxDistanceKm,
      'passportModeEnabled': filter.passportModeEnabled,
      if (filter.effectiveLatitude != null) 'latitude': filter.effectiveLatitude,
      if (filter.effectiveLongitude != null) 'longitude': filter.effectiveLongitude,
    });

    final candidates = result.data['candidates'] as List<dynamic>? ?? [];
    return candidates
        .map((c) => _profileFromFirestore(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    final callable = _functions.httpsCallable('swipeRight');
    final result = await callable.call<Map<String, dynamic>>({
      'targetUserId': targetUserId,
      if (attachedMessage != null) 'attachedMessage': attachedMessage,
    });

    final data = result.data;
    final matched = data['matched'] as bool? ?? false;

    if (matched) {
      final matchId = data['matchId'] as String?;
      if (matchId != null) {
        return CrushMatch(
          id: matchId,
          userId: userId,
          otherUserId: targetUserId,
          status: MatchStatus.mutual,
          preMatchMessageRequestsCount: 0,
          pinnedForUser: false,
          otherUserName: data['otherUserName'] as String?,
          otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
        );
      }
    }

    return null;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    final callable = _functions.httpsCallable('swipeLeft');
    await callable.call<Map<String, dynamic>>({
      'targetUserId': targetUserId,
    });
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    // Top picks could be a separate function or filtered from discovery
    final callable = _functions.httpsCallable('fetchDiscoveryCandidates');
    final result = await callable.call<Map<String, dynamic>>({
      'topPicksOnly': true,
    });

    final candidates = result.data['candidates'] as List<dynamic>? ?? [];
    return candidates
        .take(10) // Limit top picks
        .map((c) => _profileFromFirestore(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    // Fetch users who liked the current user (premium feature)
    final likesQuery = await _firestore
        .collection('likes')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final profiles = <Profile>[];
    for (final likeDoc in likesQuery.docs) {
      final likerId = likeDoc.data()['fromUserId'] as String?;
      if (likerId != null) {
        final userDoc = await _firestore.collection('users').doc(likerId).get();
        if (userDoc.exists) {
          final profileData = userDoc.data()?['profile'] as Map<String, dynamic>?;
          if (profileData != null) {
            profiles.add(_profileFromFirestore({
              'id': likerId,
              ...profileData,
            }));
          }
        }
      }
    }

    return profiles;
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    final matchesQuery = await _firestore
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .where('status', isEqualTo: 'mutual')
        .orderBy('matchedAt', descending: true)
        .limit(100)
        .get();

    return matchesQuery.docs.map((doc) {
      final data = doc.data();
      final userIds = List<String>.from(data['userIds'] ?? []);
      final otherUserId = userIds.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      return CrushMatch(
        id: doc.id,
        userId: userId,
        otherUserId: otherUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount:
            data['preMatchMessageRequestsCount'] as int? ?? 0,
        pinnedForUser: (data['pinnedBy'] as List<dynamic>?)?.contains(userId) ?? false,
        otherUserName: data['otherUserName'] as String?,
        otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<CrushMatch?> superLike({
    required String userId,
    required String targetUserId,
  }) async {
    // Call cloud function for super like
    final result = await _functions.httpsCallable('superLike').call({
      'targetUserId': targetUserId,
    });

    final data = result.data as Map<String, dynamic>?;
    if (data != null && data['isMatch'] == true) {
      return CrushMatch(
        id: data['matchId'] ?? 'match_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        otherUserId: targetUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount: 0,
        pinnedForUser: false,
      );
    }

    return null;
  }

  @override
  Future<Profile?> rewindLastSwipe(String userId) async {
    // Call cloud function for rewind
    final result = await _functions.httpsCallable('rewindSwipe').call({});

    final data = result.data as Map<String, dynamic>?;
    if (data != null && data['profile'] != null) {
      return _profileFromFirestore(data['profile'] as Map<String, dynamic>);
    }

    return null;
  }
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Profile _profileFromFirestore(Map<String, dynamic> data) {
    return Profile(
      id: data['id'] ?? data['userId'] ?? '',
      name: data['name'] ?? '',
      lastName: data['lastName'],
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      sexualOrientation: data['sexualOrientation'],
      bio: data['bio'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      primaryPhotoIndex: data['primaryPhotoIndex'] ?? 0,
      interests: List<String>.from(data['interests'] ?? []),
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      isVerified: data['isVerified'] ?? false,
      heightCm: data['heightCm'],
      relationshipGoals: data['relationshipGoals'],
      languages: List<String>.from(data['languages'] ?? []),
      zodiacSign: data['zodiacSign'],
      educationLevel: data['educationLevel'],
      familyPlans: data['familyPlans'],
      personalityType: data['personalityType'],
      workout: data['workout'],
      smoking: data['smoking'],
      drinking: data['drinking'],
      pets: data['pets'],
      jobTitle: data['jobTitle'],
      company: data['company'],
      school: data['school'],
      preferences: _preferencesFromFirestore(data['preferences']),
      privacySettings: ProfilePrivacySettings.fromJson(
        data['privacySettings'] as Map<String, dynamic>?,
      ),
    );
  }

  DiscoveryPreferences _preferencesFromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return const DiscoveryPreferences(
        minAge: 18,
        maxAge: 50,
        maxDistanceKm: 100,
        showMeGenders: ['All'],
        showMyDistance: true,
        showMyAge: true,
        hideFromDiscovery: false,
        incognitoMode: false,
        country: '',
        city: '',
      );
    }

    return DiscoveryPreferences(
      minAge: data['minAge'] ?? 18,
      maxAge: data['maxAge'] ?? 50,
      maxDistanceKm: (data['maxDistanceKm'] ?? 100).toDouble(),
      showMeGenders: List<String>.from(data['showMeGenders'] ?? ['All']),
      showMyDistance: data['showMyDistance'] ?? true,
      showMyAge: data['showMyAge'] ?? true,
      hideFromDiscovery: data['hideFromDiscovery'] ?? false,
      incognitoMode: data['incognitoMode'] ?? false,
      country: data['country'] ?? '',
      city: data['city'] ?? '',
    );
  }

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    final userDoc = await _firestore.collection('users').doc(profileId).get();
    if (!userDoc.exists) return null;

    final profileData = userDoc.data()?['profile'] as Map<String, dynamic>?;
    if (profileData == null) return null;

    return _profileFromFirestore({
      'id': profileId,
      ...profileData,
    });
  }
}
