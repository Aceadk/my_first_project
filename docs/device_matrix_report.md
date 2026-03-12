# Device Matrix Report

**Date:** 2026-03-12
**Status:** Dry run
**Purpose:** Validate the `TEST-004` evidence format and prove the matrix report covers at least one representative run for iOS, Android, and web.
**Commit Under Test:** `61792d0`
**Environment:** `dev`
**Tester:** Codex

## Automated Preflight

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | Not executed in this dry run | Reserved for release candidate execution |
| `flutter test --coverage` | Not executed in this dry run | Reserved for release candidate execution |
| `flutter test test/startup_cold_launch_guard_test.dart -r compact` | Pass | Local run on 2026-03-12; first frame marker visible within timeout |
| `npm --prefix functions test` | Not executed in this dry run | Reserved for release candidate execution |

## Dry-Run Matrix Entries

These entries validate the required reporting structure and evidence naming conventions.
They are not formal release sign-off results.

| Run ID | Platform | Device / Browser | OS / Version | Scenario packs | Result | Evidence | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `DM-20260312-ios-01` | iOS | iPhone 15 | iOS 18.x | `SMK-001`, `AUTH-001`, `ONB-001`, `CORE-001`, `SET-001` | Dry run | `artifacts/device-matrix/ios/DM-20260312-ios-01-launch.png`, `artifacts/device-matrix/ios/DM-20260312-ios-01-core.mov`, `artifacts/device-matrix/ios/DM-20260312-ios-01.log` | Template entry for flagship iPhone flow |
| `DM-20260312-android-01` | Android | Pixel 8 | Android 15 | `SMK-001`, `AUTH-001`, `ONB-001`, `CORE-001`, `SET-001` | Dry run | `artifacts/device-matrix/android/DM-20260312-android-01-launch.png`, `artifacts/device-matrix/android/DM-20260312-android-01-core.mov`, `artifacts/device-matrix/android/DM-20260312-android-01.log` | Template entry for Android baseline flow |
| `DM-20260312-web-01` | Web | Chrome desktop | macOS latest, `1440px` viewport | `SMK-001`, `AUTH-001`, `CORE-001`, `SET-001`, `WEB-001` | Dry run | `artifacts/device-matrix/web/DM-20260312-web-01-desktop.png`, `artifacts/device-matrix/web/DM-20260312-web-01-tablet.png`, `artifacts/device-matrix/web/DM-20260312-web-01-mobile.png`, `artifacts/device-matrix/web/DM-20260312-web-01-console.log` | Template entry also proves breakpoint evidence contract |

## Evidence Format Checklist

| Requirement | Covered by dry run | Notes |
| --- | --- | --- |
| At least one run per platform family (`iOS`, `Android`, `Web`) | Yes | Three template rows included |
| Exact run ID format | Yes | `DM-YYYYMMDD-platform-index` |
| Device / browser and OS fields | Yes | Present in every row |
| Scenario pack IDs | Yes | Uses runbook pack IDs verbatim |
| Evidence paths for screenshots, recordings, and logs | Yes | Placeholder paths defined for every row |
| Notes / blocker field | Yes | Final column included in every row |

## Open Issues

- No blocking issues from the targeted startup guard run.
- Startup guard output logged a timed-out `Firebase.initializeApp` bootstrap task after the first frame marker became visible; the test still passed because the guard only asserts cold-launch content visibility. Re-check this during full release-candidate preflight.

## Next Update Trigger

Replace `Dry run` results with actual `Pass`, `Fail`, or `Blocked` outcomes when a release candidate branch is ready and the automated preflight lane is green.
