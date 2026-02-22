import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/features/discovery/presentation/bloc/boost_cubit.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

/// A button that shows boost status and allows activating a boost.
class BoostButton extends StatelessWidget {
  const BoostButton({super.key});

  static const _boostColor = DsColors.secondary; // Premium plum for boost

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoostCubit, BoostState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildButton(
            context,
            icon: Icons.flash_on,
            label: 'Loading...',
            enabled: false,
            isActive: false,
          );
        }

        if (state.isBoostActive) {
          // Show active boost with countdown
          final remaining = state.boostRemaining;
          final minutes = remaining.inMinutes;
          final seconds = remaining.inSeconds % 60;
          return _buildButton(
            context,
            icon: Icons.flash_on,
            label: '${minutes}m ${seconds}s',
            enabled: false,
            isActive: true,
          );
        }

        if (state.canBoost) {
          return _buildButton(
            context,
            icon: Icons.flash_on,
            label: 'Boost',
            enabled: true,
            isActive: false,
            onTap: () => _showBoostConfirmation(context),
          );
        }

        // On cooldown
        final cooldown = state.cooldownRemaining;
        final hours = cooldown.inHours;
        final minutes = cooldown.inMinutes % 60;
        String cooldownLabel;
        if (hours > 0) {
          cooldownLabel = '${hours}h ${minutes}m';
        } else {
          cooldownLabel = '${minutes}m';
        }

        return _buildButton(
          context,
          icon: Icons.flash_off,
          label: cooldownLabel,
          enabled: false,
          isActive: false,
        );
      },
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    final color = isActive
        ? _boostColor
        : (enabled ? _boostColor : DsColors.ink300);

    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DsSpacing.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.light,
              sigmaY: DsBlur.light,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: DsSpacing.md,
                vertical: DsSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          _boostColor.withValues(alpha: 0.3),
                          _boostColor.withValues(alpha: 0.2),
                        ],
                      )
                    : null,
                color: isActive ? null : DsGlassColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(DsSpacing.md),
                border: Border.all(
                  color: isActive
                      ? _boostColor.withValues(alpha: 0.5)
                      : DsGlassColors.borderFor(context),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _boostColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: DsSpacing.xs),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBoostConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DsBlur.heavy,
              sigmaY: DsBlur.heavy,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DsGlassColors.surfaceFor(
                  context,
                  strength: DsGlassSurfaceStrength.heavy,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DsColors.surfaceLight.withValues(alpha: 0.24)
                              : DsColors.ink900.withValues(alpha: 0.26),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _boostColor.withValues(alpha: 0.2),
                              _boostColor.withValues(alpha: 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          size: 40,
                          color: _boostColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Activate Boost',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get seen by more people! Your profile will be shown to more users for the next 30-60 minutes.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Benefits list
                      _buildBenefit(
                        context,
                        Icons.visibility,
                        'Up to 10x more profile views',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefit(
                        context,
                        Icons.favorite,
                        'More potential matches',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefit(
                        context,
                        Icons.priority_high,
                        'Skip to the front of the line',
                      ),
                      const SizedBox(height: 24),
                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            HapticFeedback.mediumImpact();
                            context.read<BoostCubit>().activateBoost();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _boostColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.flash_on, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).boostNow),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(AppLocalizations.of(context).maybeLater),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefit(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _boostColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _boostColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? DsColors.textPrimaryDark
                  : DsColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact boost indicator for the app bar.
class BoostIndicator extends StatelessWidget {
  const BoostIndicator({super.key});

  static const _boostColor = DsColors.secondary;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoostCubit, BoostState>(
      builder: (context, state) {
        if (!state.isBoostActive) {
          return const SizedBox.shrink();
        }

        final remaining = state.boostRemaining;
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.sm,
            vertical: DsSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _boostColor.withValues(alpha: 0.3),
                _boostColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _boostColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, size: 14, color: _boostColor),
              const SizedBox(width: 4),
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: _boostColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
