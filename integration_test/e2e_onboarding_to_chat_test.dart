library;

import 'dart:async';
import 'dart:convert';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/data/models/message.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
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

  group('E2E: Critical Journey', () {
    setUp(() async {
      await TestHelpers.clearTestData();
    });

    testWidgets(
      'auth and onboarding checkpoints advance in route order',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await _runStep(
          'pump app shell',
          () => TestHelpers.launchApp(tester, preferences: prefs),
          timeout: const Duration(seconds: 5),
        );
        await _runStep('reach auth gateway', () async {
          await _expectRoutePath(tester, CrushRoutes.authGateway);
        });

        final authRepo = _appContext(tester).read<AuthRepository>();
        await _runStep('sign out to clean baseline', () async {
          await authRepo.signOut();
          await _expectRoutePath(tester, CrushRoutes.authGateway);
          expect(await authRepo.refreshCurrentUser(), isNull);
        });

        final signedUpUser = await _runStep(
          'sign up and route to terms',
          () async {
            final user = await _signUpDeterministically(tester);
            await _expectRoutePath(tester, CrushRoutes.termsConditions);
            return user;
          },
        );
        expect(signedUpUser.hasAcceptedTerms, isFalse);
        expect(signedUpUser.hasCompletedBasicInfo, isFalse);
        expect(signedUpUser.hasCompletedProfileSetup, isFalse);

        final acceptedUser = await _runStep(
          'accept terms and route to basic info',
          () async {
            final user = await authRepo.acceptTermsAndConditions();
            await _expectRoutePath(tester, CrushRoutes.basicInfo);
            return user;
          },
        );
        expect(acceptedUser.hasAcceptedTerms, isTrue);
        expect(acceptedUser.hasCompletedBasicInfo, isFalse);
        expect(acceptedUser.hasCompletedProfileSetup, isFalse);

        final profileRepo = _appContext(tester).read<ProfileRepository>();
        final postBasicInfo = await _runStep(
          'save basic info and route to profile setup',
          () async {
            await profileRepo.saveBasicInfo(
              username: signedUpUser.username,
              name: 'Critical Journey',
              age: 28,
              gender: 'male',
              dateOfBirth: DateTime(1997, 1, 10),
              showFirstName: true,
            );
            final refreshed = await _refreshCurrentUser(tester);
            await _expectRoutePath(tester, CrushRoutes.profileSetup);
            return refreshed;
          },
        );
        expect(postBasicInfo.hasCompletedBasicInfo, isTrue);
        expect(postBasicInfo.hasCompletedProfileSetup, isFalse);

        final onboardedUser = await _runStep(
          'save profile details and route home',
          () async {
            await profileRepo.saveProfileDetails(
              bio: 'Coffee, travel, and deterministic integration tests.',
              photoUrls: const <String>[
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
              ],
              videoUrls: const <String>[],
              interests: const <String>['Coffee', 'Travel', 'Music'],
              city: 'San Francisco',
              country: 'United States',
              showMeGenders: const <String>['female'],
            );
            final refreshed = await _refreshCurrentUser(tester);
            await _expectRoutePath(tester, CrushRoutes.home);
            return refreshed;
          },
        );
        expect(onboardedUser.hasAcceptedTerms, isTrue);
        expect(onboardedUser.hasCompletedBasicInfo, isTrue);
        expect(onboardedUser.hasCompletedProfileSetup, isTrue);
        expect(onboardedUser.isOnboardingComplete, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets(
      'discovery to chat safety checkpoints persist expected state',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await TestHelpers.launchApp(tester, preferences: prefs);
        final currentUser = await _bootstrapOnboardedUser(tester);
        await _expectRoutePath(tester, CrushRoutes.home);

        final discoveryRepo = _appContext(tester).read<DiscoveryRepository>();
        final chatRepo = _appContext(tester).read<ChatRepository>();

        final deck = await discoveryRepo.fetchDeck(currentUser.id);
        expect(deck, isNotEmpty);
        final candidate = deck.first;
        expect(candidate.id, isNot(currentUser.id));

        final match = await discoveryRepo.swipeRight(
          userId: currentUser.id,
          targetUserId: candidate.id,
        );
        expect(match, isNotNull);
        expect(match!.userId, currentUser.id);
        expect(match.otherUserId, candidate.id);

        await _assertMatchState(
          discoveryRepo: discoveryRepo,
          currentUserId: currentUser.id,
          candidate: candidate,
          match: match,
        );

        await _openChatForMatch(
          tester,
          match: match,
          currentUserId: currentUser.id,
        );
        expect(find.byType(ChatScreen), findsOneWidget);
        await _expectRoutePath(tester, '${CrushRoutes.chat}/${match.id}');

        await _assertChatCheckpoint(
          chatRepo: chatRepo,
          match: match,
          currentUserId: currentUser.id,
        );

        await chatRepo.reportUser(
          reporterId: currentUser.id,
          reportedId: match.otherUserId,
          reason: 'Spam or scams',
          matchId: match.id,
          source: 'chat',
          description: 'Deterministic report checkpoint',
        );
        await chatRepo.blockUser(
          blockerId: currentUser.id,
          blockedId: match.otherUserId,
        );

        await _assertSafetyState(
          prefs: prefs,
          currentUserId: currentUser.id,
          match: match,
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

Future<CrushUser> _bootstrapOnboardedUser(WidgetTester tester) async {
  final authRepo = _appContext(tester).read<AuthRepository>();
  final profileRepo = _appContext(tester).read<ProfileRepository>();

  await authRepo.signOut();
  await _expectRoutePath(tester, CrushRoutes.authGateway);

  final signedUpUser = await _signUpDeterministically(tester);
  await _expectRoutePath(tester, CrushRoutes.termsConditions);

  await authRepo.acceptTermsAndConditions();
  await _expectRoutePath(tester, CrushRoutes.basicInfo);

  await profileRepo.saveBasicInfo(
    username: signedUpUser.username,
    name: 'Critical Journey',
    age: 28,
    gender: 'male',
    dateOfBirth: DateTime(1997, 1, 10),
    showFirstName: true,
  );
  await _refreshCurrentUser(tester);
  await _expectRoutePath(tester, CrushRoutes.profileSetup);

  await profileRepo.saveProfileDetails(
    bio: 'Coffee, travel, and deterministic integration tests.',
    photoUrls: const <String>[
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    ],
    videoUrls: const <String>[],
    interests: const <String>['Coffee', 'Travel', 'Music'],
    city: 'San Francisco',
    country: 'United States',
    showMeGenders: const <String>['female'],
  );

  return _refreshCurrentUser(tester);
}

Future<CrushUser> _signUpDeterministically(WidgetTester tester) async {
  final authRepo = _appContext(tester).read<AuthRepository>();
  final nonce = DateTime.now().millisecondsSinceEpoch;

  return authRepo.signUpWithPassword(
    username: 'e2e_${nonce % 1000000}',
    email: 'e2e_$nonce@example.com',
    password: 'Passw0rd123',
  );
}

Future<CrushUser> _refreshCurrentUser(WidgetTester tester) async {
  final context = _appContext(tester);
  final authRepo = context.read<AuthRepository>();
  context.read<AuthBloc>().add(AuthUserRefreshRequested());
  await tester.pump(const Duration(milliseconds: 250));

  final refreshed = await authRepo.refreshCurrentUser();
  expect(refreshed, isNotNull);
  return refreshed!;
}

Future<void> _assertMatchState({
  required DiscoveryRepository discoveryRepo,
  required String currentUserId,
  required Profile candidate,
  required CrushMatch match,
}) async {
  final userMatches = await discoveryRepo.fetchMatches(currentUserId);
  expect(userMatches.map((entry) => entry.id), contains(match.id));
  final matchedEntry = userMatches.firstWhere((entry) => entry.id == match.id);
  expect(matchedEntry.status, MatchStatus.mutual);
  expect(matchedEntry.otherUserId, candidate.id);

  final reciprocalMatches = await discoveryRepo.fetchMatches(candidate.id);
  expect(reciprocalMatches.map((entry) => entry.id), contains(match.id));
  final reciprocal = reciprocalMatches.firstWhere(
    (entry) => entry.id == match.id,
  );
  expect(reciprocal.userId, candidate.id);
  expect(reciprocal.otherUserId, currentUserId);
}

Future<void> _openChatForMatch(
  WidgetTester tester, {
  required CrushMatch match,
  required String currentUserId,
}) async {
  final router = GoRouter.of(_appContext(tester));
  router.go(
    '${CrushRoutes.chat}/${match.id}',
    extra: ChatScreenArgs(
      matchId: match.id,
      currentUserId: currentUserId,
      otherUserId: match.otherUserId,
      otherName: match.otherUserName ?? 'Someone',
      otherPhotoUrl: match.otherUserPhotoUrl,
    ),
  );

  await _expectRoutePath(tester, '${CrushRoutes.chat}/${match.id}');
}

Future<void> _assertChatCheckpoint({
  required ChatRepository chatRepo,
  required CrushMatch match,
  required String currentUserId,
}) async {
  const checkpointMessage = 'critical-journey-checkpoint';
  final newMessagesCursor = DateTime.now().subtract(
    const Duration(milliseconds: 1),
  );

  final messagesStreamEvent = chatRepo
      .watchMessages(match.id)
      .firstWhere(
        (messages) =>
            messages.any((message) => message.content == checkpointMessage),
      );
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
  final readEntries = pagedAfterRead.items
      .where((message) => message.content == checkpointMessage)
      .toList();
  expect(readEntries, isNotEmpty);
  expect(readEntries.every((message) => message.isRead), isTrue);
}

Future<void> _assertSafetyState({
  required SharedPreferences prefs,
  required String currentUserId,
  required CrushMatch match,
}) async {
  final reports = prefs.getStringList('mock_reports') ?? const <String>[];
  expect(reports, hasLength(1));
  final latestReport = jsonDecode(reports.single) as Map<String, dynamic>;
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
  expect(blockedUsers, <String>{match.otherUserId});
}

Future<void> _expectRoutePath(
  WidgetTester tester,
  String expectedPath, {
  int maxTicks = 80,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (_routerPath(tester) == expectedPath) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  fail('Expected route $expectedPath, found ${_routerPath(tester)}');
}

Future<T> _runStep<T>(
  String label,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 15),
}) {
  return action().timeout(
    timeout,
    onTimeout: () => throw TimeoutException('Timed out while $label'),
  );
}

String _routerPath(WidgetTester tester) {
  final router = GoRouter.of(_appContext(tester));
  return router.routerDelegate.currentConfiguration.uri.path;
}

BuildContext _appContext(WidgetTester tester) {
  return tester.element(find.byType(MaterialApp).first);
}
