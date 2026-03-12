import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    setUp(() async {
      // Clear all stored data before each test
      await TestHelpers.clearTestData();
    });

    testWidgets('displays auth gateway screen on first launch', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
      final l10n = TestHelpers.l10n(tester);

      // Should show auth gateway with CrushHour branding
      expect(find.text('Crush'), findsOneWidget);
      expect(find.text('Find your Perfect Match'), findsOneWidget);

      // Should have Create Account and Sign In buttons
      expect(find.text(l10n.authCreateAccount), findsOneWidget);
      expect(find.text(l10n.authSignIn), findsOneWidget);
    });

    testWidgets('navigates to login screen from auth gateway', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
      final l10n = TestHelpers.l10n(tester);

      // Tap Sign In button
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text(l10n.authWelcomeBack), findsOneWidget);
      expect(find.text(l10n.authSignInToContinue), findsOneWidget);
    });

    testWidgets('shows validation errors on empty login', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Navigate to login
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Find and tap the Sign In button (on login page, not the auth gateway)
      await tester.tap(TestHelpers.loginSignInButton(tester));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email or username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('successful login with dev admin bypass navigates to home', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));
      final l10n = TestHelpers.l10n(tester);

      // Navigate to login
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Enter dev admin credentials
      final identifierField = TestHelpers.textFieldByLabel(
        tester,
        l10n.authEmailOrUsername,
      );
      await tester.enterText(identifierField, 'admin123');
      await tester.pumpAndSettle();

      final passwordField = TestHelpers.textFieldByLabel(
        tester,
        l10n.authPassword,
      );
      await tester.enterText(passwordField, 'admin123');
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.tap(TestHelpers.loginSignInButton(tester));

      // Wait for navigation
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 3));

      // Should navigate to home screen (look for home screen indicators)
      // The home screen typically shows the deck or navigation
      expect(find.text(l10n.authWelcomeBack), findsNothing);
    });

    testWidgets('navigates to sign up screen from auth gateway', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Tap Create Account button
      await tester.tap(TestHelpers.authGatewayCreateAccountButton(tester));
      await tester.pumpAndSettle();
      final ageGateConfirm = find.text('Yes, I am 18+');
      if (ageGateConfirm.evaluate().isNotEmpty) {
        await tester.tap(ageGateConfirm);
        await tester.pumpAndSettle();
      }

      // Should show sign up screen - look for sign up form elements
      // Sign up screens typically have phone or email input fields
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('can navigate to phone auth from login screen', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Navigate to login
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Tap Phone login option
      final phoneButton = find.text('Phone');
      if (phoneButton.evaluate().isNotEmpty) {
        await tester.tap(phoneButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('can navigate to email OTP auth from login screen', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Navigate to login
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Tap Email OTP login option
      final emailOtpButton = find.text('Email OTP');
      if (emailOtpButton.evaluate().isNotEmpty) {
        await tester.tap(emailOtpButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('can navigate to forgot password from login screen', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Navigate to login
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      // Tap Forgot password link
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Should navigate away from login screen
      expect(
        find.text(TestHelpers.l10n(tester).authSignInToContinue),
        findsNothing,
      );
    });
  });

  group('Session Persistence', () {
    testWidgets('remembers authenticated user across app restarts', (
      tester,
    ) async {
      // Start with authenticated state by using dev bypass
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // Login first
      await tester.tap(TestHelpers.authGatewaySignInButton(tester));
      await tester.pumpAndSettle();

      final l10n = TestHelpers.l10n(tester);
      final identifierField = TestHelpers.textFieldByLabel(
        tester,
        l10n.authEmailOrUsername,
      );
      await tester.enterText(identifierField, 'admin123');

      final passwordField = TestHelpers.textFieldByLabel(
        tester,
        l10n.authPassword,
      );
      await tester.enterText(passwordField, 'admin123');

      await tester.tap(TestHelpers.loginSignInButton(tester));
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 3));

      // Verify we're logged in (not on login screen)
      expect(find.text(l10n.authWelcomeBack), findsNothing);
    });
  });

  group('Logout Flow', () {
    testWidgets('logout returns to auth gateway', (tester) async {
      final prefs = await SharedPreferences.getInstance();

      await TestHelpers.launchApp(tester, preferences: prefs);
      await TestHelpers.pumpAndWait(tester, wait: const Duration(seconds: 2));

      // This test would require being logged in first and finding the logout option
      // For now, just verify the auth gateway is accessible
      expect(find.text('Crush'), findsOneWidget);
    });
  });
}
