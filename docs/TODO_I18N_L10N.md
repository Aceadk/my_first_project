# TODO: Internationalization & Localization Module
**Priority:** P2 – Medium
**Estimated Effort:** 30-40 hours
**Dependencies:** ARB files (`lib/l10n/app_*.arb`), LocaleCubit
**Assigned:** AI + Developer

---

## I18N-001: Implement Full RTL Layout Support
**Files:** `lib/app.dart`, all screen/widget files with hardcoded directional values
**Description:** RTL support minimal — only 3 files reference `textDirection`. App supports Arabic and Urdu (RTL) but layouts not verified. Custom layouts using `EdgeInsets`, `Positioned.left/right`, swipe gestures may break in RTL.
**Acceptance Criteria:**
- [ ] All `EdgeInsets` replaced with `EdgeInsetsDirectional`
- [ ] All `Positioned(left/right)` replaced with `PositionedDirectional(start/end)`
- [ ] Swipe card: physical direction preserved (right=like regardless of text direction)
- [ ] Chat alignment: sent on end side, received on start side
- [ ] Navigation transitions use directionality-aware slides
- [ ] Full app tested in Arabic locale
**Testing:** Set locale to Arabic; screenshot comparison of all screens; widget tests with RTL wrapper.

---

## I18N-002: Add Text Expansion Testing and Overflow Prevention
**Files:** `lib/design_system/widgets/` (buttons, chips, app bar), all form screens
**Description:** No text expansion testing performed. German/Russian translations 30-40% longer than English. Buttons, chips, constrained containers are high-risk for overflow.
**Acceptance Criteria:**
- [ ] Pseudo-locale adding 40% length to all strings
- [ ] All buttons use `FittedBox` or `Flexible` with ellipsis
- [ ] App bar title supports multi-line or ellipsis
- [ ] German and Russian locales tested on critical screens
- [ ] No `RenderFlex overflowed` errors at 1.4x text length
**Testing:** Pseudo-locale automated screenshots; German/Russian manual testing.

---

## I18N-003: Verify Pluralization Rules for All 21 Languages
**Files:** `lib/l10n/app_*.arb` files
**Description:** Different languages have complex pluralization (Arabic: 6 forms, Russian: 3, CJK: none). All countable strings must use ICU `{count, plural, ...}` syntax with correct categories.
**Acceptance Criteria:**
- [ ] All countable strings use ICU plural syntax
- [ ] Arabic includes all 6 plural categories
- [ ] Russian includes 3 plural categories
- [ ] CJK uses `other` only
- [ ] Strings verified: "X messages", "X matches", "X likes", "X photos", "X km away"
**Testing:** Unit tests at boundary values (0, 1, 2, 5, 21, 100) for Arabic, Russian, Turkish, English.

---

## I18N-004: Implement Locale-Aware Date, Time, and Number Formatting
**Files:** Chat widgets, profile screens, analytics screens
**Description:** Date/time/number formatting must adapt to locale. Different date orders, 12h/24h, number separators, distance units.
**Acceptance Criteria:**
- [ ] Dates use `DateFormat.yMMMd(locale)`
- [ ] Times respect device 12h/24h setting
- [ ] Chat separators show locale-appropriate format
- [ ] Numbers use `NumberFormat.decimalPattern(locale)`
- [ ] Distance: km for metric, miles for US/UK
**Testing:** Unit tests for English, German, Arabic, Japanese formatting.

---

## I18N-005: Audit Hardcoded Strings and Missing Translations
**Files:** All presentation layer files
**Description:** Hardcoded English strings may exist instead of ARB references. Systematic audit needed.
**Acceptance Criteria:**
- [ ] Script flags string literals in widget `build()` methods
- [ ] All user-facing strings moved to `app_en.arb`
- [ ] All 21 ARB files updated with translations
- [ ] Semantic labels localized
- [ ] Error messages in ARB files
**Testing:** Run audit script; compare key counts across ARB files.

---

## I18N-006: Verify CJK Typography and Line Breaking
**Files:** `lib/design_system/tokens/typography.dart`, chat/profile screens
**Description:** CJK languages need: different font stacks, character-level line breaking, wider character widths, adjusted line height.
**Acceptance Criteria:**
- [ ] Font stack includes CJK-capable fallback fonts
- [ ] Line height works for CJK (1.5-1.8x)
- [ ] Chat bubbles wrap CJK at character boundaries
- [ ] CJK IME input works in all text fields
**Testing:** Manual testing in Chinese, Japanese, Korean locales.

---

## I18N-007: Verify Locale Switching UX
**Files:** `lib/features/settings/presentation/screens/language_region_settings_screen.dart`, `lib/features/settings/presentation/bloc/locale_cubit.dart`
**Description:** Verify locale switch: immediate effect, persistence, fallback for missing keys, language list UX.
**Acceptance Criteria:**
- [ ] Switch takes effect immediately (no restart)
- [ ] Selected locale persists across restarts
- [ ] Missing keys fall back to English gracefully
- [ ] Language list shows native names
- [ ] "Follow device language" option available
**Testing:** Switch between English, Arabic, Japanese, German; verify persistence after force-close.
