# Apple App Store Compliance - 2026-06-03

Scope: `STORE-APL-001`–`STORE-APL-003` from [`docs/TODO_STORE_APPLE.md`](../TODO_STORE_APPLE.md).

Surface reviewed: iOS project config (`ios/Runner.xcodeproj`, `Info.plist`,
`*.entitlements`), Sign in with Apple + account-deletion + IAP flows, and UGC
moderation. Builds on existing evidence:
[`iPad_Compliance_Report.md`](iPad_Compliance_Report.md),
[`account_management_compliance_2026-05-30.md`](account_management_compliance_2026-05-30.md),
[`security_backend_audit_2026-05-30.md`](security_backend_audit_2026-05-30.md).

## Result

The Apple-mandated technical controls are in place; one compliance risk was
**fixed** (over-broad "Always" location authorization, a common review
rejection). Remaining items are human asset/metadata prep for App Store Connect,
tracked with a submission checklist.

Legend: ✅ verified · 🔧 fixed · ⚠️ manual/tracked.

---

## STORE-APL-001 - iPad device-family, screenshots, presentation

Status: ✅ technical support verified; ⚠️ asset pack manual

- `TARGETED_DEVICE_FAMILY = "1,2"` across all build configs → universal
  iPhone + iPad binary (no iPhone-only restriction that triggers "doesn't
  support iPad properly" rejections).
- iPad layout/readiness evidence already captured in
  [`iPad_Compliance_Report.md`](iPad_Compliance_Report.md) and the responsive-design
  work.
- ⚠️ Manual before submission: capture 12.9" iPad Pro + 6.7" iPhone screenshot
  sets and complete App Store Connect metadata (description, keywords, support
  URL, age rating). Tracked in the checklist below — requires a human/device.

## STORE-APL-002 - Sign in with Apple, account deletion, IAP

Status: ✅ verified

- **Sign in with Apple:** `com.apple.developer.applesignin` entitlement present
  in both `Runner.entitlements` and `RunnerRelease.entitlements`; integrated via
  the `sign_in_with_apple` package. Required because the app offers other social
  logins (Google), per App Store Guideline 4.8 / 4.0.
- **Account deletion (Guideline 5.1.1(v)):** in-app and discoverable —
  Settings → Account Actions → Delete Account → `requestAccountDeletion`
  (14-day grace, cascade delete). Verified end-to-end in ACCT-001
  (`account_management_compliance_2026-05-30.md`) and the cascade hardening in
  `profile_backend_audit_2026-06-03.md` (PROF-BE-003).
- **In-app purchase (Guideline 3.1.1):** subscriptions are sold through StoreKit
  (`in_app_purchase` / `in_app_purchase_storekit`); the Stripe web-checkout path
  (`startCheckout`) explicitly throws `UnsupportedError` on iOS, so no external
  purchase path for digital goods is exposed on device. Receipts are verified
  server-side (`verifyAppleTransaction` / `verifyPurchaseReceipt`).

## STORE-APL-003 - Privacy labels, permission copy, UGC moderation

Status: 🔧 location copy fixed; ✅ moderation verified; ⚠️ privacy nutrition label manual

- 🔧 **Permission copy least-privilege fix.** `Info.plist` previously declared
  `NSLocationAlwaysAndWhenInUseUsageDescription` + `NSLocationAlwaysUsageDescription`
  ("…even when the app is in the background"), but the app only ever requests
  **when-in-use** (`Geolocator.requestPermission()` default; foreground
  `getCurrentPosition`/`getPositionStream` for discovery distance — no background
  location work). The "Always" strings invite Guideline 5.1.1 review questions and
  misrepresent behavior. Removed both; kept `NSLocationWhenInUseUsageDescription`.
- ✅ Remaining permission strings are present and accurate: camera, contacts,
  Face ID, microphone, photo library (add + full), user tracking.
- ✅ **UGC moderation (Guideline 1.2 — required for social/dating):** report and
  block flows exist (`reportUser`/`blockUser` callables + Safety screen), images
  pass Cloud Vision SafeSearch moderation, text moderation via `moderateTextContent`,
  reported users are hidden from discovery during review, and an appeal path
  exists. Evidence: `security_backend_audit_2026-05-30.md`, ACCT-003.
- ⚠️ Manual before submission: fill the App Store Connect **privacy nutrition
  label** (data collected: location [coarse, when-in-use], contact info, photos,
  usage; linked to identity; used for app functionality). The implementation now
  matches a when-in-use (not background) location disclosure.

---

## Submission checklist (manual / human)
- [ ] 12.9" iPad Pro + 6.7" iPhone screenshot sets.
- [ ] App Store Connect metadata: description, keywords, support/marketing URLs, age rating (17+ for dating).
- [ ] Privacy nutrition label matching the verified data use (location = when-in-use).
- [ ] Demo account for App Review + reviewer notes (how to trigger match/chat/report).
- [ ] Confirm Sign in with Apple capability enabled on the App ID in the developer portal.

## Verification
- iOS config verified by source review of `project.pbxproj`, `Info.plist`, and
  both `.entitlements` files.
- Location fix: `Info.plist` now declares when-in-use only (matches code, which
  never requests Always). Mirrored on Android (STORE-GGL).
