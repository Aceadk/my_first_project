import 'dart:async';

import 'package:flutter/services.dart';

/// Secure clipboard manager that auto-clears copied content after a timeout.
///
/// Prevents sensitive data (messages, profile info) from persisting
/// in the device clipboard indefinitely.
class SecureClipboard {
  SecureClipboard._();

  static Timer? _clearTimer;

  /// Duration before clipboard is automatically cleared.
  static const Duration clearDelay = Duration(seconds: 60);

  /// Copy text to clipboard with automatic clearing after [clearDelay].
  ///
  /// Returns `true` if the copy succeeded.
  /// Any previous clear timer is cancelled and restarted.
  static Future<bool> copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      // Cancel any existing timer and start a new one
      _clearTimer?.cancel();
      _clearTimer = Timer(clearDelay, clear);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear the clipboard contents immediately.
  static void clear() {
    _clearTimer?.cancel();
    _clearTimer = null;
    Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Cancel the auto-clear timer without clearing clipboard.
  static void cancelTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
