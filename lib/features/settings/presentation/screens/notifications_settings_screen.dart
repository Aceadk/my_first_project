import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
              builder: (context, notifState) {
                final notifier = context.read<NotificationSettingsCubit>();
                return ListView(
                  children: [
                    // Header
                    Container(
                      padding: DsEdgeInsets.allLg,
                      margin: DsEdgeInsets.allLg,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DsColors.primary.withValues(alpha: 0.1),
                            DsColors.secondary.withValues(alpha: 0.1),
                          ],
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: DsEdgeInsets.allMd,
                            decoration: BoxDecoration(
                              color: DsColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: DsColors.primary,
                              size: 28,
                            ),
                          ),
                          DsGap.lgH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.settingsNotificationsHeaderTitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                DsGap.xs,
                                Text(
                                  l10n.settingsNotificationsHeaderSubtitle,
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
                    // Push notifications
                    _SettingsTile(
                      icon: Icons.smartphone_outlined,
                      title: l10n.settingsPushNotifications,
                      subtitle: l10n.settingsNotificationsPushSubtitle,
                      trailing: Switch(
                        value: notifState.push,
                        onChanged: (value) async {
                          final enabled = await notifier.togglePush(value);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                enabled
                                    ? l10n.settingsNotificationsPushEnabled
                                    : l10n.settingsNotificationsPushDisabled,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    // Email notifications
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      title: l10n.settingsEmailNotifications,
                      subtitle: l10n.settingsNotificationsEmailSubtitle,
                      trailing: Switch(
                        value: notifState.email,
                        onChanged: (value) async {
                          await notifier.toggleEmail(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    // Sound
                    _SettingsTile(
                      icon: Icons.volume_up_outlined,
                      title: l10n.settingsSound,
                      subtitle: l10n.settingsNotificationsSoundSubtitle,
                      trailing: Switch(
                        value: notifState.sound,
                        onChanged: (value) async {
                          await notifier.toggleSound(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    // Vibration
                    _SettingsTile(
                      icon: Icons.vibration_outlined,
                      title: l10n.settingsVibration,
                      subtitle: l10n.settingsNotificationsVibrationSubtitle,
                      trailing: Switch(
                        value: notifState.vibration,
                        onChanged: (value) async {
                          await notifier.toggleVibration(value);
                        },
                      ),
                    ),
                    DsGap.xxl,
                    // Category filtering section
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Text(
                        l10n.settingsNotificationCategoriesTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Text(
                        l10n.settingsNotificationCategoriesEnabledCount(
                          notifState.enabledCategoryCount,
                          6,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ),
                    DsGap.md,
                    _SettingsTile(
                      icon: Icons.favorite_outline,
                      title: l10n.settingsNotificationCategoryMatchesTitle,
                      subtitle:
                          l10n.settingsNotificationCategoryMatchesSubtitle,
                      trailing: Switch(
                        value: notifState.catMatches,
                        onChanged: (value) async {
                          await notifier.toggleCatMatches(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.chat_bubble_outline,
                      title: l10n.settingsNotificationCategoryMessagesTitle,
                      subtitle:
                          l10n.settingsNotificationCategoryMessagesSubtitle,
                      trailing: Switch(
                        value: notifState.catMessages,
                        onChanged: (value) async {
                          await notifier.toggleCatMessages(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.thumb_up_outlined,
                      title: l10n.settingsNotificationCategoryLikesTitle,
                      subtitle: l10n.settingsNotificationCategoryLikesSubtitle,
                      trailing: Switch(
                        value: notifState.catLikes,
                        onChanged: (value) async {
                          await notifier.toggleCatLikes(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.visibility_outlined,
                      title: l10n.settingsNotificationCategoryProfileViewsTitle,
                      subtitle:
                          l10n.settingsNotificationCategoryProfileViewsSubtitle,
                      trailing: Switch(
                        value: notifState.catProfileViews,
                        onChanged: (value) async {
                          await notifier.toggleCatProfileViews(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.local_offer_outlined,
                      title: l10n.settingsNotificationCategoryPromotionsTitle,
                      subtitle:
                          l10n.settingsNotificationCategoryPromotionsSubtitle,
                      trailing: Switch(
                        value: notifState.catPromotions,
                        onChanged: (value) async {
                          await notifier.toggleCatPromotions(value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: l10n.settingsNotificationCategorySafetyAlertsTitle,
                      subtitle:
                          l10n.settingsNotificationCategorySafetyAlertsSubtitle,
                      trailing: const Switch(
                        value: true,
                        onChanged: null, // Safety alerts are always on
                      ),
                    ),
                    DsGap.xxl,
                    // Quiet hours section
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Text(
                        l10n.settingsNotificationQuietHoursTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ),
                    DsGap.md,
                    _SettingsTile(
                      icon: Icons.nightlight_outlined,
                      title: l10n.settingsNotificationQuietHoursTileTitle,
                      subtitle: notifState.quietHoursEnabled
                          ? '${_formatHour(context, notifState.quietHoursStart)} – ${_formatHour(context, notifState.quietHoursEnd)}'
                          : l10n.settingsNotificationDisabled,
                      trailing: Switch(
                        value: notifState.quietHoursEnabled,
                        onChanged: (value) async {
                          await notifier.toggleQuietHours(value);
                        },
                      ),
                    ),
                    if (notifState.quietHoursEnabled) ...[
                      const Divider(indent: 72),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(l10n.startTime),
                        subtitle: Text(
                          _formatHour(context, notifState.quietHoursStart),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: notifState.quietHoursStart,
                              minute: 0,
                            ),
                          );
                          if (picked != null) {
                            await notifier.setQuietHoursStart(picked.hour);
                          }
                        },
                      ),
                      const Divider(indent: 72),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(l10n.endTime),
                        subtitle: Text(
                          _formatHour(context, notifState.quietHoursEnd),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: notifState.quietHoursEnd,
                              minute: 0,
                            ),
                          );
                          if (picked != null) {
                            await notifier.setQuietHoursEnd(picked.hour);
                          }
                        },
                      ),
                    ],
                    DsGap.xxl,
                    // Info card
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Container(
                        padding: DsEdgeInsets.allMd,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceDark
                              : DsColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? DsColors.borderDark
                                : DsColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: isDark
                                  ? DsColors.textMutedDark
                                  : DsColors.textMutedLight,
                            ),
                            DsGap.mdH,
                            Expanded(
                              child: Text(
                                l10n.settingsNotificationsDeviceSettingsInfo,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _formatHour(BuildContext context, int hour) {
  final locale = MaterialLocalizations.of(context);
  final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
  return locale.formatTimeOfDay(
    TimeOfDay(hour: hour, minute: 0),
    alwaysUse24HourFormat: use24Hour,
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    // Merge label + subtitle + control into one semantics node so a screen
    // reader announces e.g. "Push notifications, …, on, switch" as a single
    // labeled control instead of an unlabeled bare switch (SET-UI-002).
    return MergeSemantics(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
