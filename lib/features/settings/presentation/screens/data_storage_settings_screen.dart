import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/settings/presentation/bloc/storage_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class DataStorageSettingsScreen extends StatelessWidget {
  const DataStorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocBuilder<StorageSettingsCubit, StorageSettingsState>(
              builder: (context, storageState) {
                final cubit = context.read<StorageSettingsCubit>();

                return ListView(
                  children: [
                    // Header
                    Container(
                      padding: DsEdgeInsets.allLg,
                      margin: DsEdgeInsets.allLg,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DsColors.info.withValues(alpha: 0.1),
                            DsColors.info.withValues(alpha: 0.1),
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
                              color: DsColors.info.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storage_outlined,
                              color: DsColors.info,
                              size: 28,
                            ),
                          ),
                          DsGap.lgH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage Storage',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                DsGap.xs,
                                Text(
                                  'Control how media is downloaded and stored.',
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
                    // Media Downloads section
                    const _SectionHeader(title: 'Media Downloads'),
                    SwitchListTile(
                      secondary: const Icon(Icons.cloud_download_outlined),
                      title: const Text('Auto-download media'),
                      subtitle: Text(
                        storageState.mediaDownloadEnabled
                            ? storageState.mediaDownloadWifiOnly
                                  ? 'Download on Wi-Fi only'
                                  : 'Download on Wi-Fi or mobile data'
                            : 'Downloads disabled',
                      ),
                      value: storageState.mediaDownloadEnabled,
                      onChanged: (enabled) =>
                          cubit.setMediaDownloadEnabled(enabled),
                    ),
                    const Divider(indent: 72),
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_outlined),
                      title: const Text('Wi-Fi only'),
                      subtitle: const Text('Avoid using mobile data for media'),
                      value: storageState.mediaDownloadWifiOnly,
                      onChanged: storageState.mediaDownloadEnabled
                          ? (value) => cubit.setMediaDownloadWifiOnly(value)
                          : null,
                    ),
                    DsGap.lg,
                    const Divider(),
                    // Cache section
                    const _SectionHeader(title: 'Cache'),
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cache size limit',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: DsColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${storageState.cacheSizeMb} MB',
                                  style: const TextStyle(
                                    color: DsColors.info,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          DsGap.md,
                          Slider(
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            value: storageState.cacheSizeMb.toDouble(),
                            label: '${storageState.cacheSizeMb} MB',
                            onChanged: (value) =>
                                cubit.setCacheSize(value.round()),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '50 MB',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? DsColors.textMutedDark
                                          : DsColors.textMutedLight,
                                    ),
                              ),
                              Text(
                                '1 GB',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? DsColors.textMutedDark
                                          : DsColors.textMutedLight,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DsGap.lg,
                    // Clear cache button
                    Padding(
                      padding: DsEdgeInsets.horizontalLg,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await cubit.clearCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache cleared successfully.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Clear cache now'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: isDark
                                      ? DsColors.textMutedDark
                                      : DsColors.textMutedLight,
                                ),
                                DsGap.mdH,
                                Text(
                                  'About cache',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            DsGap.sm,
                            Text(
                              'Cached data helps the app load faster. Clearing it may temporarily slow down loading times.',
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
                    ),
                    DsGap.xl,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: DsColors.info,
        ),
      ),
    );
  }
}
