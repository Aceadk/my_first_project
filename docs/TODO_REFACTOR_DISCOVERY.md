# TODO: Refactor - Discovery Module

- Module: discovery screen and service architecture
- Priority: P1
- Estimated Effort: 4-6 days
- Dependencies: discovery UI/backend tasks

## Tasks

### REFDISC-001 - Deck Screen Decomposition
- Files: `lib/features/discovery/presentation/screens/deck_screen.dart`
- Description: Split oversized deck screen into focused widgets/controllers.
- Acceptance Criteria: Main screen reduced to orchestration role with clear subcomponents.
- Testing: widget tests for extracted components.
- Status: todo

### REFDISC-002 - Service Abstraction Boundaries
- Files: `lib/features/discovery/data/services/*`, `lib/features/discovery/domain/repositories/*`
- Description: Enforce repository interfaces between presentation and data services.
- Acceptance Criteria: Presentation layer no longer imports data services directly.
- Testing: compile-time checks and cubit/bloc tests.
- Status: todo

### REFDISC-003 - Matching Decision Engine Isolation
- Files: `lib/features/discovery/domain/*`
- Description: Move score/filter logic into pure domain utilities/use cases.
- Acceptance Criteria: deterministic pure-function tests for matching decisions.
- Testing: unit tests for edge case filter combinations.
- Status: todo
