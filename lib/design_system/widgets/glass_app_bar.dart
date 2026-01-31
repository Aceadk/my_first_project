import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/blur.dart';
import '../tokens/colors.dart';

/// A frosted glass app bar that blends with content behind it.
///
/// Features:
/// - Frosted glass effect with BackdropFilter
/// - Extends under status bar with proper safe area
/// - Optional gradient accent line at bottom
/// - Supports leading, title, and actions
///
/// Example:
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: GlassAppBar(
///     title: Text('Title'),
///     actions: [IconButton(...)],
///   ),
///   body: ...,
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.blur = DsBlur.heavy,
    this.backgroundColor,
    this.showBottomBorder = true,
    this.centerTitle = true,
    this.elevation = 0,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = kToolbarHeight,
  });

  /// Title text (ignored if titleWidget is provided).
  final String? title;

  /// Custom title widget (takes precedence over title).
  final Widget? titleWidget;

  /// Leading widget (back button auto-added if null and canPop).
  final Widget? leading;

  /// Action widgets on the right.
  final List<Widget>? actions;

  /// Blur sigma for the glass effect.
  final double blur;

  /// Override background color.
  final Color? backgroundColor;

  /// Whether to show a subtle border at the bottom.
  final bool showBottomBorder;

  /// Whether to center the title.
  final bool centerTitle;

  /// Elevation (typically 0 for glass effect).
  final double elevation;

  /// Whether to show back button automatically.
  final bool automaticallyImplyLeading;

  /// Height of the toolbar portion.
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final theme = Theme.of(context);

    final bgColor = backgroundColor ??
        DsGlassColors.surfaceFor(
          context,
          strength: DsGlassSurfaceStrength.heavy,
        );

    final borderColor = DsGlassColors.borderFor(context);

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    // Determine system UI overlay style
    final systemStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    Widget titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget!;
    } else if (title != null) {
      titleContent = Text(
        title!,
        style: theme.textTheme.titleLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      titleContent = const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemStyle,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: showBottomBorder
                    ? Border(bottom: BorderSide(color: borderColor, width: 0.5))
                    : null,
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: toolbarHeight,
                  child: NavigationToolbar(
                    leading: leading ??
                        (automaticallyImplyLeading && Navigator.canPop(context)
                            ? IconButton(
                                icon: Icon(Icons.arrow_back_ios_new,
                                    color: textColor),
                                onPressed: () => Navigator.pop(context),
                              )
                            : null),
                    middle: titleContent,
                    trailing: actions != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!,
                          )
                        : null,
                    centerMiddle: centerTitle,
                    middleSpacing: NavigationToolbar.kMiddleSpacing,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sliver version of the glass app bar for use with CustomScrollView.
class GlassSliverAppBar extends StatelessWidget {
  const GlassSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.blur = DsBlur.heavy,
    this.backgroundColor,
    this.expandedHeight = 200,
    this.collapsedHeight,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.centerTitle = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final double blur;
  final Color? backgroundColor;
  final double expandedHeight;
  final double? collapsedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final theme = Theme.of(context);

    final bgColor = backgroundColor ??
        DsGlassColors.surfaceFor(
          context,
          strength: DsGlassSurfaceStrength.heavy,
        );

    final textColor =
        isDark ? DsColors.textPrimaryDark : DsColors.textPrimaryLight;

    Widget? titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget;
    } else if (title != null) {
      titleContent = Text(
        title!,
        style: theme.textTheme.titleLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      title: titleContent,
      flexibleSpace: FlexibleSpaceBar(
        background: flexibleSpace != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  flexibleSpace!,
                  // Glass overlay when collapsed
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: Container(color: bgColor),
                      ),
                    ),
                  ),
                ],
              )
            : ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(color: bgColor),
                ),
              ),
      ),
    );
  }
}
