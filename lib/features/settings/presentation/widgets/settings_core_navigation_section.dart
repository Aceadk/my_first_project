import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';
import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_tile.dart';

typedef SettingsThemeLabelBuilder =
    String Function(BuildContext context, AppThemeMode mode);
typedef SettingsLanguageLabelBuilder = String Function(String code);
typedef SettingsSubscriptionSubtitleBuilder =
    String Function(BuildContext context, SubscriptionState state);
typedef SettingsIncognitoTap =
    void Function(BuildContext context, IncognitoSettings settings);

class SettingsCoreNavigationSection extends StatelessWidget {
  const SettingsCoreNavigationSection({
    super.key,
    required this.themeLabelBuilder,
    required this.languageLabelBuilder,
    required this.subscriptionSubtitleBuilder,
    required this.onIncognitoTap,
  });

  final SettingsThemeLabelBuilder themeLabelBuilder;
  final SettingsLanguageLabelBuilder languageLabelBuilder;
  final SettingsSubscriptionSubtitleBuilder subscriptionSubtitleBuilder;
  final SettingsIncognitoTap onIncognitoTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, themeMode) {
            return SettingsTile(
              icon: Icons.brightness_6_outlined,
              iconColor: DsColors.warning,
              title: l10n.settingsAppearance,
              subtitle: themeLabelBuilder(context, themeMode),
              onTap: () => context.push(CrushRoutes.appearanceSettings),
            );
          },
        ),
        const Divider(height: 1),
        BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
          builder: (context, notifState) {
            final enabledCount = [
              notifState.push,
              notifState.email,
              notifState.sound,
              notifState.vibration,
            ].where((enabled) => enabled).length;
            return SettingsTile(
              icon: Icons.notifications_outlined,
              iconColor: DsColors.primary,
              title: l10n.settingsNotifications,
              subtitle: l10n.settingsNotificationsEnabledCount(enabledCount, 4),
              onTap: () => context.push(CrushRoutes.notificationsSettings),
            );
          },
        ),
        const Divider(height: 1),
        BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return SettingsTile(
              icon: Icons.language,
              iconColor: DsColors.secondary,
              title: l10n.settingsLanguageRegion,
              subtitle: l10n.settingsLanguageRegionSummary(
                languageLabelBuilder(localeState.languageCode),
                localeState.region,
              ),
              onTap: () => context.push(CrushRoutes.languageSettings),
            );
          },
        ),
        const Divider(height: 1),
        BlocBuilder<DiscoverySettingsCubit, DiscoverySettingsState>(
          builder: (context, discoveryState) {
            return SettingsTile(
              icon: Icons.tune,
              iconColor: DsColors.warning,
              title: l10n.settingsDiscoveryFilters,
              subtitle: l10n.settingsDiscoverySummary(
                discoveryState.distanceKm.round(),
                discoveryState.minAge,
                discoveryState.maxAge,
              ),
              onTap: () => context.push(CrushRoutes.discoverySettings),
            );
          },
        ),
        const Divider(height: 1),
        BlocBuilder<StorageSettingsCubit, StorageSettingsState>(
          builder: (context, storageState) {
            return SettingsTile(
              icon: Icons.storage_outlined,
              iconColor: DsColors.info,
              title: l10n.settingsDataStorage,
              subtitle: l10n.settingsCacheSummary(storageState.cacheSizeMb),
              onTap: () => context.push(CrushRoutes.storageSettings),
            );
          },
        ),
        const Divider(height: 1),
        Builder(
          builder: (context) {
            final emailVerified = context.select<AuthBloc, bool>(
              (bloc) => bloc.state.user?.isEmailVerified ?? false,
            );
            final hasEmail = context.select<AuthBloc, bool>(
              (bloc) => (bloc.state.user?.email ?? '').isNotEmpty,
            );
            final subtitle = !hasEmail
                ? l10n.settingsAccountNoEmail
                : emailVerified
                ? l10n.settingsAccountEmailVerified
                : l10n.settingsAccountEmailNotVerified;
            return SettingsTile(
              icon: Icons.shield_outlined,
              iconColor: DsColors.success,
              title: l10n.settingsAccountSecurity,
              subtitle: subtitle,
              onTap: () => context.push(CrushRoutes.securitySettings),
            );
          },
        ),
        const Divider(height: 1),
        Builder(
          builder: (context) {
            final isIdVerified = context.select<AuthBloc, bool>(
              (bloc) => bloc.state.user?.isIdVerified ?? false,
            );
            return SettingsTile(
              icon: isIdVerified
                  ? Icons.verified_rounded
                  : Icons.verified_outlined,
              iconColor: isIdVerified ? DsColors.success : DsColors.info,
              title: l10n.settingsIdVerification,
              subtitle: isIdVerified
                  ? l10n.settingsIdVerificationVerifiedSubtitle
                  : l10n.settingsIdVerificationPromptSubtitle,
              onTap: isIdVerified
                  ? null
                  : () => context.push(CrushRoutes.idVerificationSettings),
            );
          },
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.visibility_outlined,
          iconColor: DsColors.secondary,
          title: l10n.settingsPrivacy,
          subtitle: l10n.settingsPrivacySubtitle,
          onTap: () => context.push(CrushRoutes.privacySettings),
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.chat_bubble_outline,
          iconColor: DsColors.accent,
          title: l10n.chatSettings,
          subtitle: l10n.settingsChatSettingsSubtitle,
          onTap: () => context.push(CrushRoutes.chatSettings),
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.call_outlined,
          iconColor: DsColors.info,
          title: l10n.callHistory,
          subtitle: l10n.settingsCallHistorySubtitle,
          onTap: () => context.push(CrushRoutes.callHistory),
        ),
        const Divider(height: 1),
        BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subState) {
            return SettingsTile(
              icon: Icons.workspace_premium_outlined,
              iconColor: DsColors.primary,
              title: l10n.settingsSubscription,
              subtitle: subscriptionSubtitleBuilder(context, subState),
              onTap: () => context.push(CrushRoutes.subscriptionSettings),
            );
          },
        ),
        const Divider(height: 1),
        StreamBuilder<IncognitoSettings>(
          stream: context.read<IncognitoRepository>().settingsStream,
          initialData: context.read<IncognitoRepository>().currentSettings,
          builder: (context, snapshot) {
            final settings = snapshot.data ?? const IncognitoSettings();
            final isActive = settings.isActive;
            return SettingsTile(
              icon: isActive
                  ? Icons.visibility_off
                  : Icons.visibility_off_outlined,
              iconColor: isActive ? DsColors.primary : DsColors.ink300,
              title: l10n.settingsIncognitoMode,
              subtitle: isActive
                  ? settings.expiresAt != null
                        ? settings.remainingTimeDisplay
                        : l10n.settingsIncognitoActivePremium
                  : l10n.settingsIncognitoBrowsePrivately,
              onTap: () => onIncognitoTap(context, settings),
            );
          },
        ),
        const Divider(height: 1),
        SettingsTile(
          icon: Icons.manage_accounts_outlined,
          iconColor: DsColors.secondary,
          title: l10n.settingsAccountActions,
          subtitle: l10n.settingsAccountActionsSubtitle,
          onTap: () => context.push(CrushRoutes.accountSettings),
        ),
      ],
    );
  }
}
