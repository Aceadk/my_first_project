import 'package:flutter/material.dart';
import '../tokens/breakpoints.dart';
import '../tokens/spacing.dart';

/// An adaptive layout that changes structure based on screen size.
/// Shows single panel on mobile, two-column on tablet, and
/// three-column on desktop.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.body,
    this.sidePanel,
    this.detailPanel,
    this.showSidePanelOnMobile = false,
    this.sidePanelWidth = 320,
    this.detailPanelWidth = 400,
    this.mobileBreakpoint,
    this.tabletBreakpoint,
  });

  /// Main content body
  final Widget body;

  /// Optional side panel (shown on tablet+ as left panel)
  final Widget? sidePanel;

  /// Optional detail panel (shown on desktop as right panel)
  final Widget? detailPanel;

  /// Whether to show side panel instead of body on mobile
  final bool showSidePanelOnMobile;

  /// Width of side panel on tablet/desktop
  final double sidePanelWidth;

  /// Width of detail panel on desktop
  final double detailPanelWidth;

  /// Custom mobile breakpoint
  final double? mobileBreakpoint;

  /// Custom tablet breakpoint
  final double? tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobileMax = mobileBreakpoint ?? DsBreakpoints.mobileMax;
        final tabletMax = tabletBreakpoint ?? DsBreakpoints.tabletMax;

        // Mobile: single column
        if (width < mobileMax) {
          if (showSidePanelOnMobile && sidePanel != null) {
            return sidePanel!;
          }
          return body;
        }

        // Tablet: two columns
        if (width < tabletMax) {
          if (sidePanel == null) {
            return _CenteredContent(
              maxWidth: 720,
              child: body,
            );
          }
          return Row(
            children: [
              SizedBox(
                width: sidePanelWidth,
                child: sidePanel,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          );
        }

        // Desktop: three columns (or centered if no panels)
        if (sidePanel == null && detailPanel == null) {
          return _CenteredContent(
            maxWidth: 960,
            child: body,
          );
        }

        return Row(
          children: [
            if (sidePanel != null) ...[
              SizedBox(
                width: sidePanelWidth,
                child: sidePanel,
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: body),
            if (detailPanel != null) ...[
              const VerticalDivider(width: 1),
              SizedBox(
                width: detailPanelWidth,
                child: detailPanel,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A centered content wrapper with max width constraint.
class _CenteredContent extends StatelessWidget {
  const _CenteredContent({
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A scaffold that adapts its layout for web/desktop.
/// Provides navigation rail on tablet and navigation drawer on desktop.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.destinations = const [],
    this.floatingActionButton,
    this.appBar,
    this.bottomNavigationBar,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Mobile: bottom navigation
        if (DsBreakpoints.isMobile(width)) {
          return Scaffold(
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar ??
                (destinations.isNotEmpty
                    ? _buildBottomNav(context)
                    : null),
          );
        }

        // Tablet: navigation rail
        if (DsBreakpoints.isTablet(width)) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                if (destinations.isNotEmpty)
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    labelType: NavigationRailLabelType.selected,
                    destinations: destinations
                        .map((d) => NavigationRailDestination(
                              icon: Icon(d.icon),
                              selectedIcon: Icon(d.selectedIcon ?? d.icon),
                              label: Text(d.label),
                            ))
                        .toList(),
                  ),
                if (destinations.isNotEmpty) const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        // Desktop: extended navigation rail or drawer
        return Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              if (destinations.isNotEmpty)
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  extended: true,
                  minExtendedWidth: 200,
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon ?? d.icon),
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
              if (destinations.isNotEmpty) const VerticalDivider(width: 1),
              Expanded(
                child: _CenteredContent(
                  maxWidth: DsBreakpoints.contentMaxDesktop,
                  child: body,
                ),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations
          .map((d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon ?? d.icon),
                label: d.label,
              ))
          .toList(),
    );
  }
}

/// A destination for adaptive navigation.
class AdaptiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A card that adapts its layout for different screen sizes.
class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 1,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = DsBreakpoints.isTablet(constraints.maxWidth);
        final isDesktop = DsBreakpoints.isDesktop(constraints.maxWidth);

        final effectivePadding = padding ??
            EdgeInsets.all(
              isDesktop
                  ? DsSpacing.xxl
                  : isTablet
                      ? DsSpacing.xl
                      : DsSpacing.lg,
            );

        final effectiveMargin = margin ??
            EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? DsSpacing.xxl
                  : isTablet
                      ? DsSpacing.lg
                      : DsSpacing.md,
              vertical: DsSpacing.sm,
            );

        return Padding(
          padding: effectiveMargin,
          child: Card(
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Padding(
              padding: effectivePadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A responsive grid that adapts column count based on screen size.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = DsSpacing.lg,
    this.runSpacing = DsSpacing.lg,
    this.childAspectRatio = 1.0,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = DsBreakpoints.isDesktop(width)
            ? desktopColumns
            : DsBreakpoints.isTablet(width)
                ? tabletColumns
                : mobileColumns;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Extension for responsive values based on context.
extension ResponsiveContext on BuildContext {
  /// Get screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if mobile.
  bool get isMobile => DsBreakpoints.isMobile(screenWidth);

  /// Check if tablet.
  bool get isTablet => DsBreakpoints.isTablet(screenWidth);

  /// Check if desktop.
  bool get isDesktop => DsBreakpoints.isDesktop(screenWidth);

  /// Get responsive padding.
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
        horizontal: isDesktop
            ? DsSpacing.xxxl
            : isTablet
                ? DsSpacing.xxl
                : DsSpacing.lg,
      );

  /// Get responsive value.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }
}
