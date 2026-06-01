# Matching Logic — MATCH-001 / 002 / 003

- Date: 2026-05-31
- Source TODO: `docs/TODO_MATCHING_LOGIC.md`
- Scope: pure domain logic + telemetry for discovery ranking and filtering.
- Integration choice: **pure domain + tests, no networked wiring** (the Firebase
  match repository and Cloud Functions are intentionally untouched this pass).
- Verification: local Flutter SDK (3.44.0 / Dart 3.12.0). `flutter analyze` on
  the seven changed files: **No issues found.** `flutter test` (the three new
  suites + the existing engine test): **49 passed** (40 new + 9 existing).

## Deliverables

| File | Task | Purpose |
| --- | --- | --- |
| `lib/features/discovery/domain/usecases/match_ranking_engine.dart` | MATCH-001 | Documented, deterministic, fairness-aware ranking. |
| `lib/features/discovery/domain/usecases/candidate_filter_pipeline.dart` | MATCH-002 | Composable filter pipeline with typed rejection reasons (no leakage). |
| `lib/core/analytics/match_quality_analytics.dart` | MATCH-003 | Pure `MatchQualityEvents` builders for match-quality telemetry. |
| `lib/core/services/analytics_service.dart` (edited) | MATCH-003 | Four thin `logDiscovery*` methods that emit the builder's events via Firebase. |
| `test/.../match_ranking_engine_test.dart` | MATCH-001 | 12 cases. |
| `test/.../candidate_filter_pipeline_test.dart` | MATCH-002 | 20 cases. |
| `test/core/analytics/match_quality_analytics_test.dart` | MATCH-003 | 8 cases. |

---

## MATCH-001 — Ranking fairness, cold-start, diversity

**Acceptance: "ranking inputs are documented; cold-start and fairness risks are
identified with mitigation tasks."**

### Documented ranking inputs (the four weighted signals)

Default weight scheme (distance-first, local product): **Distance 0.35 /
Interests 0.30 / Activity 0.20 / Preferences 0.15** (`CompatibilityWeights.balanced`,
overridable).

| Signal | How it is scored (normalized 0–1) |
| --- | --- |
| Distance | Linear decay 1.0 @ 0 km → 0.0 @ `referenceDistanceKm` (220 km default). Missing either location → neutral **0.5**. |
| Interests | Jaccard similarity (shared / union) of normalized interest sets. Either side empty → neutral **0.5**. |
| Activity | `isActive` → 1.0; inactive → 0.35; **new accounts** → 0.5 baseline (not buried). |
| Preferences | Age centeredness within the viewer's range (1.0 at center → ~0.5 at edges) + small verified bonus. |

Final score = weighted blend (÷ weight sum) + cold-start boost − exposure
penalty, clamped to [0,1], scaled to **0–100**. The full
`CompatibilityBreakdown` is returned per candidate so ranking is auditable.

### Cold-start & fairness risks → mitigations (implemented)

| Risk | Mitigation in code |
| --- | --- |
| New users have no interests/location/activity and rank at the bottom forever. | Neutral 0.5 priors for missing distance/interests; activity baseline lifted to 0.5 for `isNewUser`; additive `coldStartBoost` (default 0.08 → +8 pts). |
| Same candidates re-shown on every deck refresh. | `exposurePenalty` (default 0.10) subtracted for ids in `recentlyShownIds`. |
| Dense single-city regions produce a homogeneous deck. | Greedy `maxConsecutiveSameCity` (default 2) diversity pass, applied after scoring without disturbing global order more than necessary. |
| Non-deterministic ordering breaks reproducibility/tests. | Ties break on ascending profile id; the diversity pass is deterministic. |

### Residual risks (follow-up backlog, not blocking)
- Activity is a coarse `isActive` bool; a real `lastActiveAt` timestamp would
  give a smoother recency curve. (Needs a model/back-end field — out of scope.)
- Exposure penalty is session-local; persisting it across sessions needs a
  store. (Wiring task, deferred per integration choice.)

---

## MATCH-002 — Filter composition & conflict handling

**Acceptance: "conflicting filter behavior is defined; unexpected candidate
leakage is prevented."**

`CandidateFilterPipeline.apply()` evaluates every candidate against a single
`CandidateFilterCriteria` and returns accepted profiles **plus a typed
`CandidateRejection` for every removed one**. Because every removal carries a
reason and `accepted + rejected == evaluated` (asserted in tests), there is no
silent path by which a candidate can leak into or vanish from the deck.

### Defined precedence (first failing filter wins)
1. `selfProfile` 2. `blocked` (safety) 3. `alreadySwiped` 4. `hiddenFromDiscovery`
(candidate opt-out) 5. `incognito` (candidate privacy) 6. `ageOutOfRange`
7. `genderNotPreferred` 8. `insufficientSharedInterests`
9. `outOfDistance` / `missingLocation`.

Safety and candidate-privacy filters deliberately precede the viewer's
preference filters, so e.g. a blocked candidate is reported as `blocked` even if
they are also out of age range (tested).

### Defined conflict resolutions
- **Passport vs distance** — passport mode bypasses the distance filter.
- **Invalid age range** (`minAge > maxAge`) — bounds are swapped, not "reject all".
- **Empty `showMeGenders`** — means "show all", not "show none".
- **Incognito allowlist** — incognito candidates appear only when their id is in
  `incognitoVisibleToViewerIds` (e.g. they already liked the viewer).
- **Interests** — a *soft* signal by default (`minSharedInterests = 0`); becomes
  a hard filter only when the caller opts in.

---

## MATCH-003 — Discovery & match-quality instrumentation

**Acceptance: "analytics supports diagnosing poor discovery quality and backlog
prioritization."**

Telemetry is split into a pure, dependency-free builder
(`MatchQualityEvents`, returning `MatchQualityEvent` value objects) and four
thin `logDiscovery*` emit methods added to the existing `AnalyticsService`
(which forwards to Firebase). The builder owns all event-shaping logic and is
unit-tested in isolation — no Firebase needed. Four quality events:

| Event | Diagnoses |
| --- | --- |
| `discovery_deck_depleted` | How deep the deck got + *why* candidates were filtered (rejection breakdown). |
| `discovery_candidate_rejections` | Acceptance rate + per-reason breakdown for one fetch — shows whether distance/age/etc. is starving the deck. |
| `discovery_ranking_quality` | Score distribution (top/avg) + cold-start share of a ranked deck. |
| `discovery_match_conversion` | Whether a match became a conversation, and how fast. |

Rejection counts are flattened to `reject_<reason>` params keyed off
`FilterRejectionReason.analyticsKey` (so names never drift from the enum), with
zero-count reasons omitted. A test feeds **every** reason at once through each
builder and asserts the result respects Firebase's structural limits (event
name ≤40 chars, ≤25 params, each key ≤40 chars, values `num`/`String` only —
booleans encoded as 1/0). There is no validator class in the codebase, so the
test checks these constraints inline.

---

## Test Plan

### Automated (run; all green on 2026-05-31)
```bash
flutter analyze lib/core/services lib/core/analytics lib/features/discovery
flutter test \
  test/features/discovery/domain/usecases/matching_decision_engine_test.dart \
  test/features/discovery/domain/usecases/candidate_filter_pipeline_test.dart \
  test/features/discovery/domain/usecases/match_ranking_engine_test.dart \
  test/core/analytics/match_quality_analytics_test.dart
```
Coverage highlights: every filter + precedence + no-leakage invariant; perfect
candidate scores exactly 100; neutral cold-start priors; cold-start boost and
exposure penalty reorder otherwise-equal candidates; diversity caps consecutive
same-city; deterministic id tie-break; all telemetry events Firebase-valid.

### Not done (deferred per integration choice)
- Wiring the pipeline/engine/telemetry into `firebase_discovery_repository` and
  the deck bloc (these modules are dependency-free and ready to wire).
- Server-side mirroring in Cloud Functions.
- Manual analytics verification in the Firebase DebugView console.
