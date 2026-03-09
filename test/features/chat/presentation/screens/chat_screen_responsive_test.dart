import 'package:crushhour/features/chat/presentation/screens/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatConversationMaxWidthFor', () {
    test('maps to shared breakpoint max widths', () {
      expect(chatConversationMaxWidthFor(390), double.infinity);
      expect(chatConversationMaxWidthFor(820), 720);
      expect(chatConversationMaxWidthFor(1200), 960);
    });
  });
}
