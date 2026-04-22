# TODO: Refactor Profile

- Priority: P2 – Medium
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_PROFILE_FRONTEND.md`, `docs/TODO_PROFILE_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### REF-PROFILE-001 - Split oversized profile presentation flows into focused components
- Files: large profile screens/widgets and shared profile helpers
- Description: Identify large profile surfaces that mix media, validation, and persistence responsibilities.
- Acceptance Criteria: candidate files and extraction plan are documented.
- Testing: widget tests around extracted components.
- Status: open

### REF-PROFILE-002 - Normalize shared validators and media utilities
- Files: profile validators, media helpers, upload adapters
- Description: Consolidate duplicated validation and media-format logic across profile flows.
- Acceptance Criteria: shared utilities replace duplicated logic without changing behavior.
- Testing: unit tests for extracted validators/helpers.
- Status: open
