import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../models/preferences.dart';
import '../models/match.dart';
import '../models/message.dart';
import '../models/subscription.dart';
import 'auth_repository.dart';
import 'profile_repository.dart';
import 'discovery_repository.dart';
import 'chat_repository.dart';
import 'subscription_repository.dart';
import '../../core/constants.dart';

const _uuid = Uuid();
const _backendBaseUrl = String.fromEnvironment(
  'CRUSH_API_BASE_URL',
  defaultValue: 'https://api.crushhour.dev',
);

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<CrushUser?>.broadcast();
  CrushUser? _current;
  final _otpStore = <String, _OtpEntry>{};
  final _rand = Random.secure();

  @override
  Stream<CrushUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    final otp = (_rand.nextInt(900000) + 100000).toString(); // 6-digit
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    _otpStore[phoneNumber] = _OtpEntry(code: otp, expiresAt: expiresAt);

    // Attempt to hit backend if available; ignore failures for local dev.
    try {
      final uri = Uri.parse('$_backendBaseUrl/auth/otp/send');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}

    // For local testing, surface the OTP in logs.
    // ignore: avoid_print
    print('OTP for $phoneNumber: $otp (expires at $expiresAt)');
  }

  @override
  Future<CrushUser> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final stored = _otpStore[phoneNumber];
    if (stored == null || DateTime.now().isAfter(stored.expiresAt)) {
      throw Exception(
          'OTP expired or not requested. Please request a new code.');
    }
    if (stored.code != otp) {
      throw Exception('Invalid OTP.');
    }
    _otpStore.remove(phoneNumber);
    await Future.delayed(const Duration(milliseconds: 500));
    _current ??= CrushUser(
      id: _uuid.v4(),
      phoneNumber: phoneNumber,
      email: null,
      profile: null,
      isPhoneVerified: true,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
    );
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}

class _OtpEntry {
  final String code;
  final DateTime expiresAt;

  _OtpEntry({required this.code, required this.expiresAt});
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<SubscriptionPlan>.broadcast()
    ..add(SubscriptionPlan.free);
  SubscriptionPlan _current = SubscriptionPlan.free;

  @override
  Stream<SubscriptionPlan> watchPlan() => _controller.stream;

  @override
  Future<SubscriptionPlan> getCurrentPlan() async => _current;

  @override
  Future<String> startPlusCheckout() async {
    return 'https://example.com/checkout/plus';
  }

  @override
  Future<void> launchCheckoutUrl(String url) async {
    if (url.isEmpty) throw Exception('Invalid checkout URL');
  }

  @override
  Future<void> purchasePlusPlan() async {
    final uri = Uri.parse('$_backendBaseUrl/billing/plus/purchase');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'plan': 'plus'}),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to complete billing (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final plan = decoded['plan'] as String?;
        if (plan != null && plan.toLowerCase() != 'plus') {
          throw Exception('Billing responded with unexpected plan: $plan');
        }
      }
    }

    _current = SubscriptionPlan.plus;
    _controller.add(_current);
  }
}

class FakeProfileRepository implements ProfileRepository {
  CrushUser? _user;

  @override
  Future<CrushUser?> getCurrentUser() async => _user;

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

    const prefs = DiscoveryPreferences(
      minAge: 18,
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

    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      age: age,
      gender: gender,
      sexualOrientation: sexualOrientation,
      bio: '',
      photoUrls: const [],
      jobTitle: null,
      company: null,
      school: null,
      interests: const [],
      country: prefs.country,
      city: prefs.city,
      latitude: null,
      longitude: null,
      preferences: prefs,
    );

    _user = (_user ??
            CrushUser(
              id: _uuid.v4(),
              phoneNumber: '',
              email: null,
              profile: null,
              isPhoneVerified: true,
              isIdVerified: false,
              plan: SubscriptionPlan.free,
            ))
        .copyWith(profile: profile);
    return _user!;
  }

  @override
  Future<CrushUser> saveProfileDetails({
    required String bio,
    required List<String> photoUrls,
    String? jobTitle,
    String? company,
    String? school,
    required List<String> interests,
  }) async {
    final profile = _user!.profile!;
    final updated = profile.copyWith(
      bio: bio,
      photoUrls: photoUrls,
      jobTitle: jobTitle,
      company: company,
      school: school,
      interests: interests,
    );
    _user = _user!.copyWith(profile: updated);
    return _user!;
  }

  @override
  Future<void> uploadIdDocument() async {
    final user = _user;
    if (user == null) {
      throw Exception('No user available to upload ID for.');
    }

    final uri = Uri.parse('$_backendBaseUrl/verification/id/upload');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': user.id,
            'document': 'demo-id-document', // Placeholder payload for demo.
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to upload ID (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<CrushUser> markIdVerified() async {
    _user = _user!.copyWith(isIdVerified: true);
    return _user!;
  }

  @override
  Future<CrushUser> updateProfile(Profile profile) async {
    _user = _user!.copyWith(profile: profile);
    return _user!;
  }
}

class FakeDiscoveryRepository implements DiscoveryRepository {
  final FakeProfileRepository profileRepo;
  final FakeSubscriptionRepository subRepo;

  FakeDiscoveryRepository(this.profileRepo, this.subRepo);

  final Map<String, List<Profile>> _fakeDecks = {};
  final Map<String, Set<String>> _dislikesByUser = {};
  final Map<String, List<CrushMatch>> _matchesByUser = {};
  final Map<String, Map<String, Profile>> _incomingRightSwipes = {};

  @override
  Future<List<Profile>> fetchDeck(String userId) async {
    final cached = _fakeDecks[userId];
    if (cached != null) return cached;

    final user = await profileRepo.getCurrentUser();
    final prefs = user?.profile?.preferences ??
        const DiscoveryPreferences(
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

    final genders = prefs.showMeGenders.isEmpty
        ? const ['women', 'men']
        : prefs.showMeGenders;
    const names = [
      'Alex',
      'Jordan',
      'Taylor',
      'Casey',
      'Riley',
      'Sam',
      'Jamie',
      'Cameron',
      'Morgan',
      'Drew',
      'Harper',
      'Charlie',
      'Avery',
      'Quinn',
      'Reese',
      'Parker',
      'Rowan',
      'Hayden',
      'Logan',
      'Skyler',
    ];
    const interestsPool = [
      'music',
      'travel',
      'coffee',
      'fitness',
      'reading',
      'movies',
      'hiking',
      'cooking',
    ];

    final ageSpan = prefs.maxAge - prefs.minAge;
    final safeSpan = ageSpan < 0 ? 0 : ageSpan;

    final generated = List<Profile>.generate(20, (index) {
      final gender = genders[index % genders.length];
      final age = prefs.minAge + (safeSpan == 0 ? 0 : index % (safeSpan + 1));
      final interests = List<String>.generate(
        3,
        (i) => interestsPool[(index + i) % interestsPool.length],
      );
      return Profile(
        id: _uuid.v4(),
        name: '${names[index % names.length]} ${index + 1}',
        age: age,
        gender: gender,
        sexualOrientation: null,
        bio: 'Loves ${interests.first} and meeting new people.',
        photoUrls: [
          'https://picsum.photos/seed/${userId}_$index/400/600',
          'https://picsum.photos/seed/${userId}_${index}b/400/600',
        ],
        jobTitle: null,
        company: null,
        school: null,
        interests: interests,
        country: prefs.country,
        city: prefs.city,
        latitude: null,
        longitude: null,
        preferences: prefs,
      );
    });

    _fakeDecks[userId] = generated;
    return generated;
  }

  @override
  Future<CrushMatch?> swipeRight({
    required String userId,
    required String targetUserId,
    String? attachedMessage,
  }) async {
    CrushMatch? mutualForTarget;
    final targetMatches = _matchesByUser[targetUserId];
    if (targetMatches != null) {
      for (var i = 0; i < targetMatches.length; i++) {
        final match = targetMatches[i];
        if (match.otherUserId == userId &&
            match.status == MatchStatus.pending) {
          final updated = match.copyWith(status: MatchStatus.mutual);
          targetMatches[i] = updated;
          mutualForTarget = updated;
          break;
        }
      }
    }

    if (mutualForTarget != null) {
      _incomingRightSwipes[userId]?.remove(targetUserId);
      _incomingRightSwipes[targetUserId]?.remove(userId);

      final userMatch = CrushMatch(
        id: mutualForTarget.id,
        userId: userId,
        otherUserId: targetUserId,
        status: MatchStatus.mutual,
        preMatchMessageRequestsCount:
            mutualForTarget.preMatchMessageRequestsCount,
        pinnedForUser: false,
      );
      final userMatches = _matchesByUser.putIfAbsent(userId, () => []);
      final existingIndex =
          userMatches.indexWhere((m) => m.otherUserId == targetUserId);
      if (existingIndex == -1) {
        userMatches.add(userMatch);
      } else {
        userMatches[existingIndex] = userMatch;
      }
      return userMatch;
    }

    final pendingMatch = CrushMatch(
      id: _uuid.v4(),
      userId: userId,
      otherUserId: targetUserId,
      status: MatchStatus.pending,
      preMatchMessageRequestsCount: attachedMessage == null ? 0 : 1,
      pinnedForUser: false,
    );
    final userMatches = _matchesByUser.putIfAbsent(userId, () => []);
    final existingIndex =
        userMatches.indexWhere((m) => m.otherUserId == targetUserId);
    if (existingIndex == -1) {
      userMatches.add(pendingMatch);
    } else {
      userMatches[existingIndex] = pendingMatch;
    }

    final likerProfile = (await profileRepo.getCurrentUser())?.profile;
    if (likerProfile != null) {
      final likesForTarget =
          _incomingRightSwipes.putIfAbsent(targetUserId, () => {});
      likesForTarget[userId] = likerProfile;
    }

    return null;
  }

  @override
  Future<void> swipeLeft({
    required String userId,
    required String targetUserId,
  }) async {
    _dislikesByUser.putIfAbsent(userId, () => <String>{}).add(targetUserId);
    final deck = _fakeDecks[userId];
    deck?.removeWhere((profile) => profile.name == targetUserId);
  }

  @override
  Future<List<Profile>> fetchTopPicks(String userId) async {
    final deck = _fakeDecks[userId] ?? [];
    if (deck.isEmpty) return deck;

    final user = await profileRepo.getCurrentUser();
    final profile = user?.profile;
    final prefs = profile?.preferences;
    final interests = profile?.interests ?? const [];

    if (prefs == null) {
      return deck.take(10).toList();
    }

    final showMe = prefs.showMeGenders.map((g) => g.toLowerCase()).toSet();
    final targetAgeCenter = (prefs.minAge + prefs.maxAge) / 2;
    final country = prefs.country.toLowerCase();
    final city = prefs.city.toLowerCase();

    bool matchesPrefs(Profile p) {
      if (p.age < prefs.minAge || p.age > prefs.maxAge) return false;
      if (showMe.isNotEmpty && !showMe.contains(p.gender.toLowerCase())) {
        return false;
      }
      return true;
    }

    double score(Profile p) {
      final sharedInterests =
          p.interests.where((i) => interests.contains(i)).length;
      final ageScore = -((p.age - targetAgeCenter).abs());
      final locationBoost = (p.city.toLowerCase() == city ? 5 : 0) +
          (p.country.toLowerCase() == country ? 2 : 0);
      return sharedInterests * 10 + ageScore + locationBoost;
    }

    final filtered = deck.where(matchesPrefs).toList();
    filtered.sort((a, b) => score(b).compareTo(score(a)));
    return filtered.take(10).toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou(String userId) async {
    final likes = _incomingRightSwipes[userId];
    if (likes == null || likes.isEmpty) return const [];
    return List.unmodifiable(likes.values);
  }

  @override
  Future<List<CrushMatch>> fetchMatches(String userId) async {
    return _matchesByUser[userId] ?? [];
  }
}

class FakeChatRepository implements ChatRepository {
  final FakeSubscriptionRepository subRepo;
  final DiscoveryRepository discoveryRepo;

  FakeChatRepository(this.subRepo, this.discoveryRepo);

  final Map<String, List<Message>> _messagesByMatch = {};
  final Map<String, Set<String>> _blockedByUser = {};
  final _streams = <String, StreamController<List<Message>>>{};

  @override
  Stream<List<Message>> watchMessages(String matchId) {
    _streams.putIfAbsent(
      matchId,
      () => StreamController<List<Message>>.broadcast(),
    );
    _streams[matchId]!.add(_messagesByMatch[matchId] ?? []);
    return _streams[matchId]!.stream;
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    required String content,
    required MessageType type,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      matchId: matchId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      isRead: false,
      isDeletedForSender: false,
    );
    final list = _messagesByMatch.putIfAbsent(matchId, () => []);
    list.add(message);
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> markMessagesRead(String matchId, String userId) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      if (list[i].toUserId == userId) {
        list[i] = list[i].copyWith(isRead: true);
      }
    }
    _streams[matchId]?.add(List.unmodifiable(list));
  }

  @override
  Future<void> unsendMessage({
    required String matchId,
    required String messageId,
  }) async {
    // In real app, allow only sender + premium plan to unsend.
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      list[index] = list[index].copyWith(isDeletedForSender: true);
      _streams[matchId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> deleteForMe({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    final list = _messagesByMatch[matchId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      if (list[index].fromUserId != userId) {
        throw Exception('Only the sender can delete this message.');
      }
      list[index] = list[index].copyWith(isDeletedForSender: true);
      _streams[matchId]?.add(List.unmodifiable(list));
    }
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/moderation/report');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'reporterId': reporterId,
            'reportedId': reportedId,
            'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to report user (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    _blockedByUser.putIfAbsent(blockerId, () => <String>{}).add(blockedId);
  }

  @override
  Future<void> unmatch({
    required String matchId,
    required String userId,
  }) async {
    final userMatches = await discoveryRepo.fetchMatches(userId);
    CrushMatch? updatedForUser;

    for (var i = 0; i < userMatches.length; i++) {
      if (userMatches[i].id == matchId) {
        final updated = userMatches[i].copyWith(status: MatchStatus.unmatched);
        userMatches[i] = updated;
        updatedForUser = updated;
        break;
      }
    }

    if (updatedForUser != null) {
      final otherMatches =
          await discoveryRepo.fetchMatches(updatedForUser.otherUserId);
      for (var i = 0; i < otherMatches.length; i++) {
        if (otherMatches[i].id == matchId) {
          otherMatches[i] =
              otherMatches[i].copyWith(status: MatchStatus.unmatched);
          break;
        }
      }
    }

    _messagesByMatch.remove(matchId);
    _streams[matchId]?.add(const []);
  }

  @override
  Future<List<CrushMatch>> fetchUserMatches(String userId) async {
    return discoveryRepo.fetchMatches(userId);
  }
}
