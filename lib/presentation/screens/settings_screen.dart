// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/router.dart';
import '../../logic/theme/theme_cubit.dart';
import '../../logic/notification/notification_settings_cubit.dart';
import '../../logic/discovery/discovery_settings_cubit.dart';
import '../../logic/safety/safety_cubit.dart';
import '../../logic/subscription/subscription_bloc.dart';
import '../../logic/subscription/subscription_event.dart';
import '../../logic/subscription/subscription_state.dart';
import '../../data/models/subscription.dart';
import '../../core/ui/snackbar_utils.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/locale/locale_cubit.dart';
import '../../logic/storage/storage_settings_cubit.dart';
import '../../core/push/push_notifications.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final push = context.read<PushNotifications>();
          final currentUserId =
              context.select<AuthBloc, String?>((bloc) => bloc.state.user?.id);
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
                  final notifier = context.read<NotificationSettingsCubit>();
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
                        onChanged: (value) async {
                          await notifier.togglePush(value);
                          if (!context.mounted) return;
                          if (value) {
                            try {
                              if (currentUserId == null) {
                                showErrorSnackBar(
                                  context,
                                  'Sign in again to enable push notifications.',
                                );
                                return;
                              }
                              await push.registerDeviceToken(currentUserId);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Push notifications enabled.'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              showErrorSnackBar(
                                context,
                                'Could not enable push: $e',
                              );
                            }
                          } else {
                            if (currentUserId != null) {
                              await push.unregisterDeviceToken(currentUserId);
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Push notifications disabled.'),
                              ),
                            );
                          }
                        },
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
                        onChanged: (value) => notifier.toggleVibration(value),
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              BlocConsumer<LocaleCubit, LocaleState>(
                listenWhen: (previous, current) =>
                    previous.errorMessage != current.errorMessage ||
                    (previous.isDetecting && !current.isDetecting),
                listener: (context, localeState) {
                  if (localeState.errorMessage != null &&
                      localeState.errorMessage!.isNotEmpty) {
                    showErrorSnackBar(context, localeState.errorMessage!);
                  } else if (!localeState.isDetecting &&
                      localeState.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Region updated from device location.'),
                      ),
                    );
                  }
                },
                builder: (context, localeState) {
                  final localeCubit = context.read<LocaleCubit>();
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text(
                            'Language & region',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          subtitle: Text(_languageLabel(
                            localeState.languageCode,
                          )),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showLanguageSheet(
                            context,
                            localeState.languageCode,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.public),
                          title: const Text('Region'),
                          subtitle: Text(localeState.region),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showRegionDialog(
                            context,
                            localeState.region,
                            localeCubit,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.my_location),
                          title: const Text('Use device location'),
                          subtitle: const Text(
                            'Detect your region automatically',
                          ),
                          trailing: localeState.isDetecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: localeState.isDetecting
                              ? null
                              : () => localeCubit.detectFromLocation(),
                        ),
                      ],
                    ),
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
                            label: '${discoveryState.distanceKm.round()} km',
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
                        subtitle: const Text('Display how far away you are'),
                        value: discoveryState.showDistance,
                        onChanged: (value) => cubit.setShowDistance(value),
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
              BlocBuilder<StorageSettingsCubit, StorageSettingsState>(
                builder: (context, storageState) {
                  final cubit = context.read<StorageSettingsCubit>();
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text(
                            'Data & storage',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.cloud_download_outlined),
                          title: const Text('Media downloads'),
                          subtitle: Text(
                            storageState.mediaDownloadEnabled
                                ? storageState.mediaDownloadWifiOnly
                                    ? 'Download on Wi‑Fi only'
                                    : 'Download on Wi‑Fi or mobile data'
                                : 'Downloads off',
                          ),
                          trailing: Switch(
                            value: storageState.mediaDownloadEnabled,
                            onChanged: (enabled) {
                              cubit.setMediaDownloadEnabled(enabled);
                            },
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Download only on Wi‑Fi'),
                          subtitle: const Text(
                            'Avoid using mobile data for media',
                          ),
                          value: storageState.mediaDownloadWifiOnly,
                          onChanged: storageState.mediaDownloadEnabled
                              ? (value) => cubit.setMediaDownloadWifiOnly(value)
                              : null,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.storage_outlined),
                          title: const Text('Cache size'),
                          subtitle:
                              Text('${storageState.cacheSizeMb} MB reserved'),
                          trailing: SizedBox(
                            width: 180,
                            child: Slider(
                              min: 50,
                              max: 1000,
                              divisions: 19,
                              value: storageState.cacheSizeMb.toDouble(),
                              label: '${storageState.cacheSizeMb} MB',
                              onChanged: (value) =>
                                  cubit.setCacheSize(value.round()),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cleaning_services_outlined),
                          title: const Text('Clear cache'),
                          subtitle: const Text(
                            'Free up space from temporary files',
                          ),
                          onTap: () async {
                            await cubit.clearCache();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cache cleared.'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
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
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subscription',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPlus
                                ? 'Current plan: Plus'
                                : 'Current plan: Free',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPlus
                                ? 'Manage billing or renew your Plus plan.'
                                : 'Upgrade to Plus for unlimited likes, rewinds, and Passport.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (!isPlus) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Chip(
                                  label: Text(
                                    'Intro offer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Color(0xFFFFE4EC),
                                  visualDensity: VisualDensity.compact,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '50% off your first month when you upgrade today.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () {
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
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
                                      isPlus
                                          ? 'Manage subscription'
                                          : 'Upgrade to Plus',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text(
                        'Account actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: const Text('Change phone number'),
                      subtitle: const Text('Re-verify with a new phone number'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmChangePhone(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.pause_circle_outline),
                      title: const Text('Deactivate account'),
                      subtitle:
                          const Text('Hide your profile until you return'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmDeactivate(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete account',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Permanently remove your data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLegalDialog(
                        context,
                        'Terms of Service',
                        'Full terms will be available soon.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLegalDialog(
                        context,
                        'Privacy Policy',
                        'Privacy details will be available soon.',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('App version'),
                      trailing: const Text(_appVersion),
                      onTap: () => _showLegalDialog(
                        context,
                        'App version',
                        'Version $_appVersion',
                      ),
                    ),
                  ],
                ),
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
              BlocBuilder<SafetyCubit, SafetyState>(
                builder: (context, safetyState) {
                  final blockedCount = safetyState.blockedUsers.length;
                  final subtitle = blockedCount == 0
                      ? 'Manage blocked & muted users'
                      : '$blockedCount blocked user${blockedCount == 1 ? '' : 's'}';
                  return ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Safety & blocking'),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, CrushRoutes.safety);
                    },
                  );
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

  void _showLanguageSheet(BuildContext context, String current) {
    const options = [
      {'code': 'en', 'label': 'English'},
      {'code': 'es', 'label': 'Spanish'},
      {'code': 'fr', 'label': 'French'},
      {'code': 'de', 'label': 'German'},
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final cubit = sheetContext.read<LocaleCubit>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Choose language',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...options.map(
                (option) => RadioListTile<String>(
                  value: option['code']!,
                  groupValue: current,
                  title: Text(option['label']!),
                  onChanged: (value) {
                    if (value != null) {
                      cubit.setLanguage(value);
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegionDialog(
    BuildContext context,
    String currentRegion,
    LocaleCubit cubit,
  ) {
    final controller = TextEditingController(text: currentRegion);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set region'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'City, State/Province, Country',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  cubit.setRegion(value);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showLegalDialog(
    BuildContext context,
    String title,
    String body,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmChangePhone(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change phone number'),
          content: const Text(
            'You will be signed out to verify a new phone number. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthSignedOut());
      Navigator.pushNamedAndRemoveUntil(
        context,
        CrushRoutes.phoneAuth,
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate account'),
          content: const Text(
            'We will hide your profile and pause matches until you sign back in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deactivation request received (placeholder).'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently remove your data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion flow pending backend integration.'),
        ),
      );
    }
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
    return ListTile(
      leading: Radio<ThemeMode>(
        value: mode,
        groupValue: groupValue,
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => onSelected(mode),
    );
  }
}
