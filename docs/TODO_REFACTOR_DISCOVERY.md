# TODO: Refactor Discovery

- Priority: P2 – Medium
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_DISCOVERY_UI.md`, `docs/TODO_MATCHING_LOGIC.md`, `docs/TODO_DISCOVERY_BACKEND.md`
- Assigned: AI + Developer

## Tasks

### REF-DISC-001 - Isolate ranking and filter composition boundaries
- Files: discovery use cases, decision engines, backend candidate evaluators
- Description: Reduce coupling between UI-driven filters and deeper ranking/business rules.
- Acceptance Criteria: discovery ranking/filter composition has clearer seams and owners.
- Testing: unit tests for extracted ranking/filter logic.
- Status: open

### REF-DISC-002 - Decompose deck presentation into smaller testable widgets
- Files: discovery deck screens and shared card-stack helpers
- Description: Split large discovery UI surfaces so animation, gesture, and state responsibilities are easier to reason about.
- Acceptance Criteria: deck presentation hotspots have an extraction plan or are refactored.
- Testing: widget regression tests for extracted deck widgets.
- Status: open
