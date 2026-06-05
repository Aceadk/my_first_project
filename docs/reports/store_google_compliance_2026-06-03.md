# Google Play Compliance - 2026-06-03

Scope: `STORE-GGL-001`–`STORE-GGL-003` from [`docs/TODO_STORE_GOOGLE.md`](../TODO_STORE_GOOGLE.md).

Surface reviewed: Android config (`android/app/build.gradle`, `AndroidManifest.xml`,
launcher icons), data-safety-relevant permissions, account-deletion +
subscription flows, and UGC moderation. Builds on
[`account_management_compliance_2026-05-30.md`](account_management_compliance_2026-05-30.md)
and [`security_backend_audit_2026-05-30.md`](security_backend_audit_2026-05-30.md).

## Result

Play technical configuration is current and the required account/subscription/
moderation controls exist. One significant policy risk was **fixed**: the app
declared `ACCESS_BACKGROUND_LOCATION` it never used, which forces the Play
"background location access" review gate (prominent-disclosure video, frequent
rejections for dating apps). Removed. Remaining items are Play Console metadata.

Legend: ✅ verified · 🔧 fixed · ⚠️ manual/tracked.

---

## STORE-GGL-001 - Target SDK, AAB, icons, device readiness

Status: ✅ verified; ⚠️ confirm target SDK number at build

- `applicationId = "com.ace.crush"`; `compileSdk`, `targetSdk`, `minSdk`,
  `versionCode`, `versionName` inherit `flutter.*` (the pinned Flutter SDK
  defaults), so target SDK tracks the Flutter toolchain rather than a stale
  hardcoded value.
- ⚠️ Confirm at build time that `flutter.targetSdkVersion` resolves to **≥ 34**
  (Play's current minimum; 35 recommended) — run `flutter build appbundle` and
  check the merged manifest. If the pinned Flutter is older than the SDK-35
  default, bump via `targetSdk = 35` explicitly.
- Distribution is an **AAB** (`flutter build appbundle`), satisfying Play's
  app-bundle requirement. Adaptive launcher icons are configured via
  `flutter_launcher_icons` (`android: true`, adaptive fg/bg, `min_sdk_android: 21`).

## STORE-GGL-002 - Data safety, account deletion, subscription

Status: 🔧 data-safety risk fixed; ✅ deletion + billing verified

- 🔧 **Background-location permission removed.** `AndroidManifest.xml` declared
  `ACCESS_BACKGROUND_LOCATION` and `FOREGROUND_SERVICE_LOCATION`, but the app only
  reads location in the foreground (`getCurrentPosition`/`getPositionStream` while
  open, for discovery distance) — there is no location foreground service or
  geofencing. Background-location declarations trigger Play's dedicated review
  (prominent-disclosure + justification video) and are a common dating-app
  rejection. Removed both; kept `ACCESS_FINE/COARSE_LOCATION` (when-in-use) and
  generic `FOREGROUND_SERVICE`. The Play **Data safety** form can now declare
  location as foreground/when-in-use only.
- ✅ **Account deletion (Play User Data policy):** in-app via Settings → Account
  Actions → Delete Account (`requestAccountDeletion`, 14-day grace, full cascade
  incl. Storage media after the PROF-BE-003 fix), plus a web deletion URL for the
  Play "account deletion" Data-safety field. Evidence: ACCT-001.
- ✅ **Subscriptions (Play Billing policy):** purchased via Play Billing
  (`in_app_purchase_android`); the Stripe web-checkout path throws
  `UnsupportedError` on Android, so no out-of-Play purchase path for digital goods.
  Server-side validation via `verifyGooglePurchaseToken` / `verifyPurchaseReceipt`,
  with RTDN lifecycle reconciliation.
- ⚠️ Manual: complete the Play **Data safety** declaration to match the verified
  data use (location foreground-only, contacts, photos, messages; encrypted in
  transit; deletion available).

## STORE-GGL-003 - UGC moderation and reporting

Status: ✅ verified

- Report + block flows exist (`reportUser`/`blockUser` callables + Safety &
  Blocking screen); reported profiles are hidden from discovery during review
  (10-day client window), and an appeal path (`appealSafetyAction`) exists.
- Server-side moderation: Cloud Vision SafeSearch on image uploads (REST path) +
  `moderateImageContent`/`moderateTextContent` callables on the production path;
  abuse history (inbound reports/blocks) is retained through account deletion by
  design (DB-002). This satisfies Play's social/dating UGC-moderation
  expectations (in-app reporting, blocking, and content moderation).
- Evidence: `security_backend_audit_2026-05-30.md`, ACCT-003,
  `database_audit_2026-06-02.md`.

---

## Submission checklist (manual / human)
- [ ] Confirm resolved `targetSdk` ≥ 34 in the built AAB's merged manifest.
- [ ] Play Console **Data safety** form matching verified data use (location = foreground/when-in-use after this fix).
- [ ] Account-deletion **URL** + in-app path entered in the Data-safety section.
- [ ] Feature-graphic, phone/tablet screenshots, content rating (IARC) questionnaire, target-audience = adults.
- [ ] Reviewer demo account + notes (trigger match/chat/report) for dating-app review.

## Verification
- Android config verified by source review of `build.gradle` + `AndroidManifest.xml`.
- Background-location removal mirrors the iOS "Always"→"when-in-use" fix
  (`store_apple_compliance_2026-06-03.md`); both reflect the actual foreground-only
  location usage in `lib/core/services/location_service.dart`.
