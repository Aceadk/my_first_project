import 'dart:async';

import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/repositories/fake_repositories.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';
import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_core_navigation_section.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_links_section.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_subscription_panel_section.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_support_section.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('core navigation section renders major settings tiles', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final authRepository = FakeAuthRepository();
    final profileRepository = FakeProfileRepository();
    final subscriptionRepository = FakeSubscriptionRepository();
    final incognitoRepository = _TestIncognitoRepository();

    final themeCubit = ThemeCubit(
      preferences: prefs,
      authRepository: authRepository,
      profileRepository: profileRepository,
    );
    final notificationsCubit = NotificationSettingsCubit(preferences: prefs);
    final localeCubit = LocaleCubit(preferences: prefs);
    final discoveryCubit = DiscoverySettingsCubit(preferences: prefs);
    final storageCubit = StorageSettingsCubit(preferences: prefs);
    final authBloc = AuthBloc(authRepository: authRepository);
    final subscriptionBloc = SubscriptionBloc(
      subscriptionRepository: subscriptionRepository,
      authRepository: authRepository,
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<IncognitoRepository>.value(
            value: incognitoRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<NotificationSettingsCubit>.value(
              value: notificationsCubit,
            ),
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<DiscoverySettingsCubit>.value(value: discoveryCubit),
            BlocProvider<StorageSettingsCubit>.value(value: storageCubit),
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SettingsCoreNavigationSection(
                  themeLabelBuilder: _themeLabel,
                  languageLabelBuilder: _languageLabel,
                  subscriptionSubtitleBuilder: _subscriptionSubtitle,
                  onIncognitoTap: _onIncognitoTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Language & Region'), findsOneWidget);
    expect(find.text('Discovery & Filters'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Incognito mode'), findsOneWidget);

    themeCubit.close();
    notificationsCubit.close();
    localeCubit.close();
    discoveryCubit.close();
    storageCubit.close();
    authBloc.close();
    subscriptionBloc.close();
    incognitoRepository.dispose();
  });

  testWidgets('subscription panel section updates CTA for Plus users', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final subscriptionRepository = FakeSubscriptionRepository();
    final freeBloc = SubscriptionBloc(
      subscriptionRepository: subscriptionRepository,
      authRepository: authRepository,
    );

    await tester.pumpWidget(
      BlocProvider<SubscriptionBloc>.value(
        value: freeBloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsSubscriptionPanelSection()),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Upgrade to Plus'), findsOneWidget);
    freeBloc.close();

    final plusBloc = SubscriptionBloc(
      subscriptionRepository: subscriptionRepository,
      authRepository: authRepository,
    );
    plusBloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(plan: SubscriptionPlan.plus),
      ),
    );

    await tester.pumpWidget(
      BlocProvider<SubscriptionBloc>.value(
        value: plusBloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsSubscriptionPanelSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Manage subscription'), findsOneWidget);
    plusBloc.close();
  });

  testWidgets('subscription panel shows no-purchase restore status', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final subscriptionRepository = FakeSubscriptionRepository();
    final bloc = SubscriptionBloc(
      subscriptionRepository: subscriptionRepository,
      authRepository: authRepository,
    );
    bloc.add(
      SubscriptionStatusUpdated(
        SubscriptionStatus(plan: SubscriptionPlan.free, status: 'none'),
      ),
    );

    await tester.pumpWidget(
      BlocProvider<SubscriptionBloc>.value(
        value: bloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsSubscriptionPanelSection()),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Status: NONE'), findsOneWidget);
    bloc.close();
  });

  testWidgets('support section shows blocked-user summary and actions', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('safety_blocked', const ['u1', 'u2']);

    final profileRepository = FakeProfileRepository();
    final subscriptionRepository = FakeSubscriptionRepository();
    final discoveryRepository = FakeDiscoveryRepository(
      profileRepository,
      subscriptionRepository,
    );
    final chatRepository = FakeChatRepository(
      subscriptionRepository,
      discoveryRepository,
    );
    final safetyCubit = SafetyCubit(
      preferences: prefs,
      chatRepository: chatRepository,
      discoveryRepository: discoveryRepository,
    );

    await tester.pumpWidget(
      BlocProvider<SafetyCubit>.value(
        value: safetyCubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsSupportSection()),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Safety & Blocking'), findsOneWidget);
    expect(find.text('2 blocked users'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    safetyCubit.close();
  });

  testWidgets('links section renders heading and version value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsLinksSection(
            heading: 'Legal',
            links: [
              SettingsLinkItem(
                icon: Icons.article_outlined,
                title: 'Terms of Service',
              ),
              SettingsLinkItem(
                icon: Icons.info_outline,
                title: 'Version',
                value: '1.0.0',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
  });
}

String _themeLabel(BuildContext context, AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return 'Light';
    case AppThemeMode.dark:
      return 'Dark';
    case AppThemeMode.system:
      return 'System';
    case AppThemeMode.darkLuxury:
      return 'Dark Luxury';
    case AppThemeMode.darkLuxuryModern:
      return 'Dark Luxury Modern';
  }
}

String _languageLabel(String code) => code == 'en' ? 'English' : code;

String _subscriptionSubtitle(BuildContext context, SubscriptionState state) {
  return state.plan == SubscriptionPlan.plus ? 'Plus active' : 'Free';
}

void _onIncognitoTap(BuildContext context, IncognitoSettings settings) {}

class _TestIncognitoRepository implements IncognitoRepository {
  final _controller = StreamController<IncognitoSettings>.broadcast();
  IncognitoSettings _settings = const IncognitoSettings();

  @override
  Stream<IncognitoSettings> get settingsStream => _controller.stream;

  @override
  IncognitoSettings get currentSettings => _settings;

  @override
  bool get isIncognito => _settings.isActive;

  @override
  Future<IncognitoSettings> disableIncognito() async {
    _settings = const IncognitoSettings(isEnabled: false);
    _controller.add(_settings);
    return _settings;
  }

  @override
  Future<IncognitoSettings> enableIncognito({
    bool hideFromLikedYou = true,
    bool hideLastActive = true,
    bool hideReadReceipts = true,
    bool onlyShowToLiked = false,
    bool isPremium = false,
  }) async {
    _settings = IncognitoSettings(
      isEnabled: true,
      hideFromLikedYou: hideFromLikedYou,
      hideLastActive: hideLastActive,
      hideReadReceipts: hideReadReceipts,
      onlyShowToLiked: onlyShowToLiked,
      expiresAt: isPremium
          ? null
          : DateTime.now().add(const Duration(hours: 1)),
    );
    _controller.add(_settings);
    return _settings;
  }

  @override
  Duration getRemainingTime() => _settings.remainingTime;

  @override
  bool isVisibleTo(String viewerUserId, {bool viewerHasLiked = false}) {
    if (!_settings.isActive) return true;
    if (_settings.onlyShowToLiked && !viewerHasLiked) return false;
    return true;
  }

  @override
  Future<IncognitoSettings> loadSettings() async => _settings;

  @override
  bool shouldShowLastActive() =>
      !_settings.isActive || !_settings.hideLastActive;

  @override
  bool shouldShowReadReceipts() =>
      !_settings.isActive || !_settings.hideReadReceipts;

  @override
  Future<IncognitoSettings> updateSettings({
    bool? hideFromLikedYou,
    bool? hideLastActive,
    bool? hideReadReceipts,
    bool? onlyShowToLiked,
  }) async {
    _settings = _settings.copyWith(
      hideFromLikedYou: hideFromLikedYou,
      hideLastActive: hideLastActive,
      hideReadReceipts: hideReadReceipts,
      onlyShowToLiked: onlyShowToLiked,
    );
    _controller.add(_settings);
    return _settings;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
