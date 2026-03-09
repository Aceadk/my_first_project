import 'dart:async';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/utils/managed_timer_registry.dart';

/// Performance monitoring service for tracking app performance metrics.
///
/// Features:
/// - Cold start time tracking
/// - Memory usage monitoring
/// - Custom trace creation
/// - Screen load time tracking
/// - HTTP request monitoring (automatic via Firebase)
class PerformanceMonitor {
  PerformanceMonitor._();

  static final PerformanceMonitor instance = PerformanceMonitor._();

  FirebasePerformance? _performance;
  Trace Function(String name)? _traceFactory;
  HttpMetric Function(String url, HttpMethod method)? _httpMetricFactory;
  Future<void> Function(bool enabled)? _setCollectionEnabled;
  bool _isInitialized = false;
  DateTime? _appStartTime;
  DateTime? _firstFrameTime;

  // Active traces
  final Map<String, Trace> _activeTraces = {};

  // Memory monitoring
  static const _memoryMonitoringTimerKey = 'performance_memory_monitor';
  final ManagedTimerRegistry _timers = ManagedTimerRegistry();
  int _peakMemoryUsage = 0;

  /// Initialize the performance monitor.
  /// Call this as early as possible in main().
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _performance = FirebasePerformance.instance;
      _traceFactory = _performance?.newTrace;
      _httpMetricFactory = _performance?.newHttpMetric;
      _setCollectionEnabled = _performance?.setPerformanceCollectionEnabled;

      // Enable performance collection (can be toggled for debugging)
      await _setCollectionEnabled?.call(!kDebugMode);

      _isInitialized = true;
      AppLogger.debug('PerformanceMonitor: Initialized');
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to initialize - $e');
    }
  }

  @visibleForTesting
  void configureForTesting({
    required bool initialized,
    Trace Function(String name)? traceFactory,
    HttpMetric Function(String url, HttpMethod method)? httpMetricFactory,
    Future<void> Function(bool enabled)? setCollectionEnabled,
  }) {
    _isInitialized = initialized;
    _performance = null;
    _traceFactory = traceFactory;
    _httpMetricFactory = httpMetricFactory;
    _setCollectionEnabled = setCollectionEnabled;
  }

  /// Record the app start time. Call this at the very beginning of main().
  void recordAppStartTime() {
    _appStartTime = DateTime.now();
    AppLogger.debug('PerformanceMonitor: App start time recorded');
  }

  /// Record when the first frame is rendered.
  /// Call this after the first frame callback.
  void recordFirstFrame() {
    _firstFrameTime = DateTime.now();

    if (_appStartTime != null) {
      final coldStartMs = _firstFrameTime!
          .difference(_appStartTime!)
          .inMilliseconds;

      // Log custom trace for cold start
      _logColdStartTrace(coldStartMs);

      AppLogger.debug('PerformanceMonitor: Cold start time: ${coldStartMs}ms');
    }
  }

  Future<void> _logColdStartTrace(int durationMs) async {
    if (!_isInitialized || _traceFactory == null) return;

    try {
      final trace = _traceFactory!.call('cold_start');
      await trace.start();

      // Add metrics
      trace.setMetric('duration_ms', durationMs);

      // Add attributes
      trace.putAttribute('platform', Platform.operatingSystem);
      trace.putAttribute('debug_mode', kDebugMode.toString());

      await trace.stop();
    } catch (e) {
      AppLogger.error(
        'PerformanceMonitor: Failed to log cold start trace - $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOM TRACES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start a custom trace for measuring specific operations.
  Future<void> startTrace(String name) async {
    if (!_isInitialized || _traceFactory == null) return;

    try {
      if (_activeTraces.containsKey(name)) {
        AppLogger.debug('PerformanceMonitor: Trace "$name" already active');
        return;
      }

      final trace = _traceFactory!.call(name);
      await trace.start();
      _activeTraces[name] = trace;

      AppLogger.debug('PerformanceMonitor: Started trace "$name"');
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to start trace "$name" - $e');
    }
  }

  /// Stop a custom trace.
  Future<void> stopTrace(String name, {Map<String, int>? metrics}) async {
    if (!_isInitialized) return;

    try {
      final trace = _activeTraces.remove(name);
      if (trace == null) {
        AppLogger.debug('PerformanceMonitor: Trace "$name" not found');
        return;
      }

      // Add any custom metrics
      metrics?.forEach((key, value) {
        trace.setMetric(key, value);
      });

      await trace.stop();
      AppLogger.debug('PerformanceMonitor: Stopped trace "$name"');
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to stop trace "$name" - $e');
    }
  }

  /// Increment a metric on an active trace.
  void incrementTraceMetric(String traceName, String metricName, int value) {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.incrementMetric(metricName, value);
    }
  }

  /// Add an attribute to an active trace.
  void setTraceAttribute(String traceName, String key, String value) {
    final trace = _activeTraces[traceName];
    if (trace != null) {
      trace.putAttribute(key, value);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start tracking screen load time.
  Future<void> startScreenTrace(String screenName) async {
    await startTrace('screen_$screenName');
  }

  /// Stop tracking screen load time.
  Future<void> stopScreenTrace(String screenName) async {
    await stopTrace('screen_$screenName');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start monitoring memory usage periodically.
  void startMemoryMonitoring({Duration interval = const Duration(minutes: 5)}) {
    _timers.startPeriodic(_memoryMonitoringTimerKey, interval, (_) {
      _logMemoryUsage();
    });
    AppLogger.debug('PerformanceMonitor: Started memory monitoring');
  }

  /// Stop memory monitoring.
  void stopMemoryMonitoring() {
    _timers.cancel(_memoryMonitoringTimerKey);
    AppLogger.debug('PerformanceMonitor: Stopped memory monitoring');
  }

  Future<void> _logMemoryUsage() async {
    if (!_isInitialized || _traceFactory == null) return;

    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo == null) return;

      // Track peak memory
      if (memoryInfo.usedMemoryMB > _peakMemoryUsage) {
        _peakMemoryUsage = memoryInfo.usedMemoryMB;
      }

      // Log as a trace
      final trace = _traceFactory!.call('memory_snapshot');
      await trace.start();

      trace.setMetric('used_memory_mb', memoryInfo.usedMemoryMB);
      trace.setMetric('peak_memory_mb', _peakMemoryUsage);

      trace.putAttribute('platform', Platform.operatingSystem);

      await trace.stop();

      AppLogger.debug(
        'PerformanceMonitor: Memory usage: ${memoryInfo.usedMemoryMB}MB '
        '(peak: ${_peakMemoryUsage}MB)',
      );
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to log memory usage - $e');
    }
  }

  Future<MemoryInfo?> _getMemoryInfo() async {
    try {
      // Use ProcessInfo for memory stats
      final rss = ProcessInfo.currentRss;
      final maxRss = ProcessInfo.maxRss;

      return MemoryInfo(
        usedMemoryMB: (rss / (1024 * 1024)).round(),
        maxMemoryMB: (maxRss / (1024 * 1024)).round(),
      );
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to get memory info - $e');
      return null;
    }
  }

  /// Log current memory usage immediately.
  Future<void> logMemorySnapshot(String label) async {
    if (!_isInitialized || _traceFactory == null) return;

    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo == null) return;

      final trace = _traceFactory!.call('memory_$label');
      await trace.start();

      trace.setMetric('used_memory_mb', memoryInfo.usedMemoryMB);
      trace.putAttribute('label', label);

      await trace.stop();
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to log memory snapshot - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create an HTTP metric for tracking network requests.
  /// Note: Firebase Performance automatically tracks HTTP requests made via
  /// standard Flutter HTTP clients. Use this for custom tracking.
  Future<HttpMetric?> createHttpMetric(String url, HttpMethod method) async {
    if (!_isInitialized || _httpMetricFactory == null) return null;

    try {
      return _httpMetricFactory!.call(url, method);
    } catch (e) {
      AppLogger.error('PerformanceMonitor: Failed to create HTTP metric - $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Measure and log the duration of an async operation.
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    await startTrace(operationName);

    if (attributes != null) {
      attributes.forEach((key, value) {
        setTraceAttribute(operationName, key, value);
      });
    }

    try {
      final result = await operation();
      await stopTrace(operationName);
      return result;
    } catch (e) {
      setTraceAttribute(operationName, 'error', e.runtimeType.toString());
      await stopTrace(operationName);
      rethrow;
    }
  }

  /// Measure and log the duration of a sync operation.
  T measureSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, String>? attributes,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      // Log the measurement
      _logSyncMeasurement(
        operationName,
        stopwatch.elapsedMilliseconds,
        attributes: attributes,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _logSyncMeasurement(
        operationName,
        stopwatch.elapsedMilliseconds,
        attributes: {...?attributes, 'error': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  Future<void> _logSyncMeasurement(
    String name,
    int durationMs, {
    Map<String, String>? attributes,
  }) async {
    if (!_isInitialized || _traceFactory == null) return;

    try {
      final trace = _traceFactory!.call(name);
      await trace.start();

      trace.setMetric('duration_ms', durationMs);
      attributes?.forEach((key, value) {
        trace.putAttribute(key, value);
      });

      await trace.stop();
    } catch (e) {
      AppLogger.error(
        'PerformanceMonitor: Failed to log sync measurement - $e',
      );
    }
  }

  /// Get cold start duration in milliseconds.
  int? get coldStartDurationMs {
    if (_appStartTime == null || _firstFrameTime == null) return null;
    return _firstFrameTime!.difference(_appStartTime!).inMilliseconds;
  }

  /// Get peak memory usage in MB.
  int get peakMemoryUsageMB => _peakMemoryUsage;

  /// Check if performance monitoring is enabled.
  bool get isEnabled => _isInitialized;

  /// Dispose resources.
  void dispose() {
    stopMemoryMonitoring();
    _timers.cancelAll();
    _activeTraces.clear();
    _traceFactory = null;
    _httpMetricFactory = null;
    _setCollectionEnabled = null;
    _performance = null;
    _isInitialized = false;
  }
}

/// Memory information snapshot.
class MemoryInfo {
  const MemoryInfo({required this.usedMemoryMB, required this.maxMemoryMB});

  final int usedMemoryMB;
  final int maxMemoryMB;
}

/// Extension for easy performance tracking on widgets.
extension PerformanceMonitorExtension on PerformanceMonitor {
  /// Track a screen's time to interactive.
  void trackScreenReady(String screenName) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      stopScreenTrace(screenName);
    });
  }
}
