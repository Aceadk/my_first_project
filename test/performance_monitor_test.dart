import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/core/performance/performance_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceMonitor', () {
    final monitor = PerformanceMonitor.instance;

    tearDown(() {
      monitor.dispose();
    });

    test('is disabled by default until initialize is called', () {
      expect(monitor.isEnabled, isFalse);
      expect(monitor.coldStartDurationMs, isNull);
      expect(monitor.peakMemoryUsageMB, greaterThanOrEqualTo(0));
    });

    test(
      'records app start and first frame with cold_start trace when enabled',
      () async {
        final traces = <String, _SpyTrace>{};
        monitor.configureForTesting(
          initialized: true,
          traceFactory: (name) =>
              traces.putIfAbsent(name, () => _SpyTrace(name)),
        );

        monitor.recordAppStartTime();
        monitor.recordFirstFrame();
        await Future<void>.delayed(Duration.zero);

        expect(monitor.coldStartDurationMs, isNotNull);
        expect(traces['cold_start']?.startCalls, 1);
        expect(traces['cold_start']?.stopCalls, 1);
        expect(
          traces['cold_start']?.metrics.containsKey('duration_ms'),
          isTrue,
        );
      },
    );

    test(
      'startTrace/stopTrace manage active trace metrics and attributes',
      () async {
        final traces = <String, _SpyTrace>{};
        monitor.configureForTesting(
          initialized: true,
          traceFactory: (name) =>
              traces.putIfAbsent(name, () => _SpyTrace(name)),
        );

        await monitor.startTrace('feed_load');
        monitor.incrementTraceMetric('feed_load', 'items_loaded', 2);
        monitor.setTraceAttribute('feed_load', 'source', 'unit');
        await monitor.stopTrace(
          'feed_load',
          metrics: const {'duration_ms': 120},
        );

        final trace = traces['feed_load'];
        expect(trace, isNotNull);
        expect(trace?.startCalls, 1);
        expect(trace?.stopCalls, 1);
        expect(trace?.metrics['items_loaded'], 2);
        expect(trace?.metrics['duration_ms'], 120);
        expect(trace?.attributes['source'], 'unit');
      },
    );

    test('startTrace ignores duplicate trace names', () async {
      var created = 0;
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) {
          created += 1;
          return traces.putIfAbsent(name, () => _SpyTrace(name));
        },
      );

      await monitor.startTrace('dup_trace');
      await monitor.startTrace('dup_trace');

      expect(created, 1);
      expect(traces['dup_trace']?.startCalls, 1);
    });

    test('stopTrace is safe when trace does not exist', () async {
      monitor.configureForTesting(
        initialized: true,
        traceFactory: _SpyTrace.new,
      );
      await monitor.stopTrace('missing_trace');
    });

    test('measureAsync returns result and stops trace', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      final result = await monitor.measureAsync<String>(
        'async_success',
        () async => 'ok',
        attributes: const {'source': 'test'},
      );

      expect(result, 'ok');
      expect(traces['async_success']?.startCalls, 1);
      expect(traces['async_success']?.stopCalls, 1);
      expect(traces['async_success']?.attributes['source'], 'test');
    });

    test('measureAsync rethrows and records error attribute', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      expect(
        () => monitor.measureAsync<void>(
          'async_error',
          () async => throw StateError('boom'),
        ),
        throwsStateError,
      );

      await Future<void>.delayed(Duration.zero);
      expect(traces['async_error']?.stopCalls, 1);
      expect(traces['async_error']?.attributes['error'], 'StateError');
    });

    test('measureSync logs both success and failure traces', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      final ok = monitor.measureSync<int>('sync_success', () => 42);
      expect(ok, 42);

      expect(
        () => monitor.measureSync<void>(
          'sync_error',
          () => throw StateError('fail'),
        ),
        throwsStateError,
      );

      await Future<void>.delayed(Duration.zero);
      expect(traces['sync_success']?.stopCalls, 1);
      expect(traces['sync_error']?.attributes['error'], 'StateError');
    });

    test('createHttpMetric returns provided metric when configured', () async {
      final metric = _FakeHttpMetric();
      String? capturedUrl;
      HttpMethod? capturedMethod;
      monitor.configureForTesting(
        initialized: true,
        httpMetricFactory: (url, method) {
          capturedUrl = url;
          capturedMethod = method;
          return metric;
        },
      );

      final created = await monitor.createHttpMetric(
        'https://example.com',
        HttpMethod.Get,
      );

      expect(created, same(metric));
      expect(capturedUrl, 'https://example.com');
      expect(capturedMethod, HttpMethod.Get);
    });

    test('createHttpMetric returns null when not initialized', () async {
      monitor.configureForTesting(initialized: false);
      final metric = await monitor.createHttpMetric(
        'https://example.com',
        HttpMethod.Get,
      );
      expect(metric, isNull);
    });

    test('logMemorySnapshot records a trace when enabled', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      await monitor.logMemorySnapshot('manual');

      final trace = traces['memory_manual'];
      expect(trace, isNotNull);
      expect(trace?.startCalls, 1);
      expect(trace?.stopCalls, 1);
      expect(trace?.metrics.containsKey('used_memory_mb'), isTrue);
      expect(trace?.attributes['label'], 'manual');
    });

    test('memory monitoring can be started and stopped safely', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      monitor.startMemoryMonitoring(interval: const Duration(milliseconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 25));
      monitor.stopMemoryMonitoring();

      expect(traces.containsKey('memory_snapshot'), isTrue);
      expect(monitor.peakMemoryUsageMB, greaterThanOrEqualTo(0));
    });

    test('screen trace helpers and extension are callable', () async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      await monitor.startScreenTrace('home');
      await monitor.stopScreenTrace('home');
      monitor.trackScreenReady('home');

      expect(traces.containsKey('screen_home'), isTrue);
    });
  });
}

class _SpyTrace implements Trace {
  _SpyTrace(this.name);

  final String name;
  int startCalls = 0;
  int stopCalls = 0;
  final Map<String, int> metrics = <String, int>{};
  final Map<String, String> attributes = <String, String>{};

  @override
  Future<void> start() async {
    startCalls += 1;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  void incrementMetric(String metricName, int value) {
    metrics[metricName] = (metrics[metricName] ?? 0) + value;
  }

  @override
  void setMetric(String metricName, int value) {
    metrics[metricName] = value;
  }

  @override
  int getMetric(String metricName) => metrics[metricName] ?? 0;

  @override
  void putAttribute(String attributeName, String value) {
    attributes[attributeName] = value;
  }

  @override
  void removeAttribute(String attributeName) {
    attributes.remove(attributeName);
  }

  @override
  String? getAttribute(String attributeName) => attributes[attributeName];

  @override
  Map<String, String> getAttributes() => Map<String, String>.from(attributes);
}

class _FakeHttpMetric implements HttpMetric {
  int? _httpResponseCode;
  int? _requestPayloadSize;
  String? _responseContentType;
  int? _responsePayloadSize;
  final Map<String, String> _attributes = <String, String>{};

  @override
  int? get httpResponseCode => _httpResponseCode;

  @override
  set httpResponseCode(int? value) {
    _httpResponseCode = value;
  }

  @override
  int? get requestPayloadSize => _requestPayloadSize;

  @override
  set requestPayloadSize(int? value) {
    _requestPayloadSize = value;
  }

  @override
  String? get responseContentType => _responseContentType;

  @override
  set responseContentType(String? value) {
    _responseContentType = value;
  }

  @override
  int? get responsePayloadSize => _responsePayloadSize;

  @override
  set responsePayloadSize(int? value) {
    _responsePayloadSize = value;
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void putAttribute(String name, String value) {
    _attributes[name] = value;
  }

  @override
  void removeAttribute(String name) {
    _attributes.remove(name);
  }

  @override
  String? getAttribute(String name) => _attributes[name];

  @override
  Map<String, String> getAttributes() => Map<String, String>.from(_attributes);
}
