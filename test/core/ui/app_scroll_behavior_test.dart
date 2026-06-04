import 'package:crushhour/core/ui/app_scroll_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppScrollBehavior', () {
    test('enables mouse and stylus drag so pointer users can scroll', () {
      const behavior = AppScrollBehavior();

      // The default MaterialScrollBehavior omits mouse; pointer users on web /
      // desktop / tablet must be able to click-and-drag to scroll (RESP-003).
      expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
      expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
      expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
      expect(behavior.dragDevices, contains(PointerDeviceKind.stylus));
    });

    testWidgets('a list scrolls via mouse click-and-drag', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: const AppScrollBehavior(),
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (_, i) => Text('item $i'),
            ),
          ),
        ),
      );

      expect(controller.offset, 0);

      // Drag with a mouse pointer; without mouse in dragDevices this is a no-op.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, -200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
    });
  });
}
