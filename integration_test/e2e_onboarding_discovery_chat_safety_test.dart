library;

import 'dart:convert';

import 'package:crushhour/core/router.dart';
import 'package:crushhour/data/models/match.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
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
        expect(find.text('Terms & Conditions').evaluate().isNotEmpty, isTrue);

        await _completeOnboardingForDiscovery(tester, username: username);
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        await _likeCurrentDeckProfile(tester);
        final match = await _waitForFirstMatch(tester);
        expect(match, isNotNull);

        await _openChatForMatch(tester, match!);
        await _reportUserFromChat(tester);
        await _blockUserFromChat(tester);
        await _assertSafetySideEffects(tester, prefs: prefs, match: match);
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

Future<void> _completeOnboardingForDiscovery(
  WidgetTester tester, {
  required String username,
}) async {
  final context = _appContext(tester);
  final authRepo = context.read<AuthRepository>();
  final profileRepo = context.read<ProfileRepository>();

  await authRepo.acceptTermsAndConditions();
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
  await authRepo.refreshCurrentUser();
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

Future<CrushMatch?> _waitForFirstMatch(WidgetTester tester) async {
  final context = _appContext(tester);
  final authRepo = context.read<AuthRepository>();
  final discoveryRepo = context.read<DiscoveryRepository>();

  final user = await authRepo.refreshCurrentUser();
  if (user == null) return null;

  for (var i = 0; i < 12; i++) {
    final matches = await discoveryRepo.fetchMatches(user.id);
    if (matches.isNotEmpty) {
      return matches.first;
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
  required CrushMatch match,
}) async {
  final context = _appContext(tester);
  final currentUser = await context.read<AuthRepository>().refreshCurrentUser();
  expect(currentUser, isNotNull);

  final reports = prefs.getStringList('mock_reports') ?? const [];
  expect(reports.isNotEmpty, isTrue);
  final latestReport = jsonDecode(reports.last) as Map<String, dynamic>;
  expect(latestReport['reporterId'], currentUser!.id);
  expect(latestReport['reportedId'], match.otherUserId);
  expect(latestReport['reason'], 'Spam or scams');
  expect(latestReport['matchId'], match.id);
  expect(latestReport['source'], 'chat');

  final blockedRaw = prefs.getString('mock_blocked_${currentUser.id}');
  expect(blockedRaw, isNotNull);
  final blockedUsers = Set<String>.from(
    jsonDecode(blockedRaw!) as List<dynamic>,
  );
  expect(blockedUsers.contains(match.otherUserId), isTrue);
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
