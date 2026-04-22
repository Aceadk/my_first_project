import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/preferences.dart';
import 'package:crushhour/data/models/privacy_settings.dart';
import 'package:crushhour/features/discovery/domain/repositories/discovery_repository.dart';

/// Firebase implementation of DiscoveryRepository.
class FirebaseDiscoveryRepository implements DiscoveryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  DiscoveryDeckPageInfo? _lastDeckPageInfo;

  @override
  DiscoveryDeckPageInfo? get lastDeckPageInfo => _lastDeckPageInfo;

  @override
  Future<List<Profile>> fetchDeck(
    String userId, {
    DiscoveryFilter filter = const DiscoveryFilter(),
    String? cursor,
  }) async {
    final callable = _functions.httpsCallable('fetchDiscoveryCandidates');
    final payload = <String, dynamic>{
      if (filter.maxDistanceKm != null) 'maxDistanceKm': filter.maxDistanceKm,
      'passportModeEnabled': filter.passportModeEnabled,
      if (filter.effectiveLatitude != null)
        'latitude': filter.effectiveLatitude,
      if (filter.effectiveLongitude != null)
        'longitude': filter.effectiveLongitude,
    };
    if (cursor != null) {
      payload['cursor'] = cursor;
    }

    final result = await callable.call<Map<String, dynamic>>(payload);

    _lastDeckPageInfo = DiscoveryDeckPageInfo(
      hasMore: result.data['hasMore'] as bool? ?? false,
      nextCursor: result.data['nextCursor'] as String?,
    );

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
      'attachedMessage': ?attachedMessage,
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
    await callable.call<Map<String, dynamic>>({'targetUserId': targetUserId});
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

    // Collect unique liker IDs
    final likerIds = likesQuery.docs
        .map((doc) => doc.data()['fromUserId'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (likerIds.isEmpty) return const [];

    // Batch fetch user profiles (Firestore whereIn limit is 30)
    final userDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < likerIds.length; i += 30) {
      final batch = likerIds.sublist(
        i,
        i + 30 > likerIds.length ? likerIds.length : i + 30,
      );
      final batchResult = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      userDocs.addAll(batchResult.docs);
    }

    // Build profiles from fetched user docs
    final userMap = {for (final doc in userDocs) doc.id: doc};
    final profiles = <Profile>[];
    for (final likerId in likerIds) {
      final userDoc = userMap[likerId];
      if (userDoc != null && userDoc.exists) {
        final profileData = userDoc.data()?['profile'] as Map<String, dynamic>?;
        if (profileData != null) {
          profiles.add(_profileFromFirestore({'id': likerId, ...profileData}));
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
        .where('status', isEqualTo: 'active')
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
        pinnedForUser:
            (data['pinnedBy'] as List<dynamic>?)?.contains(userId) ?? false,
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
    final result = await _functions.httpsCallable('swipeRight').call({
      'targetUserId': targetUserId,
    });

    final data = result.data as Map<String, dynamic>?;
    final isMatch =
        data != null && (data['isMatch'] == true || data['matched'] == true);
    if (isMatch) {
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
    // The callable backend does not currently expose reversible swipe state.
    // Return null instead of depending on a missing function name.
    return null;
  }
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Profile _profileFromFirestore(Map<String, dynamic> data) {
    // Parse distance from Cloud Function response (distanceKm field)
    final distanceKm = data['distanceKm'] as num?;

    return Profile(
      id: data['id'] ?? data['userId'] ?? '',
      username: data['username'], // Username for deck display
      name: data['name'] ?? '',
      lastName: data['lastName'],
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      sexualOrientation: data['sexualOrientation'],
      bio: data['bio'] ?? '',
      // Filter to only include valid remote URLs (exclude any accidentally saved local paths)
      photoUrls: List<String>.from(data['photoUrls'] ?? [])
          .where(
            (url) => url.startsWith('http://') || url.startsWith('https://'),
          )
          .toList(),
      videoUrls: List<String>.from(data['videoUrls'] ?? [])
          .where(
            (url) => url.startsWith('http://') || url.startsWith('https://'),
          )
          .toList(),
      primaryPhotoIndex: data['primaryPhotoIndex'] ?? 0,
      interests: List<String>.from(data['interests'] ?? []),
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      distance: distanceKm?.toDouble(), // Distance from Cloud Function
      distanceUnit: 'km',
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? false,
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

  @override
  Future<Profile?> fetchProfileById(String profileId) async {
    final userDoc = await _firestore.collection('users').doc(profileId).get();
    if (!userDoc.exists) return null;

    final userData = userDoc.data();
    final profileData = userData?['profile'] as Map<String, dynamic>?;
    if (profileData == null) return null;

    return _profileFromFirestore({
      'id': profileId,
      'username': userData?['username'], // Username is at user doc level
      ...profileData,
    });
  }
}
