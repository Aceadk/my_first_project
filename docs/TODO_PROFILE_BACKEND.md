# TODO: Profile Backend Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_DATABASE.md`, `docs/TODO_API_ARCHITECTURE.md`, `docs/TODO_SECURITY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### PROF-BE-001 - Audit profile payload validation and permission boundaries
- Files: profile APIs, Cloud Functions, repositories, backend validators
- Description: Confirm every profile field has server-side validation and users cannot mutate privileged fields such as verification or moderation state.
- Acceptance Criteria: validation coverage documented; unsafe write paths closed or tracked.
- Testing: backend validation tests with malformed and privilege-escalation payloads.
- Status: done (2026-06-03). Verified: REST profile writes are restricted to `PROFILE_PATCH_ALLOWED_FIELDS` / `PROFILE_PREFERENCES_ALLOWED_FIELDS` allowlists, each field is validated + HTML-stripped server-side, and privileged fields (`plan`, `isIdVerified`, KYC/Stripe/email-verified) are server-only in `firestore.rules` and absent from the allowlists — no escalation path on either the direct or REST write surface. Report: `docs/reports/profile_backend_audit_2026-06-03.md`.

### PROF-BE-002 - Verify image-processing privacy and moderation pipeline
- Files: upload handlers, storage triggers, moderation jobs, metadata sanitizers
- Description: Confirm uploaded media strips EXIF data, respects size limits, and passes through moderation/safety gates before exposure.
- Acceptance Criteria: privacy-sensitive metadata is removed; moderation path is documented and enforced.
- Testing: upload pipeline tests plus manual metadata verification on sample files.
- Status: done (2026-06-03). Verified: production uploads strip EXIF via `ImageOptimizer` full pixel re-encode before reaching Storage; moderation enforced via `moderateImageContent`/`moderateTextContent` callables, with the REST path additionally running Cloud Vision SafeSearch + face-presence + magic-byte/size checks inline. Tracked follow-up: a Storage `onFinalize` trigger for server-side metadata-strip + moderation as defense-in-depth on direct-to-Storage uploads. Report: `docs/reports/profile_backend_audit_2026-06-03.md`.

### PROF-BE-003 - Validate deletion cascade for profile-owned data
- Files: deletion handlers, storage cleanup jobs, profile-linked collections
- Description: Ensure profile deletion removes media, references, caches, and relationship-linked artifacts without orphan data.
- Acceptance Criteria: cascade map documented; orphan cleanup gaps tracked or fixed.
- Testing: backend integration test and storage/database spot checks.
- Status: done (2026-06-03). **Fixed a real orphaned-media bug:** `cascadeDeleteUserData` only swept legacy `photos/{uid}/` + `chat_media/{uid}/`, leaving production profile media (`users/{uid}/...`), ID-verification docs (`verification/{uid}/`), and production chat media (`chat_media/{matchId}/{uid}/`) in Storage after deletion. Now sweeps all of them via the pure, tested `userStorageDeletionPrefixes(uid, matchIds)` helper. Covered by new `accountDeletionMap.test.js` cases (8 passing). Report: `docs/reports/profile_backend_audit_2026-06-03.md`.
