import 'dart:async';

import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/settings/presentation/screens/subscription_settings_screen.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'mock/stub_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final launcherCalls = <MethodCall>[];

  setUp(() {
    launcherCalls.clear();
    PackageInfo.setMockInitialValues(
      appName: 'Crush',
      packageName: 'com.crushhour.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
    AnalyticsService.setInstance(StubAnalyticsService());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          launcherCalls.add(call);
          if (call.method == 'canLaunch' || call.method == 'canLaunchUrl') {
            return true;
          }
          if (call.method == 'launch' || call.method == 'launchUrl') {
            return true;
          }
          return null;
        });
  });

  tearDown(() {
    AnalyticsService.resetInstance();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  SubscriptionBloc buildBloc({
    FakeSubscriptionRepository? subscriptionRepository,
  }) {
    return SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository:
          subscriptionRepository ?? FakeSubscriptionRepository(),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required SubscriptionBloc bloc,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SubscriptionBloc>.value(
          value: bloc,
          child: const SubscriptionSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<GoRouter> pumpScreenWithRouter(
    WidgetTester tester, {
    required SubscriptionBloc bloc,
  }) async {
    final router = GoRouter(
      initialLocation: CrushRoutes.subscriptionSettings,
      routes: [
        GoRoute(
          path: CrushRoutes.subscriptionSettings,
          builder: (context, state) => BlocProvider<SubscriptionBloc>.value(
            value: bloc,
            child: const SubscriptionSettingsScreen(),
          ),
        ),
        GoRoute(
          path: CrushRoutes.paywall,
          builder: (context, state) =>
              const Scaffold(body: Text('Paywall Screen')),
        ),
        GoRoute(
          path: CrushRoutes.support,
          builder: (context, state) =>
              const Scaffold(body: Text('Support Screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('free users see plan selection and restore actions', (
    tester,
  ) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc: bloc);

    expect(find.text('Current Plan'), findsOneWidget);
    expect(find.text('Choose a plan'), findsOneWidget);
    expect(
      find.byKey(const Key('subscription_settings_restore_button')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Free plan - upgrade for unlimited likes and premium controls.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('premium users see management sections and renewal copy', (
    tester,
  ) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc: bloc);
    bloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(
          tier: SubscriptionTier.plus,
          status: 'active',
          nextRenewal: DateTime(2026, 3, 1),
          cancelAtPeriodEnd: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Plan'), findsOneWidget);
    expect(find.text('Billing History'), findsOneWidget);
    expect(find.textContaining('Plus Member - Renews on'), findsOneWidget);
    expect(find.textContaining('Billing date:'), findsOneWidget);
  });

  testWidgets('change plan navigates to paywall options', (tester) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpScreenWithRouter(tester, bloc: bloc);
    bloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(tier: SubscriptionTier.plus, status: 'active'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('subscription_management_change_plan_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('subscription_management_change_plan_button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Paywall Screen'), findsOneWidget);
  });

  testWidgets('restore action shows feedback for free users', (tester) async {
    final restoreCompleter = Completer<SubscriptionStatus>();
    final repository = _ControlledSubscriptionRepository(
      onRefreshStatus: () => restoreCompleter.future,
    );
    final bloc = SubscriptionBloc(
      authRepository: FakeAuthRepository(),
      subscriptionRepository: repository,
    );
    addTearDown(() async {
      await bloc.close();
      repository.dispose();
    });

    await pumpScreen(tester, bloc: bloc);

    await tester.tap(
      find.byKey(const Key('subscription_settings_restore_button')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('subscription_settings_restore_loading')),
      findsOneWidget,
    );

    restoreCompleter.complete(
      SubscriptionStatus(tier: SubscriptionTier.free, status: 'none'),
    );
    await tester.pumpAndSettle();

    expect(find.text('No purchases found to restore.'), findsOneWidget);
  });

  testWidgets('cancel subscription opens store management on Android', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc: bloc);
    bloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(tier: SubscriptionTier.plus, status: 'active'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('subscription_management_cancel_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('subscription_management_cancel_button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final launches = launcherCalls
        .where((call) => call.method == 'launch' || call.method == 'launchUrl')
        .toList();
    expect(launches, hasLength(1));
    final launchText = launches.single.arguments.toString();
    expect(
      launchText,
      contains('https://play.google.com/store/account/subscriptions'),
    );
    expect(launchText, contains('sku=plus_monthly'));
    expect(launchText, contains('package=com.crushhour.app'));
    debugDefaultTargetPlatformOverride = null;
  });
}

class _ControlledSubscriptionRepository extends FakeSubscriptionRepository {
  _ControlledSubscriptionRepository({required this.onRefreshStatus});

  final Future<SubscriptionStatus> Function() onRefreshStatus;

  @override
  Future<SubscriptionStatus> refreshStatus() {
    return onRefreshStatus();
  }
}
