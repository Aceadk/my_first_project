import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/blur.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/gradients.dart';
import 'package:crushhour/design_system/tokens/radius.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/features/chat/data/services/ice_breaker_service.dart';

/// Empty chat state with match celebration and ice breaker suggestions.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.onRefresh,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.otherName,
  });

  final VoidCallback onRefresh;
  final List<IceBreakerSuggestion> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsGap.xxl,
          // Match icon with glass effect
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: DsBlur.medium, sigmaY: DsBlur.medium),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DsColors.primary.withValues(alpha: 0.25),
                      DsColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DsGlassColors.borderFor(context),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DsColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.primaryHorizontal.createShader(bounds),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: DsColors.surfaceLight,
                  ),
                ),
              ),
            ),
          ),
          DsGap.lg,
          ShaderMask(
            shaderCallback: (bounds) =>
                DsGradients.primaryHorizontal.createShader(bounds),
            child: Text(
              'You matched with $otherName!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DsColors.surfaceLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          DsGap.sm,
          Text(
            'Break the ice with a great opener',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          DsGap.xl,
          // Ice breaker suggestions
          if (suggestions.isNotEmpty) ...[
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      DsGradients.primaryHorizontal.createShader(bounds),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: DsColors.surfaceLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggested openers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                ),
              ],
            ),
            DsGap.md,
            ...suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                  child: _IceBreakerTile(
                    suggestion: suggestion,
                    onTap: () => onSuggestionTap(suggestion.text),
                  ),
                )),
          ],
          DsGap.lg,
          // Glass refresh button
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? DsColors.surfaceLight.withValues(alpha: 0.05)
                      : DsColors.ink900.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DsGlassColors.borderFor(context),
                    width: 0.5,
                  ),
                ),
                child: TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Show different suggestions'),
                  style: TextButton.styleFrom(
                    foregroundColor: DsColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single ice breaker suggestion tile with glass effect.
class _IceBreakerTile extends StatelessWidget {
  const _IceBreakerTile({
    required this.suggestion,
    required this.onTap,
  });

  final IceBreakerSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = DsGlassColors.surfaceFor(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DsBlur.subtle, sigmaY: DsBlur.subtle),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DsRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(DsSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          baseSurface.withValues(alpha: 0.6),
                          baseSurface.withValues(alpha: 0.4),
                        ]
                      : [
                          baseSurface.withValues(alpha: 0.7),
                          baseSurface.withValues(alpha: 0.5),
                        ],
                ),
                borderRadius: BorderRadius.circular(DsRadius.lg),
                border: Border.all(
                  color: DsGlassColors.borderFor(context),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DsColors.primary.withValues(alpha: 0.15),
                          DsColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DsRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        suggestion.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: DsSpacing.md),
                  Expanded(
                    child: Text(
                      suggestion.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: DsGradients.primaryHorizontal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DsColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: DsColors.surfaceLight,
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
}
