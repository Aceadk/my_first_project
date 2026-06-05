/// Pure keyboard-semantics policy for the chat composer (CHAT-UI-002).
///
/// Decides what an Enter key event should do given the modifier state and the
/// event phase. Kept free of Flutter widget dependencies so the
/// hardware-keyboard contract (Enter sends, Shift+Enter inserts a newline, a
/// held Enter does not spam-send) is exhaustively unit-testable.
library;

/// What the composer should do in response to an Enter key event.
enum ChatComposerKeyAction {
  /// Submit the current message.
  send,

  /// Insert a line break (let the text field handle it).
  insertNewline,

  /// Do nothing, but consume the event so the field does not insert a stray
  /// newline (used for key-repeat / key-up of a plain Enter).
  ignore,
}

/// Resolves Enter-key handling for the composer.
class ChatComposerKeyboard {
  const ChatComposerKeyboard._();

  /// Resolve the action for an Enter / numpad-Enter key event.
  ///
  /// - **Shift+Enter** inserts a newline on the initial press and on repeat
  ///   (so holding it adds multiple lines), and is ignored on key-up.
  /// - **Plain Enter** sends, but only on the initial key-down — never on
  ///   repeat — so holding Enter cannot fire a burst of duplicate sends. Its
  ///   repeat/up phases are [ignore]d (consumed) to suppress a stray newline.
  static ChatComposerKeyAction actionForEnter({
    required bool isKeyDown,
    required bool isKeyRepeat,
    required bool isShiftPressed,
  }) {
    if (isShiftPressed) {
      return (isKeyDown || isKeyRepeat)
          ? ChatComposerKeyAction.insertNewline
          : ChatComposerKeyAction.ignore;
    }
    return isKeyDown ? ChatComposerKeyAction.send : ChatComposerKeyAction.ignore;
  }
}
