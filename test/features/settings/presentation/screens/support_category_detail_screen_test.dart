import 'package:crushhour/config/support_config.dart';
import 'package:crushhour/features/settings/presentation/screens/support_category_detail_screen.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp(SupportCategory category) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SupportCategoryDetailScreen(category: category),
    );
  }

  testWidgets('renders full article sections for category details', (
    tester,
  ) async {
    final category = SupportConfig.categoryById('billing');

    await tester.pumpWidget(buildTestApp(category));
    await tester.pumpAndSettle();

    expect(find.text('Billing & Subscription'), findsOneWidget);
    expect(find.text('Billing & Subscription Help Guide'), findsOneWidget);
    expect(find.text('Recommended steps'), findsOneWidget);
    expect(find.text('Escalate to support when'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Related questions'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Related questions'), findsOneWidget);
    expect(find.text('How do I cancel my subscription?'), findsOneWidget);
    expect(find.text('Need more help?'), findsOneWidget);
  });

  testWidgets('shows FAQ fallback state for category without mapped FAQs', (
    tester,
  ) async {
    const customCategory = SupportCategory(
      id: 'custom',
      title: 'Custom Topic',
      description: 'Custom issue details.',
      icon: 'help',
      url: SupportConfig.faqUrl,
    );

    await tester.pumpWidget(buildTestApp(customCategory));
    await tester.pumpAndSettle();

    expect(find.text('Custom Topic Help Guide'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('No in-app FAQ is available for this category yet.'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No in-app FAQ is available for this category yet.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a related question expands and collapses the answer', (
    tester,
  ) async {
    final category = SupportConfig.categoryById('matching');
    final targetFaq = SupportConfig.faqsForCategory(
      'matching',
    ).firstWhere((faq) => faq.question == 'How do I get more matches?');

    await tester.pumpWidget(buildTestApp(category));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(targetFaq.question),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(targetFaq.answer), findsNothing);

    await tester.tap(find.text(targetFaq.question));
    await tester.pumpAndSettle();
    expect(find.text(targetFaq.answer), findsOneWidget);

    await tester.tap(find.text(targetFaq.question));
    await tester.pumpAndSettle();
    expect(find.text(targetFaq.answer), findsNothing);
  });
}
