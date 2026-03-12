import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/theme.dart';
import 'package:crushhour/core/theme/app_theme_mode.dart';
import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/luxury.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  late AppThemeMode _previewMode;
  bool _previewDirty = false;

  @override
  void initState() {
    super.initState();
    _previewMode = context.read<ThemeCubit>().state;
  }

  ThemeData _themeForPreview(BuildContext context, AppThemeMode mode) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    switch (mode) {
      case AppThemeMode.light:
        return CrushTheme.light();
      case AppThemeMode.dark:
        return CrushTheme.dark();
      case AppThemeMode.darkLuxury:
        return CrushTheme.darkLuxuryClassic();
      case AppThemeMode.darkLuxuryModern:
        return CrushTheme.darkLuxuryModern();
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark
            ? CrushTheme.dark()
            : CrushTheme.light();
    }
  }

  List<Color> _swatchesForMode(BuildContext context, AppThemeMode mode) {
    final theme = _themeForPreview(context, mode);
    return [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.surface,
    ];
  }

  bool _isPremiumLocked(AppThemeMode mode, bool isPlus) {
    return mode.isLuxury && !isPlus;
  }

  void _selectMode(AppThemeMode mode) {
    final current = context.read<ThemeCubit>().state;
    setState(() {
      _previewMode = mode;
      _previewDirty = mode != current;
    });
  }

  void _resetPreview(AppThemeMode current) {
    setState(() {
      _previewMode = current;
      _previewDirty = false;
    });
  }

  Future<void> _applyTheme(AppThemeMode current, bool isPlus) async {
    if (_previewMode == current) return;
    if (_isPremiumLocked(_previewMode, isPlus)) {
      _showLockedSnack();
      return;
    }
    await context.read<ThemeCubit>().setTheme(_previewMode);
    if (!mounted) return;
    setState(() {
      _previewDirty = false;
    });
  }

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).darkLuxuryThemesAreA),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motionScale =
        Theme.of(context).extension<CrushThemeEffects>()?.motionScale ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appearanceThemes),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: BlocListener<ThemeCubit, AppThemeMode>(
              listener: (context, mode) {
                if (!_previewDirty) {
                  setState(() {
                    _previewMode = mode;
                  });
                }
              },
              child: BlocBuilder<ThemeCubit, AppThemeMode>(
                builder: (context, currentMode) {
                  final subState = context.watch<SubscriptionBloc>().state;
                  final isPlus = subState.tier == SubscriptionTier.plus;
                  final previewTheme = _themeForPreview(context, _previewMode);
                  final hasChanges = _previewMode != currentMode;
                  final isLocked = _isPremiumLocked(_previewMode, isPlus);
                  final useModernLuxury =
                      _previewMode == AppThemeMode.darkLuxuryModern;
                  final luxuryGradient = useModernLuxury
                      ? DsLuxuryModernGradients.goldSheen
                      : DsLuxuryGradients.goldSheen;
                  final luxuryTextOnGold = useModernLuxury
                      ? DsLuxuryModernColors.textOnGold
                      : DsLuxuryColors.textOnGold;
                  final luxurySurface = useModernLuxury
                      ? DsLuxuryModernColors.background
                      : DsLuxuryColors.background;
                  final luxuryAccent = useModernLuxury
                      ? DsLuxuryModernColors.goldPrimary
                      : DsLuxuryColors.goldPrimary;

                  return ListView(
                    padding: const EdgeInsets.all(DsSpacing.lg),
                    children: [
                      _ThemePreviewCard(
                        theme: previewTheme,
                        mode: _previewMode,
                        durationMs: (260 * motionScale).round(),
                      ),
                      DsGap.lg,
                      Text(
                        'Choose a theme',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      DsGap.sm,
                      ..._themeOptions().map((option) {
                        final selected = option.mode == _previewMode;
                        final isPremium = option.isPremium;
                        final locked = _isPremiumLocked(option.mode, isPlus);
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: DsSpacing.sm,
                          ),
                          child: _ThemeOptionCard(
                            title: option.title,
                            subtitle: option.subtitle,
                            icon: option.icon,
                            selected: selected,
                            isPremium: isPremium,
                            isLocked: locked,
                            isApplied: option.mode == currentMode,
                            swatches: _swatchesForMode(context, option.mode),
                            onTap: () => _selectMode(option.mode),
                          ),
                        );
                      }),
                      DsGap.lg,
                      Container(
                        padding: const EdgeInsets.all(DsSpacing.md),
                        decoration: BoxDecoration(
                          color: DsGlassColors.surfaceFor(context),
                          borderRadius: BorderRadius.circular(DsRadius.lg),
                          border: Border.all(
                            color: DsGlassColors.borderFor(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync,
                              size: 20,
                              color: DsColors.primary,
                            ),
                            const SizedBox(width: DsSpacing.sm),
                            Expanded(
                              child: Text(
                                'Theme preferences sync to your account and update instantly.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DsGap.lg,
                      if (isLocked) ...[
                        Container(
                          padding: const EdgeInsets.all(DsSpacing.md),
                          decoration: BoxDecoration(
                            gradient: luxuryGradient,
                            borderRadius: BorderRadius.circular(DsRadius.lg),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: luxuryTextOnGold,
                              ),
                              const SizedBox(width: DsSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Upgrade to Plus to unlock Dark Luxury themes.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: luxuryTextOnGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              FilledButton(
                                onPressed: subState.isCheckoutInProgress
                                    ? null
                                    : () => context
                                          .read<SubscriptionBloc>()
                                          .add(SubscriptionCheckoutRequested(SubscriptionTier.plus, BillingPeriod.monthly)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: luxurySurface,
                                  foregroundColor: luxuryAccent,
                                ),
                                child: subState.isCheckoutInProgress
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context).upgrade,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: hasChanges
                                ? () => _applyTheme(currentMode, isPlus)
                                : null,
                            child: Text(hasChanges ? 'Apply theme' : 'Applied'),
                          ),
                        ),
                        if (hasChanges) ...[
                          const SizedBox(height: DsSpacing.sm),
                          TextButton(
                            onPressed: () => _resetPreview(currentMode),
                            child: Text(
                              AppLocalizations.of(context).resetPreview,
                            ),
                          ),
                        ],
                      ],
                      DsGap.xxl,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_ThemeOption> _themeOptions() {
    return [
      const _ThemeOption(
        mode: AppThemeMode.system,
        title: 'System default',
        subtitle: 'Match your device appearance',
        icon: Icons.settings_suggest_outlined,
      ),
      const _ThemeOption(
        mode: AppThemeMode.light,
        title: 'Light',
        subtitle: 'Bright backgrounds with warm surfaces',
        icon: Icons.light_mode_outlined,
      ),
      const _ThemeOption(
        mode: AppThemeMode.dark,
        title: 'Dark',
        subtitle: 'Low-light friendly with soft contrast',
        icon: Icons.dark_mode_outlined,
      ),
      const _ThemeOption(
        mode: AppThemeMode.darkLuxury,
        title: 'Dark Luxury (Royal)',
        subtitle: 'Warm gold, romantic glow, classic elegance',
        icon: Icons.auto_awesome,
        isPremium: true,
      ),
      const _ThemeOption(
        mode: AppThemeMode.darkLuxuryModern,
        title: 'Dark Luxury (Modern)',
        subtitle: 'Cool gold, sleek contrast, VIP lounge',
        icon: Icons.auto_awesome_outlined,
        isPremium: true,
      ),
    ];
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isPremium = false,
  });

  final AppThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPremium;
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.theme,
    required this.mode,
    required this.durationMs,
  });

  final ThemeData theme;
  final AppThemeMode mode;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: theme,
      duration: Duration(milliseconds: durationMs),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final effects = Theme.of(context).extension<CrushThemeEffects>();
          final highlight =
              effects?.primaryGradient ?? DsGradients.primaryHorizontal;
          final previewCopy = switch (mode) {
            AppThemeMode.darkLuxury => 'Royal gold shimmer with romantic glow',
            AppThemeMode.darkLuxuryModern =>
              'Sleek gold accents with modern glow',
            _ => 'Balanced contrast and elevated surfaces',
          };

          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(DsRadius.xl),
              border: Border.all(
                color: scheme.brightness == Brightness.dark
                    ? DsColors.borderDark
                    : DsColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DsRadius.xl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 20, color: scheme.onSurface),
                      const SizedBox(width: DsSpacing.sm),
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite, size: 18, color: scheme.primary),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DsSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(DsSpacing.md),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(DsRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: highlight,
                                borderRadius: BorderRadius.circular(
                                  DsRadius.md,
                                ),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: scheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: DsSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crush Premium',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Smooth, romantic, and safe.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {},
                              child: Text(
                                AppLocalizations.of(context).continueLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: DsSpacing.sm),
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(AppLocalizations.of(context).later),
                          ),
                        ],
                      ),
                      const SizedBox(height: DsSpacing.md),
                      Text(
                        previewCopy,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isPremium,
    required this.isLocked,
    required this.isApplied,
    required this.swatches,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool isPremium;
  final bool isLocked;
  final bool isApplied;
  final List<Color> swatches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? DsColors.primary
        : (isDark ? DsColors.borderDark : DsColors.borderLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(DsSpacing.md),
        decoration: BoxDecoration(
          color: DsGlassColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(DsRadius.lg),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: DsColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DsColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DsRadius.md),
              ),
              child: Icon(icon, color: DsColors.primary),
            ),
            const SizedBox(width: DsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: DsSpacing.xs),
                        _PremiumBadge(isLocked: isLocked),
                      ],
                      if (isApplied) ...[
                        const SizedBox(width: DsSpacing.xs),
                        const _AppliedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? DsColors.textMutedDark
                          : DsColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: swatches
                  .take(3)
                  .map(
                    (color) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsetsDirectional.only(start: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DsColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (selected) ...[
              const SizedBox(width: DsSpacing.sm),
              const Icon(Icons.check_circle, color: DsColors.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.isLocked});

  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLocked
            ? DsColors.warning.withValues(alpha: 0.15)
            : DsColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLocked ? 'Premium' : 'Plus',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isLocked ? DsColors.warning : DsColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppliedBadge extends StatelessWidget {
  const _AppliedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DsColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Applied',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DsColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
