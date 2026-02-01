import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crushhour/design_system/widgets/primary_button.dart';
import 'package:crushhour/design_system/widgets/app_text_field.dart';
import 'package:crushhour/design_system/widgets/crush_badge.dart';
import 'package:crushhour/design_system/widgets/glass_card.dart';
import 'package:crushhour/design_system/widgets/skeleton_loader.dart';
import 'package:crushhour/design_system/widgets/empty_state.dart';
import 'package:crushhour/design_system/widgets/typing_indicator.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Click Me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Loading',
              onPressed: () {},
              loading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disables button when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Loading',
              onPressed: () => pressed = true,
              loading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, false);
    });

    testWidgets('disables button when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('expands to full width when expand is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Full Width',
              onPressed: () {},
              expand: true,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('does not expand when expand is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Compact',
              onPressed: () {},
              expand: false,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsNothing);
    });

    testWidgets('has correct accessibility semantics', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Submit',
              onPressed: () {},
              semanticLabel: 'Submit form',
              semanticHint: 'Double tap to submit',
            ),
          ),
        ),
      );

      // Check that Semantics widget exists
      expect(find.byType(Semantics), findsWidgets);

      // The button should be accessible
      final semantics = tester.getSemantics(find.byType(ElevatedButton));
      expect(semantics.label, 'Submit form');
      expect(semantics.hint, 'Double tap to submit');

      handle.dispose();
    });
  });

  group('AppTextField', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              hintText: 'Enter your email',
            ),
          ),
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('displays error text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              errorText: 'Invalid email',
            ),
          ),
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'new value');
      expect(changedValue, 'new value');
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('disables input when enabled is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('shows prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              prefixIcon: Icon(Icons.email),
              suffixIcon: Icon(Icons.visibility),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('CrushBadge', () {
    testWidgets('displays count when count > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushBadge.count(
              count: 5,
              child:  SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays 99+ when count > 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushBadge.count(
              count: 150,
              child:  SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides badge when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushBadge.count(
              count: 0,
              child:  SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows dot badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushBadge.dot(
              child: SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      // Dot badge should be visible (check for positioned widget)
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('wraps child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushBadge.count(
              count: 3,
              child:  Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });

  group('CrushNewBadge', () {
    testWidgets('displays NEW text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushNewBadge(
              child: SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('wraps child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrushNewBadge(
              child: Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('GlassCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('applies padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              padding:  EdgeInsets.all(20),
              child:  Text('Padded'),
            ),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('handles tap when onTap is provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Tappable'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('has BackdropFilter for glass effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child:  Text('Glass'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('GlassCardAccent', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCardAccent(
              child: Text('Accent Card'),
            ),
          ),
        ),
      );

      expect(find.text('Accent Card'), findsOneWidget);
    });

    testWidgets('handles tap when onTap is provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassCardAccent(
              onTap: () => tapped = true,
              child: const Text('Tappable Accent'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Accent'));
      await tester.pump();

      expect(tapped, true);
    });
  });

  group('Skeleton Loaders', () {
    testWidgets('SkeletonBox renders with specified dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(width: 100, height: 20),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 20);
    });

    testWidgets('SkeletonCircle renders with specified size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: 50),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 50);
      expect(container.constraints?.maxHeight, 50);
    });

    testWidgets('SkeletonChatTile renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonChatTile(),
          ),
        ),
      );

      // Should have avatar circle and text placeholders
      expect(find.byType(SkeletonCircle), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('SkeletonMatchCard renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonMatchCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('SkeletonProfileCard renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SkeletonProfileCard(),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('DsShimmer animates child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DsShimmer(
              child: SkeletonBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      // DsShimmer uses AnimatedBuilder for shimmer animation
      expect(find.byType(AnimatedBuilder), findsWidgets);
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('DsEmptyState', () {
    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
            ),
          ),
        ),
      );

      // Pump to let animations complete
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Messages'), findsOneWidget);
    });

    testWidgets('displays message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start a conversation'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
              actionLabel: 'Send Message',
              onAction: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Send Message'), findsOneWidget);
    });

    testWidgets('calls onAction when button tapped', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
              actionLabel: 'Send Message',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Message'));
      await tester.pump();

      expect(actionCalled, true);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DsEmptyState(
              icon: Icons.inbox,
              title: 'No Messages',
              message: 'Start a conversation',
              actionLabel: 'Send Message',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that semantics container exists
      expect(find.bySemanticsLabel(RegExp('No Messages')), findsOneWidget);
    });
  });

  group('TypingIndicator', () {
    // TypingIndicator uses infinite repeating animations for the bouncing dots.
    // We need to be careful not to use pumpAndSettle which will timeout.

    testWidgets('renders without errors', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(),
            ),
          ),
        );

        // Just verify it renders
        expect(find.byType(TypingIndicator), findsOneWidget);
      });
    });

    testWidgets('contains animated dots', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(),
            ),
          ),
        );

        // Let animations start
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();

        // Should have Container widgets for the dots
        expect(find.byType(Container), findsWidgets);
      });
    });

    testWidgets('can hide glass background', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(showGlassBackground: false),
            ),
          ),
        );

        // Without glass background, no BackdropFilter
        expect(find.byType(BackdropFilter), findsNothing);
      });
    });
  });
}
