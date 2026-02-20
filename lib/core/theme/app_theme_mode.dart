enum AppThemeMode { system, light, dark, darkLuxury, darkLuxuryModern }

extension AppThemeModeX on AppThemeMode {
  bool get isLuxury =>
      this == AppThemeMode.darkLuxury || this == AppThemeMode.darkLuxuryModern;

  String get storageKey {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.darkLuxury:
        return 'luxury';
      case AppThemeMode.darkLuxuryModern:
        return 'luxury_modern';
      case AppThemeMode.system:
        return 'system';
    }
  }
}

AppThemeMode appThemeModeFromKey(String? value) {
  switch (value) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    case 'luxury':
    case 'luxury_classic':
    case 'dark_luxury':
    case 'darkLuxury':
    case 'royal':
    case 'classic':
      return AppThemeMode.darkLuxury;
    case 'luxury_modern':
    case 'modern':
    case 'modern_luxury':
    case 'darkLuxuryModern':
      return AppThemeMode.darkLuxuryModern;
    case 'system':
    default:
      return AppThemeMode.system;
  }
}
