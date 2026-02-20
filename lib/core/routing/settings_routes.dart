import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/settings/presentation/screens/settings_screen.dart'
    as settings;
import 'package:crushhour/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/notifications_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/language_region_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/discovery_filters_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/data_storage_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/account_security_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/account_actions_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/chat_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/support_screen.dart';
import 'package:crushhour/features/settings/presentation/screens/subscription_settings_screen.dart';
import 'package:crushhour/features/settings/presentation/bloc/chat_settings_cubit.dart';
import 'package:crushhour/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/data/models/chat_settings.dart';
import 'crush_routes.dart';
import 'page_builder.dart';

/// Settings-related routes.
List<RouteBase> settingsRoutes() => [
  GoRoute(
    path: CrushRoutes.settings,
    pageBuilder: (context, state) =>
        buildPage(state, const settings.SettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.appearanceSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const AppearanceSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.privacySettings,
    pageBuilder: (context, state) =>
        buildPage(state, const PrivacySettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.notificationsSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const NotificationsSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.languageSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const LanguageRegionSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.discoverySettings,
    pageBuilder: (context, state) =>
        buildPage(state, const DiscoveryFiltersSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.storageSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const DataStorageSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.securitySettings,
    pageBuilder: (context, state) =>
        buildPage(state, const AccountSecuritySettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.accountSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const AccountActionsSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.chatSettings,
    pageBuilder: (context, state) {
      // Get current chat settings from profile and subscription status
      final profileState = context.read<ProfileBloc>().state;
      final subState = context.read<SubscriptionBloc>().state;
      final chatSettings =
          profileState.profile?.chatSettings ?? const ChatSettings();
      final isPremium = subState.plan == SubscriptionPlan.plus;

      return buildPage(
        state,
        BlocProvider(
          create: (_) => ChatSettingsCubit(
            initialSettings: chatSettings,
            isPremium: isPremium,
          ),
          child: const ChatSettingsScreen(),
        ),
      );
    },
  ),
  GoRoute(
    path: CrushRoutes.subscriptionSettings,
    pageBuilder: (context, state) =>
        buildPage(state, const SubscriptionSettingsScreen()),
  ),
  GoRoute(
    path: CrushRoutes.support,
    pageBuilder: (context, state) => buildPage(state, const SupportScreen()),
  ),
];
