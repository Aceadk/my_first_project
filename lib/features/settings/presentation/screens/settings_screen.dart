// ignore_for_file: deprecated_member_use

import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/routing/crush_routes.dart';
import 'package:crushhour/core/routing/premium_cta_helper.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/widgets/adaptive_dialog.dart';
import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';
import 'package:crushhour/features/discovery/domain/repositories/incognito_repository.dart';
import 'package:crushhour/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String settingsLanguageLabelFor(String code) {
  switch (code) {
    case 'ar':
      return 'Arabic';
    case 'bn':
      return 'Bengali';
    case 'de':
      return 'German';
    case 'en':
      return 'English';
    case 'es':
      return 'Spanish';
    case 'fr':
      return 'French';
    case 'hi':
      return 'Hindi';
    case 'id':
      return 'Indonesian';
    case 'ja':
      return 'Japanese';
    case 'ko':
      return 'Korean';
    case 'ne':
      return 'Nepali';
    case 'pt':
      return 'Portuguese';
    case 'ru':
      return 'Russian';
    case 'ta':
      return 'Tamil';
    case 'te':
      return 'Telugu';
    case 'tr':
      return 'Turkish';
    case 'ur':
      return 'Urdu';
    case 'vi':
      return 'Vietnamese';
    case 'yo':
      return 'Yoruba';
    case 'yue':
      return 'Cantonese';
    case 'zh':
      return 'Chinese';
    default:
      return code.toUpperCase();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = DsBreakpoints.contentMaxWidth(constraints.maxWidth);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                children: [
                  SettingsCoreNavigationSection(
                    themeLabelBuilder: _themeLabel,
                    languageLabelBuilder: _languageLabel,
                    subscriptionSubtitleBuilder: _subscriptionSubtitle,
                    onIncognitoTap: _showIncognitoSheet,
                  ),
                  DsGap.lg,
                  const SettingsSubscriptionPanelSection(),
                  DsGap.lg,
                  const SettingsSupportSection(),
                  DsGap.lg,
                  SettingsLinksSection(
                    heading: l10n.settingsLegalSection,
                    links: [
                      SettingsLinkItem(
                        icon: Icons.article_outlined,
                        title: l10n.authTermsOfService,
                        onTap: () => context.push(CrushRoutes.termsOfService),
                      ),
                      SettingsLinkItem(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.authPrivacyPolicy,
                        onTap: () => context.push(CrushRoutes.privacyPolicy),
                      ),
                      SettingsLinkItem(
                        icon: Icons.people_outlined,
                        title: l10n.communityGuidelines,
                        onTap: () =>
                            context.push(CrushRoutes.communityGuidelines),
                      ),
                      SettingsLinkItem(
                        icon: Icons.health_and_safety_outlined,
                        title: l10n.safety,
                        onTap: () => context.push(CrushRoutes.safetyGuidelines),
                      ),
                      SettingsLinkItem(
                        icon: Icons.info_outline,
                        title: l10n.settingsVersion,
                        value: _appVersion,
                      ),
                    ],
                  ),
                  DsGap.lg,
                  SettingsLinksSection(
                    heading: l10n.settingsAboutCrush,
                    links: [
                      SettingsLinkItem(
                        icon: Icons.auto_awesome_outlined,
                        title: l10n.features,
                        onTap: () => context.push(CrushRoutes.productFeatures),
                      ),
                      SettingsLinkItem(
                        icon: Icons.sell_outlined,
                        title: l10n.pricing,
                        onTap: () => PremiumCtaHelper.showPaywall(
                          context,
                          source: 'settings_menu',
                        ),
                      ),
                    ],
                  ),
                  DsGap.xxl,
                ],
              ),
            ),
          );
        },
      ),
    );
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
        return context.l10n.settingsThemeDarkLuxuryRoyal;
      case AppThemeMode.darkLuxuryModern:
        return context.l10n.settingsThemeDarkLuxuryModern;
    }
  }

  String _languageLabel(String code) {
    return settingsLanguageLabelFor(code);
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
                              context.l10n.settingsIncognitoMode,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            DsGap.xs,
                            Text(
                              context.l10n.settingsIncognitoBrowseWithoutSeen,
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
                                Text(
                                  context.l10n.settingsIncognitoIsActive,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                  _IncognitoOptionTile(
                    title: context.l10n.settingsIncognitoHideFromLikedYou,
                    subtitle:
                        context.l10n.settingsIncognitoHideFromLikedYouSubtitle,
                    value: settings.hideFromLikedYou,
                    onChanged: (value) {
                      context.read<IncognitoRepository>().updateSettings(
                        hideFromLikedYou: value,
                      );
                    },
                  ),
                  _IncognitoOptionTile(
                    title: context.l10n.settingsIncognitoHideLastActive,
                    subtitle:
                        context.l10n.settingsIncognitoHideLastActiveSubtitle,
                    value: settings.hideLastActive,
                    onChanged: (value) {
                      context.read<IncognitoRepository>().updateSettings(
                        hideLastActive: value,
                      );
                    },
                  ),
                  _IncognitoOptionTile(
                    title: context.l10n.settingsIncognitoHideReadReceipts,
                    subtitle:
                        context.l10n.settingsIncognitoHideReadReceiptsSubtitle,
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
                        child: Text(context.l10n.turnOffIncognito),
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: DsEdgeInsets.allLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IncognitoFeatureRow(
                          icon: Icons.favorite_outline,
                          text: context
                              .l10n
                              .settingsIncognitoFeatureHideFromLikedYou,
                        ),
                        DsGap.sm,
                        _IncognitoFeatureRow(
                          icon: Icons.access_time,
                          text: context
                              .l10n
                              .settingsIncognitoFeatureHideLastActive,
                        ),
                        DsGap.sm,
                        _IncognitoFeatureRow(
                          icon: Icons.mark_chat_read,
                          text: context
                              .l10n
                              .settingsIncognitoFeatureHideReadReceipts,
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
                              context.l10n.settingsIncognitoFreeTierNotice,
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
                        child: Text(context.l10n.enableIncognito),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _subscriptionSubtitle(BuildContext context, SubscriptionState state) {
    final isPlus = state.tier.hasPremium;
    if (!isPlus) {
      return context.l10n.settingsSubscriptionFreeSummary;
    }
    final renewal = state.nextRenewal;
    if (renewal == null) {
      return context.l10n.settingsSubscriptionPlusActiveSummary;
    }
    if (state.cancelAtPeriodEnd == true) {
      return context.l10n.settingsSubscriptionPlusEndsSummary(
        _formatDate(renewal),
      );
    }
    return context.l10n.settingsSubscriptionPlusRenewsSummary(
      _formatDate(renewal),
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
