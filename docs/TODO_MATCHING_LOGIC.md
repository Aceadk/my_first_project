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
- Status: in progress — implemented + verified 2026-05-31 (flutter analyze clean; 49 domain tests green — 40 new + 9 existing). Added `match_ranking_engine.dart`: documented 4-signal weighted scoring (Distance 0.35 / Interests 0.30 / Activity 0.20 / Preferences 0.15), neutral cold-start priors, additive cold-start boost, recently-shown exposure penalty, greedy same-city diversity cap, deterministic id tie-break. Inputs + fairness/cold-start risks + mitigations documented. Remaining: wire into discovery repo/bloc; richer `lastActiveAt` activity signal. See `docs/reports/matching_logic_2026-05-31.md`.

### MATCH-002 - Validate filter composition and conflict handling
- Files: filter models, decision engine, backend candidate evaluators
- Description: Verify that age, distance, interests, incognito, passport, block, and preference filters combine predictably.
- Acceptance Criteria: conflicting filter behavior is defined; unexpected candidate leakage is prevented.
- Testing: unit tests for filter combinations and regression coverage for blocked/hidden cases.
- Status: in progress — implemented + verified 2026-05-31. Added `candidate_filter_pipeline.dart`: composes self/blocked/already-swiped/hidden/incognito/age/gender/interests/distance into one pipeline with a typed `FilterRejectionReason` per removed candidate. Precedence + conflict rules (passport>distance, inverted-age swap, empty-gender=show-all, incognito allowlist) defined; no-leakage invariant (`accepted + rejected == evaluated`, blocked beats attributes) covered by tests. Remaining: wire into candidate evaluators. See `docs/reports/matching_logic_2026-05-31.md`.

### MATCH-003 - Instrument discovery and match quality signals
- Files: analytics events, deck depletion signals, match conversion reporting
- Description: Add or verify telemetry for deck exhaustion, candidate rejection causes, and post-match conversion quality.
- Acceptance Criteria: analytics supports diagnosing poor discovery quality and backlog prioritization.
- Testing: analytics event coverage tests or manual instrumentation verification.
- Status: in progress — implemented + verified 2026-05-31. Added pure `MatchQualityEvents` builders (`match_quality_analytics.dart`) + four thin `logDiscovery*` emit methods on `AnalyticsService`: `discovery_deck_depleted` (depth + rejection breakdown), `discovery_candidate_rejections` (acceptance rate + per-reason, fed by MATCH-002), `discovery_ranking_quality` (score distribution + cold-start share), `discovery_match_conversion`. Builders unit-tested in isolation (no Firebase); a test asserts every event respects Firebase limits (name/keys ≤40 chars, ≤25 params, num/String values, bools as 1/0). Remaining: manual Firebase DebugView check + call-site wiring. See `docs/reports/matching_logic_2026-05-31.md`.
