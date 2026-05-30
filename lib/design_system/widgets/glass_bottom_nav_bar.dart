import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../theme/theme_extensions.dart';

/// A navigation item for the [GlassBottomNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
    this.badgeCount = 0,
    this.showDotOnly = false,
  });

  /// Icon when not selected.
  final IconData icon;

  /// Icon when selected.
  final IconData activeIcon;

  /// Label text for the item.
  final String label;

  /// Gradient to use when selected.
  final LinearGradient gradient;

  /// Badge count to display. Shows badge if > 0.
  final int badgeCount;

  /// If true, shows a small dot instead of a count badge.
  /// Useful for indicating unseen items without showing exact count.
  final bool showDotOnly;
}

/// A frosted glass bottom navigation bar with animated tab indicators.
///
/// Features:
/// - Frosted glass background with blur effect
/// - Animated pill-style selected indicator
/// - Gradient glow on selected item
/// - Smooth transitions between states
///
/// Example:
/// ```dart
/// GlassBottomNavBar(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: [
///     GlassNavItem(
///       icon: Icons.home_outlined,
///       activeIcon: Icons.home,
///       label: 'Home',
///       gradient: DsGradients.discover,
///     ),
///     // ... more items
///   ],
/// )
/// ```
class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.blur = DsBlur.medium,
    this.backgroundColor,
    this.height = 64,
  });

  /// Currently selected index.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Navigation items to display.
  final List<GlassNavItem> items;

  /// Blur sigma for the glass effect.
  final double blur;

  /// Override background color.
  final Color? backgroundColor;

  /// Height of the nav bar (reduced for compact look).
  final double height;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bgColor =
        backgroundColor ??
        DsGlassColors.surfaceFor(
          context,
          strength: DsGlassSurfaceStrength.heavy,
        );

    final borderColor = DsGlassColors.borderFor(context);

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height + bottomInset,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.6)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DsSpacing.sm,
                DsSpacing.xs,
                DsSpacing.sm,
                DsSpacing.xs + bottomInset,
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: _GlassNavItemWidget(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItemWidget extends StatelessWidget {
  const _GlassNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final effects = Theme.of(context).extension<CrushThemeEffects>();
    final motionScale = effects?.motionScale ?? 1.0;
    final glowColor = effects?.glowColor ?? item.gradient.colors.first;
    final shadowOpacity = effects?.shadowOpacity ?? 0.3;
    final inactiveColor = isDark
        ? DsColors.textMutedDark
        : DsColors.textMutedLight;

    // Build accessibility label
    final semanticLabel = StringBuffer(item.label);
    if (item.badgeCount > 0) {
      semanticLabel.write(', ${item.badgeCount} new');
    }
    if (isSelected) {
      semanticLabel.write(', selected');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      selected: isSelected,
      hint: 'Double tap to navigate to ${item.label}',
      child: GestureDetector(
        onTap: () {
          HapticService.navTap();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Duration(milliseconds: (200 * motionScale).round()),
          curve: Curves.easeOutCubic,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: DsSpacing.xxs),
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xs,
            vertical: DsSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? item.gradient : null,
            borderRadius: BorderRadius.circular(DsRadius.round),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: shadowOpacity),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: (150 * motionScale).round(),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 23 : 22,
                      color: isSelected ? Colors.white : inactiveColor,
                    ),
                  ),
                  if (item.badgeCount > 0)
                    PositionedDirectional(
                      end: item.showDotOnly ? -2 : -6,
                      top: item.showDotOnly ? -2 : -4,
                      child: _NavBadge(
                        count: item.badgeCount,
                        dotOnly: item.showDotOnly,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DsSpacing.xxs),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge widget for nav items (compact style).
/// Supports both dot-only mode (for Chats) and count mode (for Matches).
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count, this.dotOnly = false});

  final int count;
  final bool dotOnly;

  @override
  Widget build(BuildContext context) {
    // Dot-only mode: small red dot without text
    if (dotOnly) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: DsColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DsColors.primary.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    }

    // Count mode: show number (1-9) or "9+" if > 9
    final displayText = count > 9 ? '9+' : count.toString();
    final isSmall = count < 10;

    return Container(
      constraints: BoxConstraints(minWidth: isSmall ? 16 : 20, minHeight: 16),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 0 : 4, vertical: 1),
      decoration: BoxDecoration(
        color: DsColors.primary,
        borderRadius: BorderRadius.circular(DsRadius.chip),
        boxShadow: [
          BoxShadow(
            color: DsColors.primary.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
