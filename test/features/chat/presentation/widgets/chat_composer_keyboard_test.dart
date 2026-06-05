import 'package:crushhour/features/chat/presentation/widgets/chat_composer_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// CHAT-UI-002 — Enter/Shift+Enter/key-repeat semantics for the composer.
void main() {
  group('ChatComposerKeyboard.actionForEnter', () {
    test('plain Enter key-down sends', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: true,
          isKeyRepeat: false,
          isShiftPressed: false,
        ),
        ChatComposerKeyAction.send,
      );
    });

    test('held plain Enter (repeat) does not spam-send; it is consumed', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: false,
          isKeyRepeat: true,
          isShiftPressed: false,
        ),
        ChatComposerKeyAction.ignore,
      );
    });

    test('plain Enter key-up is consumed (no stray newline)', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: false,
          isKeyRepeat: false,
          isShiftPressed: false,
        ),
        ChatComposerKeyAction.ignore,
      );
    });

    test('Shift+Enter inserts a newline on key-down', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: true,
          isKeyRepeat: false,
          isShiftPressed: true,
        ),
        ChatComposerKeyAction.insertNewline,
      );
    });

    test('held Shift+Enter (repeat) keeps inserting newlines', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: false,
          isKeyRepeat: true,
          isShiftPressed: true,
        ),
        ChatComposerKeyAction.insertNewline,
      );
    });

    test('Shift+Enter key-up is ignored', () {
      expect(
        ChatComposerKeyboard.actionForEnter(
          isKeyDown: false,
          isKeyRepeat: false,
          isShiftPressed: true,
        ),
        ChatComposerKeyAction.ignore,
      );
    });
  });
}
