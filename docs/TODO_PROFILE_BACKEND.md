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
- Status: open

### PROF-BE-002 - Verify image-processing privacy and moderation pipeline
- Files: upload handlers, storage triggers, moderation jobs, metadata sanitizers
- Description: Confirm uploaded media strips EXIF data, respects size limits, and passes through moderation/safety gates before exposure.
- Acceptance Criteria: privacy-sensitive metadata is removed; moderation path is documented and enforced.
- Testing: upload pipeline tests plus manual metadata verification on sample files.
- Status: open

### PROF-BE-003 - Validate deletion cascade for profile-owned data
- Files: deletion handlers, storage cleanup jobs, profile-linked collections
- Description: Ensure profile deletion removes media, references, caches, and relationship-linked artifacts without orphan data.
- Acceptance Criteria: cascade map documented; orphan cleanup gaps tracked or fixed.
- Testing: backend integration test and storage/database spot checks.
- Status: open
