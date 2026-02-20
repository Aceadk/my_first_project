import 'package:flutter/material.dart';
import '../tokens/breakpoints.dart';
import '../tokens/spacing.dart';

class AuthScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final double desktopMaxWidth;
  final double tabletMaxWidth;
  final bool centerContent;

  const AuthScaffold({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.contentPadding,
    this.desktopMaxWidth = 480,
    this.tabletMaxWidth = 640,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(title: Text(title!), actions: actions)
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = DsBreakpoints.isDesktop(width);
            final isTablet = DsBreakpoints.isTablet(width);
            final maxWidth = isDesktop
                ? desktopMaxWidth
                : isTablet
                ? tabletMaxWidth
                : width;
            final padding =
                contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: DsSpacing.xxl,
                  vertical: DsSpacing.xl,
                );

            Widget content = Padding(padding: padding, child: child);

            if (isDesktop) {
              content = Card(
                child: Padding(padding: padding, child: child),
              );
            }

            final verticalPadding = isDesktop ? DsSpacing.xxxl : DsSpacing.xl;
            final scrollPadding = EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: DsSpacing.xl,
            );

            Widget scrollChild = SizedBox(width: maxWidth, child: content);

            if (centerContent) {
              scrollChild = ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - scrollPadding.vertical)
                      .clamp(0, double.infinity),
                ),
                child: Center(child: scrollChild),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: scrollPadding,
                child: scrollChild,
              ),
            );
          },
        ),
      ),
    );
  }
}
