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
      chatRepo = StubChatRepository(
        delayExecutor: (_) async {},
        shouldAutoReply: (_) => false,
        watchNewMessagesInterval: const Duration(milliseconds: 10),
      );
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
      expect(user.hasAcceptedTerms, isFalse);
      expect(user.profile, isNull);
      expect(user.hasCompletedBasicInfo, isFalse);
      expect(user.hasCompletedProfileSetup, isFalse);
      expect(user.isOnboardingComplete, isFalse);

      final postSignup = await authRepo.refreshCurrentUser();
      expect(postSignup?.id, user.id);
      expect(postSignup?.hasAcceptedTerms, isFalse);
      expect(postSignup?.isOnboardingComplete, isFalse);

      final termsAcceptedUser = await authRepo.acceptTermsAndConditions();
      expect(termsAcceptedUser.hasAcceptedTerms, isTrue);
      final postTerms = await authRepo.refreshCurrentUser();
      expect(postTerms?.hasAcceptedTerms, isTrue);
      expect(postTerms?.hasCompletedBasicInfo, isFalse);
      expect(postTerms?.hasCompletedProfileSetup, isFalse);
      expect(postTerms?.isOnboardingComplete, isFalse);

      await profileRepo.saveBasicInfo(
        username: username,
        name: 'E2E Tester',
        age: 28,
        gender: 'male',
        dateOfBirth: DateTime(1997, 1, 10),
        showFirstName: true,
      );
      final postBasicInfo = await authRepo.refreshCurrentUser();
      expect(postBasicInfo, isNotNull);
      expect(postBasicInfo!.hasCompletedBasicInfo, isTrue);
      expect(postBasicInfo.hasCompletedProfileSetup, isFalse);
      expect(postBasicInfo.isOnboardingComplete, isFalse);

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
      expect(currentUser!.profile, isNotNull);
      expect(currentUser.profile!.name, 'E2E Tester');
      expect(
        currentUser.profile!.interests,
        containsAll(<String>['Music', 'Travel', 'Coffee']),
      );
      expect(currentUser.profile!.photoUrls, isNotEmpty);
      expect(
        currentUser.profile!.preferences.showMeGenders,
        contains('female'),
      );
      expect(currentUser.hasCompletedBasicInfo, isTrue);
      expect(currentUser.hasCompletedProfileSetup, isTrue);
      expect(currentUser.isOnboardingComplete, isTrue);

      final deck = await discoveryRepo.fetchDeck(currentUser.id);
      expect(deck, isNotEmpty);
      expect(deck.first.id, isNot(currentUser.id));
      expect(deck.first.photoUrls, isNotEmpty);
      final candidate = deck.first;

      final match = await discoveryRepo.swipeRight(
        userId: currentUser.id,
        targetUserId: candidate.id,
      );
      expect(match, isNotNull);
      expect(match!.status, MatchStatus.mutual);
      expect(match.userId, currentUser.id);
      expect(match.otherUserId, candidate.id);
      expect(match.otherUserName, isNotEmpty);

      final matches = await discoveryRepo.fetchMatches(currentUser.id);
      expect(matches.map((m) => m.id), contains(match.id));
      expect(
        matches.where((m) => m.id == match.id).single.status,
        MatchStatus.mutual,
      );
      expect(
        matches.where((m) => m.otherUserId == candidate.id).single.id,
        match.id,
      );

      final deckAfterMatch = await discoveryRepo.fetchDeck(currentUser.id);
      expect(
        deckAfterMatch.any((profile) => profile.id == candidate.id),
        isFalse,
      );

      final reciprocalMatches = await discoveryRepo.fetchMatches(
        match.otherUserId,
      );
      expect(reciprocalMatches.map((m) => m.id), contains(match.id));
      final reciprocal = reciprocalMatches.firstWhere((m) => m.id == match.id);
      expect(reciprocal.userId, match.otherUserId);
      expect(reciprocal.otherUserId, currentUser.id);

      final typingEvents = <Set<String>>[];
      final presenceEvents = <bool>[];
      final mediaEvents = <bool>[];
      final typingSub = chatRepo.watchTyping(match.id).listen(typingEvents.add);
      final presenceSub = chatRepo
          .watchPresence(match.otherUserId)
          .listen(presenceEvents.add);
      final mediaSub = chatRepo
          .watchMediaSendingEnabled(match.id)
          .listen(mediaEvents.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await chatRepo.setTyping(
        matchId: match.id,
        userId: match.otherUserId,
        isTyping: true,
      );
      await chatRepo.setTyping(
        matchId: match.id,
        userId: match.otherUserId,
        isTyping: false,
      );
      await chatRepo.setPresence(userId: match.otherUserId, isOnline: false);
      await chatRepo.setPresence(userId: match.otherUserId, isOnline: true);
      await chatRepo.setMediaSendingEnabled(
        matchId: match.id,
        enabled: false,
        requesterId: currentUser.id,
      );
      await chatRepo.setMediaSendingEnabled(
        matchId: match.id,
        enabled: true,
        requesterId: currentUser.id,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(typingEvents.first, isEmpty);
      expect(
        typingEvents.any(
          (event) => event.length == 1 && event.contains(match.otherUserId),
        ),
        isTrue,
      );
      expect(typingEvents.last, isEmpty);
      expect(presenceEvents.first, isTrue);
      expect(presenceEvents, contains(false));
      expect(presenceEvents.last, isTrue);
      expect(mediaEvents.first, isTrue);
      expect(mediaEvents, contains(false));
      expect(mediaEvents.last, isTrue);

      final streamEvent = chatRepo
          .watchMessages(match.id)
          .firstWhere((messages) => messages.isNotEmpty);

      await chatRepo.sendMessage(
        matchId: match.id,
        fromUserId: currentUser.id,
        toUserId: match.otherUserId,
        content: 'Hey there!',
        type: MessageType.text,
      );
      final streamedMessages = await streamEvent.timeout(
        const Duration(seconds: 2),
      );
      expect(streamedMessages, isNotEmpty);
      expect(streamedMessages.last.content, 'Hey there!');

      final newMessageCursor = DateTime.now();
      final newMessageStreamEvent = chatRepo
          .watchNewMessages(match.id, afterTimestamp: newMessageCursor)
          .firstWhere(
            (messages) => messages.any(
              (message) => message.content == 'deterministic-checkpoint',
            ),
          );
      await chatRepo.sendMessage(
        matchId: match.id,
        fromUserId: currentUser.id,
        toUserId: match.otherUserId,
        content: 'deterministic-checkpoint',
        type: MessageType.text,
      );
      final newMessages = await newMessageStreamEvent.timeout(
        const Duration(seconds: 2),
      );
      expect(
        newMessages.any(
          (message) => message.content == 'deterministic-checkpoint',
        ),
        isTrue,
      );

      var pagedMessages = await chatRepo.fetchMessagesPaginated(
        match.id,
        limit: 10,
      );
      expect(pagedMessages.items, isNotEmpty);
      expect(pagedMessages.items.last.fromUserId, currentUser.id);
      expect(pagedMessages.items.last.toUserId, match.otherUserId);

      await chatRepo.markMessagesRead(match.id, match.otherUserId);
      pagedMessages = await chatRepo.fetchMessagesPaginated(
        match.id,
        limit: 10,
      );
      expect(pagedMessages.items.every((m) => m.isRead), isTrue);

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
      await chatRepo.blockUser(
        blockerId: currentUser.id,
        blockedId: match.otherUserId,
      );

      await _assertSafetySideEffects(currentUser.id, match);

      await typingSub.cancel();
      await presenceSub.cancel();
      await mediaSub.cancel();
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
  expect(reports.length, 1);

  final latestReport = jsonDecode(reports.last) as Map<String, dynamic>;
  expect(latestReport['reporterId'], currentUserId);
  expect(latestReport['reportedId'], match.otherUserId);
  expect(latestReport['reason'], 'Spam or scams');
  expect(latestReport['matchId'], match.id);
  expect(latestReport['source'], 'chat');
  expect(latestReport['timestamp'], isNotNull);
  final parsedTimestamp = DateTime.tryParse(
    latestReport['timestamp'] as String,
  );
  expect(parsedTimestamp, isNotNull);

  final blockedRaw = prefs.getString('mock_blocked_$currentUserId');
  expect(blockedRaw, isNotNull);

  final blockedUsers = Set<String>.from(
    jsonDecode(blockedRaw!) as List<dynamic>,
  );
  expect(blockedUsers.contains(match.otherUserId), isTrue);
  expect(blockedUsers.length, 1);
}
