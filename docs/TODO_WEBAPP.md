# TODO: Web Platform Execution Board

- Status: P0 Production Alignment In Progress
- Web Repo: `/Users/ace/crush-web`
- Current Evidence: `docs/reports/crush_web_mobile_alignment_reaudit_2026-06-06.md`
- Purpose: Sequence web-specific work while detailed acceptance criteria remain in the owning module TODO files.

## Execution Rule

- Complete gates in order.
- Do not start broad product-parity work while a P0 production-alignment gate is open.
- A feature is not complete because code exists; migration, deployment, automated verification, and staging/production evidence are required.

## Gate 0 - Green And Protected Web Baseline

1. `TEST-007` — Make standalone typecheck, tests, build, lint, manifests, rules, and authenticated E2E required release evidence.
2. `API-008` — Decide canonical domains, routes, and deployment path.
3. `SEC-FE-004` — Initialize web App Check and correct CSP/backend origins.

Exit criteria:
- Required web CI is green.
- Staging web can call protected REST/callable paths with App Check.
- As-built domains, routes, and deployment path are validated.

## Gate 1 - Canonical Data And Security Boundaries

1. `API-007` — Establish canonical cross-repo contracts and mutation boundaries.
2. `DB-004` — Prove every retained direct web/mobile data path against Firestore rules.
3. `PROF-BE-004` — Complete canonical web profile-write migration.
4. `AUTH-SEC-006` — Align auth capabilities and replace client-writable device trust.
5. `SEC-BE-004` — Move trust and benefit state behind server-owned commands.
6. `SUB-001` — Unify server-owned entitlement and benefit lifecycle.
7. `NOTIF-005` — Make web push registration and delivery production-valid.

Exit criteria:
- Web onboarding/profile/notifications/safety/subscription flows pass current rules and backend authorization.
- Clients cannot self-grant trust, entitlement, promos, or boosts.

## Gate 2 - Canonical Match And Chat Cutover

1. `CHAT-BE-004` — Migrate data, enable V2 in staging, validate, cut over production, and remove legacy paths.
2. `CHAT-RT-003` — Finish wiring offline queue and connectivity-restoration processing.
3. `CHAT-BE-002` / `CHAT-BE-003` — Close remaining chat pagination/storage and moderation/retention evidence gaps.

Exit criteria:
- No production web behavior uses legacy conversations, typing indicators, directional matches, or direct swipes.
- Authenticated discovery -> match -> chat -> report/block E2E passes.

## Gate 3 - Product And UX Alignment

1. `I18N-004` — Integrate web localization end to end.
2. `RESP-004` — Publish shared semantic design, state, and navigation contracts.
3. `A11Y-004` — Add authenticated web accessibility release coverage.
4. `CALL-011` — Decide and implement or explicitly defer browser calling.
5. `TEST-006` — Complete tablet/iPad manual evidence.

Exit criteria:
- Equivalent user goals have documented cross-platform behavior.
- Accessibility, responsive behavior, localization, and product claims match deployed capability.

## Gate 4 - Maintainability And Scale

1. `API-009` — Decompose the Cloud Functions monolith by bounded context.
2. `REF-CHAT-001` / `REF-CHAT-002` — Continue chat transport/state and composer decomposition.
3. Continue module-specific mobile/web hotspot refactors only after the release-critical gates are stable.

Exit criteria:
- Contract, route, domain, unsupported-path, and release-evidence drift fail automatically in CI.

## Risks

- `R-065` — Web production controls block or reject canonical runtime paths.
- `R-066` — Web client can self-assert security and benefit state.

## Historical Context

- Prior consolidated web TODO items were intentionally decomposed on 2026-04-16.
- This file remains a routing board; detailed tasks live in module TODO files.
- Release/change history remains in `docs/ai_workboard.md` and `docs/Developer_agent_chat.md`.
