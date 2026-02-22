import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/deep_link_bootstrap.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';

void main() {
  Future<void> pumpBootstrap(
    WidgetTester tester, {
    Future<Uri?> Function()? getInitialLink,
    Stream<Uri?>? uriLinkStream,
    bool Function(String)? isEmailSignInLink,
    Future<String?> Function(String)? secureStorageRead,
    void Function(AuthEvent event)? onAuthEvent,
    void Function(SubscriptionEvent event)? onSubscriptionEvent,
    bool isWebOverride = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeepLinkBootstrap(
          getInitialLink: getInitialLink,
          uriLinkStream: uriLinkStream,
          isEmailSignInLink: isEmailSignInLink,
          secureStorageRead: secureStorageRead,
          onAuthEvent: onAuthEvent,
          onSubscriptionEvent: onSubscriptionEvent,
          isWebOverride: isWebOverride,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pump();
  }

  group('DeepLinkBootstrap', () {
    testWidgets('dispatches auth email-link event for verify-email links', (
      tester,
    ) async {
      final authEvents = <AuthEvent>[];
      final subscriptionEvents = <SubscriptionEvent>[];
      final deepLink = Uri.parse(
        'https://example.com/verify-email?email=test%40example.com&oobCode=abc',
      );

      await pumpBootstrap(
        tester,
        getInitialLink: () async => deepLink,
        isEmailSignInLink: (_) => false,
        secureStorageRead: (_) async => null,
        onAuthEvent: authEvents.add,
        onSubscriptionEvent: subscriptionEvents.add,
      );

      expect(authEvents, hasLength(1));
      final event = authEvents.single as AuthEmailLinkSubmitted;
      expect(event.email, 'test@example.com');
      expect(event.emailLink, deepLink.toString());
      expect(subscriptionEvents, isEmpty);
    });

    testWidgets('uses pending stored email for verify-email link fallback', (
      tester,
    ) async {
      final authEvents = <AuthEvent>[];
      final deepLink = Uri.parse('https://example.com/verify_email?oobCode=abc');

      await pumpBootstrap(
        tester,
        getInitialLink: () async => deepLink,
        isEmailSignInLink: (_) => false,
        secureStorageRead: (_) async => 'pending@example.com',
        onAuthEvent: authEvents.add,
      );

      expect(authEvents, hasLength(1));
      final event = authEvents.single as AuthEmailLinkSubmitted;
      expect(event.email, 'pending@example.com');
      expect(event.emailLink, deepLink.toString());
    });

    testWidgets('dispatches auth event for Firebase email sign-in links', (
      tester,
    ) async {
      final authEvents = <AuthEvent>[];
      final deepLink = Uri.parse(
        'https://crush-265f7.firebaseapp.com/finishSignIn?mode=signIn&oobCode=xyz',
      );

      await pumpBootstrap(
        tester,
        getInitialLink: () async => deepLink,
        isEmailSignInLink: (_) => true,
        secureStorageRead: (_) async => 'magic@example.com',
        onAuthEvent: authEvents.add,
      );

      expect(authEvents, hasLength(1));
      final event = authEvents.single as AuthEmailLinkSubmitted;
      expect(event.email, 'magic@example.com');
      expect(event.emailLink, deepLink.toString());
    });

    testWidgets('dispatches subscription restore for billing callbacks', (
      tester,
    ) async {
      final subscriptionEvents = <SubscriptionEvent>[];
      final deepLink = Uri.parse('https://checkout.example.com/callback?status=ok');

      await pumpBootstrap(
        tester,
        getInitialLink: () async => deepLink,
        isEmailSignInLink: (_) => false,
        onSubscriptionEvent: subscriptionEvents.add,
      );

      expect(subscriptionEvents, hasLength(1));
      expect(subscriptionEvents.single, isA<SubscriptionRestoreRequested>());
    });

    testWidgets('subscribes to runtime uri stream when not web', (tester) async {
      final controller = StreamController<Uri?>.broadcast();
      final authEvents = <AuthEvent>[];

      await pumpBootstrap(
        tester,
        getInitialLink: () async => null,
        uriLinkStream: controller.stream,
        isEmailSignInLink: (_) => false,
        onAuthEvent: authEvents.add,
        isWebOverride: false,
      );

      controller.add(
        Uri.parse('https://example.com/verify-email?email=stream%40example.com'),
      );
      await tester.pump();

      expect(authEvents, hasLength(1));
      final event = authEvents.single as AuthEmailLinkSubmitted;
      expect(event.email, 'stream@example.com');

      await controller.close();
    });

    testWidgets('does not subscribe to runtime uri stream on web', (tester) async {
      final controller = StreamController<Uri?>.broadcast();
      final authEvents = <AuthEvent>[];

      await pumpBootstrap(
        tester,
        getInitialLink: () async => null,
        uriLinkStream: controller.stream,
        isEmailSignInLink: (_) => false,
        onAuthEvent: authEvents.add,
        isWebOverride: true,
      );

      controller.add(
        Uri.parse('https://example.com/verify-email?email=ignored%40example.com'),
      );
      await tester.pump();

      expect(authEvents, isEmpty);

      await controller.close();
    });
  });
}
