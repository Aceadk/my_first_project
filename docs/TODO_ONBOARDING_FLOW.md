# Onboarding Flow Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Onboarding Flow domain.

---

## OB-001 · P1 · Hardcoded default favourite in ProfileSetupScreen

**File:** `lib/features/profile/presentation/screens/profile_setup_screen.dart:80`

`initState` sets `_favouriteAthlete = 'Cristiano Ronaldo'` without the user choosing it. If the user never opens the favourites section, their profile ships with a pre-selected favourite they didn't pick. This should be `null` (no default).

---

## OB-002 · P1 · EmailVerificationScreen polls every 3 s with no cap

**File:** `lib/features/auth/presentation/screens/email_verification_screen.dart:65-69`

`_startVerificationCheck` creates a `Timer.periodic(3s)` that polls `checkEmailVerification()` indefinitely. If the user leaves this screen open for hours, it hammers the backend. Add a max attempt count (e.g. 200 = ~10 min) or exponential backoff, then show a manual "Check Again" prompt.

---

## OB-003 · P2 · Back button in BasicInfoScreen assumes phone sign-up

**File:** `lib/features/auth/presentation/screens/basic_info_screen.dart:961-973`

`_goBack` falls back to navigating to `CrushRoutes.otp` (phone) or `CrushRoutes.phoneAuth` when `context.canPop()` is false. If the user signed up via email, this sends them to phone auth. The fallback should consider the sign-up method used.

---

## OB-004 · P2 · Inconsistent onboarding step counts

**Files:**

- `sign_up_screen.dart:74` — logs `totalSteps: 6`
- `basic_info_screen.dart:73` — logs `totalSteps: 6`
- `profile_setup_screen.dart:93` — logs `totalSteps: 6`
- `basic_info_screen.dart:222` — UI shows "Step 3 of 5"

Analytics logs 6 total steps but the UI shows 5. These must match for consistency in analytics funnels and user-facing progress indicators.

---

## OB-005 · P2 · Extensive hardcoded strings not localized

**Files:** Multiple onboarding screens

Many user-facing strings are hardcoded in English rather than using ARB keys via `AppLocalizations`:

| Screen                           | Examples                                                                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `basic_info_screen.dart`         | `'Basic Info'`, `'Step 3 of 5'`, `'Choose a unique username'`, `'Continue'`, `'Age Notice'`, gender labels, orientation labels |
| `profile_setup_screen.dart`      | `'Please add at least 1 photo...'`, section headers, favourites labels                                                         |
| `email_verification_screen.dart` | `'Verify Your Email'`, `'Checking verification status...'`, status messages                                                    |
| `terms_conditions_screen.dart`   | Section titles and body content                                                                                                |
| `sign_up_screen.dart`            | Step labels, validation messages, error text                                                                                   |

These should be extracted to `app_en.arb` and accessed via `context.l10n.*`.

---

## OB-006 · P1 · \_routeAfterTerms uses isAccountVerified vs route_redirect uses isEmailVerified

**File:** `lib/features/auth/presentation/screens/terms_conditions_screen.dart:94`

`_routeAfterTerms` checks `!resolvedUser.isAccountVerified` to decide whether to redirect to email verification. The router's `route_redirect.dart` uses `needsAccountVerification` (which may be defined differently). If these two checks evaluate different fields, users could get stuck in a loop between T&C completion and the email verification screen. Verify they reference the same underlying boolean.

---

## OB-007 · P2 · Gender options hardcoded and not extensible

**File:** `lib/features/auth/presentation/screens/basic_info_screen.dart:48-52`

Gender options are hardcoded to `['female', 'male', 'nonbinary']` with hardcoded labels. These should be data-driven (from a constants file or server config) to allow future additions without code changes, and labels should be localized.

---

## OB-008 · P2 · Username uniqueness not validated before submit

**File:** `lib/features/auth/presentation/screens/basic_info_screen.dart:983-994`

`_usernameErrorText` only validates format (regex) but does not check server-side uniqueness. User can submit a username that's already taken, only to see a generic server error. Add a debounced uniqueness check call before form submission.

---

## OB-009 · P2 · Date picker uses hardcoded ColorScheme.dark regardless of theme

**File:** `lib/features/auth/presentation/screens/basic_info_screen.dart:747`

`_showBirthdatePicker` always applies `ColorScheme.dark(...)` to theme the dialog, even in light mode. This should use `ColorScheme.light(...)` or `ColorScheme.dark(...)` based on `isDark`.

---

## OB-010 · P1 · EmailVerificationScreen sends verification email on every initState

**File:** `lib/features/auth/presentation/screens/email_verification_screen.dart:42`

`initState` unconditionally calls `_sendVerificationEmail()`. If the user navigates away and comes back (or the router redirects them here again), they get another email. This can exhaust Firebase's email quota quickly. Should check if a recent email was already sent (e.g. via a timestamp in SharedPreferences) before auto-sending.

---

## OB-011 · P2 · "Use Different Email" button calls \_signOut

**File:** `lib/features/auth/presentation/screens/email_verification_screen.dart:374-379`

Both the "Sign Out" and "Use Different Email" buttons call `_signOut()`. "Use Different Email" should ideally navigate to an email change flow rather than signing the user out entirely.

---

## OB-012 · P2 · onboardingStartTime is a global mutable variable

**File:** `lib/features/auth/presentation/screens/sign_up_screen.dart:20`

`DateTime? onboardingStartTime` is a top-level mutable global. It's set in `SignUpScreen.initState` and presumably read in `ProfileSetupScreen`. This should be scoped to an InheritedWidget, a BLoC, or passed via route arguments — not a global.
