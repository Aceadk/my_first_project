# TODO: Google Play Compliance

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_ACCOUNT_MGMT.md`, `docs/TODO_SECURITY_FRONTEND.md`, `docs/TODO_SECURITY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### STORE-GGL-001 - Verify target SDK, AAB, icons, and device readiness
- Files: Android config, bundle settings, launcher assets, store metadata
- Description: Confirm Play submission configuration meets current SDK, bundle, and device-support requirements.
- Acceptance Criteria: Android submission config is current and documented.
- Testing: build/config checklist and bundle smoke validation.
- Status: done (2026-06-03). Verified `applicationId=com.ace.crush`, SDK levels inherit `flutter.*` (track the toolchain), AAB distribution, and adaptive launcher icons (`flutter_launcher_icons`). Tracked: confirm resolved `targetSdk ≥ 34` in the built AAB's merged manifest (bump explicitly if the pinned Flutter is older). Report: `docs/reports/store_google_compliance_2026-06-03.md`.

### STORE-GGL-002 - Audit data safety, account deletion, and subscription compliance
- Files: privacy docs, settings/account actions, subscription flows, store metadata
- Description: Verify the Play data-safety declaration matches implementation and required in-app account controls exist.
- Acceptance Criteria: Play policy disclosures and account controls are aligned with implementation.
- Testing: manual policy checklist and flow verification.
- Status: done (2026-06-03). **Fixed a Play policy blocker:** removed unused `ACCESS_BACKGROUND_LOCATION` + `FOREGROUND_SERVICE_LOCATION` (app uses foreground/when-in-use location only) — avoids the "background location access" review gate and lets Data-safety declare foreground-only. Verified in-app + URL account deletion and Play Billing subscriptions (Stripe blocked on mobile) with server-side validation. Data-safety form fill tracked as manual. Report: `docs/reports/store_google_compliance_2026-06-03.md`.

### STORE-GGL-003 - Verify user-generated-content moderation and reporting compliance
- Files: report/block/moderation flows, help content, backend moderation paths
- Description: Ensure moderation, blocking, and reporting satisfy Play expectations for social/dating apps.
- Acceptance Criteria: moderation evidence pack is ready and linked to active safety controls.
- Testing: manual moderation-flow checklist.
- Status: done (2026-06-03). Verified report/block flows, SafeSearch image + text moderation, appeal path, hide-reported-on-discovery, and retained abuse history — satisfying Play social/dating UGC-moderation expectations. Evidence linked from `security_backend_audit_2026-05-30.md`, ACCT-003, `database_audit_2026-06-02.md`. Report: `docs/reports/store_google_compliance_2026-06-03.md`.
