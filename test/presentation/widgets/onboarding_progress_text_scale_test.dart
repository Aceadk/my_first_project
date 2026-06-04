import 'package:crushhour/l10n/generated/app_localizations.dart';
import 'package:crushhour/presentation/widgets/onboarding_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ONBOARD-UI-003: the shared progress header must not overflow at large text
/// scales or with a long caption on a narrow viewport.
void main() {
  Widget host({
    required double textScale,
    String? caption,
    bool showSkip = false,
    Locale? locale,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 280, // narrow phone content width
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: textScale,
              maxScaleFactor: textScale,
              child: OnboardingProgress(
                currentStep: 3,
                caption: caption,
                showSkip: showSkip,
                onSkip: showSkip ? () {} : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders without overflow at 2x text scale', (tester) async {
    await tester.pumpWidget(host(textScale: 2.0));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingProgress), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders without overflow with skip + long caption at 2x', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        textScale: 2.0,
        showSkip: true,
        caption:
            'This is an intentionally long caption to simulate a verbose '
            'translation that could wrap or overflow the onboarding header.',
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('renders without overflow in an RTL locale at 2x (I18N-002)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(textScale: 2.0, showSkip: true, locale: const Locale('ar')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingProgress))),
      TextDirection.rtl,
    );
  });
}
