# TODO: Apple App Store Compliance

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_IPAD_COMPLIANCE.md`, `docs/TODO_AUTH_SECURITY.md`, `docs/TODO_ACCOUNT_MGMT.md`
- Assigned: AI + Developer

## Tasks

### STORE-APL-001 - Verify iPad device-family, screenshots, and presentation compliance
- Files: iOS project config, assets, store metadata, iPad evidence pack
- Description: Confirm the app fully supports iPad expectations and has the required assets and screenshots for submission.
- Acceptance Criteria: iPad support evidence exists and submission metadata is complete.
- Testing: manual checklist and screenshot pack review.
- Status: done (2026-06-03). Verified `TARGETED_DEVICE_FAMILY = "1,2"` (universal iPhone+iPad) across all build configs; iPad readiness evidence in `iPad_Compliance_Report.md`. Screenshot/metadata prep tracked as a manual App Store Connect checklist. Report: `docs/reports/store_apple_compliance_2026-06-03.md`.

### STORE-APL-002 - Audit Sign in with Apple, account deletion, and IAP compliance
- Files: auth flows, settings/account actions, subscription/store flows
- Description: Validate Apple-mandated account controls and native billing constraints.
- Acceptance Criteria: Apple-specific compliance blockers are either fixed or explicitly tracked.
- Testing: manual end-to-end store compliance checklist.
- Status: done (2026-06-03). Verified: Sign in with Apple entitlement present (both entitlements files) + integrated; in-app account deletion (Guideline 5.1.1(v)) via `requestAccountDeletion`; subscriptions sold via StoreKit with the Stripe web-checkout path throwing `UnsupportedError` on iOS (Guideline 3.1.1) + server-side receipt validation. Report: `docs/reports/store_apple_compliance_2026-06-03.md`.

### STORE-APL-003 - Verify privacy labels, permission copy, and UGC moderation evidence
- Files: iOS permission strings, privacy docs, report/block flows
- Description: Ensure App Store Connect disclosures and in-app permission copy accurately reflect behavior.
- Acceptance Criteria: privacy and moderation evidence is ready for first submission.
- Testing: review checklist and in-app copy verification.
- Status: done (2026-06-03). **Fixed:** removed over-broad `NSLocationAlways*` usage strings (app only uses when-in-use location) — a Guideline 5.1.1 risk. UGC moderation verified (report/block + SafeSearch image + text moderation + appeal + hide-on-report). Privacy nutrition-label fill tracked as manual (now matches when-in-use disclosure). Report: `docs/reports/store_apple_compliance_2026-06-03.md`.
