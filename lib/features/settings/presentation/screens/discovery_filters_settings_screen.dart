import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class DiscoveryFiltersSettingsScreen extends StatelessWidget {
  const DiscoveryFiltersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery & Filters'),
      ),
      body: BlocBuilder<DiscoverySettingsCubit, DiscoverySettingsState>(
        builder: (context, discoveryState) {
          final cubit = context.read<DiscoverySettingsCubit>();
          final ageRange = RangeValues(
            discoveryState.minAge.toDouble(),
            discoveryState.maxAge.toDouble(),
          );

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
                      Colors.orange.withValues(alpha: 0.1),
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
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    DsGap.lgH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Your Match',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DsGap.xs,
                          Text(
                            'Customize who you see in discovery.',
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
              // Distance section
              const _SectionHeader(title: 'Distance'),
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maximum distance',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: DsColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${discoveryState.distanceKm.round()} km',
                            style: const TextStyle(
                              color: DsColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    DsGap.md,
                    Slider(
                      min: 1,
                      max: 200,
                      divisions: 199,
                      value: discoveryState.distanceKm,
                      label: '${discoveryState.distanceKm.round()} km',
                      onChanged: (value) => cubit.setDistance(value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 km',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                        ),
                        Text(
                          '200 km',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DsGap.lg,
              const Divider(),
              // Age section
              const _SectionHeader(title: 'Age Range'),
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Show people aged',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: DsColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${ageRange.start.round()} - ${ageRange.end.round()}',
                            style: const TextStyle(
                              color: DsColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    DsGap.md,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '18',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                        ),
                        Text(
                          '99+',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DsGap.lg,
              const Divider(),
              // Interests section
              const _SectionHeader(title: 'Interests'),
              ListTile(
                leading: const Icon(Icons.interests_outlined),
                title: const Text('My interests'),
                subtitle: Text(_formatInterests(discoveryState.interests)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInterestsDialog(context, discoveryState),
              ),
              DsGap.lg,
              const Divider(),
              // Visibility section
              const _SectionHeader(title: 'Visibility'),
              SwitchListTile(
                secondary: const Icon(Icons.social_distance_outlined),
                title: const Text('Show my distance'),
                subtitle: const Text('Display how far away you are'),
                value: discoveryState.showDistance,
                onChanged: (value) => cubit.setShowDistance(value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Show me in discovery'),
                subtitle: const Text('Turn off to hide your profile'),
                value: discoveryState.visible,
                onChanged: (value) => cubit.setVisible(value),
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
                          'Adjusting these filters affects who sees you too.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
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
    );
  }

  String _formatInterests(List<String> interests) {
    if (interests.isEmpty) return 'Add interests to refine matches';
    return interests.join(', ');
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
              prefixIcon: Icon(Icons.interests_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: DsColors.primary,
        ),
      ),
    );
  }
}
