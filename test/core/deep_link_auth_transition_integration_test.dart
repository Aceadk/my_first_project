import 'dart:async';

import 'package:crushhour/core/deep_link_bootstrap.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/user.dart';
import 'package:crushhour/features/auth/domain/repositories/auth_repository.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpUntilSettled(
    WidgetTester tester, {
    int maxPumps = 30,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!tester.binding.hasScheduledFrame) break;
    }
  }

  AuthState buildState({required AuthStatus status, CrushUser? user}) {
    return AuthState(
      status: status,
      user: user,
      phoneInProgress: null,
      emailInProgress: null,
      emailOtpIdentifier: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  CrushUser buildUser() {
    return const CrushUser(
      id: 'deep-link-user-1',
      phoneNumber: '+15555550123',
      email: 'deeplink@example.com',
      username: 'deeplink_user',
      isEmailVerified: true,
      profile: null,
      isPhoneVerified: false,
      isIdVerified: false,
      plan: SubscriptionPlan.free,
      hasAcceptedTerms: true,
      hasSkippedBasicInfo: true,
      hasSkippedProfileSetup: true,
    );
  }

  group('Deep-link auth transition integration', () {
    Future<_IntegrationHarness> pumpHarness(
      WidgetTester tester, {
      required Uri initialLink,
      bool isAuthenticated = false,
    }) async {
      final authRepository = _NoopAuthRepository();
      final authBloc = _MutableAuthBloc(
        authRepository: authRepository,
        initialState: buildState(
          status: isAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: isAuthenticated ? buildUser() : null,
        ),
      );
      var authFlag = isAuthenticated;
      final authStatusController = StreamController<bool>.broadcast();
      final navigatedRoutes = <String>[];
      final router = GoRouter(
        initialLocation: CrushRoutes.authGateway,
        routes: [
          GoRoute(
            path: CrushRoutes.authGateway,
            builder: (context, state) =>
                const Scaffold(body: Text('Auth Screen')),
          ),
          GoRoute(
            path: '${CrushRoutes.chat}/:matchId',
            builder: (context, state) =>
                Scaffold(body: Text('Chat ${state.pathParameters['matchId']}')),
          ),
          GoRoute(
            path: '${CrushRoutes.userProfile}/:userId',
            builder: (context, state) => Scaffold(
              body: Text('Profile ${state.pathParameters['userId']}'),
            ),
          ),
          GoRoute(
            path: CrushRoutes.settings,
            builder: (context, state) =>
                const Scaffold(body: Text('Settings Screen')),
          ),
          GoRoute(
            path: CrushRoutes.supportCategory,
            builder: (context, state) => Scaffold(
              body: Text('Support ${state.pathParameters['categoryId'] ?? ''}'),
            ),
          ),
        ],
      );

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 16));
        await authStatusController.close();
        router.dispose();
        await authBloc.close();
      });

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: DeepLinkBootstrap(
            getInitialLink: () async => initialLink,
            isEmailSignInLink: (_) => false,
            isAuthenticated: () => authFlag,
            authStatusStream: authStatusController.stream,
            onNavigate: (route, {extra}) {
              navigatedRoutes.add(route);
              router.go(route, extra: extra);
            },
            isWebOverride: true,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );

      await tester.pump();
      await pumpUntilSettled(tester, maxPumps: 20);

      return _IntegrationHarness(
        authBloc: authBloc,
        router: router,
        authStatusController: authStatusController,
        navigatedRoutes: navigatedRoutes,
        setAuthenticated: (value) {
          authFlag = value;
        },
      );
    }

    Future<void> authenticateHarness(
      WidgetTester tester,
      _IntegrationHarness harness,
    ) async {
      harness.authBloc.emitAuthState(
        buildState(status: AuthStatus.authenticated, user: buildUser()),
      );
      harness.setAuthenticated(true);
      harness.authStatusController.add(true);
      await tester.pump();
      await pumpUntilSettled(tester, maxPumps: 20);
    }

    testWidgets('replays pending auth-required deep link after login', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse('https://crushhour.app/chat/match_pending'),
      );

      expect(harness.authStatusController.hasListener, isTrue);
      expect(find.text('Auth Screen'), findsOneWidget);
      expect(harness.router.routeInformationProvider.value.uri.path, '/auth');
      expect(harness.navigatedRoutes, contains('/auth'));

      await authenticateHarness(tester, harness);

      expect(harness.navigatedRoutes, contains('/chat/match_pending'));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/chat/match_pending',
      );
      expect(find.text('Chat match_pending'), findsOneWidget);
    });

    testWidgets('replays pending user-profile deep link after login', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse('https://crushhour.app/user-profile/user_42'),
      );

      expect(harness.router.routeInformationProvider.value.uri.path, '/auth');
      expect(harness.navigatedRoutes, contains('/auth'));

      await authenticateHarness(tester, harness);

      expect(harness.navigatedRoutes, contains('/user-profile/user_42'));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/user-profile/user_42',
      );
      expect(find.text('Profile user_42'), findsOneWidget);
    });

    testWidgets('replays pending settings deep link after login', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse('https://crushhour.app/settings'),
      );

      expect(harness.router.routeInformationProvider.value.uri.path, '/auth');
      expect(harness.navigatedRoutes, contains('/auth'));

      await authenticateHarness(tester, harness);

      expect(harness.navigatedRoutes, contains('/settings'));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/settings',
      );
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('replays pending premium deep link to settings after login', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse('https://crushhour.app/premium'),
      );

      expect(harness.router.routeInformationProvider.value.uri.path, '/auth');
      expect(harness.navigatedRoutes, contains('/auth'));

      await authenticateHarness(tester, harness);

      expect(harness.navigatedRoutes, contains('/settings'));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/settings',
      );
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('replays pending match deep link to chat after login', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse('https://crushhour.app/match/match_alias_7'),
      );

      expect(harness.router.routeInformationProvider.value.uri.path, '/auth');
      expect(harness.navigatedRoutes, contains('/auth'));

      await authenticateHarness(tester, harness);

      expect(harness.navigatedRoutes, contains('/chat/match_alias_7'));
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/chat/match_alias_7',
      );
      expect(find.text('Chat match_alias_7'), findsOneWidget);
    });

    testWidgets('opens support category deep links without authentication', (
      tester,
    ) async {
      final harness = await pumpHarness(
        tester,
        initialLink: Uri.parse(
          'https://crushhour.app/support/category/matching',
        ),
      );

      expect(
        harness.router.routeInformationProvider.value.uri.path,
        '/support/category/matching',
      );
      expect(harness.navigatedRoutes, contains('/support/category/matching'));
      expect(find.text('Support matching'), findsOneWidget);
    });
  });
}

class _IntegrationHarness {
  _IntegrationHarness({
    required this.authBloc,
    required this.router,
    required this.authStatusController,
    required this.navigatedRoutes,
    required this.setAuthenticated,
  });

  final _MutableAuthBloc authBloc;
  final GoRouter router;
  final StreamController<bool> authStatusController;
  final List<String> navigatedRoutes;
  final void Function(bool value) setAuthenticated;
}

class _NoopAuthRepository implements AuthRepository {
  @override
  bool get isVerificationBypassEnabled => false;

  @override
  bool get supportsAppleSignIn => false;

  @override
  bool get supportsUsernameLogin => false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authStateChanges) {
      return const Stream<CrushUser?>.empty();
    }
    if (invocation.memberName == #bootstrapSession) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _MutableAuthBloc extends AuthBloc {
  _MutableAuthBloc({
    required super.authRepository,
    required AuthState initialState,
  }) {
    emit(initialState);
  }

  void emitAuthState(AuthState state) {
    emit(state);
  }
}
