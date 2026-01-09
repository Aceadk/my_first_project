import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile.dart';
import '../../models/preferences.dart';
import '../../models/match.dart';
import '../discovery_repository.dart';

/// Mock implementation of DiscoveryRepository with sample profiles.
/// This allows the app to function for development/demo without a backend.
class StubDiscoveryRepository implements DiscoveryRepository {
  static const _matchesKey = 'mock_matches';
  static const _swipedKey = 'mock_swiped';

  final _random = Random();

  // Sample mock profiles for discovery
  final List<Profile> _mockProfiles = [
    const Profile(
      id: 'mock_1',
      name: 'Emma',
      age: 26,
      gender: 'Woman',
      bio: 'Coffee enthusiast ☕ | Travel addict ✈️ | Dog mom 🐕\n\nLooking for someone to explore the city with!',
      photoUrls: ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'],
      videoUrls: [],
      interests: ['Travel', 'Photography', 'Coffee', 'Hiking', 'Dogs'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: true,
      heightCm: 165,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Spanish'],
      zodiacSign: 'Leo',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Product Designer',
      company: 'Tech Startup',
      preferences: DiscoveryPreferences(minAge: 24, maxAge: 35, maxDistanceKm: 50, showMeGenders: ['Man'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_2',
      name: 'James',
      age: 29,
      gender: 'Man',
      bio: 'Software engineer by day, musician by night 🎸\n\nLet\'s grab tacos and talk about life.',
      photoUrls: ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400'],
      videoUrls: [],
      interests: ['Music', 'Coding', 'Tacos', 'Gaming', 'Fitness'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: true,
      heightCm: 183,
      relationshipGoals: 'Long-term relationship',
      languages: ['English'],
      zodiacSign: 'Virgo',
      educationLevel: 'Master\'s degree',
      jobTitle: 'Software Engineer',
      company: 'Google',
      preferences: DiscoveryPreferences(minAge: 23, maxAge: 32, maxDistanceKm: 50, showMeGenders: ['Woman'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_3',
      name: 'Sofia',
      age: 24,
      gender: 'Woman',
      bio: 'Med student 👩‍⚕️ | Foodie 🍕 | Netflix binger 📺\n\nSwipe right if you can handle my puns!',
      photoUrls: ['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400'],
      videoUrls: [],
      interests: ['Medicine', 'Cooking', 'Netflix', 'Yoga', 'Books'],
      country: 'United States',
      city: 'Los Angeles',
      isVerified: false,
      heightCm: 160,
      relationshipGoals: 'Something casual',
      languages: ['English', 'Portuguese'],
      zodiacSign: 'Pisces',
      educationLevel: 'Doctorate',
      jobTitle: 'Medical Student',
      school: 'UCLA',
      preferences: DiscoveryPreferences(minAge: 24, maxAge: 34, maxDistanceKm: 30, showMeGenders: ['Man'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'Los Angeles'),
    ),
    const Profile(
      id: 'mock_4',
      name: 'Michael',
      age: 31,
      gender: 'Man',
      bio: 'Architect who loves building things 🏗️\n\nWeekends = hiking + craft beer',
      photoUrls: ['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400'],
      videoUrls: [],
      interests: ['Architecture', 'Hiking', 'Craft Beer', 'Photography', 'Design'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: true,
      heightCm: 180,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'German'],
      zodiacSign: 'Capricorn',
      educationLevel: 'Master\'s degree',
      jobTitle: 'Architect',
      company: 'Foster + Partners',
      preferences: DiscoveryPreferences(minAge: 25, maxAge: 35, maxDistanceKm: 40, showMeGenders: ['Woman'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_5',
      name: 'Olivia',
      age: 27,
      gender: 'Woman',
      bio: 'Marketing guru 📈 | Yoga lover 🧘‍♀️ | Plant mom 🌱\n\nLooking for my adventure partner!',
      photoUrls: ['https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400'],
      videoUrls: [],
      interests: ['Marketing', 'Yoga', 'Plants', 'Sustainability', 'Wine'],
      country: 'United States',
      city: 'New York',
      isVerified: true,
      heightCm: 168,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'French'],
      zodiacSign: 'Libra',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Marketing Manager',
      company: 'Nike',
      preferences: DiscoveryPreferences(minAge: 26, maxAge: 36, maxDistanceKm: 25, showMeGenders: ['Man'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'New York'),
    ),
    const Profile(
      id: 'mock_6',
      name: 'Daniel',
      age: 28,
      gender: 'Man',
      bio: 'Chef 👨‍🍳 | Foodie at heart | Will cook for you 🍳\n\nThe way to my heart is through good conversation.',
      photoUrls: ['https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400'],
      videoUrls: [],
      interests: ['Cooking', 'Food', 'Travel', 'Wine', 'Restaurants'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: true,
      heightCm: 178,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Italian'],
      zodiacSign: 'Taurus',
      educationLevel: 'Associate degree',
      jobTitle: 'Head Chef',
      company: 'Fine Dining Restaurant',
      preferences: DiscoveryPreferences(minAge: 23, maxAge: 33, maxDistanceKm: 35, showMeGenders: ['Woman'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_7',
      name: 'Ava',
      age: 25,
      gender: 'Woman',
      bio: 'Artist 🎨 | Dreamer | Cat person 🐱\n\nLooking for someone who appreciates creativity.',
      photoUrls: ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400'],
      videoUrls: [],
      interests: ['Art', 'Painting', 'Museums', 'Cats', 'Music'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: false,
      heightCm: 163,
      relationshipGoals: 'Still figuring it out',
      languages: ['English'],
      zodiacSign: 'Aquarius',
      educationLevel: 'Bachelor\'s degree',
      jobTitle: 'Freelance Artist',
      preferences: DiscoveryPreferences(minAge: 24, maxAge: 32, maxDistanceKm: 45, showMeGenders: ['Man', 'Woman'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
    const Profile(
      id: 'mock_8',
      name: 'Noah',
      age: 30,
      gender: 'Man',
      bio: 'Entrepreneur 🚀 | Fitness junkie 💪 | Dog dad\n\nBuilding companies and meaningful connections.',
      photoUrls: ['https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400'],
      videoUrls: [],
      interests: ['Startups', 'Fitness', 'Dogs', 'Investing', 'Podcasts'],
      country: 'United States',
      city: 'San Francisco',
      isVerified: true,
      heightCm: 185,
      relationshipGoals: 'Long-term relationship',
      languages: ['English', 'Mandarin'],
      zodiacSign: 'Aries',
      educationLevel: 'MBA',
      jobTitle: 'Founder & CEO',
      company: 'Tech Startup',
      preferences: DiscoveryPreferences(minAge: 25, maxAge: 35, maxDistanceKm: 50, showMeGenders: ['Woman'], showMyDistance: true, showMyAge: true, hideFromDiscovery: false, incognitoMode: false, country: 'United States', city: 'San Francisco'),
    ),
  ];

  @override
  Future<List<Profile>> fetchDeck(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Get already swiped profiles
    final swiped = await _getSwipedProfiles(userId);

    // Filter out swiped profiles and shuffle
    final available = _mockProfiles
        .where((p) => !swiped.contains(p.id))
        .toList()
      ..shuffle(_random);

    return available;
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Record the swipe
    await _recordSwipe(userId, targetUserId, true);

    // 50% chance of instant match for demo purposes
    if (_random.nextBool()) {
      final matchedProfile = _mockProfiles.firstWhere(
        (p) => p.id == targetUserId,
        orElse: () => _mockProfiles.first,
      );

      final match = CrushMatch(
        id: 'match_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        otherUserId: targetUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount: 0,
        pinnedForUser: false,
        otherUserName: matchedProfile.name,
        otherUserPhotoUrl: matchedProfile.photoUrls.isNotEmpty
            ? matchedProfile.photoUrls.first
            : null,
      );

      await _saveMatch(userId, match);
      return match;
    }

    return null;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _recordSwipe(userId, targetUserId, false);
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Return top 3 verified profiles as "top picks"
    return _mockProfiles
        .where((p) => p.isVerified)
        .take(3)
        .toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Return 2 random profiles as "likes you" for demo
    final shuffled = List<Profile>.from(_mockProfiles)..shuffle(_random);
    return shuffled.take(2).toList();
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _getMatches(userId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Set<String>> _getSwipedProfiles(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final swipedJson = prefs.getString('${_swipedKey}_$userId');
    if (swipedJson == null) return {};
    return Set<String>.from(jsonDecode(swipedJson));
  }

  Future<void> _recordSwipe(String userId, String targetId, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    final swiped = await _getSwipedProfiles(userId);
    swiped.add(targetId);
    await prefs.setString('${_swipedKey}_$userId', jsonEncode(swiped.toList()));
  }

  Future<void> _saveMatch(String userId, CrushMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('${_matchesKey}_$userId');
    final matches = matchesJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(matchesJson))
        : <Map<String, dynamic>>[];

    matches.add(_matchToJson(match));
    await prefs.setString('${_matchesKey}_$userId', jsonEncode(matches));
  }

  Future<List<CrushMatch>> _getMatches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString('${_matchesKey}_$userId');
    if (matchesJson == null) return [];

    final matchesList = List<Map<String, dynamic>>.from(jsonDecode(matchesJson));
    return matchesList.map((m) => _matchFromJson(m)).toList();
  }

  Map<String, dynamic> _matchToJson(CrushMatch match) {
    return {
      'id': match.id,
      'userId': match.userId,
      'otherUserId': match.otherUserId,
      'status': match.status.name,
      'preMatchMessageRequestsCount': match.preMatchMessageRequestsCount,
      'pinnedForUser': match.pinnedForUser,
      'otherUserName': match.otherUserName,
      'otherUserPhotoUrl': match.otherUserPhotoUrl,
    };
  }

  CrushMatch _matchFromJson(Map<String, dynamic> json) {
    return CrushMatch(
      id: json['id'],
      userId: json['userId'],
      otherUserId: json['otherUserId'],
      status: MatchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MatchStatus.mutual,
      ),
      preMatchMessageRequestsCount: json['preMatchMessageRequestsCount'] ?? 0,
      pinnedForUser: json['pinnedForUser'] ?? false,
      otherUserName: json['otherUserName'],
      otherUserPhotoUrl: json['otherUserPhotoUrl'],
    );
  }

}
