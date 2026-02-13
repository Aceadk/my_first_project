import 'package:crushhour/design_system/animations/ds_animations.dart';
import 'package:crushhour/design_system/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Animation tokens', () {
    test('durations are stable and ordered as expected', () {
      expect(DsDurations.fastest, const Duration(milliseconds: 100));
      expect(DsDurations.fast, const Duration(milliseconds: 150));
      expect(DsDurations.quick, const Duration(milliseconds: 200));
      expect(DsDurations.normal, const Duration(milliseconds: 300));
      expect(DsDurations.medium, const Duration(milliseconds: 400));
      expect(DsDurations.slow, const Duration(milliseconds: 500));
      expect(DsDurations.slower, const Duration(milliseconds: 600));
      expect(DsDurations.complex, const Duration(milliseconds: 800));
    });

    test('curves map to expected Flutter presets', () {
      expect(DsCurves.standard, Curves.easeInOut);
      expect(DsCurves.enter, Curves.easeOut);
      expect(DsCurves.exit, Curves.easeIn);
      expect(DsCurves.emphasized, Curves.easeInOutCubic);
      expect(DsCurves.bounce, Curves.elasticOut);
      expect(DsCurves.spring, Curves.easeOutBack);
    });
  });

  group('Animation widgets', () {
    testWidgets('DsFadeIn supports immediate and delayed start', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: DsFadeIn(child: Text('fade-now'))),
      );
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.text('fade-now'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: DsFadeIn(
            delay: Duration(milliseconds: 5),
            child: Text('fade-delay'),
          ),
        ),
      );
      expect(find.text('fade-delay'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 6));
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('DsSlideIn variants and delayed path build correctly', (
      tester,
    ) async {
      const fromBottom = DsSlideIn.fromBottom(child: Text('bottom'));
      const fromTop = DsSlideIn.fromTop(child: Text('top'));
      const fromLeft = DsSlideIn.fromLeft(child: Text('left'));
      const fromRight = DsSlideIn.fromRight(child: Text('right'));

      expect(fromBottom.begin, const Offset(0, 0.2));
      expect(fromTop.begin, const Offset(0, -0.2));
      expect(fromLeft.begin, const Offset(-0.2, 0));
      expect(fromRight.begin, const Offset(0.2, 0));

      await tester.pumpWidget(
        const MaterialApp(
          home: DsSlideIn(
            delay: Duration(milliseconds: 4),
            child: Text('slide-delay'),
          ),
        ),
      );

      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets('DsScaleIn, DsStaggeredList, and DsPressable interactions', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              const DsScaleIn(child: Text('scale')),
              const DsStaggeredList(
                children: [Text('item-1'), Text('item-2'), Text('item-3')],
              ),
              DsPressable(
                onTap: () => tapped = true,
                child: const Text('press'),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.byType(DsSlideIn), findsNWidgets(3));
      expect(find.text('item-1'), findsOneWidget);

      final pressableFinder = find.text('press');
      final gesture = await tester.startGesture(
        tester.getCenter(pressableFinder),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      await tester.tap(pressableFinder);
      await tester.pump();
      expect(tapped, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Page transitions', () {
    testWidgets(
      'route builders expose expected durations and transition types',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));

        final fade = DsPageTransitions.fade<void>(
          page: const Text('fade-page'),
          settings: const RouteSettings(name: '/fade'),
        );
        final slideUp = DsPageTransitions.slideUp<void>(page: const Text('up'));
        final slideRight = DsPageTransitions.slideRight<void>(
          page: const Text('right'),
        );
        final scale = DsPageTransitions.scale<void>(page: const Text('scale'));
        final shared = DsPageTransitions.sharedAxisHorizontal<void>(
          page: const Text('shared'),
          reverse: true,
        );
        final detail = DsPageTransitions.profileDetail<void>(
          page: const Text('detail'),
        );
        final reveal = DsPageTransitions.matchReveal<void>(
          page: const Text('reveal'),
        );

        expect(fade.transitionDuration, DsDurations.normal);
        expect(fade.reverseTransitionDuration, DsDurations.normal);
        expect(reveal.opaque, isFalse);
        expect(reveal.barrierColor, Colors.black54);
        expect(reveal.transitionDuration, DsDurations.slow);
        expect(detail.transitionDuration, DsDurations.medium);
        expect(detail.reverseTransitionDuration, DsDurations.normal);

        const a = AlwaysStoppedAnimation<double>(1);
        const b = AlwaysStoppedAnimation<double>(1);
        expect(
          fade.buildTransitions(context, a, b, const SizedBox()),
          isA<FadeTransition>(),
        );
        expect(
          slideUp.buildTransitions(context, a, b, const SizedBox()),
          isA<SlideTransition>(),
        );
        expect(
          slideRight.buildTransitions(context, a, b, const SizedBox()),
          isA<SlideTransition>(),
        );
        expect(
          scale.buildTransitions(context, a, b, const SizedBox()),
          isA<ScaleTransition>(),
        );
        expect(
          shared.buildTransitions(context, a, b, const SizedBox()),
          isA<SlideTransition>(),
        );
        expect(
          detail.buildTransitions(context, a, b, const SizedBox()),
          isA<ScaleTransition>(),
        );
        expect(
          reveal.buildTransitions(context, a, b, const SizedBox()),
          isA<ScaleTransition>(),
        );
      },
    );

    testWidgets('navigator extension helpers push pages', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
        ),
      );

      navKey.currentState!.pushFade<void>(
        const Scaffold(body: Text('fade-target')),
      );
      await tester.pumpAndSettle();
      expect(find.text('fade-target'), findsOneWidget);

      navKey.currentState!.pushSlideUp<void>(
        const Scaffold(body: Text('slide-target')),
      );
      await tester.pumpAndSettle();
      expect(find.text('slide-target'), findsOneWidget);

      navKey.currentState!.pushScale<void>(
        const Scaffold(body: Text('scale-target')),
      );
      await tester.pumpAndSettle();
      expect(find.text('scale-target'), findsOneWidget);

      navKey.currentState!.pushProfileDetail<void>(
        const Scaffold(body: Text('profile-target')),
      );
      await tester.pumpAndSettle();
      expect(find.text('profile-target'), findsOneWidget);
    });
  });
}
