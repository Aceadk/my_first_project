import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static void logInfo(String message) {
    developer.log(message, name: 'CrushHour');
    debugPrint(message);
  }

  static void logError(String context, Object error, [StackTrace? stackTrace]) {
    final message = '$context: $error';
    developer.log(
      message,
      name: 'CrushHour',
      error: error,
      stackTrace: stackTrace,
    );
    debugPrint(message);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
