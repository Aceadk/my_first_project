# Onboarding UI Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Onboarding UI domain.

---

## OBU-001 · P1 · AppBar background uses light color in dark mode

**Files:** `login_screen.dart:69`, `sign_up_screen.dart:135`, `terms_conditions_screen.dart:110`

All three screens use `DsColors.backgroundLight.withValues(alpha: 0)` for AppBar background. While the alpha is 0 (transparent), this is fragile — if the alpha changes, it would be wrong in dark mode. Use `Colors.transparent` instead.

---

## OBU-002 · P1 · Terms & Conditions progress bar bg ignores dark mode

**File:** `terms_conditions_screen.dart:155`

`LinearProgressIndicator` uses `DsColors.skeletonLight` as `backgroundColor` regardless of theme. Should use `DsColors.skeletonDark` in dark mode (same issue exists in `_PasswordStrength` at `sign_up_screen.dart:1549`).

---

## OBU-003 · P2 · Terms/Privacy text is not tappable on auth gateway

**File:** `auth_gateway_screen.dart:320-328`

"By continuing, you agree to our Terms of Service and Privacy Policy" is plain `Text`. The terms and privacy policy links should be `RichText` with `TapGestureRecognizer` to open the actual legal documents (via `url_launcher` or a route).

---

## OBU-004 · P2 · T&C checkbox missing Semantics.checkbox role

**File:** `terms_conditions_screen.dart:309`

The agreement checkbox uses `Semantics(button: true)` but should use `Semantics(checked: _isAgreed, label: ...)` for screen readers to announce it as a checkbox, not a button.

---

## OBU-005 · P2 · Auth gateway wordmark uses hardcoded `Colors.white`

**File:** `auth_gateway_screen.dart:171`

The wordmark style sets `color: Colors.white`. While the `ShaderMask` paints over it, this is fragile. If the shader fails or is removed, the text would be invisible on light backgrounds.

---

## OBU-006 · P2 · Google button missing logo icon on both screens

**Files:** `auth_gateway_screen.dart:274`, `login_screen.dart:244`, `sign_up_screen.dart:182`

"Continue with Google" button has no icon — only text. Apple button correctly includes `Icons.apple`. Add a Google logo (SVG or asset) to match Apple's visual pattern.

---

## OBU-007 · P2 · Duplicate `Semantics` wrapper in login screen

**File:** `login_screen.dart:328-332`

The dev-mode test credentials panel wraps in `Semantics(button: true)` twice (nested). Remove the inner one.

---

## OBU-008 · P1 · Age gate dialog answers have no disabled state

**File:** `auth_gateway_screen.dart:442-460`

"No" and "Yes" buttons in the age gate have no loading state, and tapping "No" pops with `false` but doesn't explain _why_ the user can't proceed. Consider showing a brief message explaining the 18+ requirement when the user taps "No".

---

## OBU-009 · P2 · Password strength bar uses light-only bg color

**File:** `sign_up_screen.dart:1549`

`_PasswordStrength` uses `DsColors.skeletonLight` for the progress bar background. Should adapt to dark mode using `DsColors.skeletonDark`.

---

## OBU-010 · P1 · Sign-up AppBar back button has no Semantics label

**File:** `sign_up_screen.dart:137-141`

The AppBar back button uses `GlassIconButton` with `icon: Icons.arrow_back` but no `tooltip` or `Semantics.label` for accessibility. The basic_info_screen version correctly uses `Icons.arrow_back_ios_new_rounded` — these should be consistent.

---

## OBU-011 · P2 · Login screen icon uses hardcoded `DsColors.backgroundLight`

**File:** `login_screen.dart:106`

The heart icon in the login header uses `color: DsColors.backgroundLight` — this is fine as it's always on a gradient background, but it should use `Colors.white` for semantic clarity (it's not a background color, it's a foreground icon on a gradient).

---

## OBU-012 · P2 · `_EmailLinkStep` instructions panel lacks dark mode adaptation

**File:** `sign_up_screen.dart:1345`

The instructions container uses `DsColors.surfaceLight` in light mode, which is correct. But the warning box inside uses `DsColors.warning` text — this contrast is fine in both modes but should be verified. The instruction numbers also use hardcoded `DsColors.primary` which is fine.

---

## OBU-013 · P2 · T&C checkbox unchecked bg uses backgroundLight with alpha 0

**File:** `terms_conditions_screen.dart:345`

When unchecked, the checkbox background uses `DsColors.backgroundLight.withValues(alpha: 0)`. Should simply use `Colors.transparent`.

---

## OBU-014 · P2 · Feature rows on auth gateway not localized

**File:** `auth_gateway_screen.dart:207-221`

Feature highlight texts ("Verified profiles for safety", "Send messages before matching", "Meet people near you") are hardcoded strings. These should use `AppLocalizations` keys.
