import 'package:crushhour/core/services/photo_verification_service.dart';
import 'package:crushhour/design_system/tokens/sizes.dart';
import 'package:crushhour/design_system/widgets/verification_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required Widget child,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('DsVerificationBadge', () {
    testWidgets('renders nothing for none level', (tester) async {
      await tester.pumpWidget(
        host(child: const DsVerificationBadge(level: VerificationLevel.none)),
      );

      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('maps badge sizes to icon token sizes', (tester) async {
      const cases = <(DsVerificationBadgeSize, double)>[
        (DsVerificationBadgeSize.tiny, DsSizes.iconXs),
        (DsVerificationBadgeSize.small, DsSizes.iconSm),
        (DsVerificationBadgeSize.medium, DsSizes.iconMd),
        (DsVerificationBadgeSize.large, DsSizes.iconLg),
      ];

      for (final entry in cases) {
        await tester.pumpWidget(
          host(
            child: DsVerificationBadge(
              level: VerificationLevel.photo,
              size: entry.$1,
              showTooltip: false,
            ),
          ),
        );
        final icon = tester.widget<Icon>(find.byType(Icon).first);
        expect(icon.size, entry.$2);
      }
    });

    testWidgets('renders label, tooltip, and semantics', (tester) async {
      await tester.pumpWidget(
        host(
          child: const DsVerificationBadge(
            level: VerificationLevel.id,
            showLabel: true,
            showTooltip: true,
          ),
        ),
      );

      expect(find.text('ID Verified'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      final labels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.label)
          .whereType<String>()
          .toList();
      expect(labels.any((label) => label.contains('ID Verified')), isTrue);
      expect(
        labels.any((label) => label.contains('Government ID verified')),
        isTrue,
      );
    });
  });

  group('DsVerificationStatus', () {
    testWidgets('renders compact and non-compact variants', (tester) async {
      await tester.pumpWidget(
        host(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsVerificationStatus(level: VerificationLevel.basic),
              DsVerificationStatus(
                level: VerificationLevel.photo,
                compact: true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Basic Verified'), findsOneWidget);
      expect(find.text('Photo Verified'), findsOneWidget);
      expect(find.byType(DsVerificationBadge), findsNWidgets(2));

      await tester.pumpWidget(
        host(
          brightness: Brightness.dark,
          child: const DsVerificationStatus(level: VerificationLevel.id),
        ),
      );
      expect(find.text('ID Verified'), findsOneWidget);
    });
  });

  group('DsVerificationPrompt', () {
    testWidgets('maps current level to next target and runs callback', (
      tester,
    ) async {
      const cases = <(VerificationLevel, String, String)>[
        (
          VerificationLevel.none,
          'Get Basic Verified',
          'Verify your email or phone',
        ),
        (VerificationLevel.basic, 'Get Photo Verified', 'Take a quick selfie'),
        (VerificationLevel.photo, 'Get ID Verified', 'Upload a government ID'),
        (VerificationLevel.id, 'Get Premium Verified', 'quick video call'),
        (VerificationLevel.premium, 'Get Premium Verified', 'quick video call'),
      ];

      for (final entry in cases) {
        var tapped = false;
        await tester.pumpWidget(
          host(
            child: DsVerificationPrompt(
              currentLevel: entry.$1,
              onStartVerification: () => tapped = true,
            ),
          ),
        );

        expect(find.text(entry.$2), findsOneWidget);
        expect(find.textContaining(entry.$3), findsOneWidget);

        await tester.tap(find.text('Start Verification'));
        await tester.pump();
        expect(tapped, isTrue);
      }
    });
  });
}
