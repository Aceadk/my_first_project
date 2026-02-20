import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/services/crash_reporting_service.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';
import 'package:crushhour/design_system/tokens/radius.dart';

/// Installs a global [ErrorWidget.builder] that renders branded fallback UI
/// instead of the default red/grey error screen.
///
/// Call once, early in app startup (e.g. in `main()` before `runApp`).
///
/// When a widget throws during build/layout/paint, Flutter replaces it with
/// the widget returned by [ErrorWidget.builder]. This function replaces that
/// builder with one that shows [ErrorFallbackCard] — a compact branded error
/// view with a retry button.
///
/// For full-page error boundaries with retry + go-home, wrap subtrees with
/// [ErrorBoundary].
void installErrorWidgetBuilder() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log and report the error
    AppLogger.error(
      'ErrorWidget.builder caught rendering error',
      error: details.exception,
      stackTrace: details.stack,
      data: {'library': details.library ?? ''},
    );

    CrashReportingService.instance.recordError(
      details.exception,
      details.stack,
      reason: 'Rendering error: ${details.library ?? "unknown"}',
    );

    // In debug mode, show the default red screen for easy debugging
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }

    // In release mode, show a widget that notifies the nearest ErrorBoundary
    // (if any) and renders a compact branded error card in-place.
    return _ErrorBoundaryNotifier(details: details);
  };
}

/// Widget returned by the custom [ErrorWidget.builder]. On first build it
/// notifies the nearest [ErrorBoundary] (if any) so the boundary can switch
/// to its full-page fallback UI. Falls back to a compact branded card when
/// no boundary is found.
class _ErrorBoundaryNotifier extends StatefulWidget {
  const _ErrorBoundaryNotifier({required this.details});

  final FlutterErrorDetails details;

  @override
  State<_ErrorBoundaryNotifier> createState() => _ErrorBoundaryNotifierState();
}

class _ErrorBoundaryNotifierState extends State<_ErrorBoundaryNotifier> {
  bool _notified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notified) {
      _notified = true;
      final boundary = ErrorBoundary._of(context);
      if (boundary != null) {
        boundary.reportError(widget.details);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ErrorFallbackCard();
  }
}

/// A compact branded error card shown in-place when a widget fails to render.
/// Used as a fallback when no [ErrorBoundary] ancestor is found.
class ErrorFallbackCard extends StatelessWidget {
  const ErrorFallbackCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(DsSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: DsColors.error,
                size: 32,
              ),
              SizedBox(height: DsSpacing.sm),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: DsColors.ink300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that catches rendering errors in its subtree and displays
/// a full-page branded fallback UI with retry and go-home actions.
///
/// How it works:
/// - Wraps [child] in an [_ErrorBoundaryScope] InheritedWidget
/// - Installs a custom [ErrorWidget.builder] that detects the nearest
///   [ErrorBoundary] ancestor and notifies it
/// - When notified, replaces the entire subtree with [_ErrorFallbackView]
///
/// Usage:
/// ```dart
/// // App-level boundary (wraps entire app)
/// ErrorBoundary(
///   screenName: 'App',
///   child: MaterialApp(...),
/// )
///
/// // Feature-level boundary (isolates feature crashes)
/// ErrorBoundary(
///   screenName: 'Chat',
///   child: ChatScreen(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.screenName = 'Unknown',
    this.showHomeButton = true,
    this.onRetry,
  });

  /// The child widget tree to protect.
  final Widget child;

  /// Name of the screen/feature for error reporting context.
  final String screenName;

  /// Whether to show a "Go Home" button in the fallback UI.
  final bool showHomeButton;

  /// Optional custom retry callback. If null, the boundary rebuilds the child.
  final VoidCallback? onRetry;

  /// Look up the nearest [ErrorBoundary] from [context].
  /// Returns null if none is found.
  static _ErrorBoundaryState? _of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ErrorBoundaryScope>();
    return scope?._state;
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorDescription;

  void reportError(FlutterErrorDetails details) {
    AppLogger.error(
      'ErrorBoundary caught error in ${widget.screenName}',
      error: details.exception,
      stackTrace: details.stack,
      data: {'screen': widget.screenName, 'library': details.library ?? ''},
    );

    CrashReportingService.instance.recordError(
      details.exception,
      details.stack,
      reason: 'ErrorBoundary: ${widget.screenName}',
      information: {
        'screen': widget.screenName,
        'library': details.library ?? 'unknown',
      },
    );

    AnalyticsService.instance.logErrorBoundaryTriggered(
      screen: widget.screenName,
    );

    if (mounted) {
      // Schedule state update after current frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorDescription = kDebugMode ? details.exceptionAsString() : null;
          });
        }
      });
    }
  }

  void _retry() {
    AnalyticsService.instance.logErrorRecoveryAction(
      action: 'retry',
      screen: widget.screenName,
      errorType: 'render_error',
    );
    setState(() {
      _hasError = false;
      _errorDescription = null;
    });
    widget.onRetry?.call();
  }

  void _goHome() {
    AnalyticsService.instance.logErrorRecoveryAction(
      action: 'go_home',
      screen: widget.screenName,
      errorType: 'render_error',
    );
    setState(() {
      _hasError = false;
      _errorDescription = null;
    });
    if (mounted) {
      try {
        GoRouter.of(context).go('/home');
      } catch (_) {
        // Router not available (e.g., app-level boundary) — just retry
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorFallbackView(
        screenName: widget.screenName,
        errorDetails: _errorDescription,
        showHomeButton: widget.showHomeButton,
        onRetry: _retry,
        onGoHome: _goHome,
      );
    }

    return _ErrorBoundaryScope(state: this, child: widget.child);
  }
}

/// InheritedWidget that exposes the nearest [_ErrorBoundaryState]
/// so that the custom [ErrorWidget.builder] can notify it.
class _ErrorBoundaryScope extends InheritedWidget {
  const _ErrorBoundaryScope({
    required _ErrorBoundaryState state,
    required super.child,
  }) : _state = state;

  final _ErrorBoundaryState _state;

  @override
  bool updateShouldNotify(_ErrorBoundaryScope oldWidget) =>
      _state != oldWidget._state;
}

/// Branded fallback UI shown when an error is caught.
class _ErrorFallbackView extends StatelessWidget {
  const _ErrorFallbackView({
    required this.screenName,
    required this.onRetry,
    required this.onGoHome,
    this.errorDetails,
    this.showHomeButton = true,
  });

  final String screenName;
  final String? errorDetails;
  final bool showHomeButton;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? DsColors.backgroundDark : DsColors.backgroundLight,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DsSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DsColors.error.withAlpha(26),
                    borderRadius: BorderRadius.circular(DsRadius.xl),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: DsColors.error,
                    size: 40,
                  ),
                ),
                DsGap.xxl,

                // Title
                Text(
                  ErrorMessages.generic.split('.').first,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                DsGap.sm,

                // Subtitle
                Text(
                  'We hit an unexpected issue. Try again or head back to the home screen.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? DsColors.textMutedDark
                        : DsColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Debug details (only in debug mode)
                if (errorDetails != null) ...[
                  DsGap.lg,
                  Container(
                    padding: const EdgeInsets.all(DsSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? DsColors.surfaceElevatedDark
                          : DsColors.ink50,
                      borderRadius: BorderRadius.circular(DsRadius.sm),
                    ),
                    child: Text(
                      errorDetails!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                DsGap.xxxl,

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DsColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: DsSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DsRadius.md),
                      ),
                    ),
                  ),
                ),

                // Go Home button
                if (showHomeButton) ...[
                  DsGap.md,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onGoHome,
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: const Text('Go Home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? DsColors.textPrimaryDark
                            : DsColors.textPrimaryLight,
                        padding: const EdgeInsets.symmetric(
                          vertical: DsSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DsRadius.md),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? DsColors.borderDark
                              : DsColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
