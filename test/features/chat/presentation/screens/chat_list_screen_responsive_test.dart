import 'package:crushhour/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatUsesSplitView', () {
    test('phone widths use single-column push navigation', () {
      expect(chatUsesSplitView(390), isFalse);
      expect(chatUsesSplitView(599), isFalse);
    });

    test('tablet and desktop widths use master-detail split view', () {
      expect(chatUsesSplitView(600), isTrue);
      expect(chatUsesSplitView(834), isTrue);
      expect(chatUsesSplitView(1440), isTrue);
    });
  });

  group('chatListPaneWidthFor', () {
    test('uses tablet min width floor at the tablet breakpoint', () {
      expect(chatListPaneWidthFor(600), 300);
    });

    test('scales within tablet range before desktop breakpoint', () {
      expect(chatListPaneWidthFor(834), closeTo(300.24, 0.001));
      expect(chatListPaneWidthFor(1000), 360);
    });

    test('uses desktop floor and cap on wide layouts', () {
      expect(chatListPaneWidthFor(1024), 340);
      expect(chatListPaneWidthFor(1366), closeTo(437.12, 0.001));
      expect(chatListPaneWidthFor(1920), 460);
    });
  });
}
