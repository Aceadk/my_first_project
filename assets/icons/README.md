# Crush App Icons

Add your app icon images to this directory:

## Required Files

1. **app_icon.png** (1024x1024 pixels)
   - The main app icon
   - Text-only branding: "Crush" (no heart, no extra symbol)
   - Use the app's brand palette (primary/secondary)
   - Dark background (#0D0E12) recommended

2. **app_icon_foreground.png** (1024x1024 pixels)
   - Foreground layer for Android adaptive icons
   - Text-only logo with transparent background
   - This will be placed over the adaptive_icon_background color (#0D0E12)

3. **launch_wordmark.png** (840x270 pixels)
   - Wordmark used for native launch screens (Android/iOS)
   - Text-only logo with transparent background
   - Should match the in-app splash wordmark

## Generating Icons

Generate the text-only icons and launch wordmark with the helper script:

```bash
dart run tool/generate_app_icons.dart
```

Then run:

```bash
cd /Users/ace/Desktop/my_first_project
dart run flutter_launcher_icons
```

This will generate all required icon sizes for both Android and iOS.

## Design Guidelines

- **Android**: Adaptive icons use a foreground (logo text) over a background (color)
- **iOS**: Uses the full app_icon.png (no transparency allowed)
- Keep important content within the safe zone (center 66% of the icon)
- Avoid fine details that may not be visible at small sizes
