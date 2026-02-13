import 'package:crushhour/core/performance/performance_monitor.dart';
import 'package:crushhour/core/performance/performance_observer.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance observers and widgets', () {
    final monitor = PerformanceMonitor.instance;

    tearDown(() {
      monitor.dispose();
    });

    testWidgets('navigator observer tracks screen pushes and replacements', (
      tester,
    ) async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      final navKey = GlobalKey<NavigatorState>();
      final observer = PerformanceNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [observer],
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(settings.name ?? '/')),
            );
          },
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(traces['screen_/'], isNotNull);
      expect(traces['screen_/']!.startCalls, greaterThanOrEqualTo(1));
      expect(traces['screen_/']!.stopCalls, greaterThanOrEqualTo(0));

      navKey.currentState!.pushReplacementNamed('/next');
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text('/next'), findsOneWidget);
      expect(traces['screen_/next'], isNotNull);
      expect(traces['screen_/next']!.startCalls, greaterThanOrEqualTo(1));
      expect(traces['screen_/next']!.stopCalls, greaterThanOrEqualTo(0));
    });

    testWidgets('popup routes are ignored by default shouldTrack behavior', (
      tester,
    ) async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      final navKey = GlobalKey<NavigatorState>();
      final observer = PerformanceNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('home')),
        ),
      );
      await tester.pump();
      await tester.pump();

      final before = traces.length;
      showDialog<void>(
        context: navKey.currentContext!,
        builder: (_) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();

      expect(find.text('dialog'), findsOneWidget);
      expect(traces.length, before);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();
    });

    testWidgets('PerformanceTrackedWidget records screen and memory traces', (
      tester,
    ) async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PerformanceTrackedWidget(
            traceName: 'discover',
            trackMemory: true,
            child: Text('discover-page'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('discover-page'), findsOneWidget);
      expect(traces['screen_discover'], isNotNull);
      expect(traces['screen_discover']!.startCalls, greaterThanOrEqualTo(1));
      expect(traces['screen_discover']!.stopCalls, greaterThanOrEqualTo(0));
      expect(traces.keys.any((key) => key == 'memory_after_discover'), isTrue);
    });

    testWidgets('PerformanceTrackedLoader tracks load only once', (
      tester,
    ) async {
      final traces = <String, _SpyTrace>{};
      monitor.configureForTesting(
        initialized: true,
        traceFactory: (name) => traces.putIfAbsent(name, () => _SpyTrace(name)),
      );

      final loading = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: loading,
            builder: (context, isLoading, child) {
              return PerformanceTrackedLoader(
                traceName: 'chat',
                isLoading: isLoading,
                child: Text(isLoading ? 'loading' : 'done'),
              );
            },
          ),
        ),
      );
      await tester.pump();

      loading.value = false;
      await tester.pump();
      loading.value = true;
      await tester.pump();
      loading.value = false;
      await tester.pump();

      final trace = traces['load_chat'];
      expect(trace, isNotNull);
      expect(trace!.startCalls, 1);
      expect(trace.stopCalls, 1);
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
