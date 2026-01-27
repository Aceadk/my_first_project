enum AppThemeMode {
  system,
  light,
  dark,
  darkLuxury,
}

extension AppThemeModeX on AppThemeMode {
  bool get isLuxury => this == AppThemeMode.darkLuxury;

  String get storageKey {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.darkLuxury:
        return 'luxury';
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
    case 'dark_luxury':
    case 'darkLuxury':
      return AppThemeMode.darkLuxury;
    case 'system':
    default:
      return AppThemeMode.system;
  }
}

