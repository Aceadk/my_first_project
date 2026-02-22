# TODO: Refactor - Settings and Account Module

- Module: settings UI orchestration and account actions
- Priority: P2
- Estimated Effort: 3-5 days
- Dependencies: settings/account/security tasks

## Tasks

### REFSET-001 - Settings Screen Section Modularization
- Files: `lib/features/settings/presentation/screens/*`
- Description: Split large settings screens into reusable section widgets.
- Acceptance Criteria: each section has isolated logic and tests.
- Testing: widget tests for each settings section.
- Status: todo

### REFSET-002 - Account Action Command Layer
- Files: `lib/features/settings/domain/*`, `lib/features/settings/data/*`
- Description: Move destructive account actions to dedicated command/use-case layer.
- Acceptance Criteria: UI triggers typed commands with consistent error mapping.
- Testing: unit tests for delete/export/cancel-delete commands.
- Status: todo

### REFSET-003 - Preference Sync Abstraction
- Files: `lib/features/settings/data/*`, `functions/src/*`
- Description: Centralize preference sync contract (local cache + server truth).
- Acceptance Criteria: no duplicated sync code across settings cubits/services.
- Testing: unit tests for merge/conflict behavior.
- Status: todo
