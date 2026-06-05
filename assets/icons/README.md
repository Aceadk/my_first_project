# Crush App Icons

Add the source logo images to this directory, then regenerate the derived
platform assets.

## Required Files

1. **app_icon.png** (square, 1024px or larger recommended)
   - Main launcher, PWA, social preview, macOS, and Windows icon source.
   - Use a dark background that blends with #0D0E12.

2. **app_icon_foreground.png** (1024x1024 pixels)
   - Foreground layer for Android adaptive icons.
   - Keep important artwork inside the adaptive icon safe zone.

3. **launch_wordmark.png** (wide transparent PNG)
   - Compact mark used for native Android/iOS launch screens.
   - The generator resizes it to 1x/2x/3x native launch assets.

4. **splash_screen.png** (portrait PNG)
   - Full Flutter splash-screen artwork bundled at runtime.
   - Keep the central logo readable on mobile and iPad; wide web/tablet layouts
     display it contained against the dark background.

## Generating Icons

Generate web, macOS, Windows, and native launch images:

```bash
dart run tool/generate_app_icons.dart
```

Then generate Android and iOS/iPad launcher icons:

```bash
dart run flutter_launcher_icons
```

## Design Guidelines

- **Android**: Adaptive icons use `app_icon_foreground.png` over #0D0E12.
- **iOS/iPad**: Uses `app_icon.png`; iOS icons cannot retain alpha.
- **Web**: Uses generated `web/favicon.png` and `web/icons/*`.
- **Splash**: Native launch screens use `launch_wordmark.png`; the Flutter
  splash route uses `splash_screen.png`.
- Keep important icon content inside the safe zone (center 66% of the icon).
- Avoid fine details that may not be visible at small sizes
