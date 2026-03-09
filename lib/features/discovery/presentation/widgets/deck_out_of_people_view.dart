import 'package:crushhour/core/extensions/localization_extension.dart';
import 'package:crushhour/core/router.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_settings_cubit.dart';
import 'package:crushhour/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:crushhour/features/discovery/presentation/widgets/empty_deck_animations.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/presentation/widgets/upsell_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DeckOutOfPeopleView extends StatelessWidget {
  const DeckOutOfPeopleView({
    super.key,
    required this.discoveryState,
    required this.isPlus,
    this.locationLabel,
    this.onRefresh,
    required this.onShowPassportUpsell,
  });

  final DiscoveryState discoveryState;
  final bool isPlus;
  final String? locationLabel;
  final VoidCallback? onRefresh;
  final VoidCallback onShowPassportUpsell;

  @override
  Widget build(BuildContext context) {
    final localDeckExhausted = discoveryState.localDeckExhausted;
    final passportModeActive = discoveryState.passportModeActive;
    final currentDistanceKm = discoveryState.currentDistanceLimitKm;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    String subtitle;
    IconData icon;
    Color? iconColor;

    if (passportModeActive) {
      title = 'No one in this city yet';
      subtitle = 'Try exploring a different destination or check back later.';
      icon = Icons.flight_takeoff;
      iconColor = DsColors.info;
    } else if (localDeckExhausted) {
      title = 'Explored far and wide';
      subtitle =
          'You\'ve seen everyone up to ${currentDistanceKm.round()} km away.\n'
          'Try Passport mode to explore globally!';
      icon = Icons.explore;
      iconColor = DsColors.secondary;
    } else {
      title = context.l10n.discoveryAllCaughtUp;
      subtitle = context.l10n.discoveryNoMorePeople;
      icon = Icons.people_outline;
      iconColor = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PulsingIconContainer(
                    icon: icon,
                    iconSize: 56,
                    iconColor:
                        iconColor ??
                        (isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.7)
                            : DsColors.ink900.withValues(alpha: 0.54)),
                  ),
                  DsGap.lg,
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DsGap.sm,
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                  if (locationLabel != null) ...[
                    DsGap.md,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DsColors.surfaceLight.withValues(alpha: 0.1)
                            : DsColors.ink900.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: isDark
                                ? DsColors.textMutedDark
                                : DsColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            passportModeActive
                                ? locationLabel!
                                : '$locationLabel • ${currentDistanceKm.round()} km',
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
                  DsGap.xxl,
                  BlocBuilder<DiscoverySettingsCubit, DiscoverySettingsState>(
                    builder: (context, filterState) {
                      final activeCount = filterState.activeAdvancedFilterCount;
                      return FilledButton.icon(
                        icon: activeCount > 0
                            ? Badge(
                                label: Text('$activeCount'),
                                backgroundColor: DsColors.secondary,
                                child: const Icon(Icons.tune, size: 18),
                              )
                            : const Icon(Icons.tune, size: 18),
                        onPressed: () =>
                            context.push(CrushRoutes.discoverySettings),
                        label: Text(
                          activeCount > 0 ? 'Filters active' : 'Adjust filters',
                        ),
                      );
                    },
                  ),
                  DsGap.md,
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context).refreshDeck),
                    onPressed: onRefresh,
                  ),
                  if (!passportModeActive) ...[
                    DsGap.md,
                    AnimatedPassportButton(
                      onPressed: isPlus
                          ? () => context.push(CrushRoutes.discoverySettings)
                          : onShowPassportUpsell,
                      label: isPlus
                          ? 'Enable Passport mode'
                          : 'Try Passport with Plus',
                      isPlus: isPlus,
                    ),
                  ],
                  if (!isPlus) ...[
                    DsGap.lg,
                    const UpgradeNudgeCard(
                      title: 'Unlock Passport Mode',
                      subtitle:
                          'Go global with Passport and explore people from anywhere.',
                      bullets: [
                        'Passport to any city',
                        'Unlimited likes & rewinds',
                        'See who likes you first',
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
