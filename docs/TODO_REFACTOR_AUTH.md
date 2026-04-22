# TODO: Refactor Auth

- Priority: P2 – Medium
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_AUTH_SECURITY.md`
- Assigned: AI + Developer

## Tasks

### REF-AUTH-001 - Isolate auth session orchestration from provider-specific logic
- Files: auth repositories, token/session managers, startup auth wiring
- Description: Reduce coupling between provider-specific auth handling and generic session lifecycle logic.
- Acceptance Criteria: auth session responsibilities are clearly separated and testable.
- Testing: repository/unit coverage for refactored seams.
- Status: open

### REF-AUTH-002 - Reduce duplication in provider failure mapping and recovery
- Files: provider-specific failure mappers and shared auth utilities
- Description: Consolidate duplicated provider error handling without hiding provider-specific recovery guidance.
- Acceptance Criteria: shared abstractions reduce duplication while preserving actionable UX copy.
- Testing: mapper regression tests.
- Status: open
