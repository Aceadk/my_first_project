import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:crushhour/core/services/haptic_service.dart';
import '../tokens/blur.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Dark translucent background for both modes
    final bgColor = backgroundColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.75)
            : Colors.black.withValues(alpha: 0.65));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.12);

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DsSpacing.xs,
                  vertical: DsSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    return _GlassNavItemWidget(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                    );
                  }),
                ),
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
    // Inactive icons use a muted white for dark translucent background
    final inactiveColor = Colors.white.withValues(alpha: 0.5);

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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? DsSpacing.md : DsSpacing.sm,
            vertical: DsSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? item.gradient : null,
            borderRadius: BorderRadius.circular(DsRadius.round),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: item.gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: 22,
                      color: isSelected ? Colors.white : inactiveColor,
                    ),
                  ),
                  // Badge (dot or count)
                  if (item.badgeCount > 0)
                    Positioned(
                      right: item.showDotOnly ? -2 : -6,
                      top: item.showDotOnly ? -2 : -4,
                      child: _NavBadge(
                        count: item.badgeCount,
                        dotOnly: item.showDotOnly,
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: DsSpacing.xs + 2),
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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
  const _NavBadge({
    required this.count,
    this.dotOnly = false,
  });

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
          color: const Color(0xFFFF3B5C), // Bright red
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B5C).withValues(alpha: 0.5),
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
      constraints: BoxConstraints(
        minWidth: isSmall ? 16 : 20,
        minHeight: 16,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 0 : 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B5C), // Solid red for clean look
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B5C).withValues(alpha: 0.4),
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
