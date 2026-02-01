import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/core/theme.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/design_system/widgets/glass_button.dart';
import 'package:crushhour/design_system/widgets/glass_text_field.dart';

// Repositories
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/discovery_repository.dart';
import 'package:crushhour/features/chat/data/repositories/chat_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/subscription_repository.dart';
import 'package:crushhour/features/calls/data/repositories/call_repository.dart';

// Stub implementations
import 'package:crushhour/features/auth/data/repositories/impl/stub_auth_repository.dart';
import 'package:crushhour/features/profile/data/repositories/impl/stub_profile_repository.dart';
import 'package:crushhour/features/discovery/data/repositories/impl/stub_discovery_repository.dart';
import 'package:crushhour/features/chat/data/repositories/impl/stub_chat_repository.dart';
import 'package:crushhour/features/subscription/data/repositories/impl/stub_subscription_repository.dart';
import 'package:crushhour/features/calls/data/repositories/impl/stub_call_repository.dart';

// BLoCs
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_event.dart';
import 'package:crushhour/features/auth/presentation/bloc/session_bloc.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:crushhour/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/calls/presentation/bloc/call_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/privacy_settings_cubit.dart';

/// Test app configuration for integration tests.
/// Uses stub repositories for isolated, repeatable testing.
class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.preferences,
    this.initialLocation,
  });

  final SharedPreferences preferences;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: _buildTestRepositories(),
      child: MultiBlocProvider(
        providers: _buildTestBlocs(preferences),
        child: _TestRouterHost(initialLocation: initialLocation),
      ),
    );
  }

  static List<RepositoryProvider> _buildTestRepositories() {
    final authRepo = StubAuthRepository();
    final profileRepo = StubProfileRepository();
    final subRepo = StubSubscriptionRepository();
    final discoveryRepo = StubDiscoveryRepository();
    final chatRepo = StubChatRepository();
    final callRepo = StubCallRepository();

    return [
      RepositoryProvider<AuthRepository>.value(value: authRepo),
      RepositoryProvider<ProfileRepository>.value(value: profileRepo),
      RepositoryProvider<SubscriptionRepository>.value(value: subRepo),
      RepositoryProvider<DiscoveryRepository>.value(value: discoveryRepo),
      RepositoryProvider<ChatRepository>.value(value: chatRepo),
      RepositoryProvider<CallRepository>.value(value: callRepo),
    ];
  }

  static List<BlocProvider> _buildTestBlocs(SharedPreferences preferences) {
    return [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(AuthStarted()),
      ),
      BlocProvider<SessionBloc>(
        create: (context) => SessionBloc(
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<SubscriptionBloc>(
        create: (context) => SubscriptionBloc(
          subscriptionRepository: context.read<SubscriptionRepository>(),
        )..add(SubscriptionWatchStarted()),
      ),
      BlocProvider<ProfileBloc>(
        create: (context) => ProfileBloc(
          profileRepository: context.read<ProfileRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<DiscoveryBloc>(
        create: (context) => DiscoveryBloc(
          discoveryRepository: context.read<DiscoveryRepository>(),
          subscriptionRepository: context.read<SubscriptionRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<ChatBloc>(
        create: (context) => ChatBloc(
          chatRepository: context.read<ChatRepository>(),
          subscriptionRepository: context.read<SubscriptionRepository>(),
          authRepository: context.read<AuthRepository>(),
        ),
      ),
      BlocProvider<CallBloc>(
        create: (context) => CallBloc(
          callRepository: context.read<CallRepository>(),
        ),
      ),
      BlocProvider<ThemeCubit>(
        create: (context) => ThemeCubit(
          preferences: preferences,
          authRepository: context.read<AuthRepository>(),
          profileRepository: context.read<ProfileRepository>(),
        ),
      ),
      BlocProvider<NotificationSettingsCubit>(
        create: (_) => NotificationSettingsCubit(preferences: preferences),
      ),
      BlocProvider<DiscoverySettingsCubit>(
        create: (_) => DiscoverySettingsCubit(preferences: preferences),
      ),
      BlocProvider<SafetyCubit>(
        create: (context) => SafetyCubit(
          preferences: preferences,
          chatRepository: context.read<ChatRepository>(),
          discoveryRepository: context.read<DiscoveryRepository>(),
        ),
      ),
      BlocProvider<LocaleCubit>(
        create: (_) => LocaleCubit(preferences: preferences),
      ),
      BlocProvider<StorageSettingsCubit>(
        create: (_) => StorageSettingsCubit(preferences: preferences),
      ),
      BlocProvider<PrivacySettingsCubit>(
        create: (_) => PrivacySettingsCubit(preferences: preferences),
      ),
    ];
  }
}

class _TestRouterHost extends StatefulWidget {
  const _TestRouterHost({this.initialLocation});

  final String? initialLocation;

  @override
  State<_TestRouterHost> createState() => _TestRouterHostState();
}

class _TestRouterHostState extends State<_TestRouterHost> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _router = createRouter(authBloc);
    if (widget.initialLocation != null) {
      _router.go(widget.initialLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, themeMode) {
        final materialMode = switch (themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.darkLuxury => ThemeMode.dark,
          AppThemeMode.darkLuxuryModern => ThemeMode.dark,
        };
        return MaterialApp.router(
          title: 'CrushHour Test',
          theme: CrushTheme.light(),
          darkTheme: CrushTheme.dark(),
          themeMode: materialMode,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Test helper utilities
class TestHelpers {
  /// Clear all stored test data
  static Future<void> clearTestData() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Pump app and settle all animations
  static Future<void> pumpAndSettle(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  }

  /// Access localized strings for the current test app.
  static AppLocalizations l10n(WidgetTester tester) {
    final locale = tester.binding.platformDispatcher.locale;
    return lookupAppLocalizations(locale);
  }

  /// Finder for the primary auth button on the auth gateway (Create account).
  static Finder authGatewayCreateAccountButton(WidgetTester tester) {
    return find.widgetWithText(
      GlassPrimaryButton,
      l10n(tester).authCreateAccount,
    );
  }

  /// Finder for the auth gateway sign-in button.
  static Finder authGatewaySignInButton(WidgetTester tester) {
    return find.widgetWithText(
      GlassOutlinedButton,
      l10n(tester).authSignIn,
    );
  }

  /// Finder for the login screen sign-in button.
  static Finder loginSignInButton(WidgetTester tester) {
    return find.widgetWithText(
      GlassPrimaryButton,
      l10n(tester).authSignIn,
    );
  }

  /// Finder for a TextField inside a GlassTextField by its label.
  static Finder textFieldByLabel(WidgetTester tester, String label) {
    final field = find.widgetWithText(GlassTextField, label);
    return find.descendant(of: field, matching: find.byType(TextField));
  }

  /// Wait for async operations and settle
  static Future<void> pumpAndWait(
    WidgetTester tester, {
    Duration wait = const Duration(milliseconds: 500),
  }) async {
    await tester.pump(wait);
    await tester.pumpAndSettle();
  }

  /// Find widget by key and tap
  static Future<void> tapByKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text into field by key
  static Future<void> enterTextByKey(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Find text field and enter text
  static Future<void> enterTextInField(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = 100,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }
}
