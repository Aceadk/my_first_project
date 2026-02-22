# TODO: Refactor - Profile Module

- Module: profile edit, media pipeline, validation
- Priority: P1
- Estimated Effort: 4-6 days
- Dependencies: profile FE/BE tasks

## Tasks

### REFPROF-001 - Profile Form Model Extraction
- Files: `lib/features/profile/presentation/screens/profile_edit_screen.dart`
- Description: Move profile field transforms/validation out of widget tree into dedicated form model.
- Acceptance Criteria: screen becomes presentation-only and easier to test.
- Testing: unit tests for form model validation rules.
- Status: todo

### REFPROF-002 - Media Service API Simplification
- Files: `lib/features/profile/data/services/profile_media_service.dart`
- Description: Normalize upload/delete/URL migration APIs with explicit result types.
- Acceptance Criteria: no ambiguous return paths and consistent error handling.
- Testing: unit tests for upload/delete/ensureRemoteUrls branches.
- Status: todo

### REFPROF-003 - Prompt/Profile Data Migration Completion
- Files: `lib/features/profile/domain/models/*`, related data models
- Description: Complete deprecated prompt model usage removal and mapping cleanup.
- Acceptance Criteria: no deprecated prompt access in active profile flows.
- Testing: unit tests covering prompt migration behavior.
- Status: todo
