library;

import 'dart:convert';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Onboarding -> Discovery -> Match -> Chat -> Report/Block', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'signup onboarding leads to chat safety actions',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
        await _ensureSignedOutAtAuthGateway(tester);

        final username = await _signUpViaOnboarding(tester);
        final signedUpUser = await _expectOnboardingState(
          tester,
          hasAcceptedTerms: false,
          hasCompletedBasicInfo: false,
          hasCompletedProfileSetup: false,
          isOnboardingComplete: false,
        );
        expect(signedUpUser.profile, isNull);
        expect(find.text('Terms & Conditions').evaluate().isNotEmpty, isTrue);

        final onboardedUser = await _completeOnboardingForDiscovery(
          tester,
          username: username,
        );
        expect(onboardedUser.id, signedUpUser.id);
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        final candidate = await _firstDeckCandidate(
          tester,
          userId: onboardedUser.id,
        );
        await _likeCurrentDeckProfile(tester);
        final match = await _waitForMatchAgainstCandidate(
          tester,
          currentUserId: onboardedUser.id,
          expectedOtherUserId: candidate.id,
        );
        expect(match, isNotNull);
        expect(match!.userId, onboardedUser.id);
        expect(match.otherUserId, candidate.id);

        await _assertDiscoverySideEffects(
          tester,
          currentUserId: onboardedUser.id,
          candidateId: candidate.id,
          match: match,
        );

        await _openChatForMatch(tester, match);
        await _assertRealtimeChatSignals(
          tester,
          match: match,
          currentUserId: onboardedUser.id,
        );
        await _assertDeterministicChatCheckpoint(
          tester,
          match: match,
          currentUserId: onboardedUser.id,
        );
        await _reportUserFromChat(tester);
        await _blockUserFromChat(tester);
        await _assertSafetySideEffects(
          tester,
          prefs: prefs,
          currentUserId: onboardedUser.id,
          match: match,
        );
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );
  });
}

Future<void> _ensureSignedOutAtAuthGateway(WidgetTester tester) async {
  final context = _appContext(tester);
  await context.read<AuthRepository>().signOut();
  await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
}

Future<String> _signUpViaOnboarding(WidgetTester tester) async {
  final nonce = DateTime.now().millisecondsSinceEpoch;
  final username = 'e2e${nonce % 1000000}';
  final email = 'e2e_$nonce@example.com';
  const password = 'Passw0rd123';

  await tester.tap(TestHelpers.authGatewayCreateAccountButton(tester));
  await tester.pumpAndSettle();

  final ageGateConfirm = find.text('Yes, I am 18+');
  if (ageGateConfirm.evaluate().isNotEmpty) {
    await tester.tap(ageGateConfirm.first);
    await tester.pumpAndSettle();
  }

  await tester.enterText(
    TestHelpers.textFieldByLabel(tester, 'Username'),
    username,
  );
  await tester.tap(find.text('Continue').first);
  await tester.pumpAndSettle();

  await tester.enterText(
    TestHelpers.textFieldByLabel(tester, 'Email address'),
    email,
  );
  await tester.tap(find.text('Continue').first);
  await tester.pumpAndSettle();

  await tester.enterText(
    TestHelpers.textFieldByLabel(tester, 'Password'),
    password,
  );
  await tester.tap(find.text('Create Account').first);
  await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

  return username;
}

Future<CrushUser> _completeOnboardingForDiscovery(
  WidgetTester tester, {
  required String username,
}) async {
  final context = _appContext(tester);
  final authRepo = context.read<AuthRepository>();
  final profileRepo = context.read<ProfileRepository>();

  await authRepo.acceptTermsAndConditions();
  final postTerms = await authRepo.refreshCurrentUser();
  expect(postTerms, isNotNull);
  expect(postTerms!.hasAcceptedTerms, isTrue);
  expect(postTerms.hasCompletedBasicInfo, isFalse);
  expect(postTerms.hasCompletedProfileSetup, isFalse);
  expect(postTerms.isOnboardingComplete, isFalse);

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
  expect(postBasicInfo!.hasAcceptedTerms, isTrue);
  expect(postBasicInfo.hasCompletedBasicInfo, isTrue);
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
  final postProfile = await authRepo.refreshCurrentUser();
  expect(postProfile, isNotNull);
  expect(postProfile!.hasAcceptedTerms, isTrue);
  expect(postProfile.hasCompletedBasicInfo, isTrue);
  expect(postProfile.hasCompletedProfileSetup, isTrue);
  expect(postProfile.isOnboardingComplete, isTrue);

  return postProfile;
}

Future<void> _likeCurrentDeckProfile(WidgetTester tester) async {
  final context = _appContext(tester);
  GoRouter.of(context).go(CrushRoutes.home);
  await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 1));

  final likeButton = find.byIcon(Icons.favorite_rounded);
  expect(likeButton.evaluate().isNotEmpty, isTrue);
  await tester.tap(likeButton.first);
  await tester.pumpAndSettle();
}

Future<CrushMatch?> _waitForMatchAgainstCandidate(
  WidgetTester tester, {
  required String currentUserId,
  required String expectedOtherUserId,
}) async {
  final context = _appContext(tester);
  final discoveryRepo = context.read<DiscoveryRepository>();

  for (var i = 0; i < 20; i++) {
    final matches = await discoveryRepo.fetchMatches(currentUserId);
    final expectedMatch = matches.where(
      (m) => m.otherUserId == expectedOtherUserId,
    );
    if (expectedMatch.isNotEmpty) {
      return expectedMatch.first;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  return null;
}

Future<void> _openChatForMatch(WidgetTester tester, CrushMatch match) async {
  final sendMessage = find.text('Send Message');
  if (sendMessage.evaluate().isNotEmpty) {
    await tester.tap(sendMessage.first);
    await tester.pumpAndSettle();
    return;
  }

  final context = _appContext(tester);
  final authRepo = context.read<AuthRepository>();
  final router = GoRouter.of(context);
  final user = await authRepo.refreshCurrentUser();
  expect(user, isNotNull);

  router.go(
    '${CrushRoutes.chat}/${match.id}',
    extra: ChatScreenArgs(
      matchId: match.id,
      currentUserId: user!.id,
      otherUserId: match.otherUserId,
      otherName: match.otherUserName ?? 'Someone',
      otherPhotoUrl: match.otherUserPhotoUrl,
    ),
  );
  await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
}

Future<CrushUser> _expectOnboardingState(
  WidgetTester tester, {
  required bool hasAcceptedTerms,
  required bool hasCompletedBasicInfo,
  required bool hasCompletedProfileSetup,
  required bool isOnboardingComplete,
}) async {
  final context = _appContext(tester);
  final currentUser = await context.read<AuthRepository>().refreshCurrentUser();
  expect(currentUser, isNotNull);
  expect(currentUser!.hasAcceptedTerms, hasAcceptedTerms);
  expect(currentUser.hasCompletedBasicInfo, hasCompletedBasicInfo);
  expect(currentUser.hasCompletedProfileSetup, hasCompletedProfileSetup);
  expect(currentUser.isOnboardingComplete, isOnboardingComplete);
  return currentUser;
}

Future<Profile> _firstDeckCandidate(
  WidgetTester tester, {
  required String userId,
}) async {
  final context = _appContext(tester);
  final deck = await context.read<DiscoveryRepository>().fetchDeck(userId);
  expect(deck, isNotEmpty);
  final candidate = deck.first;
  expect(candidate.id, isNot(userId));
  expect(candidate.photoUrls, isNotEmpty);
  return candidate;
}

Future<void> _assertDiscoverySideEffects(
  WidgetTester tester, {
  required String currentUserId,
  required String candidateId,
  required CrushMatch match,
}) async {
  final context = _appContext(tester);
  final discoveryRepo = context.read<DiscoveryRepository>();

  final userDeckAfterMatch = await discoveryRepo.fetchDeck(currentUserId);
  expect(
    userDeckAfterMatch.any((profile) => profile.id == candidateId),
    isFalse,
  );

  final userMatches = await discoveryRepo.fetchMatches(currentUserId);
  expect(userMatches.map((m) => m.id), contains(match.id));
  final matchedEntry = userMatches.firstWhere((m) => m.id == match.id);
  expect(matchedEntry.status, MatchStatus.mutual);
  expect(matchedEntry.otherUserId, candidateId);

  final reciprocalMatches = await discoveryRepo.fetchMatches(match.otherUserId);
  expect(reciprocalMatches.map((m) => m.id), contains(match.id));
  final reciprocal = reciprocalMatches.firstWhere((m) => m.id == match.id);
  expect(reciprocal.userId, match.otherUserId);
  expect(reciprocal.otherUserId, currentUserId);
}

Future<void> _assertRealtimeChatSignals(
  WidgetTester tester, {
  required CrushMatch match,
  required String currentUserId,
}) async {
  final context = _appContext(tester);
  final chatRepo = context.read<ChatRepository>();

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

  await tester.pump(const Duration(milliseconds: 25));

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
    requesterId: currentUserId,
  );
  await chatRepo.setMediaSendingEnabled(
    matchId: match.id,
    enabled: true,
    requesterId: currentUserId,
  );

  await tester.pump(const Duration(milliseconds: 25));
  await typingSub.cancel();
  await presenceSub.cancel();
  await mediaSub.cancel();

  expect(typingEvents, isNotEmpty);
  expect(typingEvents.first, isEmpty);
  expect(
    typingEvents.any(
      (event) => event.length == 1 && event.contains(match.otherUserId),
    ),
    isTrue,
  );
  expect(typingEvents.last, isEmpty);

  expect(presenceEvents, isNotEmpty);
  expect(presenceEvents.first, isTrue);
  expect(presenceEvents, contains(false));
  expect(presenceEvents.last, isTrue);

  expect(mediaEvents, isNotEmpty);
  expect(mediaEvents.first, isTrue);
  expect(mediaEvents, contains(false));
  expect(mediaEvents.last, isTrue);
}

Future<void> _assertDeterministicChatCheckpoint(
  WidgetTester tester, {
  required CrushMatch match,
  required String currentUserId,
}) async {
  final context = _appContext(tester);
  final chatRepo = context.read<ChatRepository>();
  const checkpointMessage = 'deterministic-checkpoint';

  final messagesStreamEvent = chatRepo
      .watchMessages(match.id)
      .firstWhere(
        (messages) =>
            messages.any((message) => message.content == checkpointMessage),
      );

  final newMessagesCursor = DateTime.now();
  final newMessagesStreamEvent = chatRepo
      .watchNewMessages(match.id, afterTimestamp: newMessagesCursor)
      .firstWhere(
        (messages) =>
            messages.any((message) => message.content == checkpointMessage),
      );

  await chatRepo.sendMessage(
    matchId: match.id,
    fromUserId: currentUserId,
    toUserId: match.otherUserId,
    content: checkpointMessage,
    type: MessageType.text,
  );

  final streamedMessages = await messagesStreamEvent.timeout(
    const Duration(seconds: 2),
  );
  expect(
    streamedMessages.any((message) => message.content == checkpointMessage),
    isTrue,
  );

  final newMessages = await newMessagesStreamEvent.timeout(
    const Duration(seconds: 2),
  );
  expect(
    newMessages.any((message) => message.content == checkpointMessage),
    isTrue,
  );

  final pagedMessages = await chatRepo.fetchMessagesPaginated(
    match.id,
    limit: 20,
  );
  final checkpointEntries = pagedMessages.items
      .where((message) => message.content == checkpointMessage)
      .toList();
  expect(checkpointEntries, isNotEmpty);
  expect(checkpointEntries.last.fromUserId, currentUserId);
  expect(checkpointEntries.last.toUserId, match.otherUserId);

  await chatRepo.markMessagesRead(match.id, match.otherUserId);
  final pagedAfterRead = await chatRepo.fetchMessagesPaginated(
    match.id,
    limit: 20,
  );
  final readCheckpointEntries = pagedAfterRead.items
      .where((message) => message.content == checkpointMessage)
      .toList();
  expect(readCheckpointEntries, isNotEmpty);
  expect(readCheckpointEntries.every((message) => message.isRead), isTrue);
}

Future<void> _reportUserFromChat(WidgetTester tester) async {
  await _openChatSafetyMenu(tester);

  final reportMenuItem = find.text('Report user');
  expect(reportMenuItem.evaluate().isNotEmpty, isTrue);
  await tester.tap(reportMenuItem.first);
  await tester.pumpAndSettle();

  final reason = find.text('Spam or scams');
  expect(reason.evaluate().isNotEmpty, isTrue);
  await tester.tap(reason.first);
  await TestHelpers.pumpAndWait(
    tester,
    wait: const Duration(milliseconds: 600),
  );

  expect(find.textContaining('Report submitted').evaluate().isNotEmpty, isTrue);
}

Future<void> _blockUserFromChat(WidgetTester tester) async {
  await _openChatSafetyMenu(tester);

  final blockMenuItem = find.text('Block user');
  expect(blockMenuItem.evaluate().isNotEmpty, isTrue);
  await tester.tap(blockMenuItem.first);
  await TestHelpers.pumpAndWait(
    tester,
    wait: const Duration(milliseconds: 600),
  );

  expect(find.textContaining('Blocked').evaluate().isNotEmpty, isTrue);
}

Future<void> _assertSafetySideEffects(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required String currentUserId,
  required CrushMatch match,
}) async {
  final context = _appContext(tester);
  final chatRepo = context.read<ChatRepository>();

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

  await chatRepo.blockUser(
    blockerId: currentUserId,
    blockedId: match.otherUserId,
  );

  final blockedRaw = prefs.getString('mock_blocked_$currentUserId');
  expect(blockedRaw, isNotNull);
  final blockedUsers = Set<String>.from(
    jsonDecode(blockedRaw!) as List<dynamic>,
  );
  expect(blockedUsers.contains(match.otherUserId), isTrue);
  expect(blockedUsers.length, 1);
}

Future<void> _openChatSafetyMenu(WidgetTester tester) async {
  final menuIcon = find.byIcon(Icons.more_vert);
  expect(menuIcon.evaluate().isNotEmpty, isTrue);
  await tester.tap(menuIcon.last);
  await tester.pumpAndSettle();
}

BuildContext _appContext(WidgetTester tester) {
  return tester.element(find.byType(MaterialApp).first);
}
