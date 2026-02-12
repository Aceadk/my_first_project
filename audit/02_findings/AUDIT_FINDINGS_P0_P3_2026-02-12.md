# Audit Findings (P0-P3) - 2026-02-12

## P0 (Immediate)

### P0-001 App Check enforcement disabled for callable surface
- Evidence: `functions/src/index.ts:297` sets `ENFORCE_APP_CHECK = false`.
- Impact: Backend callable endpoints accept requests without enforced App Check, increasing abuse and automation risk.
- Recommendation: Roll out staged enforcement (monitor -> partial -> full) and set enforcement true per environment.
- Status update (2026-02-12): Mitigated in current branch. Enforcement now activates in production runtime; local/emulator remains monitor-only.

### P0-002 CORS fallback allows all origins when allowlist is empty
- Evidence: `functions/src/index.ts:113` allows request when `corsAllowedOrigins.length === 0`.
- Impact: Misconfiguration or missing env value can silently expose API to broad cross-origin access.
- Recommendation: Fail closed in production when allowlist is empty; keep localhost exception only for emulator/dev.
- Status update (2026-02-12): Mitigated in current branch. Empty allowlist now fails closed in production.

## P1 (High)

### P1-001 Functions test suite failing
- Evidence: `npm test` in `functions` reports 3 failures in `profile completeness helpers`.
- Impact: Backend quality gate is red; profile quality logic contracts are currently broken or test/export mismatch exists.
- Recommendation: Fix export/contract for `evaluateProfileCompleteness` and `ensureProfileQuality`, then re-run tests.
- Status update (2026-02-12): Mitigated in current branch. `npm test` is now green.

### P1-002 Functions lint gate failing
- Evidence: `npm run lint` in `functions` reports 14 errors.
- Impact: CI merge confidence degraded; typed lint pipeline currently unstable.
- Recommendation: Resolve ESLint project include mismatch for generated d.ts, remove unused vars, and clean strict typing issues.
- Status update (2026-02-12): Mitigated in current branch. `npm run lint` is now green.

### P1-003 Test coverage baseline far below directive target
- Evidence: `flutter test --coverage` => 7.10% line coverage (4185/58952).
- Impact: Directive requires >=80% business logic coverage; current baseline is insufficient for safe refactoring and release confidence.
- Recommendation: Prioritize domain/data layer unit tests and critical flow integration tests first.

## P2 (Medium)

### P2-001 Dependency freshness gap (Flutter ecosystem)
- Evidence: `dart pub outdated` reports 60 upgradable locked dependencies, 12 constrained below resolvable versions.
- Impact: Higher maintenance/security drift risk over time.
- Recommendation: Create phased dependency upgrade plan (minor/patch first, then major with migration tests).

### P2-002 Active code comment debt without ticket references
- Evidence: 3 comment markers in code (`audit/raw/todo_inventory_code_markers_raw.txt`).
- Impact: Ambiguous ownership and deferred design decisions remain undocumented in backlog.
- Recommendation: Convert each marker into tracked backlog item and annotate code with ticket ID.

### P2-003 Large mixed backend surface (callables + REST + triggers) without unified endpoint documentation
- Evidence: 36 callable exports + 29 REST endpoints + 5 Firestore triggers + 2 Pub/Sub jobs.
- Impact: Onboarding complexity and operational risk during incident response.
- Recommendation: Publish canonical API/event catalog with auth/rate-limit/schema per endpoint/event.

## P3 (Improvement)

### P3-001 Audit deliverables not yet complete for all role-specific diagrams
- Evidence: Directive requires architecture diagrams, route maps, schema diagrams, and UX flow packs.
- Impact: Collaboration friction and slower execution, but not a release blocker by itself.
- Recommendation: Complete diagram set in `audit/05_role_deliverables` and keep versioned updates.
