# TODO: Internationalization & Localization

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ACCESSIBILITY.md`, `docs/TODO_ONBOARDING_UI.md`
- Assigned: AI + Developer

## Tasks

### I18N-001 - Remove remaining hardcoded user-facing strings
- Files: mobile and web UI presentation layers, shared helpers
- Description: Audit the remaining hardcoded strings and move them into localization resources with stable keys.
- Acceptance Criteria: critical flows have no hardcoded user-facing copy outside approved exception lists.
- Testing: localization extraction audit and targeted UI spot checks.
- Status: in progress (2026-06-05). Localized onboarding progress/nav widgets, 6 critical-flow files (phone_protection, change_email, subscription_settings, paywall, chat_input_bar, privacy_settings), and **fully localized `safety_screen.dart`** (~78 strings incl. a `{count, plural}` + `{name}`/`{date}` placeholders; zero hardcoded strings remain — verified by `safety_l10n_keys_test.dart`). **Fully localized the calls feature** (incoming-call, PiP overlay, `call_screen` connection-state machine, `call_history` with `l10n` threaded through its group/status helpers) via new `call*` keys + `{seconds}`/`{duration}` placeholders; `calls_l10n_keys_test.dart` covers them. **(2026-06-05)** Resolved the legacy-settings open item: `presentation/screens/home/settings_screen.dart` was confirmed **dead code** (zero references; router uses `features/settings/.../settings_screen.dart`) and **deleted** (its only reference, in `brand_copy_case_regression_test.dart`, was removed). **Fully localized `auth/.../change_email_screen.dart`** (~20 strings: title, intro, current-email `{email}` placeholder, field labels/helpers, validation, password-verify dialog, and all result/snackbar copy) via ~15 new `auth*` keys (reusing `authVerificationCode`/`authSendCode`/`authEnterCodeHint`/`authCurrentPassword`/`errorInvalidEmail`); covered by `test/features/auth/change_email_l10n_keys_test.dart`. **Regenerated the stale `hardcoded_strings.txt`** (it was a pre-localization snapshot listing already-localized files) into an honest UI-only scan, with auth the largest remaining bucket. **(2026-06-05, cont.) Fully localized two more email/code-verification auth screens — `email_protection_screen.dart` and `new_device_screen.dart`** (verified/locked states, intros, field labels/helpers, validation, all result/snackbar copy) reusing the change_email keys plus ~17 new `auth*` keys (and `onboardingBasicInfoUsernameFormatError`); covered by `test/features/auth/email_verification_screens_l10n_keys_test.dart` (45 auth tests green). Rescan: UI literals **~135 (~102 shipped); auth/screens 34→27**. **Still open/tracked:** the rest of the auth long tail (phone_protection, email_auth, otp, sign_up, login form fields) and smaller settings/profile/discovery copy. **Approved exceptions:** `dev/widget_catalog/*` (dev tool), `video_call_screen.dart` (dev stub), call-history `_timeAgo` compact units, masked/format placeholders (`••••••••`/`+1`/`you@example.com`), long-form legal screens. All major user-facing flows are now localized. Report: `docs/reports/i18n_l10n_audit_2026-06-04.md`.

### I18N-002 - Verify RTL, locale formatting, and text expansion resilience
- Files: localized strings, date/number formatters, mirrored layouts
- Description: Ensure RTL layouts, locale-aware formatters, and long translations do not break major screens.
- Acceptance Criteria: RTL and long-string hotspots are tested and tracked; locale formatting is consistent.
- Testing: widget/manual checks with Arabic/Hebrew and long-language pseudolocales.
- Status: done (2026-06-04). Verified RTL-aware layout: 0 non-directional `EdgeInsets.only(left/right)` in features/presentation vs 108 `EdgeInsetsDirectional` + 130 `AlignmentDirectional`; `intl` `DateFormat` used with active locale; `ar`/`ur` + `en_XA` pseudolocale supported. Added an RTL + 2×-scale regression test for the shared onboarding header. Manual Arabic/Hebrew sweep of major screens remains a release-gate item. Report: `docs/reports/i18n_l10n_audit_2026-06-04.md`.

### I18N-003 - Audit pluralization and embedded-text asset risks
- Files: localization resources, UI copy, icons/images with embedded text
- Description: Validate plural rules and ensure visual assets do not contain language-specific baked-in text.
- Acceptance Criteria: plural-sensitive flows use proper localization APIs; embedded-text assets are removed or tracked.
- Testing: localization QA and asset review.
- Status: done (2026-06-04). Verified pluralization uses proper ICU `{count, plural, …}` syntax (16 plural keys: time-ago, unread counts, …), not concatenation; one naive count string (`daily_likes_service` "$remaining likes") folded into the I18N-001 backlog. Embedded-text assets limited to the brand wordmark/app icon (acceptable exception) — no localizable baked-in text. Report: `docs/reports/i18n_l10n_audit_2026-06-04.md`.
