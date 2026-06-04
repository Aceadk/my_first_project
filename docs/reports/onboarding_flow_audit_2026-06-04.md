# Onboarding Flow Audit - 2026-06-04

Scope: `ONBOARD-001`–`ONBOARD-003` from
[`docs/TODO_ONBOARDING_FLOW.md`](../TODO_ONBOARDING_FLOW.md).

Surfaces reviewed: the pure route resolver
([`route_redirect.dart`](../../lib/core/routing/route_redirect.dart)), route
preservation (`AppStatePreserver` in [`app.dart`](../../lib/app.dart)), the
onboarding completion getters
([`user.dart`](../../lib/shared/dto/user.dart)), the age gate in
[`basic_info_screen.dart`](../../lib/features/auth/presentation/screens/basic_info_screen.dart),
and the permission rationale flow
([`permission_rationale_screen.dart`](../../lib/features/auth/presentation/screens/permission_rationale_screen.dart)).

## Result

The flow is deterministic and well-built; resume/gating logic already has strong
unit coverage. The audit **hardened one defense-in-depth gap** in the basic-info
completion rule and added regression coverage.

Legend: ✅ verified · 🔧 fixed · ⚠️ tracked.

---

## ONBOARD-001 - Resume and interruption recovery

Status: ✅ verified

- **Deterministic resolver.** `resolveRouteRedirect(authState, path)` is a pure
  function of auth status + onboarding flags, so resume after an app kill, auth
  refresh, or rotation always recomputes the same target. Onboarding gates run
  in a fixed order: terms → basic info → profile setup → email verification →
  home.
- **No strand / no loop.** Each gate target is a fixed point (resolving the
  redirect while already on that route returns `null`), and a fully-onboarded
  user on any auth/onboarding route is sent to `home`. Resume-from-deep-route
  (e.g. `/home` for a partially-onboarded user → the correct next step) and the
  no-loop cases are covered by the 11 cases in
  [`router_redirect_test.dart`](../../test/router_redirect_test.dart).
- **Route preservation.** `AppStatePreserver` saves the current route on
  background and restores it on resume; the redirect then re-gates it.

## ONBOARD-002 - Permission ordering and rationale

Status: ✅ verified

- **Rationale before system prompt.** Location permission is requested only
  after `PermissionRationaleScreen` in profile setup
  ([`profile_setup_screen.dart`](../../lib/features/profile/presentation/screens/profile_setup_screen.dart)).
- **No launch barrage.** Push permission is requested contextually via the
  notifications settings toggle (`togglePush`), not at cold start; camera/photo
  access is requested on demand by the native picker when the user adds media.
  Permissions are therefore sequenced and contextual, not stacked at first run.
- ⚠️ Full first-run prompt ordering on physical iOS/Android/web remains a manual
  release-gate check.

## ONBOARD-003 - Age gating, terms acceptance, completion semantics

Status: 🔧 hardened age completion rule; ✅ rest verified

- ✅ **Age gate (input).** `basic_info` blocks under-18 two ways: the date
  picker's `lastDate` is `now - 18 years` (an under-18 DOB isn't selectable), and
  `_handleNext` blocks on `_birthdateErrorText` (which returns "too young" for
  `age < 18`, sourced from `ValidationConstants.minAge`).
- 🔧 **Defense-in-depth fix.** `CrushUser.hasCompletedBasicInfo` treated any
  `age > 0` as complete, so an underage age that reached a profile via legacy
  data, the API, or a bug would have satisfied the onboarding gate even though
  the input UI blocks it. Changed it to require
  `age >= ValidationConstants.minAge`, so an underage profile is never treated as
  onboarded and is re-gated to basic info. Covered by a new case in
  [`user_model_hotspot_test.dart`](../../test/user_model_hotspot_test.dart)
  (age 16 → not complete; age 18 → complete).
- ✅ **Terms acceptance.** `needsTermsAcceptance` gates every protected route to
  the terms screen until accepted (covered by the redirect tests).
- ✅ **Completion semantics.** `hasCompletedProfileSetup` (photo/video present)
  and `isOnboardingComplete` are unit-tested in `user_model_hotspot_test`.

---

## Changed files

- `lib/shared/dto/user.dart` (age completion hardening)
- `test/user_model_hotspot_test.dart` (underage regression case)

## Verification

- `flutter analyze` on changed files — clean.
- `flutter test` (user model, router redirect, stub profile repo, e2e onboarding flow) — all passing; no regressions from the completion-rule change.
- ⚠️ Manual first-run permission ordering on iOS/Android/web remains a release-gate item.
