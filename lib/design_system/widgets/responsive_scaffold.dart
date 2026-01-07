import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/breakpoints.dart';

/// A scaffold that adapts its layout based on screen size.
/// On tablets, content is centered with a maximum width.
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;

  /// Maximum width for the body content on mobile (usually unconstrained)
  final double mobileMaxWidth;

  /// Maximum width for the body content on tablet
  final double tabletMaxWidth;

  /// Whether to center content on larger screens
  final bool centerOnLargerScreens;

  /// Custom content padding (defaults to responsive padding)
  final EdgeInsets? contentPadding;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.mobileMaxWidth = double.infinity,
    this.tabletMaxWidth = 720,
    this.centerOnLargerScreens = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = DsBreakpoints.isTablet(width);

          final maxWidth = isTablet ? tabletMaxWidth : mobileMaxWidth;

          final defaultPadding = EdgeInsets.symmetric(
            horizontal: isTablet ? DsSpacing.xxxl : DsSpacing.lg,
            vertical: DsSpacing.lg,
          );

          final padding = contentPadding ?? defaultPadding;

          Widget content = Padding(
            padding: padding,
            child: body,
          );

          if (centerOnLargerScreens && maxWidth != double.infinity) {
            content = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}

/// A wrapper that provides responsive constraints to its child.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double mobileMaxWidth;
  final double tabletMaxWidth;
  final bool center;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobileMaxWidth = double.infinity,
    this.tabletMaxWidth = 720,
    this.center = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = DsBreakpoints.isTablet(width);

        final maxWidth = isTablet ? tabletMaxWidth : mobileMaxWidth;

        Widget content = child;

        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        if (center && maxWidth != double.infinity) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: content,
            ),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        );
      },
    );
  }
}

/// A two-column layout for tablet screens.
/// Shows only the main content on mobile.
class ResponsiveTwoColumn extends StatelessWidget {
  final Widget? sidePanel;
  final Widget mainContent;
  final double sidePanelWidth;
  final bool showSidePanelOnMobile;

  const ResponsiveTwoColumn({
    super.key,
    this.sidePanel,
    required this.mainContent,
    this.sidePanelWidth = 320,
    this.showSidePanelOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = DsBreakpoints.isTablet(constraints.maxWidth);

        if (!isTablet || sidePanel == null) {
          // Mobile: show main content only (or side panel if specified)
          if (showSidePanelOnMobile && sidePanel != null) {
            return sidePanel!;
          }
          return mainContent;
        }

        // Tablet: show two-column layout
        return Row(
          children: [
            SizedBox(
              width: sidePanelWidth,
              child: sidePanel,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: mainContent),
          ],
        );
      },
    );
  }
}

/// A grid that adapts columns based on screen width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.spacing = DsSpacing.lg,
    this.runSpacing = DsSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = DsBreakpoints.isTablet(constraints.maxWidth);
        final columns = isTablet ? tabletColumns : mobileColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            final itemWidth = (constraints.maxWidth -
                    (spacing * (columns - 1))) /
                columns;
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
