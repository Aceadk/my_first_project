import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/discovery/data/models/filter_options.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
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

          return BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, subState) {
              final isPlus = subState.plan == SubscriptionPlan.plus;

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

                  // Passport Mode Section (Plus feature)
                  _PassportModeSection(
                    isPlus: isPlus,
                    passportEnabled: discoveryState.passportModeEnabled,
                    passportLocation: discoveryState.passportLocation,
                    onToggle: (enabled) => cubit.setPassportMode(enabled),
                    onSelectLocation: () => _showLocationPicker(context, cubit),
                    onClearLocation: () => cubit.clearPassportLocation(),
                    onUpgrade: () {
                      context.read<SubscriptionBloc>().add(PlusCheckoutRequested());
                    },
                  ),
                  DsGap.md,
                  const Divider(),

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
                                discoveryState.passportModeEnabled
                                    ? 'Global'
                                    : '${discoveryState.distanceKm.round()} km',
                                style: TextStyle(
                                  color: discoveryState.passportModeEnabled
                                      ? Colors.cyan
                                      : DsColors.primary,
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
                          onChanged: discoveryState.passportModeEnabled
                              ? null
                              : (value) => cubit.setDistance(value),
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
                        if (discoveryState.passportModeEnabled) ...[
                          DsGap.sm,
                          Container(
                            padding: DsEdgeInsets.allSm,
                            decoration: BoxDecoration(
                              color: Colors.cyan.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DsRadius.sm),
                              border: Border.all(
                                color: Colors.cyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flight_takeoff,
                                  size: 16,
                                  color: Colors.cyan.shade300,
                                ),
                                DsGap.smH,
                                Expanded(
                                  child: Text(
                                    'Passport mode active — distance limit disabled',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.cyan.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          max: 75,
                          divisions: 57,
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
                              '75',
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
                  DsGap.lg,
                  const Divider(),

                  // Advanced Filters Section (Plus feature)
                  _AdvancedFiltersSection(
                    isPlus: isPlus,
                    state: discoveryState,
                    cubit: cubit,
                    onUpgrade: () {
                      context.read<SubscriptionBloc>().add(PlusCheckoutRequested());
                    },
                  ),
                  DsGap.lg,

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

  void _showLocationPicker(BuildContext context, DiscoverySettingsCubit cubit) {
    // Popular cities for Passport mode
    const popularCities = [
      _CityLocation('New York, USA', 40.7128, -74.0060),
      _CityLocation('Los Angeles, USA', 34.0522, -118.2437),
      _CityLocation('London, UK', 51.5074, -0.1278),
      _CityLocation('Paris, France', 48.8566, 2.3522),
      _CityLocation('Tokyo, Japan', 35.6762, 139.6503),
      _CityLocation('Sydney, Australia', -33.8688, 151.2093),
      _CityLocation('Dubai, UAE', 25.2048, 55.2708),
      _CityLocation('Singapore', 1.3521, 103.8198),
      _CityLocation('Miami, USA', 25.7617, -80.1918),
      _CityLocation('Barcelona, Spain', 41.3851, 2.1734),
      _CityLocation('Berlin, Germany', 52.5200, 13.4050),
      _CityLocation('Amsterdam, Netherlands', 52.3676, 4.9041),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? DsColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DsRadius.xl),
              topRight: Radius.circular(DsRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              DsGap.md,
              // Header
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Row(
                  children: [
                    Container(
                      padding: DsEdgeInsets.allSm,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan.withValues(alpha: 0.2),
                            Colors.blue.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DsRadius.md),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.cyan,
                      ),
                    ),
                    DsGap.mdH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passport to anywhere',
                            style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Select a city to explore',
                            style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              DsGap.md,
              const Divider(),
              // City list
              Expanded(
                child: ListView.builder(
                  padding: DsEdgeInsets.allMd,
                  itemCount: popularCities.length,
                  itemBuilder: (context, index) {
                    final city = popularCities[index];
                    return _CityTile(
                      city: city,
                      onTap: () {
                        cubit.setPassportLocation(
                          locationName: city.name,
                          latitude: city.latitude,
                          longitude: city.longitude,
                        );
                        cubit.setPassportMode(true);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Passport Mode section with glassmorphism design.
class _PassportModeSection extends StatelessWidget {
  const _PassportModeSection({
    required this.isPlus,
    required this.passportEnabled,
    required this.passportLocation,
    required this.onToggle,
    required this.onSelectLocation,
    required this.onClearLocation,
    required this.onUpgrade,
  });

  final bool isPlus;
  final bool passportEnabled;
  final String? passportLocation;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSelectLocation;
  final VoidCallback onClearLocation;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: DsEdgeInsets.horizontalLg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
          child: Container(
            padding: DsEdgeInsets.allLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: passportEnabled
                    ? [
                        Colors.cyan.withValues(alpha: 0.2),
                        Colors.blue.withValues(alpha: 0.15),
                      ]
                    : [
                        (isDark ? DsGlassColors.surfaceDark : DsGlassColors.surfaceLight),
                        (isDark ? DsGlassColors.surfaceMediumDark : DsGlassColors.surfaceMediumLight),
                      ],
              ),
              borderRadius: BorderRadius.circular(DsRadius.lg),
              border: Border.all(
                color: passportEnabled
                    ? Colors.cyan.withValues(alpha: 0.4)
                    : (isDark ? DsGlassColors.borderDark : DsGlassColors.borderLight),
                width: 1.5,
              ),
              boxShadow: passportEnabled
                  ? [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon with animated glow when active
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: DsEdgeInsets.allMd,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: passportEnabled
                              ? [Colors.cyan, Colors.blue]
                              : [
                                  DsColors.secondary.withValues(alpha: 0.2),
                                  DsColors.primary.withValues(alpha: 0.2),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(DsRadius.md),
                        boxShadow: passportEnabled
                            ? [
                                BoxShadow(
                                  color: Colors.cyan.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.flight_takeoff,
                        color: passportEnabled ? Colors.white : DsColors.secondary,
                        size: 24,
                      ),
                    ),
                    DsGap.lgH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Passport Mode',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DsGap.smH,
                              if (!isPlus)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [DsColors.primary, DsColors.secondary],
                                    ),
                                    borderRadius: BorderRadius.circular(DsRadius.round),
                                  ),
                                  child: const Text(
                                    'PLUS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          DsGap.xs,
                          Text(
                            passportEnabled && passportLocation != null
                                ? 'Exploring: $passportLocation'
                                : 'Swipe anywhere in the world',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: passportEnabled
                                  ? Colors.cyan.shade300
                                  : (isDark ? DsColors.textMutedDark : DsColors.textMutedLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPlus)
                      Switch(
                        value: passportEnabled,
                        onChanged: onToggle,
                        activeTrackColor: Colors.cyan.withValues(alpha: 0.5),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.cyan;
                          }
                          return null;
                        }),
                      ),
                  ],
                ),
                if (isPlus) ...[
                  DsGap.lg,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSelectLocation,
                          icon: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: passportEnabled ? Colors.cyan : null,
                          ),
                          label: Text(
                            passportLocation ?? 'Select location',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: passportEnabled ? Colors.cyan : null,
                            side: BorderSide(
                              color: passportEnabled
                                  ? Colors.cyan.withValues(alpha: 0.5)
                                  : (isDark ? DsColors.borderDark : DsColors.borderLight),
                            ),
                          ),
                        ),
                      ),
                      if (passportEnabled && passportLocation != null) ...[
                        DsGap.smH,
                        IconButton(
                          onPressed: onClearLocation,
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Return to my location',
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.cyan,
                            backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  DsGap.lg,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onUpgrade,
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Upgrade to Plus'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DsColors.primary,
                      ),
                    ),
                  ),
                  DsGap.sm,
                  Text(
                    'Unlock Passport mode and explore people from anywhere in the world.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
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

class _CityLocation {
  const _CityLocation(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.onTap,
  });

  final _CityLocation city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(DsRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DsRadius.md),
          child: Padding(
            padding: DsEdgeInsets.allMd,
            child: Row(
              children: [
                Container(
                  padding: DsEdgeInsets.allSm,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DsRadius.sm),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Colors.cyan,
                    size: 20,
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  child: Text(
                    city.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Advanced Filters section with glassmorphism design (Plus feature).
class _AdvancedFiltersSection extends StatelessWidget {
  const _AdvancedFiltersSection({
    required this.isPlus,
    required this.state,
    required this.cubit,
    required this.onUpgrade,
  });

  final bool isPlus;
  final DiscoverySettingsState state;
  final DiscoverySettingsCubit cubit;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with Plus badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Advanced Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DsColors.secondary,
                ),
              ),
              DsGap.smH,
              if (!isPlus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DsColors.primary, DsColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(DsRadius.round),
                  ),
                  child: const Text(
                    'PLUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              if (isPlus && state.hasActiveAdvancedFilters)
                TextButton.icon(
                  onPressed: () => cubit.clearAllAdvancedFilters(),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text('Clear (${state.activeAdvancedFilterCount})'),
                  style: TextButton.styleFrom(
                    foregroundColor: DsColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),

        // If not Plus, show upgrade prompt
        if (!isPlus) ...[
          Padding(
            padding: DsEdgeInsets.horizontalLg,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DsRadius.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: DsBlur.light, sigmaY: DsBlur.light),
                child: Container(
                  padding: DsEdgeInsets.allLg,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DsColors.secondary.withValues(alpha: 0.15),
                        DsColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DsRadius.lg),
                    border: Border.all(
                      color: DsColors.secondary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: DsEdgeInsets.allMd,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [DsColors.secondary, DsColors.primary],
                              ),
                              borderRadius: BorderRadius.circular(DsRadius.md),
                            ),
                            child: const Icon(
                              Icons.filter_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          DsGap.lgH,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unlock Advanced Filters',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DsGap.xs,
                                Text(
                                  'Filter by height, education, lifestyle & more',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      DsGap.lg,
                      // Preview of locked filters
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _LockedFilterChip(label: 'Height', icon: Icons.height),
                          _LockedFilterChip(label: 'Education', icon: Icons.school),
                          _LockedFilterChip(label: 'Goals', icon: Icons.favorite),
                          _LockedFilterChip(label: 'Verified', icon: Icons.verified),
                          _LockedFilterChip(label: 'Lifestyle', icon: Icons.self_improvement),
                          _LockedFilterChip(label: 'Religion', icon: Icons.church),
                        ],
                      ),
                      DsGap.lg,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onUpgrade,
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Upgrade to Plus'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DsColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // Plus user - show actual filters
          // Height Range
          _AdvancedFilterTile(
            icon: Icons.height,
            title: 'Height',
            subtitle: _getHeightSubtitle(),
            onTap: () => _showHeightPicker(context),
          ),

          // Education Level
          _AdvancedFilterTile(
            icon: Icons.school,
            title: 'Education',
            subtitle: _getEducationSubtitle(),
            onTap: () => _showEducationPicker(context),
          ),

          // Relationship Goals
          _AdvancedFilterTile(
            icon: Icons.favorite_outline,
            title: 'Relationship Goals',
            subtitle: _getRelationshipGoalsSubtitle(),
            onTap: () => _showRelationshipGoalsPicker(context),
          ),

          // Verified Only Toggle
          SwitchListTile(
            secondary: Container(
              padding: DsEdgeInsets.allSm,
              decoration: BoxDecoration(
                color: DsColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DsRadius.sm),
              ),
              child: const Icon(
                Icons.verified,
                color: DsColors.secondary,
                size: 20,
              ),
            ),
            title: const Text('Verified profiles only'),
            subtitle: const Text('Only see verified profiles'),
            value: state.verifiedOnly,
            onChanged: (value) => cubit.setVerifiedOnly(value),
          ),

          // Lifestyle section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Lifestyle',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Smoking
          _AdvancedFilterTile(
            icon: Icons.smoking_rooms,
            title: 'Smoking',
            subtitle: _getSmokingSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Smoking Preference',
              options: DiscoveryFilterOptions.smokingOptions,
              selectedId: state.smokingFilter,
              onSelected: (value) => cubit.setSmokingFilter(value),
            ),
          ),

          // Drinking
          _AdvancedFilterTile(
            icon: Icons.local_bar,
            title: 'Drinking',
            subtitle: _getDrinkingSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Drinking Preference',
              options: DiscoveryFilterOptions.drinkingOptions,
              selectedId: state.drinkingFilter,
              onSelected: (value) => cubit.setDrinkingFilter(value),
            ),
          ),

          // Exercise
          _AdvancedFilterTile(
            icon: Icons.fitness_center,
            title: 'Exercise',
            subtitle: _getExerciseSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Exercise Preference',
              options: DiscoveryFilterOptions.exerciseOptions,
              selectedId: state.exerciseFilter,
              onSelected: (value) => cubit.setExerciseFilter(value),
            ),
          ),

          // Family Plans
          _AdvancedFilterTile(
            icon: Icons.child_friendly,
            title: 'Family Plans',
            subtitle: _getFamilyPlansSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Family Plans',
              options: DiscoveryFilterOptions.familyPlansOptions,
              selectedId: state.familyPlansFilter,
              onSelected: (value) => cubit.setFamilyPlansFilter(value),
            ),
          ),

          // More section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'More',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Zodiac
          _AdvancedFilterTile(
            icon: Icons.stars,
            title: 'Zodiac Sign',
            subtitle: _getZodiacSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Zodiac Sign',
              options: DiscoveryFilterOptions.zodiacSigns,
              selectedId: state.zodiacFilter,
              onSelected: (value) => cubit.setZodiacFilter(value),
            ),
          ),

          // Religion
          _AdvancedFilterTile(
            icon: Icons.church,
            title: 'Religion',
            subtitle: _getReligionSubtitle(),
            onTap: () => _showSingleSelectPicker(
              context,
              title: 'Religion',
              options: DiscoveryFilterOptions.religionOptions,
              selectedId: state.religionFilter,
              onSelected: (value) => cubit.setReligionFilter(value),
            ),
          ),
        ],
      ],
    );
  }

  String _getHeightSubtitle() {
    if (state.minHeightCm == null && state.maxHeightCm == null) {
      return 'Any height';
    }
    if (state.minHeightCm != null && state.maxHeightCm != null) {
      return '${HeightUtils.getDisplayHeight(state.minHeightCm!)} - ${HeightUtils.getDisplayHeight(state.maxHeightCm!)}';
    }
    if (state.minHeightCm != null) {
      return 'At least ${HeightUtils.getDisplayHeight(state.minHeightCm!)}';
    }
    return 'Up to ${HeightUtils.getDisplayHeight(state.maxHeightCm!)}';
  }

  String _getEducationSubtitle() {
    if (state.educationLevels.isEmpty) return 'Any education';
    return state.educationLevels
        .map((id) => DiscoveryFilterOptions.getLabelForId(id, DiscoveryFilterOptions.educationLevels))
        .whereType<String>()
        .join(', ');
  }

  String _getRelationshipGoalsSubtitle() {
    if (state.relationshipGoals.isEmpty) return 'Any goals';
    return state.relationshipGoals
        .map((id) => DiscoveryFilterOptions.getLabelForId(id, DiscoveryFilterOptions.relationshipGoals))
        .whereType<String>()
        .join(', ');
  }

  String _getSmokingSubtitle() {
    if (state.smokingFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.smokingFilter!, DiscoveryFilterOptions.smokingOptions) ?? 'Any';
  }

  String _getDrinkingSubtitle() {
    if (state.drinkingFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.drinkingFilter!, DiscoveryFilterOptions.drinkingOptions) ?? 'Any';
  }

  String _getExerciseSubtitle() {
    if (state.exerciseFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.exerciseFilter!, DiscoveryFilterOptions.exerciseOptions) ?? 'Any';
  }

  String _getFamilyPlansSubtitle() {
    if (state.familyPlansFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.familyPlansFilter!, DiscoveryFilterOptions.familyPlansOptions) ?? 'Any';
  }

  String _getZodiacSubtitle() {
    if (state.zodiacFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.zodiacFilter!, DiscoveryFilterOptions.zodiacSigns) ?? 'Any';
  }

  String _getReligionSubtitle() {
    if (state.religionFilter == null) return 'Any';
    return DiscoveryFilterOptions.getLabelForId(state.religionFilter!, DiscoveryFilterOptions.religionOptions) ?? 'Any';
  }

  void _showHeightPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int minHeight = state.minHeightCm ?? HeightUtils.minHeight;
    int maxHeight = state.maxHeightCm ?? HeightUtils.maxHeight;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? DsColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DsRadius.xl),
                  topRight: Radius.circular(DsRadius.xl),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  DsGap.md,
                  // Header
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: Row(
                      children: [
                        Text(
                          'Height Range',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            cubit.clearHeightFilter();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  DsGap.lg,
                  // Height display
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Min',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                              ),
                            ),
                            Text(
                              HeightUtils.getDisplayHeight(minHeight),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DsColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Max',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                              ),
                            ),
                            Text(
                              HeightUtils.getDisplayHeight(maxHeight),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: DsColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DsGap.lg,
                  // Range slider
                  Padding(
                    padding: DsEdgeInsets.horizontalMd,
                    child: RangeSlider(
                      min: HeightUtils.minHeight.toDouble(),
                      max: HeightUtils.maxHeight.toDouble(),
                      divisions: 100,
                      values: RangeValues(minHeight.toDouble(), maxHeight.toDouble()),
                      labels: RangeLabels(
                        HeightUtils.cmToFeetInches(minHeight),
                        HeightUtils.cmToFeetInches(maxHeight),
                      ),
                      onChanged: (range) {
                        setState(() {
                          minHeight = range.start.round();
                          maxHeight = range.end.round();
                        });
                      },
                    ),
                  ),
                  DsGap.lg,
                  // Apply button
                  Padding(
                    padding: DsEdgeInsets.allLg,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          cubit.setHeightRange(minCm: minHeight, maxCm: maxHeight);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEducationPicker(BuildContext context) {
    _showMultiSelectPicker(
      context,
      title: 'Education Level',
      options: DiscoveryFilterOptions.educationLevels,
      selectedIds: state.educationLevels,
      onSelected: (values) => cubit.setEducationLevels(values),
    );
  }

  void _showRelationshipGoalsPicker(BuildContext context) {
    _showMultiSelectPicker(
      context,
      title: 'Relationship Goals',
      options: DiscoveryFilterOptions.relationshipGoals,
      selectedIds: state.relationshipGoals,
      onSelected: (values) => cubit.setRelationshipGoals(values),
    );
  }

  void _showMultiSelectPicker(
    BuildContext context, {
    required String title,
    required List<FilterOption> options,
    required List<String> selectedIds,
    required void Function(List<String>) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> selected = List.from(selectedIds);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? DsColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DsRadius.xl),
                  topRight: Radius.circular(DsRadius.xl),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  DsGap.md,
                  // Header
                  Padding(
                    padding: DsEdgeInsets.horizontalLg,
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() => selected.clear());
                          },
                          child: const Text('Clear'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Options list
                  Expanded(
                    child: ListView.builder(
                      padding: DsEdgeInsets.allMd,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = selected.contains(option.id);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(option.label),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(option.id);
                              } else {
                                selected.remove(option.id);
                              }
                            });
                          },
                          activeColor: DsColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DsRadius.sm),
                          ),
                        );
                      },
                    ),
                  ),
                  // Apply button
                  Padding(
                    padding: DsEdgeInsets.allLg,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          onSelected(selected);
                          Navigator.pop(context);
                        },
                        child: Text('Apply${selected.isNotEmpty ? ' (${selected.length})' : ''}'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSingleSelectPicker(
    BuildContext context, {
    required String title,
    required List<FilterOption> options,
    required String? selectedId,
    required void Function(String?) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: isDark ? DsColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DsRadius.xl),
              topRight: Radius.circular(DsRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              DsGap.md,
              // Header
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (selectedId != null)
                      TextButton(
                        onPressed: () {
                          onSelected(null);
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Options list
              Expanded(
                child: ListView.builder(
                  padding: DsEdgeInsets.allMd,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = selectedId == option.id;
                    return RadioListTile<String>(
                      value: option.id,
                      groupValue: selectedId,
                      title: Text(option.label),
                      onChanged: (value) {
                        onSelected(value);
                        Navigator.pop(context);
                      },
                      activeColor: DsColors.secondary,
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DsRadius.sm),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual advanced filter tile.
class _AdvancedFilterTile extends StatelessWidget {
  const _AdvancedFilterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: DsEdgeInsets.allSm,
        decoration: BoxDecoration(
          color: DsColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DsRadius.sm),
        ),
        child: Icon(
          icon,
          color: DsColors.secondary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Locked filter chip for non-Plus users.
class _LockedFilterChip extends StatelessWidget {
  const _LockedFilterChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  // Allow const construction by making this a const widget

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DsRadius.round),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.lock,
            size: 12,
            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
          ),
        ],
      ),
    );
  }
}
