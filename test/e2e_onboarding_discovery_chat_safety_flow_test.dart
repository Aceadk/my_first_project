import 'dart:convert';

import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_discovery_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock/firebase_mock.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  setupFirebaseAnalyticsMocks();

  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('Flow: Onboarding -> Discovery -> Match -> Chat -> Report/Block', () {
    late StubAuthRepository authRepo;
    late StubProfileRepository profileRepo;
    late StubDiscoveryRepository discoveryRepo;
    late StubChatRepository chatRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clearSecureStorageMock();
      authRepo = StubAuthRepository();
      profileRepo = StubProfileRepository();
      discoveryRepo = StubDiscoveryRepository();
      chatRepo = StubChatRepository();
    });

    tearDown(() {
      authRepo.dispose();
      chatRepo.dispose();
    });

    test('persists report and block side effects', () async {
      final nonce = DateTime.now().millisecondsSinceEpoch;
      final username = 'e2e${nonce % 1000000}';
      final email = 'e2e_$nonce@example.com';

      final user = await authRepo.signUpWithPassword(
        username: username,
        email: email,
        password: 'Passw0rd123',
      );
      expect(user.id, isNotEmpty);

      final termsAcceptedUser = await authRepo.acceptTermsAndConditions();
      expect(termsAcceptedUser.hasAcceptedTerms, isTrue);

      await profileRepo.saveBasicInfo(
        username: username,
        name: 'E2E Tester',
        age: 28,
        gender: 'male',
        dateOfBirth: DateTime(1997, 1, 10),
        showFirstName: true,
      );

      await profileRepo.saveProfileDetails(
        bio: 'Love coffee, music, and long walks in the city.',
        photoUrls: const [
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
        ],
        videoUrls: const [],
        interests: const ['Music', 'Travel', 'Coffee'],
        city: 'San Francisco',
        country: 'United States',
        showMeGenders: const ['female'],
      );

      final currentUser = await authRepo.refreshCurrentUser();
      expect(currentUser, isNotNull);

      final deck = await discoveryRepo.fetchDeck(currentUser!.id);
      expect(deck, isNotEmpty);

      final match = await discoveryRepo.swipeRight(
        userId: currentUser.id,
        targetUserId: deck.first.id,
      );
      expect(match, isNotNull);

      final matches = await discoveryRepo.fetchMatches(currentUser.id);
      expect(matches.map((m) => m.id), contains(match!.id));

      await chatRepo.sendMessage(
        matchId: match.id,
        fromUserId: currentUser.id,
        toUserId: match.otherUserId,
        content: 'Hey there!',
        type: MessageType.text,
      );

      await chatRepo.reportUser(
        reporterId: currentUser.id,
        reportedId: match.otherUserId,
        reason: 'Spam or scams',
        matchId: match.id,
        source: 'chat',
      );

      await chatRepo.blockUser(
        blockerId: currentUser.id,
        blockedId: match.otherUserId,
      );

      await _assertSafetySideEffects(currentUser.id, match);
    });
  });
}

Future<void> _assertSafetySideEffects(
  String currentUserId,
  CrushMatch match,
) async {
  final prefs = await SharedPreferences.getInstance();

  final reports = prefs.getStringList('mock_reports') ?? const [];
  expect(reports.isNotEmpty, isTrue);

  final latestReport = jsonDecode(reports.last) as Map<String, dynamic>;
  expect(latestReport['reporterId'], currentUserId);
  expect(latestReport['reportedId'], match.otherUserId);
  expect(latestReport['reason'], 'Spam or scams');
  expect(latestReport['matchId'], match.id);
  expect(latestReport['source'], 'chat');

  final blockedRaw = prefs.getString('mock_blocked_$currentUserId');
  expect(blockedRaw, isNotNull);

  final blockedUsers = Set<String>.from(
    jsonDecode(blockedRaw!) as List<dynamic>,
  );
  expect(blockedUsers.contains(match.otherUserId), isTrue);
}
