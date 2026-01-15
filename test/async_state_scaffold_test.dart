import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/shared/widgets/async_state_scaffold.dart';

void main() {
  testWidgets('shows loader when loading with error/empty present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncStateScaffold(
          isLoading: true,
          errorMessage: 'Oops',
          empty: SizedBox.shrink(),
          body: Text('Body'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Oops'), findsNothing);
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('renders error view and triggers retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncStateScaffold(
          errorMessage: 'Something went wrong',
          onRetry: () => retried = true,
          body: const Text('Body'),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
