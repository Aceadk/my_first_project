# Remediation Backlog -- CRUSH Dating App
**Date:** 2026-02-12
**Version:** 2.0 (Comprehensive Update)

Status legend: `todo`, `in_progress`, `blocked`, `done`

---

## P0 -- Critical (Must Fix Before Launch)

| ID | Priority | Domain | Task | Owner | Status | Acceptance Criteria | Finding Ref |
|---|---|---|---|---|---|---|---|
| CR-AUD-001 | P0 | Backend Security | Enable App Check enforcement strategy for callable endpoints | Web/Backend | done | Enforced in production runtime (`K_SERVICE`/`NODE_ENV=production`), monitor mode in local/emulator | P0-SEC-003 |
| CR-AUD-002 | P0 | Backend Security | Change CORS behavior to fail closed when allowlist missing in production | Web/Backend | done | Production now rejects browser origins when allowlist is empty; localhost/dev still supported | P0-SEC-004 |
| CR-AUD-023 | P0 | Infrastructure | Enable Firebase Storage in Console for project `crush-265f7` | Developer | todo | `firebase deploy --only storage` succeeds; photo upload test passes | P0-SEC-001 |
| CR-AUD-024 | P0 | Platform Security | Configure Android Play Integrity in Play Console and Firebase Console | Developer | todo | Android devices pass App Check attestation; enforcement can be enabled | P0-SEC-002 |

## P1 -- High Priority

| ID | Priority | Domain | Task | Owner | Status | Acceptance Criteria | Finding Ref |
|---|---|---|---|---|---|---|---|
| CR-AUD-003 | P1 | Backend Quality | Fix failing profile completeness function tests | Web/Backend | done | `cd functions && npm test` now fully green (11 passing) | P1-QUAL-002 |
| CR-AUD-004 | P1 | Backend Quality | Resolve ESLint typed-project mismatch for generated DataConnect files | Web/Backend | done | `.eslintrc.js` excludes generated DataConnect path; lint runs clean | P1-QUAL-003 |
| CR-AUD-005 | P1 | Backend Quality | Remove/resolve unused vars and explicit-any lint errors in `functions/src/index.ts` | Web/Backend | done | `cd functions && npm run lint` now passes with zero errors | P1-QUAL-003 |
| CR-AUD-006 | P1 | Mobile Quality | Raise business-logic test coverage from 13.94% to >=40% (phase 1) | Flutter | in_progress | Coverage report >=40% and critical domain paths covered (12% interim milestone surpassed at 13.94%) | P1-QUAL-001 |
| CR-AUD-007 | P1 | Mobile Quality | Raise business-logic test coverage from >=40% to >=80% (phase 2) | Flutter | todo | Coverage report >=80% with stable CI execution | P1-QUAL-001 |
| CR-AUD-008 | P1 | Integration | Expand integration/e2e to include full onboarding->discovery->match->chat->report/block flows | Flutter + Web/Backend | in_progress | Flow implemented in `integration_test/e2e_onboarding_discovery_chat_safety_test.dart` with report/block side-effect assertions; deterministic business-flow surrogate test added in `test/e2e_onboarding_discovery_chat_safety_flow_test.dart` (green). Device-level deterministic run pending CI/device validation due local macOS build stall/timeout. | P1-QUAL-001 |
| CR-AUD-009 | P1 | Compliance | Create store compliance checklist evidence pack (Apple + Google) | UI/UX + Flutter | in_progress | Checklist mapped to in-app implementation and policy URLs | -- |
| CR-AUD-010 | P1 | Data Privacy | Verify account deletion flow for complete data erasure across Firestore/RTDB/Storage | Web/Backend | done | `cascadeDeleteUserData` Cloud Function deletes: matches+messages, blocks/reports/likes, message_requests, Storage files, RTDB data, Auth user; 14-day grace period via `requestAccountDeletion` callable; web+mobile aligned; account recovery on sign-in | -- |
| CR-AUD-019 | P1 | Mobile Quality | Add unit tests for `chat_settings_cubit` and `match_chat_settings_cubit` flows | Flutter | done | Cubit state transitions and error paths covered with deterministic tests | P1-ARCH-003 |
| CR-AUD-020 | P1 | Mobile Quality | Add unit tests for notification/privacy settings cubits | Flutter | done | `notification_settings_cubit` and `privacy_settings_cubit` key flows covered | P1-ARCH-003 |
| CR-AUD-021 | P1 | Safety | Add tests for `date_plan_service` scheduling/check-in/escalation flows | Flutter | done | Date safety service logic covered including overdue and escalation behavior | -- |
| CR-AUD-025 | P1 | Web Security | Migrate CSP from `unsafe-inline` to nonce-based for script-src | Web/Backend | done | Per-request nonces generated in middleware.ts; `unsafe-inline` removed from script-src; style-src keeps unsafe-inline for Tailwind CSS; CSP moved from next.config.js to middleware | P1-SEC-001 |
| CR-AUD-026 | P1 | Web Security | Implement Redis-backed distributed rate limiting (Upstash) | Web/Backend | done | Upstash Redis REST client (INCR+EXPIRE pattern); graceful fallback to in-memory; async API; callers updated in session + checkout routes | P1-SEC-002 |
| CR-AUD-027 | P1 | Architecture | Begin clean architecture refactor -- fix presentation-to-data imports | Flutter | done | Domain repository interfaces created (auth + chat); auth+chat presentation imports fixed to use domain layer; all test stubs updated with E2EE methods | P1-ARCH-001 |
| CR-AUD-028 | P1 | Architecture | Split ChatBloc into sub-BLoCs (message, media, E2EE, typing) | Flutter | done | RealtimeStateCubit + ChatSessionCubit + MessageHandlingBloc; ChatBloc rewritten as facade with event-based aggregation (ChatSubBlocChanged); 0 warnings; 20/20 tests pass | P1-ARCH-002 |
| CR-AUD-029 | P1 | Testing | Write BLoC unit tests for top 8 BLoCs | Flutter | done | 24/24 BLoCs covered; MessageRequestsCubit + WeeklyPicksCubit tests added; 1058 total tests passing | P1-ARCH-003 |

## P2 -- Medium Priority

| ID | Priority | Domain | Task | Owner | Status | Acceptance Criteria | Finding Ref |
|---|---|---|---|---|---|---|---|
| CR-AUD-011 | P2 | Dependency Mgmt | Run patch/minor dependency upgrade sweep and regression test | Flutter + Web/Backend | todo | Lockfiles updated, tests pass, no regressions | P2-QUAL-001 |
| CR-AUD-012 | P2 | Architecture | Publish canonical API + event contract catalog (REST + callable + triggers) | Web/Backend | todo | Versioned docs with auth/validation/error model | P3-ARCH-002 |
| CR-AUD-013 | P2 | Technical Debt | Convert active NOTE markers to ticket-referenced decisions | Flutter + Web/Backend | done | No untracked NOTE/TODO markers in code | -- |
| CR-AUD-014 | P2 | UX/Accessibility | Run WCAG 2.1 AA audit on all critical journeys | UI/UX | todo | Accessibility report with pass/fail and remediation tasks | -- |
| CR-AUD-015 | P2 | Performance | Establish p95 API latency and app startup baselines under load | Web/Backend + Flutter | todo | Baseline report and alert thresholds committed | -- |
| CR-AUD-016 | P2 | Observability | Add structured logging and alerting coverage matrix for critical flows | Web/Backend | todo | Alerting for auth, chat delivery, payments, moderation | -- |
| CR-AUD-022 | P2 | Platform Reliability | Add tests for push-notification + performance monitor core services | Flutter | done | `push_notification_service` and performance observers have deterministic unit coverage | -- |
| CR-AUD-030 | P2 | Security | Add match-membership verification to chat media storage rules | Web/Backend | todo | Storage rules verify `request.auth.uid` is match participant before allowing read | P2-SEC-003 |
| CR-AUD-031 | P2 | Security | Enforce email verification server-side on Cloud Functions | Web/Backend | todo | Sensitive endpoints check `auth.token.email_verified`; unverified users blocked from chat/discovery | P2-SEC-002 |
| CR-AUD-032 | P2 | Security | Enable App Check on remaining callable functions | Web/Backend | todo | All callable functions have `verifyAppCheck()` call; audit log confirms coverage | P2-SEC-001 |
| CR-AUD-033 | P2 | Code Quality | Replace 260 debugPrint statements with AppLogger | Flutter | done | ~54 files migrated; 0 errors/warnings on flutter analyze; only app_logger.dart retains debugPrint (internal impl) | P2-ARCH-002 |
| CR-AUD-034 | P2 | Architecture | Extract shared DTOs to common layer | Flutter | todo | All repo implementations import from shared DTO directory | P2-ARCH-001 |
| CR-AUD-035 | P2 | Architecture | Standardize error handling on Result/Either pattern | Flutter | todo | All repository methods return `Result<T>`; no raw exception throwing | P2-ARCH-003 |
| CR-AUD-036 | P2 | Web Quality | Remove console.log from 25 web source files | Web/Backend | done | All console.log calls wrapped in `process.env.NODE_ENV === 'development'` guards across 6 files | P2-WEB-001 |
| CR-AUD-037 | P2 | Web Quality | Replace TypeScript `any` with proper types in 3 files | Web/Backend | done | `any`→`unknown` in auth pages; removed `as any` in quiz; proper type narrowing via instanceof | P2-WEB-002 |
| CR-AUD-038 | P2 | Web Performance | Implement message list virtualization | Web/Backend | todo | Chat renders 1000+ messages without performance degradation | P2-WEB-003 |
| CR-AUD-039 | P2 | Web Performance | Optimize chat media images | Web/Backend | todo | All chat images use Next.js `<Image>` with responsive sizing | P2-WEB-004 |
| CR-AUD-040 | P2 | Testing | Set up web unit test framework (Vitest/Jest) | Web/Backend | todo | `pnpm test` runs; auth store, API routes, and utilities covered | P2-QUAL-002 |

## P3 -- Low Priority / Improvements

| ID | Priority | Domain | Task | Owner | Status | Acceptance Criteria | Finding Ref |
|---|---|---|---|---|---|---|---|
| CR-AUD-017 | P3 | Documentation | Maintain role-based deliverables packet and weekly updates in `/audit` | All | in_progress | Weekly report cadence sustained | P3-QUAL-001 |
| CR-AUD-018 | P3 | Design System | Build screen inventory and component compliance matrix for mobile/web | UI/UX | todo | 100% screen/component mapping with deviations logged | -- |
| CR-AUD-041 | P3 | Architecture | Split router.dart into modular route files by domain | Flutter | todo | Router file under 200 LOC; routes split by feature | P3-ARCH-001 |
| CR-AUD-042 | P3 | Web Performance | Run bundle analysis and optimize web build size | Web/Backend | todo | Bundle analyzer report committed; largest chunks identified | P3-WEB-001 |

---

## Execution Order

### Phase 1: Launch Blockers (Week 1)
1. Enable Firebase Storage (`CR-AUD-023`) -- P0
2. Configure Android Play Integrity (`CR-AUD-024`) -- P0
3. Verify App Check enforcement in production -- P0
4. Begin BLoC unit tests for critical flows (`CR-AUD-029`) -- P1

### Phase 2: Security Hardening (Weeks 2-3)
5. Migrate CSP to nonce-based (`CR-AUD-025`) -- P1
6. Implement Redis rate limiting (`CR-AUD-026`) -- P1
7. Add match-membership to storage rules (`CR-AUD-030`) -- P2
8. Enforce email verification server-side (`CR-AUD-031`) -- P2

### Phase 3: Architecture Quality (Weeks 3-5)
9. Split ChatBloc (`CR-AUD-028`) -- P1
10. Begin clean architecture refactor (`CR-AUD-027`) -- P1
11. Raise test coverage to 40% (`CR-AUD-006`) -- P1
12. Replace debugPrint with AppLogger (`CR-AUD-033`) -- P2

### Phase 4: Web Hardening (Weeks 4-6)
13. Set up web unit tests (`CR-AUD-040`) -- P2
14. Implement message virtualization (`CR-AUD-038`) -- P2
15. Optimize chat images (`CR-AUD-039`) -- P2
16. Remove console.log (`CR-AUD-036`) -- P2

### Phase 5: Maintenance Track (Weeks 6-8)
17. Dependency upgrade sweep (`CR-AUD-011`) -- P2
18. Standardize error handling (`CR-AUD-035`) -- P2
19. Extract shared DTOs (`CR-AUD-034`) -- P2
20. Raise coverage to 80% (`CR-AUD-007`) -- P1

---

## Summary

| Priority | Total | Done | In Progress | Todo | Blocked |
|----------|-------|------|-------------|------|---------|
| P0 | 4 | 2 | 0 | 2 | 0 |
| P1 | 16 | 12 | 2 | 2 | 0 |
| P2 | 18 | 6 | 0 | 12 | 0 |
| P3 | 4 | 0 | 1 | 3 | 0 |
| **Total** | **42** | **20 (48%)** | **3 (7%)** | **19 (45%)** | **0** |
