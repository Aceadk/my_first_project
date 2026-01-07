import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/match.dart';
import '../../services/recommendation_api.dart';
import '../../../core/constants.dart';
import '../discovery_repository.dart';

class FirebaseDiscoveryRepository implements DiscoveryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final RecommendationApi _reco;

  FirebaseDiscoveryRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    required RecommendationApi recommendationApi,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _reco = recommendationApi;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  @override
  Future<List<Profile>> fetchDeck(String userId) async {
    // Return dummy profiles for dev bypass users
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      return _generateDummyProfiles();
    }

    try {
      final callable = _functions.httpsCallable('fetchDiscoveryCandidates');
      final result = await callable.call(<String, dynamic>{'limit': 50});
      final data = result.data as Map<dynamic, dynamic>;
      final profiles = (data['profiles'] as List<dynamic>? ?? [])
          .map((entry) => _profileFromRemote(entry))
          .toList();
      if (profiles.isNotEmpty) return profiles;
    } catch (_) {
      // fall back to existing recommendation pipeline
    }

    final ids = await _reco.fetchRecommendations(limit: 50);
    if (ids.isEmpty) return [];
    return _fetchProfilesByIds(ids);
  }

  List<Profile> _generateDummyProfiles() {
    const names = [
      'Emma', 'Olivia', 'Ava', 'Sophia', 'Isabella',
      'Mia', 'Charlotte', 'Amelia', 'Harper', 'Evelyn',
      'Liam', 'Noah', 'Oliver', 'James', 'Elijah',
      'William', 'Henry', 'Lucas', 'Benjamin', 'Mason',
    ];
    const bios = [
      'Love hiking and outdoor adventures! 🏔️',
      'Coffee enthusiast and bookworm 📚☕',
      'Traveling the world one city at a time ✈️',
      'Fitness lover and foodie 🏋️‍♀️🍕',
      'Music is my passion 🎵',
      'Dog parent and proud of it 🐕',
      'Looking for someone to share adventures with',
      'Let\'s grab coffee and see where it goes!',
    ];
    const interests = [
      ['Travel', 'Photography', 'Hiking'],
      ['Music', 'Movies', 'Reading'],
      ['Fitness', 'Yoga', 'Cooking'],
      ['Art', 'Museums', 'Coffee'],
      ['Dogs', 'Nature', 'Beach'],
    ];
    const genders = ['female', 'male'];

    return List.generate(20, (index) {
      final gender = genders[index % 2];
      final nameIndex = index % names.length;
      return Profile(
        id: 'dummy-profile-$index',
        name: names[nameIndex],
        age: 22 + (index % 10),
        gender: gender,
        sexualOrientation: null,
        bio: bios[index % bios.length],
        photoUrls: [
          'https://picsum.photos/seed/dummy$index/400/600',
          'https://picsum.photos/seed/dummy${index}b/400/600',
        ],
        videoUrls: const [],
        prompts: const [],
        isVerified: index % 3 == 0,
        jobTitle: index % 2 == 0 ? 'Software Engineer' : 'Designer',
        company: index % 2 == 0 ? 'Tech Corp' : 'Creative Studio',
        school: 'University of Demo',
        interests: interests[index % interests.length],
        country: 'United States',
        city: 'San Francisco',
        latitude: 37.7749,
        longitude: -122.4194,
        preferences: const DiscoveryPreferences(
          minAge: 18,
          maxAge: 45,
          maxDistanceKm: 50,
          showMeGenders: ['female', 'male'],
          showMyDistance: true,
          showMyAge: true,
          hideFromDiscovery: false,
          incognitoMode: false,
          country: 'United States',
          city: 'San Francisco',
        ),
      );
    });
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    // Dev bypass: simulate match on every 3rd swipe
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      final shouldMatch = targetUserId.hashCode % 3 == 0;
      if (!shouldMatch) return null;
      return CrushMatch(
        id: 'dummy-match-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        otherUserId: targetUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount: 0,
        pinnedForUser: false,
      );
    }

    final callable = _functions.httpsCallable('swipeRight');
    final result = await callable.call(<String, dynamic>{
      'targetUserId': targetUserId,
      'attachedMessage': attachedMessage,
    });

    final data = result.data as Map<dynamic, dynamic>;
    final matched = data['matched'] == true;
    if (!matched) return null;

    final matchId = data['matchId'] as String;
    final matchDoc = await _matches.doc(matchId).get();
    final matchData = matchDoc.data()!;
    final userIds = List<String>.from(matchData['userIds'] ?? []);
    final otherUser =
        userIds.firstWhere((id) => id != userId, orElse: () => targetUserId);

    final statusStr = matchData['status'] as String? ?? 'mutual';
    final status = _statusFromString(statusStr);
    final preMap =
        (matchData['preMatchRequests'] as Map<String, dynamic>? ?? {});
    final preCount = (preMap[userId] as num?)?.toInt() ?? 0;
    final pinnedMap =
        (matchData['pinnedForUser'] as Map<String, dynamic>? ?? {});
    final pinned = pinnedMap[userId] ?? false;

    return CrushMatch(
      id: matchId,
      userId: userId,
      otherUserId: otherUser,
      status: status,
      preMatchMessageRequestsCount: preCount,
      pinnedForUser: pinned,
    );
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    // Dev bypass: no-op for swipe left
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      return;
    }
    // Optional: you can create a 'passes' collection, but not required for MVP.
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    // Dev bypass: return subset of dummy profiles
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      return _generateDummyProfiles().take(10).toList();
    }

    final ids = await _reco.fetchTopPicks(limit: 10);
    if (ids.isEmpty) return [];
    return _fetchProfilesByIds(ids);
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    // Dev bypass: return some dummy profiles as "likes"
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      return _generateDummyProfiles().skip(10).take(5).toList();
    }

    final ids = await _reco.fetchLikesYou(limit: 50);
    if (ids.isEmpty) return [];
    return _fetchProfilesByIds(ids);
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    // Dev bypass: return empty matches
    if (!kReleaseMode && userId.startsWith('dev-admin-')) {
      return [];
    }

    final q = await _matches
        .where('userIds', arrayContains: userId)
        .get();

    return q.docs.map((doc) {
      final data = doc.data();
      final userIds = List<String>.from(data['userIds'] ?? []);
      final other =
          userIds.firstWhere((id) => id != userId, orElse: () => '');
      final statusStr = data['status'] as String? ?? 'pending';
      final status = _statusFromString(statusStr);
      final preMap =
          (data['preMatchRequests'] as Map<String, dynamic>? ?? {});
      final preCount = (preMap[userId] as num?)?.toInt() ?? 0;
      final pinnedMap =
          (data['pinnedForUser'] as Map<String, dynamic>? ?? {});
      final pinned = pinnedMap[userId] ?? false;

      return CrushMatch(
        id: doc.id,
        userId: userId,
        otherUserId: other,
        status: status,
        preMatchMessageRequestsCount: preCount,
        pinnedForUser: pinned,
      );
    }).toList();
  }

  Future<List<Profile>> _fetchProfilesByIds(List<String> ids) async {
    final List<Profile> profiles = [];
    if (ids.isEmpty) return profiles;

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }

    final map = <String, Profile>{};
    for (final chunk in chunks) {
      final snap = await _users.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final profileData = data['profile'] as Map<String, dynamic>?;
        if (profileData == null) continue;
        map[doc.id] = _profileFromData(doc.id, profileData);
      }
    }

    for (final id in ids) {
      final profile = map[id];
      if (profile != null) {
        profiles.add(profile);
      }
    }
    return profiles;
  }

  Profile _profileFromData(String id, Map<String, dynamic> profileData) {
    final prefsData = (profileData['preferences'] as Map<String, dynamic>? ?? {});
    final prefs = DiscoveryPreferences(
      minAge: prefsData['minAge'] ?? CrushConstants.minAge,
      maxAge: prefsData['maxAge'] ?? 45,
      maxDistanceKm: (prefsData['maxDistanceKm'] ?? 50).toDouble(),
      showMeGenders:
          List<String>.from(prefsData['showMeGenders'] ?? ['female', 'male']),
      showMyDistance: prefsData['showMyDistance'] ?? true,
      showMyAge: prefsData['showMyAge'] ?? true,
      hideFromDiscovery: prefsData['hideFromDiscovery'] ?? false,
      incognitoMode: prefsData['incognitoMode'] ?? false,
      country: prefsData['country'] ?? 'Unknown',
      city: prefsData['city'] ?? 'Unknown',
    );

    return Profile(
      id: id,
      name: profileData['name'] ?? '',
      age: (profileData['age'] ?? CrushConstants.minAge) as int,
      gender: profileData['gender'] ?? '',
      sexualOrientation: profileData['sexualOrientation'],
      bio: profileData['bio'] ?? '',
      photoUrls: List<String>.from(profileData['photoUrls'] ?? []),
      videoUrls: List<String>.from(profileData['videoUrls'] ?? []),
      prompts: List<String>.from(profileData['prompts'] ?? []),
      isVerified: profileData['isVerified'] ?? false,
      jobTitle: profileData['jobTitle'],
      company: profileData['company'],
      school: profileData['school'],
      interests: List<String>.from(profileData['interests'] ?? []),
      verificationBadge: profileData['verificationBadge'],
      drinking: profileData['drinking'],
      smoking: profileData['smoking'],
      diet: profileData['diet'],
      exercise: profileData['exercise'],
      country: profileData['country'] ?? 'Unknown',
      city: profileData['city'] ?? 'Unknown',
      latitude: (profileData['latitude'] as num?)?.toDouble(),
      longitude: (profileData['longitude'] as num?)?.toDouble(),
      preferences: prefs,
    );
  }

  Profile _profileFromRemote(dynamic payload) {
    if (payload is Map<dynamic, dynamic>) {
      final id = payload['id'] as String? ?? '';
      final profileMap = (payload['profile'] as Map<dynamic, dynamic>? ?? {})
          .map((key, value) => MapEntry(key.toString(), value));
      if (id.isNotEmpty && profileMap.isNotEmpty) {
        return _profileFromData(id, profileMap);
      }
    }
    return _profileFromData(
      '',
      const {
        'name': '',
        'age': CrushConstants.minAge,
        'gender': '',
        'bio': '',
        'photoUrls': <String>[],
        'videoUrls': <String>[],
        'prompts': <String>[],
        'isVerified': false,
        'jobTitle': null,
        'company': null,
        'school': null,
        'interests': <String>[],
        'country': 'Unknown',
        'city': 'Unknown',
        'latitude': null,
        'longitude': null,
        'preferences': {
          'minAge': CrushConstants.minAge,
          'maxAge': 45,
          'maxDistanceKm': 50,
          'showMeGenders': ['female', 'male'],
          'showMyDistance': true,
          'showMyAge': true,
          'hideFromDiscovery': false,
          'incognitoMode': false,
          'country': 'Unknown',
          'city': 'Unknown',
        },
      },
    );
  }

  MatchStatus _statusFromString(String s) {
    switch (s) {
      case 'mutual':
        return MatchStatus.mutual;
      case 'rejected':
        return MatchStatus.rejected;
      case 'unmatched':
        return MatchStatus.unmatched;
      case 'pending':
      default:
        return MatchStatus.pending;
    }
  }
}
