import 'package:flutter/material.dart';
import '../animations/ds_animations.dart';

/// Custom page transitions for smooth navigation.
class DsPageTransitions {
  DsPageTransitions._();

  /// Fade transition - simple fade in/out.
  static PageRouteBuilder<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = DsDurations.normal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: DsCurves.enter),
          child: child,
        );
      },
    );
  }

  /// Slide up transition - for modals, detail screens.
  static PageRouteBuilder<T> slideUp<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = DsDurations.normal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: DsCurves.enter));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: DsCurves.enter),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide right transition - for horizontal navigation.
  static PageRouteBuilder<T> slideRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = DsDurations.normal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: DsCurves.enter));

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  /// Scale transition - for emphasis.
  static PageRouteBuilder<T> scale<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = DsDurations.normal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: DsCurves.spring));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: DsCurves.enter),
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis horizontal transition - for tab switching.
  static PageRouteBuilder<T> sharedAxisHorizontal<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = DsDurations.normal,
    bool reverse = false,
  }) {
    final direction = reverse ? -1.0 : 1.0;
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: Offset(0.3 * direction, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: DsCurves.emphasized),
            );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Profile detail transition - zoom from card.
  static PageRouteBuilder<T> profileDetail<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: DsDurations.medium,
      reverseTransitionDuration: DsDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: DsCurves.emphasized),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Match celebration transition - dramatic reveal.
  static PageRouteBuilder<T> matchReveal<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: DsDurations.slow,
      reverseTransitionDuration: DsDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: DsCurves.bounce));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

/// Extension on Navigator for easy transition usage.
extension DsNavigatorExtension on NavigatorState {
  /// Push with fade transition.
  Future<T?> pushFade<T>(Widget page) {
    return push(DsPageTransitions.fade<T>(page: page));
  }

  /// Push with slide up transition.
  Future<T?> pushSlideUp<T>(Widget page) {
    return push(DsPageTransitions.slideUp<T>(page: page));
  }

  /// Push with scale transition.
  Future<T?> pushScale<T>(Widget page) {
    return push(DsPageTransitions.scale<T>(page: page));
  }

  /// Push profile detail with hero-like transition.
  Future<T?> pushProfileDetail<T>(Widget page) {
    return push(DsPageTransitions.profileDetail<T>(page: page));
  }
}
