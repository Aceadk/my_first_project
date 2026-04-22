# TODO: Matching Logic Module

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_DISCOVERY_BACKEND.md`, `docs/TODO_DATABASE.md`
- Assigned: AI + Developer

## Tasks

### MATCH-001 - Audit ranking fairness, cold-start behavior, and candidate diversity
- Files: matching use cases, ranking services, recommendation helpers
- Description: Review how new users, sparse geographies, and skewed activity patterns affect match quality and candidate exposure.
- Acceptance Criteria: ranking inputs are documented; cold-start and fairness risks are identified with mitigation tasks.
- Testing: deterministic test fixtures covering new users, low-density regions, and repeated deck refreshes.
- Status: open

### MATCH-002 - Validate filter composition and conflict handling
- Files: filter models, decision engine, backend candidate evaluators
- Description: Verify that age, distance, interests, incognito, passport, block, and preference filters combine predictably.
- Acceptance Criteria: conflicting filter behavior is defined; unexpected candidate leakage is prevented.
- Testing: unit tests for filter combinations and regression coverage for blocked/hidden cases.
- Status: open

### MATCH-003 - Instrument discovery and match quality signals
- Files: analytics events, deck depletion signals, match conversion reporting
- Description: Add or verify telemetry for deck exhaustion, candidate rejection causes, and post-match conversion quality.
- Acceptance Criteria: analytics supports diagnosing poor discovery quality and backlog prioritization.
- Testing: analytics event coverage tests or manual instrumentation verification.
- Status: open
