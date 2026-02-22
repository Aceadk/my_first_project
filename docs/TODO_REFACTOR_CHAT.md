# TODO: Refactor - Chat Module

- Module: chat screen, bloc, realtime adapters
- Priority: P1
- Estimated Effort: 5-7 days
- Dependencies: CHAT-UI/CHAT-RT tasks

## Tasks

### REFCHAT-001 - Chat Screen Reduction
- Files: `lib/features/chat/presentation/screens/chat_screen.dart`, extracted widget files
- Description: Continue splitting large chat screen into composable units.
- Acceptance Criteria: screen orchestrator is lean and independently testable.
- Testing: widget tests per extracted component.
- Status: todo

### REFCHAT-002 - Bloc Subscription Refactor
- Files: `lib/features/chat/presentation/bloc/chat_bloc.dart`
- Description: Centralize subscription registration/cancellation and isolate side effects.
- Acceptance Criteria: no uncancelled subscription diagnostics.
- Testing: bloc lifecycle tests and analyzer clean pass.
- Status: todo

### REFCHAT-003 - Transport Adapter Interface
- Files: `lib/features/chat/data/*`, `lib/features/chat/domain/*`
- Description: Hide transport implementation behind domain adapters for swapability and tests.
- Acceptance Criteria: chat domain logic testable with fake transport.
- Testing: unit tests with fake adapters.
- Status: todo
