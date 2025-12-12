import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/router.dart';
import '../../logic/theme/theme_cubit.dart';
import '../../logic/notification/notification_settings_cubit.dart';
import '../../logic/discovery/discovery_settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Appearance'),
                subtitle: Text(_themeLabel(themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeSheet(context, themeMode),
              ),
              const Divider(),
              BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
                builder: (context, notifState) {
                  final notifier =
                      context.read<NotificationSettingsCubit>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Push notifications'),
                        subtitle: const Text(
                          'Messages, matches, and app updates',
                        ),
                        value: notifState.push,
                        onChanged: (value) => notifier.togglePush(value),
                      ),
                      SwitchListTile(
                        title: const Text('Email notifications'),
                        subtitle: const Text('Updates sent to your inbox'),
                        value: notifState.email,
                        onChanged: (value) => notifier.toggleEmail(value),
                      ),
                      SwitchListTile(
                        title: const Text('Sound'),
                        subtitle: const Text('Play sounds for alerts'),
                        value: notifState.sound,
                        onChanged: (value) => notifier.toggleSound(value),
                      ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle:
                            const Text('Vibrate on new messages or matches'),
                        value: notifState.vibration,
                        onChanged: (value) =>
                            notifier.toggleVibration(value),
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              BlocBuilder<DiscoverySettingsCubit, DiscoverySettingsState>(
                builder: (context, discoveryState) {
                  final cubit = context.read<DiscoverySettingsCubit>();
                  final ageRange = RangeValues(
                    discoveryState.minAge.toDouble(),
                    discoveryState.maxAge.toDouble(),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Discovery & content filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Max distance'),
                        subtitle: Text(
                            '${discoveryState.distanceKm.round()} km away'),
                        trailing: SizedBox(
                          width: 180,
                          child: Slider(
                            min: 1,
                            max: 200,
                            divisions: 199,
                            value: discoveryState.distanceKm,
                            label:
                                '${discoveryState.distanceKm.round()} km',
                            onChanged: (value) => cubit.setDistance(value),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Age range',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            RangeSlider(
                              min: 18,
                              max: 99,
                              divisions: 81,
                              values: ageRange,
                              labels: RangeLabels(
                                '${ageRange.start.round()}',
                                '${ageRange.end.round()}',
                              ),
                              onChanged: (range) => cubit.setAgeRange(range),
                            ),
                            Text(
                              '${ageRange.start.round()} - ${ageRange.end.round()} years',
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Interests'),
                        subtitle: Text(_formatInterests(
                          discoveryState.interests,
                        )),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showInterestsDialog(context, discoveryState),
                      ),
                      SwitchListTile(
                        title: const Text('Show my distance'),
                        subtitle:
                            const Text('Display how far away you are'),
                        value: discoveryState.showDistance,
                        onChanged: (value) =>
                            cubit.setShowDistance(value),
                      ),
                      SwitchListTile(
                        title: const Text('Show me in discovery'),
                        subtitle: const Text(
                          'Turn off to hide your profile',
                        ),
                        value: discoveryState.visible,
                        onChanged: (value) => cubit.setVisible(value),
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.verified_user),
                title: Text('Account & verification'),
              ),
              const ListTile(
                leading: Icon(Icons.lock),
                title: Text('Privacy'),
              ),
              const ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help & support'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, CrushRoutes.logout);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:

        return 'Use system setting';
    }
  }

  void _showThemeSheet(BuildContext context, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOptionTile(
                title: 'Use system setting',
                subtitle: 'Match your device appearance',
                mode: ThemeMode.system,
                groupValue: current,
                onSelected: (mode) {
                  sheetContext.read<ThemeCubit>().setTheme(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _ThemeOptionTile(
                title: 'Light',
                subtitle: 'Bright backgrounds and dark text',
                mode: ThemeMode.light,
                groupValue: current,
                onSelected: (mode) {
                  sheetContext.read<ThemeCubit>().setTheme(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _ThemeOptionTile(
                title: 'Dark',
                subtitle: 'Dim backgrounds and light text',
                mode: ThemeMode.dark,
                groupValue: current,
                onSelected: (mode) {
                  sheetContext.read<ThemeCubit>().setTheme(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showInterestsDialog(
    BuildContext context,
    DiscoverySettingsState state,
  ) {
    final controller = TextEditingController(
      text: state.interests.join(', '),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cubit = dialogContext.read<DiscoverySettingsCubit>();
        return AlertDialog(
          title: const Text('Edit interests'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add interests separated by commas',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final parts = controller.text.split(',');
                cubit.setInterests(parts);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatInterests(List<String> interests) {
    if (interests.isEmpty) return 'Add interests to refine matches';
    return interests.join(', ');
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.groupValue,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
