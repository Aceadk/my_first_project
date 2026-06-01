import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/utils/accessibility.dart' as ds;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A11Y-003 — design-token contrast audit.
///
/// Codifies the WCAG 2.1 contrast guarantees of the design-system color tokens
/// so that a token regression (e.g. lightening a muted text color) fails CI
/// instead of silently shipping an unreadable combination. Ratios are computed
/// with [ds.DsAccessibility.contrastRatio], which uses the WCAG relative
/// luminance formula.
void main() {
  double ratio(Color fg, Color bg) =>
      ds.DsAccessibility.contrastRatio(fg, bg);

  // The minimum contrast for normal body text (WCAG AA).
  const aaNormal = ds.DsAccessibility.contrastAA; // 4.5:1
  // The minimum contrast for large/bold text and UI component boundaries.
  const aaLarge = ds.DsAccessibility.contrastAALarge; // 3.0:1

  group('A11Y-003 design token contrast', () {
    test('primary body text meets AA on every base surface', () {
      // Light theme.
      expect(
        ratio(DsColors.textPrimaryLight, DsColors.backgroundLight),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textPrimaryLight, DsColors.surfaceLight),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textPrimaryLight, DsColors.surfaceElevatedLight),
        greaterThanOrEqualTo(aaNormal),
      );

      // Dark theme.
      expect(
        ratio(DsColors.textPrimaryDark, DsColors.backgroundDark),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textPrimaryDark, DsColors.surfaceDark),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textPrimaryDark, DsColors.surfaceElevatedDark),
        greaterThanOrEqualTo(aaNormal),
      );
    });

    test('muted/secondary text meets AA on its theme surface', () {
      expect(
        ratio(DsColors.textMutedLight, DsColors.backgroundLight),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textMutedLight, DsColors.surfaceLight),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textMutedDark, DsColors.backgroundDark),
        greaterThanOrEqualTo(aaNormal),
      );
      expect(
        ratio(DsColors.textMutedDark, DsColors.surfaceDark),
        greaterThanOrEqualTo(aaNormal),
      );
    });

    test('accessibleTextColor clears normal-text AA on every brand/status fill', () {
      // Regression guard for the mid-tone bug: a fixed 0.5 luminance cutoff
      // mis-picked white for the success/mint token (2.16:1). The fixed helper
      // chooses the higher-contrast ink/paper, which clears AA on all fills.
      for (final bg in <Color>[
        DsColors.primary,
        DsColors.primaryDark,
        DsColors.secondary,
        DsColors.accent,
        DsColors.backgroundLight,
        DsColors.backgroundDark,
        DsColors.error,
        DsColors.success,
        DsColors.warning,
        DsColors.info,
      ]) {
        final fg = ds.DsAccessibility.accessibleTextColor(bg);
        expect(
          ratio(fg, bg),
          greaterThanOrEqualTo(aaNormal),
          reason: 'accessibleTextColor on $bg should clear normal-text AA',
        );
      }
    });

    test('filled-button foregrounds clear large-text AA on brand fills', () {
      // White-on-brand is the default FilledButton pairing across the app.
      // Brand rose/plum/mint are saturated mid-tones, so they are validated at
      // the large/bold threshold (3.0:1) — the size FilledButton labels use.
      expect(
        ratio(Colors.white, DsColors.primary),
        greaterThanOrEqualTo(aaLarge),
      );
      expect(
        ratio(Colors.white, DsColors.secondary),
        greaterThanOrEqualTo(aaLarge),
      );
      expect(
        ratio(Colors.white, DsColors.primaryDark),
        greaterThanOrEqualTo(aaLarge),
      );
    });

    test('error is usable as large/bold text on a light surface', () {
      // error is the only status token used directly as text (destructive
      // actions, e.g. the account-actions delete row). At 3.03:1 it clears the
      // large/bold threshold, so it must only be used at >=18px or bold.
      expect(
        ratio(DsColors.error, DsColors.surfaceLight),
        greaterThanOrEqualTo(aaLarge),
      );
    });

    test('light status tokens carry dark text rather than acting as text', () {
      // success/warning/info are light accent hues (2.16/1.75/2.25 on white),
      // so they must be used as chip/icon FILLS with dark text on top — never
      // as light text on a light surface.
      for (final status in <Color>[
        DsColors.success,
        DsColors.warning,
        DsColors.info,
      ]) {
        expect(
          ratio(Colors.black, status),
          greaterThanOrEqualTo(aaNormal),
          reason: 'dark text on $status should clear normal-text AA',
        );
      }
    });

    test('online vs offline indicators are distinguishable from each other', () {
      // Color-independence is enforced in the UI (labels/icons), but the dots
      // should still be perceptibly different hues for low-vision users.
      expect(
        ratio(DsColors.onlineIndicator, DsColors.offlineIndicator),
        greaterThan(1.5),
      );
    });
  });
}
