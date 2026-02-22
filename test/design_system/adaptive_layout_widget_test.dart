import 'package:crushhour/design_system/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required double width, required Widget child}) {
    return MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: width, height: 500, child: child),
          ),
        ),
      ),
    );
  }

  Future<void> setLargeSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  const destinations = <AdaptiveDestination>[
    AdaptiveDestination(icon: Icons.home_outlined, label: 'Home'),
    AdaptiveDestination(icon: Icons.chat_bubble_outline, label: 'Chat'),
  ];

  group('AdaptiveLayout', () {
    testWidgets('uses mobile/tablet/desktop branches', (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(
        host(
          width: 500,
          child: const AdaptiveLayout(
            body: Text('body'),
            sidePanel: Text('side'),
          ),
        ),
      );
      expect(find.text('body'), findsOneWidget);
      expect(find.text('side'), findsNothing);

      await tester.pumpWidget(
        host(
          width: 500,
          child: const AdaptiveLayout(
            body: Text('body'),
            sidePanel: Text('side'),
            showSidePanelOnMobile: true,
          ),
        ),
      );
      expect(find.text('side'), findsOneWidget);
      expect(find.text('body'), findsNothing);

      await tester.pumpWidget(
        host(
          width: 700,
          child: const AdaptiveLayout(body: Text('tablet-body')),
        ),
      );
      final tabletCentered = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('tablet-body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(tabletCentered.constraints.maxWidth, 720);

      await tester.pumpWidget(
        host(
          width: 700,
          child: const AdaptiveLayout(
            sidePanel: Text('tablet-side'),
            body: Text('tablet-body-2'),
          ),
        ),
      );
      expect(find.text('tablet-side'), findsOneWidget);
      expect(find.text('tablet-body-2'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);

      await tester.pumpWidget(
        host(
          width: 1200,
          child: const AdaptiveLayout(
            sidePanel: Text('desktop-side'),
            body: Text('desktop-body'),
            detailPanel: Text('desktop-detail'),
          ),
        ),
      );
      expect(find.text('desktop-side'), findsOneWidget);
      expect(find.text('desktop-body'), findsOneWidget);
      expect(find.text('desktop-detail'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNWidgets(2));

      await tester.pumpWidget(
        host(
          width: 1200,
          child: const AdaptiveLayout(body: Text('desktop-centered')),
        ),
      );
      final desktopCentered = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('desktop-centered'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(desktopCentered.constraints.maxWidth, 960);
    });
  });

  group('AdaptiveScaffold', () {
    testWidgets('renders navigation patterns by breakpoint', (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(
        host(
          width: 500,
          child: const AdaptiveScaffold(
            body: Text('mobile-body'),
            destinations: destinations,
          ),
        ),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      int? selectedIndex;
      await tester.pumpWidget(
        host(
          width: 700,
          child: AdaptiveScaffold(
            body: const Text('tablet-body'),
            destinations: destinations,
            onDestinationSelected: (value) => selectedIndex = value,
          ),
        ),
      );
      final tabletRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(tabletRail.extended, isFalse);
      tabletRail.onDestinationSelected?.call(1);
      expect(selectedIndex, 1);

      await tester.pumpWidget(
        host(
          width: 1200,
          child: const AdaptiveScaffold(
            body: Text('desktop-body'),
            destinations: destinations,
          ),
        ),
      );
      final desktopRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(desktopRail.extended, isTrue);
      final desktopCentered = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('desktop-body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(desktopCentered.constraints.maxWidth, 960);
    });
  });

  group('AdaptiveCard', () {
    testWidgets('applies responsive padding and margin', (tester) async {
      await setLargeSurface(tester);
      await tester.pumpWidget(
        host(width: 500, child: const AdaptiveCard(child: Text('card-child'))),
      );

      final cardPaddingMobile = tester.widgetList<Padding>(
        find.ancestor(
          of: find.text('card-child'),
          matching: find.byType(Padding),
        ),
      );
      expect(
        cardPaddingMobile.any((p) => p.padding == const EdgeInsets.all(16)),
        isTrue,
      );
      expect(
        cardPaddingMobile.any(
          (p) =>
              p.padding ==
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isTrue,
      );

      await tester.pumpWidget(
        host(
          width: 1200,
          child: const AdaptiveCard(child: Text('card-child-desktop')),
        ),
      );
      final cardPaddingDesktop = tester.widgetList<Padding>(
        find.ancestor(
          of: find.text('card-child-desktop'),
          matching: find.byType(Padding),
        ),
      );
      expect(
        cardPaddingDesktop.any((p) => p.padding == const EdgeInsets.all(24)),
        isTrue,
      );
      expect(
        cardPaddingDesktop.any(
          (p) =>
              p.padding ==
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
        isTrue,
      );
    });
  });

  group('AdaptiveGrid', () {
    testWidgets('uses expected grid columns by breakpoint', (tester) async {
      await setLargeSurface(tester);
      Future<void> pumpGrid(double width) async {
        await tester.pumpWidget(
          host(
            width: width,
            child: const AdaptiveGrid(
              children: [SizedBox(), SizedBox(), SizedBox()],
            ),
          ),
        );
      }

      await pumpGrid(500);
      var grid = tester.widget<GridView>(find.byType(GridView));
      var delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);

      await pumpGrid(700);
      grid = tester.widget<GridView>(find.byType(GridView));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      await pumpGrid(1200);
      grid = tester.widget<GridView>(find.byType(GridView));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });
  });

  group('ResponsiveContext', () {
    testWidgets('exposes responsive flags, values, and padding', (
      tester,
    ) async {
      await setLargeSurface(tester);
      Future<void> pumpProbe(double width) async {
        await tester.pumpWidget(
          host(width: width, child: const _ResponsiveProbe()),
        );
      }

      await pumpProbe(500);
      expect(find.textContaining('m:true'), findsOneWidget);
      expect(find.textContaining('v:m'), findsOneWidget);
      expect(find.textContaining('pad:16.0'), findsOneWidget);

      await pumpProbe(700);
      expect(find.textContaining('t:true'), findsOneWidget);
      expect(find.textContaining('v:t'), findsOneWidget);
      expect(find.textContaining('pad:24.0'), findsOneWidget);

      await pumpProbe(1200);
      expect(find.textContaining('d:true'), findsOneWidget);
      expect(find.textContaining('v:d'), findsOneWidget);
      expect(find.textContaining('pad:32.0'), findsOneWidget);
    });
  });
}

class _ResponsiveProbe extends StatelessWidget {
  const _ResponsiveProbe();

  @override
  Widget build(BuildContext context) {
    final value = context.responsive<String>(
      mobile: 'm',
      tablet: 't',
      desktop: 'd',
    );
    final horizontalPad = context.responsivePadding.horizontal / 2;

    return Text(
      'm:${context.isMobile}|t:${context.isTablet}|d:${context.isDesktop}|'
      'v:$value|pad:$horizontalPad',
    );
  }
}
