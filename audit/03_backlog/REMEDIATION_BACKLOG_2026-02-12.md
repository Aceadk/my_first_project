# Remediation Backlog (2026-02-12)

Status legend: `todo`, `in_progress`, `blocked`, `done`

| ID | Priority | Domain | Task | Owner | Status | Acceptance Criteria |
|---|---|---|---|---|---|---|
| CR-AUD-001 | P0 | Backend Security | Enable App Check enforcement strategy for callable endpoints | Web/Backend | todo | Enforcement enabled in production path with rollout plan and monitoring |
| CR-AUD-002 | P0 | Backend Security | Change CORS behavior to fail closed when allowlist missing in production | Web/Backend | todo | Production rejects non-whitelisted origins; emulator localhost still works |
| CR-AUD-003 | P1 | Backend Quality | Fix failing profile completeness function tests | Web/Backend | todo | `cd functions && npm test` passes fully |
| CR-AUD-004 | P1 | Backend Quality | Resolve ESLint typed-project mismatch for generated DataConnect files | Web/Backend | todo | `cd functions && npm run lint` passes |
| CR-AUD-005 | P1 | Backend Quality | Remove/resolve unused vars and explicit-any lint errors in `functions/src/index.ts` | Web/Backend | todo | Zero lint errors without disabling critical rules |
| CR-AUD-006 | P1 | Mobile Quality | Raise business-logic test coverage from 7.10% to >=40% (phase 1) | Flutter | todo | Coverage report >=40% and critical domain paths covered |
| CR-AUD-007 | P1 | Mobile Quality | Raise business-logic test coverage from >=40% to >=80% (phase 2) | Flutter | todo | Coverage report >=80% with stable CI execution |
| CR-AUD-008 | P1 | Integration | Expand integration/e2e to include full onboarding->discovery->match->chat->report/block flows | Flutter + Web/Backend | todo | Deterministic green integration suite on CI |
| CR-AUD-009 | P1 | Compliance | Create store compliance checklist evidence pack (Apple + Google) | UI/UX + Flutter | todo | Checklist mapped to in-app implementation and policy URLs |
| CR-AUD-010 | P1 | Data Privacy | Verify account deletion flow for complete data erasure across Firestore/RTDB/Storage | Web/Backend | todo | Tested and documented deletion runbook |
| CR-AUD-011 | P2 | Dependency Mgmt | Run patch/minor dependency upgrade sweep and regression test | Flutter + Web/Backend | todo | Lockfiles updated, tests pass, no regressions |
| CR-AUD-012 | P2 | Architecture | Publish canonical API + event contract catalog (REST + callable + triggers) | Web/Backend | todo | Versioned docs with auth/validation/error model |
| CR-AUD-013 | P2 | Technical Debt | Convert active NOTE markers to ticket-referenced decisions | Flutter + Web/Backend | todo | No untracked NOTE/TODO markers in code |
| CR-AUD-014 | P2 | UX/Accessibility | Run WCAG 2.1 AA audit on all critical journeys | UI/UX | todo | Accessibility report with pass/fail and remediation tasks |
| CR-AUD-015 | P2 | Performance | Establish p95 API latency and app startup baselines under load | Web/Backend + Flutter | todo | Baseline report and alert thresholds committed |
| CR-AUD-016 | P2 | Observability | Add structured logging and alerting coverage matrix for critical flows | Web/Backend | todo | Alerting for auth, chat delivery, payments, moderation |
| CR-AUD-017 | P3 | Documentation | Maintain role-based deliverables packet and weekly updates in `/audit` | All | in_progress | Weekly report cadence sustained |
| CR-AUD-018 | P3 | Design System | Build screen inventory and component compliance matrix for mobile/web | UI/UX | todo | 100% screen/component mapping with deviations logged |

## Execution Order
1. Close P0 security items (`CR-AUD-001`, `CR-AUD-002`).
2. Restore backend quality gates (`CR-AUD-003` to `CR-AUD-005`).
3. Raise test confidence on mobile/integration (`CR-AUD-006` to `CR-AUD-008`).
4. Complete compliance and privacy hardening (`CR-AUD-009`, `CR-AUD-010`).
5. Continue P2/P3 modernization and documentation track.
