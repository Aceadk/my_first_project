// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/safety_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/adaptive_dialog.dart';
import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';
import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';
import 'package:crushhour/features/subscription/presentation/widgets/promo_code_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = DsBreakpoints.contentMaxWidth(constraints.maxWidth);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: BlocBuilder<ThemeCubit, AppThemeMode>(
                builder: (context, themeMode) {
                  return ListView(
                    children: [
                      // Appearance
                      _SettingsTile(
                        icon: Icons.brightness_6_outlined,
                        iconColor: DsColors.warning,
                        title: context.l10n.settingsAppearance,
                        subtitle: _themeLabel(context, themeMode),
                        onTap: () =>
                            context.push(CrushRoutes.appearanceSettings),
                      ),
                      const Divider(height: 1),
                      // Notifications
                      BlocBuilder<
                        NotificationSettingsCubit,
                        NotificationSettingsState
                      >(
                        builder: (context, notifState) {
                          final enabledCount = [
                            notifState.push,
                            notifState.email,
                            notifState.sound,
                            notifState.vibration,
                          ].where((e) => e).length;
                          return _SettingsTile(
                            icon: Icons.notifications_outlined,
                            iconColor: DsColors.primary,
                            title: context.l10n.settingsNotifications,
                            subtitle: '$enabledCount of 4 enabled',
                            onTap: () =>
                                context.push(CrushRoutes.notificationsSettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Language & Region
                      BlocBuilder<LocaleCubit, LocaleState>(
                        builder: (context, localeState) {
                          return _SettingsTile(
                            icon: Icons.language,
                            iconColor: DsColors.secondary,
                            title: context.l10n.settingsLanguageRegion,
                            subtitle:
                                '${_languageLabel(localeState.languageCode)} - ${localeState.region}',
                            onTap: () =>
                                context.push(CrushRoutes.languageSettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Discovery & Filters
                      BlocBuilder<
                        DiscoverySettingsCubit,
                        DiscoverySettingsState
                      >(
                        builder: (context, discoveryState) {
                          return _SettingsTile(
                            icon: Icons.tune,
                            iconColor: DsColors.warning,
                            title: context.l10n.settingsDiscoveryFilters,
                            subtitle:
                                '${discoveryState.distanceKm.round()} km, ${discoveryState.minAge}-${discoveryState.maxAge} years',
                            onTap: () =>
                                context.push(CrushRoutes.discoverySettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Data & Storage
                      BlocBuilder<StorageSettingsCubit, StorageSettingsState>(
                        builder: (context, storageState) {
                          return _SettingsTile(
                            icon: Icons.storage_outlined,
                            iconColor: DsColors.info,
                            title: context.l10n.settingsDataStorage,
                            subtitle: 'Cache: ${storageState.cacheSizeMb} MB',
                            onTap: () =>
                                context.push(CrushRoutes.storageSettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Account Security
                      Builder(
                        builder: (context) {
                          final emailVerified = context.select<AuthBloc, bool>(
                            (bloc) => bloc.state.user?.isEmailVerified ?? false,
                          );
                          final hasEmail = context.select<AuthBloc, bool>(
                            (bloc) => (bloc.state.user?.email ?? '').isNotEmpty,
                          );
                          String subtitle;
                          if (!hasEmail) {
                            subtitle = 'No email added';
                          } else if (emailVerified) {
                            subtitle = 'Email verified';
                          } else {
                            subtitle = 'Email not verified';
                          }
                          return _SettingsTile(
                            icon: Icons.shield_outlined,
                            iconColor: DsColors.success,
                            title: context.l10n.settingsAccountSecurity,
                            subtitle: subtitle,
                            onTap: () =>
                                context.push(CrushRoutes.securitySettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // ID Verification
                      Builder(
                        builder: (context) {
                          final isIdVerified = context.select<AuthBloc, bool>(
                            (bloc) => bloc.state.user?.isIdVerified ?? false,
                          );
                          return _SettingsTile(
                            icon: isIdVerified
                                ? Icons.verified_rounded
                                : Icons.verified_outlined,
                            iconColor: isIdVerified
                                ? DsColors.success
                                : DsColors.info,
                            title: 'ID Verification',
                            subtitle: isIdVerified
                                ? 'Verified - Badge active'
                                : 'Verify to unlock 50% more swipes',
                            onTap: isIdVerified
                                ? null
                                : () => context.push(
                                    CrushRoutes.idVerificationSettings,
                                  ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Privacy Settings
                      _SettingsTile(
                        icon: Icons.visibility_outlined,
                        iconColor: DsColors.secondary,
                        title: context.l10n.settingsPrivacy,
                        subtitle: context.l10n.settingsPrivacySubtitle,
                        onTap: () => context.push(CrushRoutes.privacySettings),
                      ),
                      const Divider(height: 1),
                      // Chat Settings
                      _SettingsTile(
                        icon: Icons.chat_bubble_outline,
                        iconColor: DsColors.accent,
                        title: 'Chat Settings',
                        subtitle: 'Message retention & auto-delete',
                        onTap: () => context.push(CrushRoutes.chatSettings),
                      ),
                      const Divider(height: 1),
                      // Call History
                      _SettingsTile(
                        icon: Icons.call_outlined,
                        iconColor: DsColors.info,
                        title: 'Call History',
                        subtitle: 'Recent audio and video calls',
                        onTap: () => context.push(CrushRoutes.callHistory),
                      ),
                      const Divider(height: 1),
                      // Subscription
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, subState) {
                          return _SettingsTile(
                            icon: Icons.workspace_premium_outlined,
                            iconColor: DsColors.primary,
                            title: context.l10n.settingsSubscription,
                            subtitle: _subscriptionSubtitle(subState),
                            onTap: () =>
                                context.push(CrushRoutes.subscriptionSettings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Incognito Mode
                      StreamBuilder<IncognitoSettings>(
                        stream: context
                            .read<IncognitoRepository>()
                            .settingsStream,
                        initialData: context
                            .read<IncognitoRepository>()
                            .currentSettings,
                        builder: (context, snapshot) {
                          final settings =
                              snapshot.data ?? const IncognitoSettings();
                          final isActive = settings.isActive;
                          return _SettingsTile(
                            icon: isActive
                                ? Icons.visibility_off
                                : Icons.visibility_off_outlined,
                            iconColor: isActive
                                ? DsColors.primary
                                : DsColors.ink300,
                            title: 'Incognito Mode',
                            subtitle: isActive
                                ? settings.expiresAt != null
                                      ? settings.remainingTimeDisplay
                                      : 'Active (Premium)'
                                : 'Browse profiles privately',
                            onTap: () => _showIncognitoSheet(context, settings),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      // Account Actions
                      _SettingsTile(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: DsColors.secondary,
                        title: context.l10n.settingsAccountActions,
                        subtitle: context.l10n.settingsAccountActionsSubtitle,
                        onTap: () => context.push(CrushRoutes.accountSettings),
                      ),
                      DsGap.lg,
                      // Subscription section
                      BlocConsumer<SubscriptionBloc, SubscriptionState>(
                        listenWhen: (previous, current) =>
                            previous.errorMessage != current.errorMessage,
                        listener: (context, state) {
                          final error = state.errorMessage;
                          if (error != null && error.isNotEmpty) {
                            showErrorSnackBar(context, error);
                          }
                        },
                        builder: (context, subState) {
                          final isPlus = subState.plan == SubscriptionPlan.plus;
                          final loading = subState.isCheckoutInProgress;
                          final statusLabel = subState.statusLabel;
                          final renewal = subState.nextRenewal;
                          final cancelAtPeriodEnd =
                              subState.cancelAtPeriodEnd == true;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: DsColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium,
                                          color: DsColors.primary,
                                        ),
                                      ),
                                      DsGap.mdH,
                                      Text(
                                        context.l10n.settingsSubscription,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  DsGap.md,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPlus
                                          ? DsColors.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : (isDark
                                                ? DsColors.surfaceDark
                                                : DsColors.surfaceLight),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isPlus ? 'Plus Member' : 'Free Plan',
                                      style: TextStyle(
                                        color: isPlus ? DsColors.primary : null,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (statusLabel != null ||
                                      renewal != null) ...[
                                    DsGap.sm,
                                    Text(
                                      [
                                        if (statusLabel != null)
                                          'Status: ${statusLabel.toUpperCase()}',
                                        if (renewal != null)
                                          '${cancelAtPeriodEnd ? 'Access ends' : 'Renews'} on ${formatDate(renewal)}',
                                      ].join(' - '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? DsColors.textMutedDark
                                                : DsColors.textMutedLight,
                                          ),
                                    ),
                                  ],
                                  DsGap.sm,
                                  Text(
                                    isPlus
                                        ? 'Manage billing or renew your Plus plan.'
                                        : 'Upgrade to Plus for unlimited likes, rewinds, and Passport.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? DsColors.textMutedDark
                                              : DsColors.textMutedLight,
                                        ),
                                  ),
                                  if (!isPlus) ...[
                                    DsGap.md,
                                    Container(
                                      padding: DsEdgeInsets.allSm,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            DsColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            DsColors.secondary.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            size: 16,
                                            color: DsColors.primary,
                                          ),
                                          DsGap.smH,
                                          Expanded(
                                            child: Text(
                                              '50% off your first month!',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  DsGap.md,
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: loading
                                          ? null
                                          : () {
                                              if (isPlus) {
                                                context.push(
                                                  CrushRoutes
                                                      .subscriptionSettings,
                                                );
                                                return;
                                              }
                                              context
                                                  .read<SubscriptionBloc>()
                                                  .add(PlusCheckoutRequested());
                                            },
                                      child: loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      DsColors.surfaceLight,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              isPlus
                                                  ? 'Manage subscription'
                                                  : 'Upgrade to Plus',
                                            ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: subState.isRestoring
                                            ? null
                                            : () => context
                                                  .read<SubscriptionBloc>()
                                                  .add(
                                                    SubscriptionRestoreRequested(),
                                                  ),
                                        child: subState.isRestoring
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('Restore'),
                                      ),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          color: DsColors.ink300,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            PromoCodeSheet.show(context),
                                        icon: const Icon(
                                          Icons.card_giftcard,
                                          size: 16,
                                        ),
                                        label: const Text('Promo code'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      DsGap.lg,
                      // Other options
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        iconColor: DsColors.accent,
                        title: 'Safety & Blocking',
                        subtitle: _safetySubtitle(context),
                        onTap: () => context.push(CrushRoutes.safety),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        iconColor: DsColors.info,
                        title: 'Help & Support',
                        subtitle: 'FAQ, contact support, and more',
                        onTap: () => context.push(CrushRoutes.support),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.logout,
                        iconColor: DsColors.ink300,
                        title: context.l10n.authSignOut,
                        subtitle: 'Sign out of your account',
                        onTap: () => context.push(CrushRoutes.logout),
                      ),
                      DsGap.lg,
                      // Legal section
                      Padding(
                        padding: DsEdgeInsets.horizontalLg,
                        child: Text(
                          'Legal',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                        ),
                      ),
                      DsGap.sm,
                      ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(context.l10n.authTermsOfService),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.termsOfService),
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(context.l10n.authPrivacyPolicy),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.privacyPolicy),
                      ),
                      ListTile(
                        leading: const Icon(Icons.people_outlined),
                        title: const Text('Community Guidelines'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(CrushRoutes.communityGuidelines),
                      ),
                      ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: const Text('Safety'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.safetyGuidelines),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(context.l10n.settingsVersion),
                        trailing: Text(
                          _appVersion,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                        ),
                      ),
                      DsGap.lg,
                      // About section
                      Padding(
                        padding: DsEdgeInsets.horizontalLg,
                        child: Text(
                          'About Crush',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                        ),
                      ),
                      DsGap.sm,
                      ListTile(
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('Features'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.productFeatures),
                      ),
                      ListTile(
                        leading: const Icon(Icons.sell_outlined),
                        title: const Text('Pricing'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(CrushRoutes.pricing),
                      ),
                      DsGap.xxl,
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _safetySubtitle(BuildContext context) {
    final blockedCount = context.select<SafetyCubit, int>(
      (cubit) => cubit.state.blockedUsers.length,
    );
    return blockedCount == 0
        ? 'Manage blocked users'
        : '$blockedCount blocked user${blockedCount == 1 ? '' : 's'}';
  }

  String _themeLabel(BuildContext context, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return context.l10n.settingsThemeLight;
      case AppThemeMode.dark:
        return context.l10n.settingsThemeDark;
      case AppThemeMode.system:
        return context.l10n.settingsThemeSystem;
      case AppThemeMode.darkLuxury:
        return 'Dark Luxury (Royal)';
      case AppThemeMode.darkLuxuryModern:
        return 'Dark Luxury (Modern)';
    }
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showIncognitoSheet(BuildContext context, IncognitoSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = settings.isActive;

    AdaptiveBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: DsEdgeInsets.allLg,
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: isActive ? DsColors.primary : DsColors.ink300,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incognito Mode',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            DsGap.xs,
                            Text(
                              'Browse profiles without being seen',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? DsColors.textMutedDark
                                        : DsColors.textMutedLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (isActive) ...[
                  // Show current status
                  Padding(
                    padding: DsEdgeInsets.allLg,
                    child: Container(
                      padding: DsEdgeInsets.allMd,
                      decoration: BoxDecoration(
                        color: DsColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: DsColors.primary,
                          ),
                          DsGap.mdH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Incognito is active',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (settings.expiresAt != null)
                                  Text(
                                    settings.remainingTimeDisplay,
                                    style: TextStyle(
                                      color: isDark
                                          ? DsColors.textMutedDark
                                          : DsColors.textMutedLight,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Feature toggles
                  _IncognitoOptionTile(
                    title: 'Hide from "Liked You"',
                    subtitle: 'Your likes won\'t appear in their list',
                    value: settings.hideFromLikedYou,
                    onChanged: (value) {
                      context.read<IncognitoRepository>().updateSettings(
                        hideFromLikedYou: value,
                      );
                    },
                  ),
                  _IncognitoOptionTile(
                    title: 'Hide last active',
                    subtitle: 'Others won\'t see when you were online',
                    value: settings.hideLastActive,
                    onChanged: (value) {
                      context.read<IncognitoRepository>().updateSettings(
                        hideLastActive: value,
                      );
                    },
                  ),
                  _IncognitoOptionTile(
                    title: 'Hide read receipts',
                    subtitle: 'Messages won\'t show as read',
                    value: settings.hideReadReceipts,
                    onChanged: (value) {
                      context.read<IncognitoRepository>().updateSettings(
                        hideReadReceipts: value,
                      );
                    },
                  ),
                  DsGap.md,
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context
                              .read<IncognitoRepository>()
                              .disableIncognito();
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Turn off Incognito'),
                      ),
                    ),
                  ),
                ] else ...[
                  // Features preview
                  const Padding(
                    padding: DsEdgeInsets.allLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IncognitoFeatureRow(
                          icon: Icons.favorite_outline,
                          text: 'Your likes won\'t appear in "Liked You"',
                        ),
                        DsGap.sm,
                        _IncognitoFeatureRow(
                          icon: Icons.access_time,
                          text: 'Hide your last active status',
                        ),
                        DsGap.sm,
                        _IncognitoFeatureRow(
                          icon: Icons.mark_chat_read,
                          text: 'Hide read receipts in chats',
                        ),
                      ],
                    ),
                  ),
                  DsGap.sm,
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: Container(
                      padding: DsEdgeInsets.allSm,
                      decoration: BoxDecoration(
                        color: DsColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: DsColors.warning,
                          ),
                          DsGap.smH,
                          Expanded(
                            child: Text(
                              'Free users get 1 hour. Upgrade for unlimited.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? DsColors.textMutedDark
                                    : DsColors.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DsGap.lg,
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.read<IncognitoRepository>().enableIncognito();
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Enable Incognito'),
                      ),
                    ),
                  ),
                ],
                DsGap.lg,
              ],
            ),
          ),
        );
      },
    );
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _subscriptionSubtitle(SubscriptionState state) {
    final isPlus = state.plan == SubscriptionPlan.plus;
    if (!isPlus) {
      return 'Free Plan - Upgrade for unlimited likes';
    }
    final renewal = state.nextRenewal;
    if (renewal == null) {
      return 'Plus Member - Active';
    }
    final prefix = state.cancelAtPeriodEnd == true ? 'Ends' : 'Renews';
    return 'Plus Member - $prefix on ${formatDate(renewal)}';
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _IncognitoOptionTile extends StatelessWidget {
  const _IncognitoOptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: DsColors.primary,
    );
  }
}

class _IncognitoFeatureRow extends StatelessWidget {
  const _IncognitoFeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DsColors.primary),
        DsGap.mdH,
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
