import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock/stub_analytics_service.dart';

void main() {
  setUpAll(() {
    AnalyticsService.setInstance(StubAnalyticsService());
  });

  tearDownAll(() {
    AnalyticsService.resetInstance();
  });

  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            screenName: 'Test',
            showHomeButton: false,
            child: Scaffold(body: Text('Hello')),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('shows fallback UI when reportError is called',
        (tester) async {
      final boundaryKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            key: boundaryKey,
            screenName: 'Broken',
            showHomeButton: false,
            child: const Scaffold(body: Text('Normal')),
          ),
        ),
      );

      expect(find.text('Normal'), findsOneWidget);

      // Simulate an error being reported to the boundary
      (boundaryKey.currentState! as dynamic).reportError(
        FlutterErrorDetails(exception: FlutterError('Test error')),
      );

      await tester.pump();
      await tester.pump(); // Second pump for postFrameCallback

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('retry clears error and re-renders child', (tester) async {
      final boundaryKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            key: boundaryKey,
            screenName: 'RetryTest',
            showHomeButton: false,
            child: const Scaffold(body: Text('Recovered')),
          ),
        ),
      );

      // Report an error
      (boundaryKey.currentState! as dynamic).reportError(
        FlutterErrorDetails(exception: FlutterError('Test error')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      // Child should render again
      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('shows Go Home button when showHomeButton is true',
        (tester) async {
      final boundaryKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            key: boundaryKey,
            screenName: 'HomeTest',
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      (boundaryKey.currentState! as dynamic).reportError(
        FlutterErrorDetails(exception: FlutterError('Test error')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Go Home'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('hides Go Home button when showHomeButton is false',
        (tester) async {
      final boundaryKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            key: boundaryKey,
            screenName: 'NoHomeTest',
            showHomeButton: false,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      (boundaryKey.currentState! as dynamic).reportError(
        FlutterErrorDetails(exception: FlutterError('Test error')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Go Home'), findsNothing);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('onRetry callback is invoked on retry', (tester) async {
      var retryCalled = false;
      final boundaryKey = GlobalKey<State>();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            key: boundaryKey,
            screenName: 'CallbackTest',
            showHomeButton: false,
            onRetry: () => retryCalled = true,
            child: const Scaffold(body: Text('Content')),
          ),
        ),
      );

      (boundaryKey.currentState! as dynamic).reportError(
        FlutterErrorDetails(exception: FlutterError('Test error')),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retryCalled, true);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('ErrorFallbackCard', () {
    testWidgets('renders compact error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorFallbackCard()),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('installErrorWidgetBuilder', () {
    testWidgets('replaces default ErrorWidget.builder', (tester) async {
      final original = ErrorWidget.builder;

      installErrorWidgetBuilder();

      expect(ErrorWidget.builder, isNot(equals(original)));

      // Restore original for other tests
      ErrorWidget.builder = original;
    });
  });
}
