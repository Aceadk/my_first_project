import 'package:flutter/foundation.dart';

import 'app_logger.dart';

enum AppEnv {
  dev,
  prod,
}

class AppEnvConfig {
  static const String _envRaw =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  static final AppEnv env = _parse(_envRaw);
  static bool _loggedBypass = false;

  static bool get isDev => !kReleaseMode && env == AppEnv.dev;
  static bool get isProd => !isDev;
  static bool get bypassVerification => isDev;

  static void logBypassIfActive() {
    if (!bypassVerification || _loggedBypass) return;
    _loggedBypass = true;
    AppLogger.logInfo('DEV mode: auth verification bypass is active.');
  }

  static AppEnv _parse(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'dev' || normalized == 'development') {
      return AppEnv.dev;
    }
    return AppEnv.prod;
  }
}
