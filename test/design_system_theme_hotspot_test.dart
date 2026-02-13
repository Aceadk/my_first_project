import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crushhour/design_system/theme/app_theme.dart';
import 'package:crushhour/design_system/theme/theme_extensions.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/luxury.dart';
import 'package:crushhour/design_system/tokens/typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return Directory.systemTemp.path;
          }
          return Directory.systemTemp.path;
        });

    final fixtureUrls = <String, String>{
      'https://fonts.gstatic.com/s/a/1306435ed883e4a1e6dad370e6d035955da71f4df9c07ca192833f7cb58a18d7.ttf':
          'test/fixtures/google_fonts/PlusJakartaSans-Regular.ttf',
      'https://fonts.gstatic.com/s/a/8590ab94f96850ab246d5795a9ba442e42f64036673bc329573dfe93efbc7c87.ttf':
          'test/fixtures/google_fonts/PlusJakartaSans-SemiBold.ttf',
      'https://fonts.gstatic.com/s/a/775cd3f92411b97cc374e0d8909c5caf3713508120866dc62b08f7a20213ba6d.ttf':
          'test/fixtures/google_fonts/PlayfairDisplay-Regular.ttf',
      'https://fonts.gstatic.com/s/a/9d28ec9ef0160652a7f0c9a1be5a55361b9f5249e8da1ad0b81916dbf1fee7e5.ttf':
          'test/fixtures/google_fonts/PlayfairDisplay-SemiBold.ttf',
    };
    final fixtureBytes = fixtureUrls.map(
      (url, path) => MapEntry(url, File(path).readAsBytesSync()),
    );

    google_fonts_base.httpClient = MockClient((request) async {
      final bytes = fixtureBytes[request.url.toString()];
      if (bytes == null) return http.Response('missing fixture', 404);
      return http.Response.bytes(bytes, 200);
    });
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  tearDown(() async {
    await GoogleFonts.pendingFonts();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('DsTypography', () {
    test('font families are available', () async {
      expect(DsTypography.bodyFontFamily, isNotEmpty);
      expect(DsTypography.displayFontFamily, isNotEmpty);
      expect(
        DsTypography.bodyFontFamily,
        isNot(equals(DsTypography.displayFontFamily)),
      );
      await GoogleFonts.pendingFonts();
    });

    test(
      'builds light and dark text themes with expected semantic colors',
      () async {
        final light = DsTypography.textTheme(isDark: false);
        final dark = DsTypography.textTheme(isDark: true);

        expect(light.displayLarge?.color, DsColors.textPrimaryLight);
        expect(light.bodySmall?.color, DsColors.textMutedLight);
        expect(dark.displayLarge?.color, DsColors.textPrimaryDark);
        expect(dark.bodySmall?.color, DsColors.textMutedDark);

        expect(light.displayLarge?.fontWeight, FontWeight.w600);
        expect(light.displayMedium?.fontWeight, FontWeight.w600);
        expect(light.displaySmall?.fontWeight, FontWeight.w600);
        await GoogleFonts.pendingFonts();
      },
    );

    test('builds luxury text theme with premium weight overrides', () async {
      final luxury = DsTypography.luxuryTextTheme();

      expect(luxury.displayLarge?.fontWeight, FontWeight.w700);
      expect(luxury.displayMedium?.fontWeight, FontWeight.w700);
      expect(luxury.displaySmall?.fontWeight, FontWeight.w700);
      expect(luxury.titleLarge?.fontWeight, FontWeight.w700);
      expect(luxury.labelLarge?.fontWeight, FontWeight.w700);
      await GoogleFonts.pendingFonts();
    });
  });

  group('AppTheme', () {
    test('light theme uses expected palette and extension', () async {
      final theme = AppTheme.light();
      final effects = theme.extension<CrushThemeEffects>();

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, DsColors.primary);
      expect(theme.colorScheme.surface, DsColors.surfaceLight);
      expect(theme.scaffoldBackgroundColor, DsColors.backgroundLight);
      expect(theme.iconTheme.color, DsColors.textPrimaryLight);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        DsTypography.bodyFontFamily,
      );
      expect(effects, isNotNull);
      expect(effects!.glassSurface, DsGlassColors.surfaceLight);
      expect(effects.glassBorder, DsGlassColors.borderLight);
      expect(effects.motionScale, 1.0);
      await GoogleFonts.pendingFonts();
    });

    test('dark theme uses expected palette and extension', () async {
      final theme = AppTheme.dark();
      final effects = theme.extension<CrushThemeEffects>();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, DsColors.primary);
      expect(theme.colorScheme.surface, DsColors.surfaceDark);
      expect(theme.scaffoldBackgroundColor, DsColors.backgroundDark);
      expect(theme.iconTheme.color, DsColors.textPrimaryDark);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        DsTypography.bodyFontFamily,
      );
      expect(effects, isNotNull);
      expect(effects!.glassSurface, DsGlassColors.surfaceDark);
      expect(effects.glassBorder, DsGlassColors.borderDark);
      expect(effects.shadowOpacity, 0.2);
      await GoogleFonts.pendingFonts();
    });

    test('darkLuxury delegates to darkLuxuryClassic', () async {
      final luxury = AppTheme.darkLuxury();
      final classic = AppTheme.darkLuxuryClassic();

      expect(luxury.brightness, Brightness.dark);
      expect(luxury.colorScheme.primary, classic.colorScheme.primary);
      expect(luxury.scaffoldBackgroundColor, classic.scaffoldBackgroundColor);
      expect(
        luxury.textTheme.displayLarge?.fontWeight,
        classic.textTheme.displayLarge?.fontWeight,
      );
      expect(
        luxury.extension<CrushThemeEffects>()?.glowColor,
        classic.extension<CrushThemeEffects>()?.glowColor,
      );
      await GoogleFonts.pendingFonts();
    });

    test('darkLuxuryClassic uses classic luxury tokens', () async {
      final theme = AppTheme.darkLuxuryClassic();
      final effects = theme.extension<CrushThemeEffects>();

      expect(theme.colorScheme.primary, DsLuxuryColors.goldPrimary);
      expect(theme.colorScheme.surface, DsLuxuryColors.surface);
      expect(theme.scaffoldBackgroundColor, DsLuxuryColors.background);
      expect(theme.iconTheme.color, DsLuxuryColors.iconPrimary);
      expect(
        theme.snackBarTheme.backgroundColor,
        DsLuxuryColors.surfaceElevated,
      );
      expect(effects, isNotNull);
      expect(effects!.glassSurface, DsLuxuryColors.glass);
      expect(effects.glassBorder, DsLuxuryColors.glassBorder);
      expect(effects.motionScale, 1.2);
      await GoogleFonts.pendingFonts();
    });

    test('darkLuxuryModern uses modern luxury tokens', () async {
      final theme = AppTheme.darkLuxuryModern();
      final effects = theme.extension<CrushThemeEffects>();

      expect(theme.colorScheme.primary, DsLuxuryModernColors.goldPrimary);
      expect(theme.colorScheme.surface, DsLuxuryModernColors.surface);
      expect(theme.scaffoldBackgroundColor, DsLuxuryModernColors.background);
      expect(theme.iconTheme.color, DsLuxuryModernColors.iconPrimary);
      expect(
        theme.snackBarTheme.backgroundColor,
        DsLuxuryModernColors.surfaceElevated,
      );
      expect(effects, isNotNull);
      expect(effects!.glassSurface, DsLuxuryModernColors.glass);
      expect(effects.glassBorder, DsLuxuryModernColors.glassBorder);
      expect(effects.motionScale, 1.2);
      await GoogleFonts.pendingFonts();
    });
  });

  group('DsGlassColors', () {
    test('surface and border map by brightness', () {
      expect(
        DsGlassColors.surface(Brightness.light),
        DsGlassColors.surfaceLight,
      );
      expect(DsGlassColors.surface(Brightness.dark), DsGlassColors.surfaceDark);
      expect(DsGlassColors.border(Brightness.light), DsGlassColors.borderLight);
      expect(DsGlassColors.border(Brightness.dark), DsGlassColors.borderDark);
    });

    testWidgets('surfaceFor and borderFor use effects extension when present', (
      tester,
    ) async {
      Color? lightSurface;
      Color? mediumSurface;
      Color? heavySurface;
      Color? border;
      Color? highlight;
      Color? strongHighlight;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkLuxuryClassic(),
          home: Builder(
            builder: (context) {
              lightSurface = DsGlassColors.surfaceFor(context);
              mediumSurface = DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.medium,
              );
              heavySurface = DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.heavy,
              );
              border = DsGlassColors.borderFor(context);
              highlight = DsGlassColors.highlightFor(context);
              strongHighlight = DsGlassColors.highlightFor(
                context,
                strong: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(lightSurface, DsLuxuryColors.glass);
      expect(mediumSurface, isNot(equals(DsLuxuryColors.glass)));
      expect(heavySurface, isNot(equals(DsLuxuryColors.glass)));
      expect(border, DsLuxuryColors.glassBorder);
      expect(highlight, DsLuxuryColors.glowGold.withValues(alpha: 0.32));
      expect(strongHighlight, DsLuxuryColors.glowGold.withValues(alpha: 0.5));
    });

    testWidgets('surfaceFor and highlightFor fallback without extension', (
      tester,
    ) async {
      Color? lightSurface;
      Color? mediumSurface;
      Color? heavySurface;
      Color? border;
      Color? normalHighlight;
      Color? strongHighlight;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              lightSurface = DsGlassColors.surfaceFor(context);
              mediumSurface = DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.medium,
              );
              heavySurface = DsGlassColors.surfaceFor(
                context,
                strength: DsGlassSurfaceStrength.heavy,
              );
              border = DsGlassColors.borderFor(context);
              normalHighlight = DsGlassColors.highlightFor(context);
              strongHighlight = DsGlassColors.highlightFor(
                context,
                strong: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(lightSurface, DsGlassColors.surfaceDark);
      expect(mediumSurface, DsGlassColors.surfaceMediumDark);
      expect(heavySurface, DsGlassColors.surfaceHeavyDark);
      expect(border, DsGlassColors.borderDark);
      expect(normalHighlight, DsGlassColors.highlight);
      expect(strongHighlight, DsGlassColors.highlightStrong);
    });
  });
}
