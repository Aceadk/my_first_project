/// Golden Tests for Design System Components
///
/// These tests verify UI consistency by comparing rendered widgets
/// against reference "golden" images.
///
/// To update goldens (first run or after intentional UI changes):
/// ```
/// flutter test --update-goldens test/golden/design_system_golden_test.dart
/// ```
///
/// To run tests (verify UI matches goldens):
/// ```
/// flutter test test/golden/design_system_golden_test.dart
/// ```
///
/// Tagged `golden` and excluded from the cross-platform CI `flutter test` run:
/// golden images are pixel-comparisons against locally-generated references and
/// are not portable to the Linux CI runner / a different Flutter version. Run
/// them locally with a matched toolchain (`flutter test test/golden/`).
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/design_system/widgets/app_text_field.dart';
import 'package:crushhour/design_system/widgets/crush_badge.dart';
import 'package:crushhour/design_system/widgets/glass_card.dart';
import 'package:crushhour/design_system/widgets/empty_state.dart';
import 'package:crushhour/design_system/widgets/skeleton_loader.dart';

void main() {
  group('Golden Tests: PrimaryButton', () {
    testWidgets('default state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          PrimaryButton(
            label: 'Get Started',
            onPressed: () {},
          ),
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_default.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          PrimaryButton(
            label: 'Loading',
            onPressed: () {},
            loading: true,
          ),
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_loading.png'),
      );
    });

    testWidgets('disabled state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const PrimaryButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_disabled.png'),
      );
    });

    testWidgets('compact (non-expanded) state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          PrimaryButton(
            label: 'Compact',
            onPressed: () {},
            expand: false,
          ),
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_compact.png'),
      );
    });
  });

  group('Golden Tests: AppTextField', () {
    testWidgets('default state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const AppTextField(
            label: 'Email',
            hintText: 'Enter your email',
          ),
        ),
      );

      await expectLater(
        find.byType(AppTextField),
        matchesGoldenFile('goldens/text_field_default.png'),
      );
    });

    testWidgets('error state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const AppTextField(
            label: 'Email',
            hintText: 'Enter your email',
            errorText: 'Invalid email address',
          ),
        ),
      );

      await expectLater(
        find.byType(AppTextField),
        matchesGoldenFile('goldens/text_field_error.png'),
      );
    });

    testWidgets('with icons', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const AppTextField(
            label: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: Icon(Icons.visibility),
            obscureText: true,
          ),
        ),
      );

      await expectLater(
        find.byType(AppTextField),
        matchesGoldenFile('goldens/text_field_with_icons.png'),
      );
    });

    testWidgets('disabled state', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const AppTextField(
            label: 'Disabled Field',
            hintText: 'Cannot edit',
            enabled: false,
          ),
        ),
      );

      await expectLater(
        find.byType(AppTextField),
        matchesGoldenFile('goldens/text_field_disabled.png'),
      );
    });
  });

  group('Golden Tests: CrushBadge', () {
    testWidgets('count badge', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const CrushBadge.count(
            count: 5,
            child: Icon(Icons.notifications, size: 32),
          ),
        ),
      );

      await expectLater(
        find.byType(CrushBadge),
        matchesGoldenFile('goldens/crush_badge_count.png'),
      );
    });

    testWidgets('overflow count badge (99+)', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const CrushBadge.count(
            count: 150,
            child: Icon(Icons.notifications, size: 32),
          ),
        ),
      );

      await expectLater(
        find.byType(CrushBadge),
        matchesGoldenFile('goldens/crush_badge_overflow.png'),
      );
    });

    testWidgets('dot badge', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const CrushBadge.dot(
            child: Icon(Icons.chat, size: 32),
          ),
        ),
      );

      await expectLater(
        find.byType(CrushBadge),
        matchesGoldenFile('goldens/crush_badge_dot.png'),
      );
    });

    testWidgets('new badge', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const CrushNewBadge(
            child: Icon(Icons.star, size: 32),
          ),
        ),
      );

      await expectLater(
        find.byType(CrushNewBadge),
        matchesGoldenFile('goldens/crush_badge_new.png'),
      );
    });
  });

  group('Golden Tests: GlassCard', () {
    testWidgets('default glass card', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Glass Card Content'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(GlassCard),
        matchesGoldenFile('goldens/glass_card_default.png'),
      );
    });

    testWidgets('glass card with accent', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const GlassCardAccent(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Accent Glass Card'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(GlassCardAccent),
        matchesGoldenFile('goldens/glass_card_accent.png'),
      );
    });
  });

  group('Golden Tests: DsEmptyState', () {
    testWidgets('with icon', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const Center(
            child: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Your inbox is empty. Start a conversation!',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DsEmptyState),
        matchesGoldenFile('goldens/empty_state_default.png'),
      );
    });

    testWidgets('with action button', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          Center(
            child: DsEmptyState(
              icon: Icons.explore_off,
              title: 'No Matches Found',
              message: 'Try adjusting your preferences',
              actionLabel: 'Update Preferences',
              onAction: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DsEmptyState),
        matchesGoldenFile('goldens/empty_state_with_action.png'),
      );
    });
  });

  group('Golden Tests: Skeleton Loaders', () {
    testWidgets('skeleton box', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const SkeletonBox(width: 200, height: 20),
        ),
      );

      await expectLater(
        find.byType(SkeletonBox),
        matchesGoldenFile('goldens/skeleton_box.png'),
      );
    });

    testWidgets('skeleton circle', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const SkeletonCircle(size: 50),
        ),
      );

      await expectLater(
        find.byType(SkeletonCircle),
        matchesGoldenFile('goldens/skeleton_circle.png'),
      );
    });

    testWidgets('skeleton chat tile', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const SkeletonChatTile(),
        ),
      );

      await expectLater(
        find.byType(SkeletonChatTile),
        matchesGoldenFile('goldens/skeleton_chat_tile.png'),
      );
    });

    testWidgets('skeleton match card', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const SkeletonMatchCard(),
        ),
      );

      await expectLater(
        find.byType(SkeletonMatchCard),
        matchesGoldenFile('goldens/skeleton_match_card.png'),
      );
    });
  });

  group('Golden Tests: Dark Mode', () {
    testWidgets('primary button dark mode', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          PrimaryButton(
            label: 'Dark Mode Button',
            onPressed: () {},
          ),
          darkMode: true,
        ),
      );

      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_dark.png'),
      );
    });

    testWidgets('text field dark mode', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const AppTextField(
            label: 'Email',
            hintText: 'Enter your email',
          ),
          darkMode: true,
        ),
      );

      await expectLater(
        find.byType(AppTextField),
        matchesGoldenFile('goldens/text_field_dark.png'),
      );
    });

    testWidgets('glass card dark mode', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Dark Mode Glass'),
            ),
          ),
          darkMode: true,
        ),
      );

      await expectLater(
        find.byType(GlassCard),
        matchesGoldenFile('goldens/glass_card_dark.png'),
      );
    });

    testWidgets('empty state dark mode', (tester) async {
      await tester.pumpWidget(
        _wrapInMaterialApp(
          const Center(
            child: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Your inbox is empty',
            ),
          ),
          darkMode: true,
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DsEmptyState),
        matchesGoldenFile('goldens/empty_state_dark.png'),
      );
    });
  });
}

/// Wraps a widget in MaterialApp for testing
Widget _wrapInMaterialApp(Widget child, {bool darkMode = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}
