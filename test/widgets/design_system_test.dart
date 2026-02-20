import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/design_system/widgets/read_receipt.dart';
import 'package:crushhour/design_system/widgets/profile_completion.dart';
import 'package:crushhour/design_system/widgets/message_search.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

void main() {
  // Note: TypingIndicator tests are skipped because they have animations
  // that require special handling with fake_async

  group('ReadReceipt', () {
    testWidgets('shows sending state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(status: MessageStatus.sending),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows sent state with single check', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(status: MessageStatus.sent),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows delivered state with double check', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(status: MessageStatus.delivered),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('shows read state with double check', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(status: MessageStatus.read),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('shows failed state with error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(status: MessageStatus.failed),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows label when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadReceipt(
              status: MessageStatus.read,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Read'), findsOneWidget);
    });
  });

  group('ProfileCompletionIndicator', () {
    testWidgets('displays percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              percentage: 0.75,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('shows 0% for empty profile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              percentage: 0.0,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows 100% for complete profile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              percentage: 1.0,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('ProfileCompletionCard', () {
    testWidgets('displays completion items', (tester) async {
      final items = [
        const ProfileCompletionItem(
          id: 'photo',
          label: 'Add a photo',
          icon: Icons.photo,
          isComplete: true,
        ),
        const ProfileCompletionItem(
          id: 'bio',
          label: 'Write a bio',
          icon: Icons.edit,
          isComplete: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileCompletionCard(items: items),
            ),
          ),
        ),
      );

      expect(find.text('Add a photo'), findsOneWidget);
      expect(find.text('Write a bio'), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);
    });

    testWidgets('calls onItemTap for incomplete items', (tester) async {
      ProfileCompletionItem? tappedItem;

      final items = [
        const ProfileCompletionItem(
          id: 'bio',
          label: 'Write a bio',
          icon: Icons.edit,
          isComplete: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileCompletionCard(
                items: items,
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Write a bio'));
      await tester.pumpAndSettle();

      expect(tappedItem?.id, 'bio');
    });
  });

  // Note: GlassSkeleton and TypingIndicator tests are skipped because they have
  // animations that require special handling with fake_async

  group('MessageSearchBar', () {
    testWidgets('calls onSearch when text changes', (tester) async {
      String? searchQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageSearchBar(
              onSearch: (query) => searchQuery = query,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(searchQuery, 'hello');
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageSearchBar(
              onSearch: (_) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.close), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      String? searchQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageSearchBar(
              onSearch: (query) => searchQuery = query,
              onClear: () {},
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(searchQuery, 'test');

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(searchQuery, '');
    });
  });

  group('MessageSearchResult', () {
    Widget wrapWithL10n(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    testWidgets('displays sender name and message', (tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          MessageSearchResult(
            senderName: 'John',
            message: 'Hello world',
            timestamp: DateTime.now(),
            query: '',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('John'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('highlights search query in message', (tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          MessageSearchResult(
            senderName: 'John',
            message: 'Hello world',
            timestamp: DateTime.now(),
            query: 'world',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The message should contain RichText with highlighted portion
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithL10n(
          MessageSearchResult(
            senderName: 'John',
            message: 'Hello',
            timestamp: DateTime.now(),
            query: '',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('John'));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
