import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DsBreakpoints width checks', () {
    test('classifies compact/mobile/tablet/desktop ranges correctly', () {
      expect(DsBreakpoints.isCompact(359), isTrue);
      expect(DsBreakpoints.isCompact(360), isFalse);

      expect(DsBreakpoints.isMobile(599), isTrue);
      expect(DsBreakpoints.isMobile(600), isFalse);

      expect(DsBreakpoints.isTablet(600), isTrue);
      expect(DsBreakpoints.isTablet(1023), isTrue);
      expect(DsBreakpoints.isTablet(1024), isFalse);

      expect(DsBreakpoints.isDesktop(1024), isTrue);
      expect(DsBreakpoints.isDesktop(1439), isTrue);
      expect(DsBreakpoints.isDesktop(1440), isFalse);

      expect(DsBreakpoints.isLargeDesktop(1440), isTrue);
      expect(DsBreakpoints.isLargeDesktop(1439), isFalse);
    });

    test('returns responsive values by width', () {
      expect(
        DsBreakpoints.responsiveValue(
          375,
          mobile: 'm',
          tablet: 't',
          desktop: 'd',
        ),
        'm',
      );
      expect(
        DsBreakpoints.responsiveValue(
          800,
          mobile: 'm',
          tablet: 't',
          desktop: 'd',
        ),
        't',
      );
      expect(
        DsBreakpoints.responsiveValue(
          1200,
          mobile: 'm',
          tablet: 't',
          desktop: 'd',
        ),
        'd',
      );
    });

    test('falls back to tablet/mobile values when desktop not provided', () {
      expect(DsBreakpoints.responsiveValue(1200, mobile: 1, tablet: 2), 2);
      expect(DsBreakpoints.responsiveValue(800, mobile: 1), 1);
    });

    test('returns grid columns and content max width by size', () {
      expect(DsBreakpoints.gridColumns(350), 1);
      expect(DsBreakpoints.gridColumns(700), 2);
      expect(DsBreakpoints.gridColumns(1200), 3);
      expect(DsBreakpoints.gridColumns(1600), 4);

      expect(DsBreakpoints.contentMaxWidth(350), double.infinity);
      expect(DsBreakpoints.contentMaxWidth(700), 720);
      expect(DsBreakpoints.contentMaxWidth(1200), 960);
      expect(DsBreakpoints.contentMaxWidth(1600), 1200);
    });
  });

  group('DsBreakpoints context helpers', () {
    testWidgets('detects portrait and landscape orientation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: _BreakpointProbe(),
          ),
        ),
      );

      final state = tester.state<_BreakpointProbeState>(
        find.byType(_BreakpointProbe),
      );
      expect(state.isPortrait, isTrue);
      expect(state.isLandscape, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(900, 500)),
            child: _BreakpointProbe(),
          ),
        ),
      );

      final landscapeState = tester.state<_BreakpointProbeState>(
        find.byType(_BreakpointProbe),
      );
      expect(landscapeState.isPortrait, isFalse);
      expect(landscapeState.isLandscape, isTrue);
      expect(landscapeState.responsiveValue, 'tablet');
      expect(landscapeState.gridColumns, 2);
    });
  });
}

class _BreakpointProbe extends StatefulWidget {
  const _BreakpointProbe();

  @override
  State<_BreakpointProbe> createState() => _BreakpointProbeState();
}

class _BreakpointProbeState extends State<_BreakpointProbe> {
  bool isPortrait = false;
  bool isLandscape = false;
  String responsiveValue = '';
  int gridColumns = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isPortrait = DsBreakpoints.isPortrait(context);
    isLandscape = DsBreakpoints.isLandscape(context);
    responsiveValue = DsBreakpoints.of<String>(
      context,
      mobile: 'mobile',
      tablet: 'tablet',
      desktop: 'desktop',
    );
    gridColumns = DsBreakpoints.gridColumnsOf(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
