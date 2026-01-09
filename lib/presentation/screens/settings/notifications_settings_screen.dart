import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/notification/notification_settings_cubit.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing_widgets.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DsGap.xs,
                          Text(
                            'Get notified about matches, messages, and more.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
                    if (!context.mounted) return;
                    // TODO: Connect to your push notification service
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Push notifications enabled.'
                            : 'Push notifications disabled.'),
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
                  onChanged: (value) => notifier.toggleEmail(value),
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
                  onChanged: (value) => notifier.toggleSound(value),
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
                  onChanged: (value) => notifier.toggleVibration(value),
                ),
              ),
              DsGap.xxl,
              // Info card
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Text(
                          'You can also manage notifications in your device settings.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
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
    );
  }
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
