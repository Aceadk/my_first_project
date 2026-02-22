import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/features/settings/presentation/bloc/notification_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/core/services/push_notification_service.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsNotifications)),
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
                                  'Stay Connected',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                DsGap.xs,
                                Text(
                                  'Get notified about matches, messages, and more.',
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
                      title: 'Push notifications',
                      subtitle: 'Messages, matches, and app updates',
                      trailing: Switch(
                        value: notifState.push,
                        onChanged: (value) async {
                          await notifier.togglePush(value);
                          // Sync with Firestore so backend respects the setting
                          await PushNotificationService.instance
                              .updateNotificationPreferences(push: value);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Push notifications enabled.'
                                    : 'Push notifications disabled.',
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
                      title: 'Email notifications',
                      subtitle: 'Updates sent to your inbox',
                      trailing: Switch(
                        value: notifState.email,
                        onChanged: (value) async {
                          await notifier.toggleEmail(value);
                          // Sync with Firestore so backend can send/skip emails
                          await PushNotificationService.instance
                              .updateNotificationPreferences(email: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    // Sound
                    _SettingsTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Sound',
                      subtitle: 'Play sounds for alerts',
                      trailing: Switch(
                        value: notifState.sound,
                        onChanged: (value) async {
                          await notifier.toggleSound(value);
                          // Sync with Firestore for backend awareness
                          await PushNotificationService.instance
                              .updateNotificationPreferences(sound: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    // Vibration
                    _SettingsTile(
                      icon: Icons.vibration_outlined,
                      title: 'Vibration',
                      subtitle: 'Vibrate on new messages or matches',
                      trailing: Switch(
                        value: notifState.vibration,
                        onChanged: (value) async {
                          await notifier.toggleVibration(value);
                          // Sync with Firestore for backend awareness
                          await PushNotificationService.instance
                              .updateNotificationPreferences(vibration: value);
                        },
                      ),
                    ),
                    DsGap.xxl,
                    // Category filtering section
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Text(
                        'Notification Categories',
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
                        '${notifState.enabledCategoryCount} of 6 enabled',
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
                      title: 'Matches',
                      subtitle: 'New match notifications',
                      trailing: Switch(
                        value: notifState.catMatches,
                        onChanged: (value) async {
                          await notifier.toggleCatMatches(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences(matches: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Messages',
                      subtitle: 'New message notifications',
                      trailing: Switch(
                        value: notifState.catMessages,
                        onChanged: (value) async {
                          await notifier.toggleCatMessages(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences(messages: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.thumb_up_outlined,
                      title: 'Likes',
                      subtitle: 'When someone likes your profile',
                      trailing: Switch(
                        value: notifState.catLikes,
                        onChanged: (value) async {
                          await notifier.toggleCatLikes(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences(likes: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.visibility_outlined,
                      title: 'Profile Views',
                      subtitle: 'When someone views your profile',
                      trailing: Switch(
                        value: notifState.catProfileViews,
                        onChanged: (value) async {
                          await notifier.toggleCatProfileViews(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences(
                                profileViews: value,
                              );
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    _SettingsTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Promotions',
                      subtitle: 'Special offers and features',
                      trailing: Switch(
                        value: notifState.catPromotions,
                        onChanged: (value) async {
                          await notifier.toggleCatPromotions(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences(promotions: value);
                        },
                      ),
                    ),
                    const Divider(indent: 72),
                    const _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Safety Alerts',
                      subtitle: 'Always on — cannot be disabled',
                      trailing: Switch(
                        value: true,
                        onChanged: null, // Safety alerts are always on
                      ),
                    ),
                    DsGap.xxl,
                    // Quiet hours section
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Text(
                        'Quiet Hours',
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
                      title: 'Quiet hours',
                      subtitle: notifState.quietHoursEnabled
                          ? '${_formatHour(notifState.quietHoursStart)} – ${_formatHour(notifState.quietHoursEnd)}'
                          : 'Disabled',
                      trailing: Switch(
                        value: notifState.quietHoursEnabled,
                        onChanged: (value) async {
                          await notifier.toggleQuietHours(value);
                          await PushNotificationService.instance
                              .updateNotificationPreferences();
                        },
                      ),
                    ),
                    if (notifState.quietHoursEnabled) ...[
                      const Divider(indent: 72),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(AppLocalizations.of(context).startTime),
                        subtitle: Text(_formatHour(notifState.quietHoursStart)),
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
                        title: Text(AppLocalizations.of(context).endTime),
                        subtitle: Text(_formatHour(notifState.quietHoursEnd)),
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
                                'You can also manage notifications in your device settings.',
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

String _formatHour(int hour) {
  if (hour == 0) return '12:00 AM';
  if (hour == 12) return '12:00 PM';
  if (hour < 12) return '$hour:00 AM';
  return '${hour - 12}:00 PM';
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
