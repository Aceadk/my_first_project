import 'package:flutter/material.dart';

/// Animation duration constants for consistent timing across the app.
class DsDurations {
  DsDurations._();

  /// 100ms - Very fast micro-interactions
  static const Duration fastest = Duration(milliseconds: 100);

  /// 150ms - Fast interactions like button presses
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms - Quick transitions
  static const Duration quick = Duration(milliseconds: 200);

  /// 300ms - Standard animations
  static const Duration normal = Duration(milliseconds: 300);

  /// 400ms - Slightly slower for emphasis
  static const Duration medium = Duration(milliseconds: 400);

  /// 500ms - Slower transitions for larger elements
  static const Duration slow = Duration(milliseconds: 500);

  /// 600ms - Entry/exit animations
  static const Duration slower = Duration(milliseconds: 600);

  /// 800ms - Complex multi-step animations
  static const Duration complex = Duration(milliseconds: 800);
}

/// Standard animation curves for consistent motion.
class DsCurves {
  DsCurves._();

  /// Standard easing - use for most animations
  static const Curve standard = Curves.easeInOut;

  /// Deceleration - for elements entering the screen
  static const Curve enter = Curves.easeOut;

  /// Acceleration - for elements leaving the screen
  static const Curve exit = Curves.easeIn;

  /// Emphasized - for important state changes
  static const Curve emphasized = Curves.easeInOutCubic;

  /// Bounce - for playful interactions
  static const Curve bounce = Curves.elasticOut;

  /// Spring - for natural motion
  static const Curve spring = Curves.easeOutBack;
}

/// Fade in animation widget.
class DsFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const DsFadeIn({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
  });

  @override
  State<DsFadeIn> createState() => _DsFadeInState();
}

class _DsFadeInState extends State<DsFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return widget.child;
    }
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// Slide and fade in animation widget.
class DsSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset begin;

  const DsSlideIn({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
    this.begin = const Offset(0, 0.1),
  });

  /// Slide in from the bottom
  const DsSlideIn.fromBottom({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
  }) : begin = const Offset(0, 0.2);

  /// Slide in from the top
  const DsSlideIn.fromTop({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
  }) : begin = const Offset(0, -0.2);

  /// Slide in from the left
  const DsSlideIn.fromLeft({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
  }) : begin = const Offset(-0.2, 0);

  /// Slide in from the right
  const DsSlideIn.fromRight({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.enter,
  }) : begin = const Offset(0.2, 0);

  @override
  State<DsSlideIn> createState() => _DsSlideInState();
}

class _DsSlideInState extends State<DsSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return widget.child;
    }
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Scale animation widget.
class DsScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double begin;

  const DsScaleIn({
    super.key,
    required this.child,
    this.duration = DsDurations.normal,
    this.delay = Duration.zero,
    this.curve = DsCurves.spring,
    this.begin = 0.8,
  });

  @override
  State<DsScaleIn> createState() => _DsScaleInState();
}

class _DsScaleInState extends State<DsScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: widget.begin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: DsCurves.enter,
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return widget.child;
    }
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Staggered list animation helper.
class DsStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final Curve curve;

  const DsStaggeredList({
    super.key,
    required this.children,
    this.itemDuration = DsDurations.normal,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.curve = DsCurves.enter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length, (index) {
        return DsSlideIn(
          duration: itemDuration,
          delay: staggerDelay * index,
          curve: curve,
          child: children[index],
        );
      }),
    );
  }
}

/// Animated press feedback for buttons and tappable elements.
class DsPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const DsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = DsDurations.fast,
  });

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTapDown: reduceMotion ? null : (_) => setState(() => _isPressed = true),
      onTapUp: reduceMotion ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: reduceMotion
          ? null
          : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: reduceMotion
          ? widget.child
          : AnimatedScale(
              scale: _isPressed ? widget.scaleDown : 1.0,
              duration: widget.duration,
              curve: DsCurves.standard,
              child: widget.child,
            ),
    );
  }
}
