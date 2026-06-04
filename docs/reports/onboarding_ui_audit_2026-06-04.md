# Onboarding UI Audit - 2026-06-04

Scope: `ONBOARD-UI-001`–`ONBOARD-UI-003` from
[`docs/TODO_ONBOARDING_UI.md`](../TODO_ONBOARDING_UI.md).

Surfaces reviewed: the onboarding step flow (terms → basic info → profile setup →
email verification, plus phone/OTP verification) and the shared onboarding
widgets ([`onboarding_progress.dart`](../../lib/presentation/widgets/onboarding_progress.dart),
[`onboarding_nav_buttons.dart`](../../lib/presentation/widgets/onboarding_nav_buttons.dart)),
which sit on top of [`AuthScaffold`](../../lib/design_system/widgets/auth_scaffold.dart).

## Result

Width/navigation were already solid; the audit found and **fixed two real
issues** — a header that overflowed at large text scale, and onboarding form
fields that didn't chain the soft-keyboard action.

Legend: ✅ verified · 🔧 fixed · ⚠️ tracked.

---

## ONBOARD-UI-001 - Large-screen layout (iPad/tablet/web)

Status: ✅ verified

- Onboarding steps render through `AuthScaffold`, which caps body width via
  `DsBreakpoints` (tablet/desktop max widths) and centers content — so steps are
  intentional on large screens, not stretched phone layouts.
- Steps with bespoke layouts (`basic_info`) additionally wrap content in
  `ConstrainedBox(maxWidth: DsBreakpoints.responsiveValue(...))`.
- Covered by the existing `terms_conditions_screen_responsive_test` and
  `profile_setup_screen_keyboard_overflow_test`.

## ONBOARD-UI-002 - Keyboard, focus, and external input

Status: 🔧 fixed field focus chaining

- 🔧 **Fixed — soft-keyboard field traversal.** The three text fields in
  [`basic_info_screen.dart`](../../lib/features/auth/presentation/screens/basic_info_screen.dart)
  (username, first name, last name) set no `textInputAction`, so the on-screen
  keyboard showed a generic action that didn't advance between fields. Added
  `FocusNode`s plus `TextInputAction.next` → `next` → `done` with
  `onSubmitted` focus hand-off (and `TextCapitalization.words` on the name
  fields). Focus nodes are disposed. Covered by
  [`basic_info_screen_focus_test.dart`](../../test/features/auth/presentation/screens/basic_info_screen_focus_test.dart).
- ✅ **Keyboard avoidance** is handled by the scaffolds' resize behavior
  (verified for profile setup via its keyboard-overflow test). Hardware-keyboard
  Tab traversal uses Flutter's default focus order.

## ONBOARD-UI-003 - Large-text, RTL, localization resilience

Status: 🔧 fixed header overflow

- 🔧 **Fixed — progress header overflow.** `OnboardingProgress` laid out the
  "Step X of Y" counter as a non-flexible `Text` beside the step name, so at
  **2× text scale** on a narrow viewport the header `Row` overflowed
  (37 px without Skip, 166 px with Skip — reproduced by a new test). Combined the
  counter and step name into a single `Text.rich` inside an `Expanded` with
  `TextOverflow.ellipsis`, which both prevents overflow (it truncates) and keeps
  "Skip" pinned to the trailing edge. Covered by
  [`onboarding_progress_text_scale_test.dart`](../../test/presentation/widgets/onboarding_progress_text_scale_test.dart).
- ⚠️ **Tracked (belongs to I18N):** `OnboardingProgress` step names
  (`'Welcome'`, `'Verify phone'`, …) and `OnboardingNavButtons` default labels
  (`'Next'`, `'Previous'`) are hardcoded English, so they currently can't take
  long translations. Real localization of these strings is an `I18N_L10N` task,
  not a layout fix; the overflow hardening above is forward-compatible with
  longer translated strings.

---

## Changed files

- `lib/presentation/widgets/onboarding_progress.dart` (overflow fix)
- `lib/features/auth/presentation/screens/basic_info_screen.dart` (focus chaining)
- `test/presentation/widgets/onboarding_progress_text_scale_test.dart` (new)
- `test/features/auth/presentation/screens/basic_info_screen_focus_test.dart` (new)

## Verification

- `flutter analyze` on changed files — clean.
- `flutter test` (2 new tests + onboarding google-button layout, profile-setup keyboard, terms responsive) — 13 passing, no regressions.
- ⚠️ Manual hardware-keyboard + RTL + on-device 200% text sweep of the full onboarding flow remains a release-gate item.
