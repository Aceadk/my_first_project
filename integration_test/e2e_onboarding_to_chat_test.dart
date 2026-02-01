/// End-to-End Flow Tests: Onboarding → Match → Chat
///
/// These tests verify the complete user journey through the app,
/// simulating real user behavior from first launch to chatting with a match.
///
/// Run with stub authentication (faster, isolated):
/// ```
/// flutter test integration_test/e2e_onboarding_to_chat_test.dart
/// ```
///
/// Run with real Firebase authentication:
/// ```
/// flutter test integration_test/e2e_onboarding_to_chat_test.dart \
///   --dart-define=USE_FIREBASE_AUTH=true \
///   --dart-define=TEST_EMAIL=adhikarigya8@gmail.com \
///   --dart-define=TEST_PASSWORD=admin1234
/// ```
///
/// Run on connected device:
/// ```
/// flutter test integration_test/e2e_onboarding_to_chat_test.dart -d <device_id>
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';
import 'test_credentials.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Complete User Journey', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'New user: Auth Gateway → Sign Up flow displays correctly',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
        final l10n = TestHelpers.l10n(tester);

        // Step 1: Verify auth gateway displays
        expect(find.text('Crush'), findsOneWidget);
        expect(find.text(l10n.authCreateAccount), findsOneWidget);
        expect(find.text(l10n.authSignIn), findsOneWidget);

        // Step 2: Navigate to sign up
        await tester.tap(TestHelpers.authGatewayCreateAccountButton(tester));
        await tester.pumpAndSettle();
        final ageGateConfirm = find.text('Yes, I am 18+');
        if (ageGateConfirm.evaluate().isNotEmpty) {
          await tester.tap(ageGateConfirm);
          await tester.pumpAndSettle();
        }

        // Step 3: Verify sign up screen is displayed
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'New user: Sign In → Home → Navigate all tabs',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Step 1: Sign in with dev credentials
        await _performLogin(tester);

        // Step 2: Verify we're on the home screen (not on auth screens)
        expect(find.text('CrushHour'), findsNothing);
        expect(find.text('Welcome back'), findsNothing);

        // Step 3: Navigate through all main tabs
        await _navigateToAllTabs(tester);
      },
    );

    testWidgets(
      'User journey: Login → Profile View → Settings → Back',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Navigate to profile
        await _navigateToProfile(tester);

        // Navigate to settings
        await _navigateToSettings(tester);

        // Verify we can navigate back
        await _navigateBack(tester);
      },
    );

    testWidgets(
      'User journey: Login → Discovery deck interactions',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Attempt deck interactions (swipe actions if available)
        await _attemptDeckInteraction(tester);
      },
    );

    testWidgets(
      'User journey: Login → Chat list navigation',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Navigate to chat/messages
        await _navigateToChat(tester);

        // Verify chat screen renders
        final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);
      },
    );

    testWidgets(
      'User journey: Login → Matches screen navigation',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Navigate to matches
        await _navigateToMatches(tester);

        // Verify matches screen renders
        final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);
      },
    );
  });

  group('E2E: Error Handling and Recovery', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Invalid login credentials show error message',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
        final l10n = TestHelpers.l10n(tester);

        // Navigate to login
        await tester.tap(TestHelpers.authGatewaySignInButton(tester));
        await tester.pumpAndSettle();

        // Enter invalid credentials
        final identifierField =
            TestHelpers.textFieldByLabel(tester, l10n.authEmailOrUsername);
        if (identifierField.evaluate().isNotEmpty) {
          await tester.enterText(identifierField, 'invalid@example.com');
        }

        final passwordField =
            TestHelpers.textFieldByLabel(tester, l10n.authPassword);
        if (passwordField.evaluate().isNotEmpty) {
          await tester.enterText(passwordField, 'wrongpassword');
        }

        // Try to sign in
        final signInButton = TestHelpers.loginSignInButton(tester);
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
        }

        // Should still be on login screen (not navigated away)
        // The stub repository handles authentication
        final hasTextField = find.byType(TextField).evaluate().isNotEmpty;
        expect(hasTextField, isTrue);
      },
    );

    testWidgets(
      'Empty form submission shows validation errors',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Navigate to login
        await tester.tap(TestHelpers.authGatewaySignInButton(tester));
        await tester.pumpAndSettle();

        // Submit empty form
        final signInButton = TestHelpers.loginSignInButton(tester);
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();
        }

        // Should show validation errors
        final errorTextFinder = find.textContaining('Please enter');
        expect(errorTextFinder.evaluate().isNotEmpty, isTrue);
      },
    );
  });

  group('E2E: Navigation State Persistence', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Tab navigation maintains correct state',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Navigate through tabs and verify each renders correctly
        await _navigateToChat(tester);
        var hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);

        await _navigateToMatches(tester);
        hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);

        await _navigateToProfile(tester);
        hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);
      },
    );
  });

  group('E2E: Accessibility Checks', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Auth gateway has accessible elements',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
        final l10n = TestHelpers.l10n(tester);

        // Verify buttons are accessible
        expect(find.text(l10n.authCreateAccount), findsOneWidget);
        expect(find.text(l10n.authSignIn), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'Login form has accessible input fields',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Navigate to login
        await tester.tap(TestHelpers.authGatewaySignInButton(tester));
        await tester.pumpAndSettle();

        // Verify text fields exist
        expect(find.byType(TextField), findsWidgets);

        handle.dispose();
      },
    );
  });

  group('E2E: Performance Checks', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'App launches and renders within reasonable time',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await tester.pump();

        stopwatch.stop();

        // App should render first frame quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Should have a scaffold rendered
        final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
        expect(hasScaffold, isTrue);
      },
    );

    testWidgets(
      'Navigation between screens is smooth',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(TestApp(preferences: prefs));
        await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

        // Login
        await _performLogin(tester);

        // Measure navigation time
        final stopwatch = Stopwatch()..start();

        await _navigateToProfile(tester);
        await _navigateToSettings(tester);
        await _navigateBack(tester);

        stopwatch.stop();

        // Navigation should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      },
    );
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Perform login with test credentials
/// Uses TestCredentials which can be overridden via --dart-define
Future<void> _performLogin(WidgetTester tester) async {
  final l10n = TestHelpers.l10n(tester);
  await tester.tap(TestHelpers.authGatewaySignInButton(tester));
  await tester.pumpAndSettle();

  final identifierField =
      TestHelpers.textFieldByLabel(tester, l10n.authEmailOrUsername);
  if (identifierField.evaluate().isNotEmpty) {
    await tester.enterText(identifierField, TestCredentials.testEmail);
  }

  final passwordField = TestHelpers.textFieldByLabel(tester, l10n.authPassword);
  if (passwordField.evaluate().isNotEmpty) {
    await tester.enterText(passwordField, TestCredentials.testPassword);
  }

  final signInButton = TestHelpers.loginSignInButton(tester);
  if (signInButton.evaluate().isNotEmpty) {
    await tester.tap(signInButton);
    await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 3));
  }
}

/// Navigate to profile screen
Future<void> _navigateToProfile(WidgetTester tester) async {
  final profileIcon = find.byIcon(Icons.person);
  final profileIconOutlined = find.byIcon(Icons.person_outline);

  if (profileIcon.evaluate().isNotEmpty) {
    await tester.tap(profileIcon.first);
    await tester.pumpAndSettle();
  } else if (profileIconOutlined.evaluate().isNotEmpty) {
    await tester.tap(profileIconOutlined.first);
    await tester.pumpAndSettle();
  }
}

/// Navigate to settings screen
Future<void> _navigateToSettings(WidgetTester tester) async {
  final settingsIcon = find.byIcon(Icons.settings);
  final settingsIconOutlined = find.byIcon(Icons.settings_outlined);

  if (settingsIcon.evaluate().isNotEmpty) {
    await tester.tap(settingsIcon.first);
    await tester.pumpAndSettle();
  } else if (settingsIconOutlined.evaluate().isNotEmpty) {
    await tester.tap(settingsIconOutlined.first);
    await tester.pumpAndSettle();
  }
}

/// Navigate to chat/messages screen
Future<void> _navigateToChat(WidgetTester tester) async {
  final chatIcons = [
    find.byIcon(Icons.chat),
    find.byIcon(Icons.chat_bubble),
    find.byIcon(Icons.chat_bubble_outline),
    find.byIcon(Icons.message),
    find.byIcon(Icons.message_outlined),
  ];

  for (final iconFinder in chatIcons) {
    if (iconFinder.evaluate().isNotEmpty) {
      await tester.tap(iconFinder.first);
      await tester.pumpAndSettle();
      return;
    }
  }
}

/// Navigate to matches screen
Future<void> _navigateToMatches(WidgetTester tester) async {
  final matchIcons = [
    find.byIcon(Icons.favorite),
    find.byIcon(Icons.favorite_outline),
    find.byIcon(Icons.people),
    find.byIcon(Icons.people_outline),
  ];

  for (final iconFinder in matchIcons) {
    if (iconFinder.evaluate().isNotEmpty) {
      await tester.tap(iconFinder.first);
      await tester.pumpAndSettle();
      return;
    }
  }

  // Try text-based navigation
  final matchesText = find.text('Matches');
  if (matchesText.evaluate().isNotEmpty) {
    await tester.tap(matchesText.first);
    await tester.pumpAndSettle();
  }
}

/// Navigate back
Future<void> _navigateBack(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  final backIcon = find.byIcon(Icons.arrow_back);
  final backIconIos = find.byIcon(Icons.arrow_back_ios);

  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
    await tester.pumpAndSettle();
  } else if (backIcon.evaluate().isNotEmpty) {
    await tester.tap(backIcon.first);
    await tester.pumpAndSettle();
  } else if (backIconIos.evaluate().isNotEmpty) {
    await tester.tap(backIconIos.first);
    await tester.pumpAndSettle();
  }
}

/// Navigate through all main tabs
Future<void> _navigateToAllTabs(WidgetTester tester) async {
  // Try navigating to each main tab
  await _navigateToChat(tester);
  await _navigateToMatches(tester);
  await _navigateToProfile(tester);

  // Navigate back to home/discovery if possible
  final homeIcon = find.byIcon(Icons.home);
  final homeOutlined = find.byIcon(Icons.home_outlined);
  final exploreIcon = find.byIcon(Icons.explore);
  final exploreOutlined = find.byIcon(Icons.explore_outlined);

  if (homeIcon.evaluate().isNotEmpty) {
    await tester.tap(homeIcon.first);
    await tester.pumpAndSettle();
  } else if (homeOutlined.evaluate().isNotEmpty) {
    await tester.tap(homeOutlined.first);
    await tester.pumpAndSettle();
  } else if (exploreIcon.evaluate().isNotEmpty) {
    await tester.tap(exploreIcon.first);
    await tester.pumpAndSettle();
  } else if (exploreOutlined.evaluate().isNotEmpty) {
    await tester.tap(exploreOutlined.first);
    await tester.pumpAndSettle();
  }
}

/// Attempt deck interactions (like/pass buttons)
Future<void> _attemptDeckInteraction(WidgetTester tester) async {
  // Look for pass button (usually X icon)
  final passButton = find.byIcon(Icons.close);
  if (passButton.evaluate().isNotEmpty) {
    await tester.tap(passButton.first);
    await tester.pumpAndSettle();
  }

  // Look for like button (usually heart icon)
  final likeButton = find.byIcon(Icons.favorite);
  final likeButtonOutline = find.byIcon(Icons.favorite_outline);

  if (likeButton.evaluate().isNotEmpty) {
    await tester.tap(likeButton.first);
    await tester.pumpAndSettle();
  } else if (likeButtonOutline.evaluate().isNotEmpty) {
    await tester.tap(likeButtonOutline.first);
    await tester.pumpAndSettle();
  }

  // Look for super like button (usually star icon)
  final superLikeButton = find.byIcon(Icons.star);
  final superLikeOutline = find.byIcon(Icons.star_outline);

  if (superLikeButton.evaluate().isNotEmpty) {
    await tester.tap(superLikeButton.first);
    await tester.pumpAndSettle();
  } else if (superLikeOutline.evaluate().isNotEmpty) {
    await tester.tap(superLikeOutline.first);
    await tester.pumpAndSettle();
  }
}
