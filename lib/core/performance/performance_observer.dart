import 'package:flutter/material.dart';
import 'performance_monitor.dart';

/// A navigation observer that automatically tracks screen load times.
///
/// Add this to your Navigator or GoRouter to automatically track
/// how long each screen takes to load.
class PerformanceNavigatorObserver extends NavigatorObserver {
  PerformanceNavigatorObserver({
    this.nameExtractor,
    this.shouldTrack,
  });

  /// Optional function to extract a clean screen name from the route.
  /// If not provided, uses the route's settings name or 'unknown'.
  final String Function(Route<dynamic>? route)? nameExtractor;

  /// Optional function to determine if a route should be tracked.
  /// Returns true by default for all routes.
  final bool Function(Route<dynamic>? route)? shouldTrack;

  final _monitor = PerformanceMonitor.instance;

  String _getScreenName(Route<dynamic>? route) {
    if (nameExtractor != null) {
      return nameExtractor!(route);
    }
    return route?.settings.name ?? 'unknown';
  }

  bool _shouldTrack(Route<dynamic>? route) {
    if (shouldTrack != null) {
      return shouldTrack!(route);
    }
    // Skip dialog routes and modal routes by default
    if (route is PopupRoute) return false;
    return true;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (!_shouldTrack(route)) return;

    final screenName = _getScreenName(route);
    _monitor.startScreenTrace(screenName);

    // Stop the trace after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitor.stopScreenTrace(screenName);
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute == null || !_shouldTrack(newRoute)) return;

    final screenName = _getScreenName(newRoute);
    _monitor.startScreenTrace(screenName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitor.stopScreenTrace(screenName);
    });
  }
}

/// A widget that tracks its build and render time.
///
/// Wrap important screens with this to automatically track their
/// time to first meaningful paint.
class PerformanceTrackedWidget extends StatefulWidget {
  const PerformanceTrackedWidget({
    super.key,
    required this.traceName,
    required this.child,
    this.trackMemory = false,
  });

  /// Name for the performance trace.
  final String traceName;

  /// The child widget to track.
  final Widget child;

  /// Whether to also log memory usage when the widget is built.
  final bool trackMemory;

  @override
  State<PerformanceTrackedWidget> createState() =>
      _PerformanceTrackedWidgetState();
}

class _PerformanceTrackedWidgetState extends State<PerformanceTrackedWidget> {
  final _monitor = PerformanceMonitor.instance;
  bool _hasTracked = false;

  @override
  void initState() {
    super.initState();
    _monitor.startScreenTrace(widget.traceName);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasTracked) {
          _hasTracked = true;
          _monitor.stopScreenTrace(widget.traceName);

          if (widget.trackMemory) {
            _monitor.logMemorySnapshot('after_${widget.traceName}');
          }
        }
      });
    }

    return widget.child;
  }
}

/// A widget that tracks the time for async data to load.
///
/// Use this to wrap content that depends on async data loading.
class PerformanceTrackedLoader extends StatefulWidget {
  const PerformanceTrackedLoader({
    super.key,
    required this.traceName,
    required this.isLoading,
    required this.child,
  });

  final String traceName;
  final bool isLoading;
  final Widget child;

  @override
  State<PerformanceTrackedLoader> createState() =>
      _PerformanceTrackedLoaderState();
}

class _PerformanceTrackedLoaderState extends State<PerformanceTrackedLoader> {
  final _monitor = PerformanceMonitor.instance;
  bool _isTracking = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      _startTracking();
    }
  }

  @override
  void didUpdateWidget(PerformanceTrackedLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Started loading
    if (widget.isLoading && !oldWidget.isLoading && !_isTracking) {
      _startTracking();
    }

    // Finished loading
    if (!widget.isLoading && oldWidget.isLoading && _isTracking) {
      _stopTracking();
    }
  }

  void _startTracking() {
    if (_hasCompleted) return; // Only track once
    _isTracking = true;
    _monitor.startTrace('load_${widget.traceName}');
  }

  void _stopTracking() {
    if (!_isTracking) return;
    _isTracking = false;
    _hasCompleted = true;
    _monitor.stopTrace('load_${widget.traceName}');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
