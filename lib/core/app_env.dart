import 'package:flutter/foundation.dart';
import 'package:crushhour/config/app_config.dart';

import 'app_logger.dart';

enum AppEnv { dev, prod }

AppEnv resolveAppEnvForFlavor(String flavor) {
  final normalized = flavor.trim().toLowerCase();
  if (normalized == 'development' || normalized == 'dev') {
    return AppEnv.dev;
  }
  return AppEnv.prod;
}

class AppEnvConfig {
  static final AppEnv env = resolveAppEnvForFlavor(AppConfig.flavor);
  static bool _loggedBypass = false;

  static bool get isDev => !kReleaseMode && env == AppEnv.dev;
  static bool get isProd => !isDev;
  static bool get bypassVerification => isDev;

  static void logBypassIfActive() {
    if (!bypassVerification || _loggedBypass) return;
    _loggedBypass = true;
    AppLogger.info('DEV mode: auth verification bypass is active.');
  }
}
