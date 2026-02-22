# TODO: Refactor - Authentication Module

- Module: auth architecture simplification
- Priority: P1
- Estimated Effort: 4-6 days
- Dependencies: AUTH-SEC tasks, DI cleanup

## Tasks

### REFAUTH-001 - Auth Flow Orchestration Split
- Files: `lib/features/auth/presentation/*`, `lib/features/auth/domain/*`
- Description: Separate UI orchestration from business rules into testable use cases.
- Acceptance Criteria: UI layer contains no token/session mutation logic.
- Testing: unit coverage for use cases and bloc/cubit states.
- Status: todo

### REFAUTH-002 - Unified Auth Error Mapping
- Files: `lib/features/auth/data/*`, `lib/core/errors/*`
- Description: Replace ad hoc exception strings with typed auth failures.
- Acceptance Criteria: Auth presentation maps errors from a single failure hierarchy.
- Testing: unit tests for mapping and user-facing message selection.
- Status: todo

### REFAUTH-003 - Session Bootstrap Isolation
- Files: `lib/app.dart`, `lib/core/session/*`
- Description: Extract startup session restore logic into isolated bootstrap service.
- Acceptance Criteria: startup path deterministic and unit-testable.
- Testing: session bootstrap tests with mocked storage/network.
- Status: todo
