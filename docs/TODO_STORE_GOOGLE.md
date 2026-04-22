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
- Status: open

### STORE-GGL-002 - Audit data safety, account deletion, and subscription compliance
- Files: privacy docs, settings/account actions, subscription flows, store metadata
- Description: Verify the Play data-safety declaration matches implementation and required in-app account controls exist.
- Acceptance Criteria: Play policy disclosures and account controls are aligned with implementation.
- Testing: manual policy checklist and flow verification.
- Status: open

### STORE-GGL-003 - Verify user-generated-content moderation and reporting compliance
- Files: report/block/moderation flows, help content, backend moderation paths
- Description: Ensure moderation, blocking, and reporting satisfy Play expectations for social/dating apps.
- Acceptance Criteria: moderation evidence pack is ready and linked to active safety controls.
- Testing: manual moderation-flow checklist.
- Status: open
