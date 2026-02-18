import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared page builder used by all route modules.
///
/// Provides a consistent transition animation (fade + slight slide-up)
/// across every screen in the app.
CustomTransitionPage<void> buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.02),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
