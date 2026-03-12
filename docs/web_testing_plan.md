# CRUSH Device Matrix Runbook

This document is the canonical manual device and browser verification runbook for `TEST-004`.
The legacy filename is retained so existing references stay valid.

## Objective

Run one consistent release-readiness matrix across iOS, Android, and web so the same core journey is verified on representative hardware, browser engines, and responsive breakpoints before ship sign-off.

## Entry Criteria

Do not start the manual matrix until the current branch satisfies all of the following:

- `flutter analyze`
- `flutter test --coverage`
- `flutter test test/startup_cold_launch_guard_test.dart -r compact`
- `npm --prefix functions test`
- Release candidate commit SHA and environment are recorded in the report

If any automated preflight step is red, record the blocker in the report and stop the manual matrix.

## Scenario Packs

Use these scenario pack IDs in the evidence report so runs are comparable across platforms:

| ID | Scope | Minimum evidence |
| --- | --- | --- |
| `SMK-001` | Cold launch, splash, auth shell, no blank screen | Launch screenshot + startup logs |
| `AUTH-001` | Login, logout, invalid credentials, password reset entry point | Screen recording or screenshot sequence |
| `ONB-001` | Onboarding completion through first arrival on home/discovery | Final landing screenshot |
| `CORE-001` | Discovery -> like/match -> chat send -> report/block access path | Screen recording + chat evidence |
| `SET-001` | Profile/settings load, privacy/settings persistence, subscription surface visibility | Settings screenshots |
| `WEB-001` | Browser navigation, deep link handling, responsive breakpoints | Desktop + tablet + mobile screenshots |

## Required Release Matrix

### Mobile

| Platform | Device | OS target | Required cadence | Why it is in the matrix |
| --- | --- | --- | --- | --- |
| iOS | iPhone 15 or current flagship | Latest iOS major supported at release time | Every release | Primary iPhone baseline for auth, discovery, chat, and subscription flows |
| iOS | iPhone SE (3rd gen) or equivalent compact device | Lowest supported iOS major | Every release | Small-screen layout and keyboard pressure path |
| iPadOS | iPad 10th gen or Air-class tablet | Latest iPadOS major supported at release time | Every release | Multitasking, adaptive layout, onboarding/settings readability |
| Android | Pixel 8 or current flagship | Latest Android major supported at release time | Every release | Clean AOSP baseline and notification behavior |
| Android | Galaxy A54 or equivalent mid-range device | One previous Android major | Every release | Mid-range performance and OEM behavior |

### Web

| Platform | Browser / device class | OS target | Required cadence | Why it is in the matrix |
| --- | --- | --- | --- | --- |
| Web | Chrome latest desktop | macOS latest or Windows 11 | Every release | Primary desktop browser and Lighthouse baseline |
| Web | Safari latest desktop | macOS latest | Every release | WebKit compatibility and Apple review parity |
| Web | Edge latest desktop | Windows 11 latest | Every release | Chromium variant and Windows baseline |
| Web | Safari mobile | Latest iPhone iOS major | Every release | Mobile web responsive behavior and login/onboarding checks |
| Web | Chrome mobile | Latest Android major | Every release | Mobile web responsive behavior on Android |

## Breakpoints To Capture

For every web run, capture these viewport widths in addition to any browser-native screenshots:

- `390px` wide mobile portrait
- `820px` wide tablet portrait
- `1440px` wide desktop

If a flow fails only at one breakpoint, record the failing width explicitly in the report.

## Evidence Capture Contract

Record every matrix run in [docs/device_matrix_report.md](/Users/ace/my_first_project/docs/device_matrix_report.md) using the fields below:

| Field | Requirement |
| --- | --- |
| Run ID | `DM-YYYYMMDD-<platform>-<index>` |
| Commit | Exact git SHA under test |
| Environment | `dev`, `staging`, or `prod-like` |
| Platform | `iOS`, `Android`, `iPadOS`, or `Web` |
| Device / Browser | Exact hardware model or browser + OS |
| Scenario packs | Comma-separated pack IDs from this runbook |
| Result | `Pass`, `Fail`, `Blocked`, or `Dry run` |
| Evidence | Screenshot paths, screen recording paths, log bundle paths, or issue IDs |
| Notes | Known limitations, flaky behavior, retries, or blockers |

Minimum evidence required for a `Pass` result:

- One launch screenshot for `SMK-001`
- One screen recording or equivalent screenshot sequence for `CORE-001`
- One log reference for crashes, console errors, or notable warnings

If a run fails:

- Capture the exact failing step
- Link the issue ID if one is filed
- Mark downstream dependent runs as `Blocked` instead of `Fail`

## Execution Order

1. Confirm the automated preflight commands are green.
2. Record the branch, commit SHA, environment, and tester in the report.
3. Run `SMK-001`, `AUTH-001`, `ONB-001`, `CORE-001`, and `SET-001` on each required mobile device.
4. Run `SMK-001`, `AUTH-001`, `CORE-001`, `SET-001`, and `WEB-001` on each required browser/device class.
5. Attach evidence paths for each run as you go; do not backfill from memory later.
6. Summarize open defects and release blockers at the bottom of the report.

## Release Sign-Off Rule

The release matrix is complete only when all required rows for the current release are present in the report and each row is either:

- `Pass`, or
- `Blocked` by an already-documented release-blocking issue with a linked owner

Rows left blank do not count as deferred; they count as missing coverage.
