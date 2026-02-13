# Audit Findings (P0-P3) -- CRUSH Dating App
**Date:** 2026-02-12
**Auditor:** AI (Claude Opus 4.6)
**Scope:** Flutter mobile app, Firebase backend, Next.js web app

---

## Scoring Summary

| Domain | Score | Rating |
|--------|-------|--------|
| Security | 7.5/10 | Good |
| Architecture | 7.2/10 | Good |
| Web | 7.8/10 | Good |
| Testing | 5.0/10 | Needs Improvement |
| **Overall Weighted** | **7.0/10** | **Good** |

---

## P0 -- Critical / Immediate Action Required

### P0-SEC-001: Firebase Storage Not Initialized (R-121)
- **Domain:** Infrastructure / Security
- **Evidence:** Firebase Storage is not enabled for project `crush-265f7`. `firebase deploy --only storage` fails. Storage rules cannot be deployed.
- **Impact:** Profile photo uploads, chat media, and all storage-dependent features are non-functional in production. Users cannot complete profile setup requiring photos.
- **Recommendation:** Enable Firebase Storage in Firebase Console for project `crush-265f7`, then run `firebase deploy --only storage`.
- **Owner:** Developer (requires console access)
- **Status:** OPEN -- Blocker for production launch

### P0-SEC-002: Android Play Integrity Not Configured
- **Domain:** Security / Platform
- **Evidence:** App Check service (`lib/core/services/app_check_service.dart`) references Play Integrity provider for Android, but Play Integrity is not configured in Google Play Console or Firebase Console.
- **Impact:** Android devices cannot pass App Check attestation. When App Check enforcement is enabled (`ENFORCE_APP_CHECK=true`), all Android API calls will be rejected.
- **Recommendation:** Configure Play Integrity API in Google Play Console, register the app in Firebase Console App Check settings for Android.
- **Owner:** Developer (requires console access)
- **Status:** OPEN -- Blocker for App Check enforcement

### P0-SEC-003: App Check Enforcement Disabled (Previously P0-001)
- **Domain:** Backend Security
- **Evidence:** `functions/src/index.ts:297` previously set `ENFORCE_APP_CHECK = false`. Mitigated: enforcement now activates in production runtime.
- **Impact:** Without enforcement, backend callable endpoints accept requests without App Check, enabling automation and abuse.
- **Recommendation:** Verify enforcement is active in production deployment. Monitor rejection rates.
- **Status:** MITIGATED -- enforcement active in production runtime; local/emulator remains monitor-only

### P0-SEC-004: CORS Fallback Allows All Origins When Allowlist Empty (Previously P0-002)
- **Domain:** Backend Security
- **Evidence:** `functions/src/index.ts:113` previously allowed requests when `corsAllowedOrigins.length === 0`.
- **Impact:** Misconfiguration or missing env value can silently expose API to broad cross-origin access.
- **Recommendation:** Verify production CORS config is correctly populated after deployment.
- **Status:** MITIGATED -- empty allowlist now fails closed in production

---

## P1 -- High Priority

### P1-SEC-001: CSP Uses `unsafe-inline` for Styles
- **Domain:** Web Security
- **Evidence:** `crush-web/apps/web/next.config.js` CSP header includes `style-src 'self' 'unsafe-inline'` for Google Fonts compatibility.
- **Impact:** Allows injection of arbitrary inline styles, which can be exploited for CSS-based data exfiltration attacks.
- **Recommendation:** Migrate to nonce-based CSP (`style-src 'self' 'nonce-{random}'`) using Next.js middleware to generate per-request nonces.
- **Status:** OPEN
- **Effort:** Medium (requires middleware changes)

### P1-SEC-002: In-Memory Rate Limiting (Web)
- **Domain:** Web Security
- **Evidence:** `crush-web/apps/web/src/shared/lib/rate-limit.ts` uses in-memory sliding window rate limiter that resets on serverless cold starts.
- **Impact:** On Vercel serverless, each function instance has its own memory. Rate limits are not shared across instances and reset on cold start, allowing burst abuse.
- **Recommendation:** Migrate to Redis-backed rate limiting (Upstash Redis or similar) for distributed, persistent rate state.
- **Status:** OPEN
- **Effort:** Medium

### P1-ARCH-001: 73 Presentation Layer Violations (Clean Architecture)
- **Domain:** Architecture
- **Evidence:** 73 files in `lib/features/*/presentation/` directly import from `data/` layer, violating clean architecture boundaries. Presentation layer should only depend on domain layer.
- **Impact:** Tight coupling between UI and data implementation. Makes testing harder, increases refactoring risk, and prevents swapping data sources.
- **Recommendation:** Introduce domain-layer interfaces/use cases as intermediaries. Refactor in batches by feature module, starting with `auth` and `chat` (highest traffic).
- **Status:** OPEN
- **Effort:** Large (phased refactor)

### P1-ARCH-002: ChatBloc Exceeds 800 Lines (824 LOC)
- **Domain:** Architecture / State Management
- **Evidence:** `lib/features/chat/presentation/bloc/chat_bloc.dart` is 824 lines, handling message sending, media, E2EE, typing indicators, reactions, editing, and deletion.
- **Impact:** High cognitive complexity, difficult to test individual flows, increased risk of state bugs.
- **Recommendation:** Split into sub-BLoCs: `ChatMessageBloc` (send/edit/delete), `ChatMediaBloc` (attachments/media), `ChatE2eeBloc` (encryption state), `ChatTypingCubit` (typing indicators).
- **Status:** OPEN
- **Effort:** Medium

### P1-ARCH-003: No BLoC Unit Tests
- **Domain:** Testing / Architecture
- **Evidence:** 0 of 24 BLoCs/Cubits have dedicated unit tests for state transitions. Only integration-level tests exist for a few BLoCs.
- **Impact:** State transition regressions are undetectable. Critical for auth, discovery, chat, and subscription flows.
- **Recommendation:** Write BLoC unit tests for the 8 highest-risk BLoCs first: AuthBloc, DiscoveryBloc, ChatBloc, MatchesBloc, SubscriptionBloc, ProfileBloc, SessionBloc, CallBloc.
- **Status:** OPEN
- **Effort:** Large

### P1-QUAL-001: Test Coverage Far Below Target
- **Domain:** Quality
- **Evidence:** 46 test files for 472 lib files (9.7% file ratio). 444 passing tests, 6 skipped. Line coverage: 8.79% (5189/59017 lines). Target: 80% business logic coverage.
- **Impact:** Low confidence in refactoring safety. Regressions likely to slip through undetected.
- **Recommendation:** Phase 1: reach 40% coverage on domain/data layers. Phase 2: reach 80% on business logic. Prioritize BLoC tests, repository tests, and service tests.
- **Status:** IN PROGRESS (137 new tests added in recent sprint)
- **Effort:** Large (ongoing)

### P1-QUAL-002: Functions Test Suite Previously Failing (Resolved)
- **Domain:** Backend Quality
- **Evidence:** `npm test` in `functions` previously reported 3 failures in profile completeness helpers.
- **Status:** RESOLVED -- `npm test` now green (11 passing, 0 failing)

### P1-QUAL-003: Functions Lint Gate Previously Failing (Resolved)
- **Domain:** Backend Quality
- **Evidence:** `npm run lint` in `functions` previously reported 14 errors.
- **Status:** RESOLVED -- `npm run lint` now clean

---

## P2 -- Medium Priority

### P2-SEC-001: App Check Not Enforced on All Endpoints
- **Domain:** Security
- **Evidence:** `ENFORCE_APP_CHECK` flag controls enforcement. Currently in monitor mode for most endpoints. Some callable functions may not have `verifyAppCheck()` calls.
- **Impact:** API abuse possible from clients that bypass App Check.
- **Recommendation:** Audit all callable functions for `verifyAppCheck()` calls. Enable enforcement after Play Integrity and DeviceCheck are configured.
- **Status:** OPEN (depends on P0-SEC-002)

### P2-SEC-002: Email Verification is Soft-Enforced
- **Domain:** Security / Auth
- **Evidence:** Email verification screen exists but users can potentially bypass or delay verification. No server-side enforcement blocking unverified users from accessing features.
- **Impact:** Unverified email accounts can access app features, reducing trust and enabling fake accounts.
- **Recommendation:** Add server-side middleware to Cloud Functions that checks `auth.token.email_verified` before allowing access to sensitive endpoints (chat, discovery, profile updates).
- **Status:** OPEN

### P2-SEC-003: Chat Media Storage Rules Allow Broad Read Access
- **Domain:** Security / Storage
- **Evidence:** `storage.rules` allows any authenticated user to read from `chat_media/{matchId}/{userId}/{fileName}` if they are authenticated, without verifying match membership.
- **Impact:** Any authenticated user could potentially access chat media from conversations they are not part of, if they know the matchId.
- **Recommendation:** Add match membership verification to storage rules: verify `request.auth.uid` is a participant in the match document before allowing read access.
- **Status:** OPEN

### P2-ARCH-001: Duplicate DTOs Across Repository Implementations
- **Domain:** Architecture
- **Evidence:** Multiple repository implementations (Firebase, HTTP, Stub) define similar DTO structures independently rather than sharing a common DTO layer.
- **Impact:** Maintenance burden, potential for DTO drift between implementations.
- **Recommendation:** Extract shared DTOs to `lib/core/network/dto/` and import from all repository implementations.
- **Status:** OPEN

### P2-ARCH-002: 260 `debugPrint` Statements in Production Code
- **Domain:** Code Quality
- **Evidence:** Approximately 260 `debugPrint` statements scattered across `lib/` source files.
- **Impact:** Performance overhead in production builds (debugPrint is compiled out in release mode, but indicates lack of structured logging). Makes log output noisy in development.
- **Recommendation:** Replace with `AppLogger` calls for structured logging. Remove purely development-focused debug prints.
- **Status:** OPEN

### P2-ARCH-003: Inconsistent Error Handling Patterns
- **Domain:** Architecture
- **Evidence:** Mix of try-catch with string errors, Result/Either pattern (in some files), and raw exception throwing across different features.
- **Impact:** Unpredictable error UX. Some errors show raw technical messages to users.
- **Recommendation:** Standardize on Result/Either pattern for all repository methods. Create `AppFailure` hierarchy with user-friendly messages.
- **Status:** OPEN

### P2-WEB-001: Console Logging in 25 Web Source Files
- **Domain:** Web Quality
- **Evidence:** 25 files in `crush-web/` contain `console.log` or `console.error` statements that should be removed or replaced with structured logging for production.
- **Impact:** Information leakage in browser console. Performance overhead from string interpolation.
- **Recommendation:** Replace with a structured logging utility that can be disabled in production builds.
- **Status:** OPEN

### P2-WEB-002: TypeScript `any` Type in 3 Files
- **Domain:** Web Quality
- **Evidence:** 3 files in `crush-web/` use `any` type despite TypeScript strict mode being enabled project-wide.
- **Impact:** Type safety bypass reduces confidence in those code paths.
- **Recommendation:** Replace `any` with proper TypeScript types or `unknown` with type guards.
- **Status:** OPEN

### P2-WEB-003: Message List Needs Virtualization
- **Domain:** Web Performance
- **Evidence:** Chat message list in `crush-web/` renders all messages in DOM without virtualization.
- **Impact:** Performance degradation with long chat histories (100+ messages). Increased memory usage and scroll jank.
- **Recommendation:** Implement virtual scrolling using `react-window` or `@tanstack/virtual` for the message list.
- **Status:** OPEN

### P2-WEB-004: Unoptimized Images in Chat
- **Domain:** Web Performance
- **Evidence:** Chat media images are served at original upload resolution without Next.js Image optimization or responsive sizing.
- **Impact:** Slow load times for chat media, especially on mobile connections.
- **Recommendation:** Use Next.js `<Image>` component with responsive sizes for chat media. Add CDN-level image optimization.
- **Status:** OPEN

### P2-QUAL-001: Dependency Freshness Gap
- **Domain:** Maintenance
- **Evidence:** `dart pub outdated` reports 60 upgradable locked dependencies, 12 constrained below resolvable versions.
- **Impact:** Increasing security and compatibility drift.
- **Recommendation:** Create phased dependency upgrade plan: patch/minor first, then major with migration tests.
- **Status:** OPEN

### P2-QUAL-002: No Web Unit Tests
- **Domain:** Testing
- **Evidence:** `crush-web/` has no unit test files. No test runner configuration detected.
- **Impact:** Web-specific logic (auth store, services, utilities) has zero automated test coverage.
- **Recommendation:** Set up Vitest or Jest for web app. Add tests for auth store, Firebase config, API routes, and utility functions.
- **Status:** OPEN

### P2-ARCH-004: Orphaned `/lib/core/result.dart` (Resolved)
- **Domain:** Architecture
- **Evidence:** Duplicate `Result` class file found at `/lib/core/result.dart` alongside the canonical `/lib/core/utils/result.dart`.
- **Status:** RESOLVED -- orphaned file deleted

---

## P3 -- Low Priority / Improvements

### P3-ARCH-001: Router File Too Large
- **Domain:** Architecture
- **Evidence:** `lib/core/router.dart` contains all 56 route definitions, redirect logic, and auth guards in a single file.
- **Impact:** High change risk and cognitive load.
- **Recommendation:** Split into modular route files by feature domain (auth routes, settings routes, discovery routes, etc.).
- **Status:** OPEN

### P3-ARCH-002: Missing API/Event Contract Documentation
- **Domain:** Documentation
- **Evidence:** 36 callable functions + 29 REST endpoints + 5 Firestore triggers + 2 Pub/Sub jobs lack a unified API contract catalog.
- **Impact:** Onboarding complexity and incident response difficulty.
- **Recommendation:** Publish canonical API catalog with auth/rate-limit/schema per endpoint.
- **Status:** OPEN

### P3-QUAL-001: Audit Deliverables Incomplete
- **Domain:** Documentation
- **Evidence:** Some role-specific diagrams (architecture, ER, data flow) are still pending.
- **Impact:** Collaboration friction and slower execution.
- **Recommendation:** Complete diagram set in `audit/05_role_deliverables/`.
- **Status:** IN PROGRESS

### P3-WEB-001: Web Build Size Not Optimized
- **Domain:** Web Performance
- **Evidence:** No bundle analysis has been performed on the Next.js web build.
- **Recommendation:** Run `@next/bundle-analyzer` and identify optimization opportunities (tree-shaking, dynamic imports, code splitting).
- **Status:** OPEN

---

## Strengths Identified

### Security Strengths
- Sign in with Apple implemented (`sign_in_with_apple` package)
- End-to-end encryption for chat (AES-GCM 256-bit with SHA-256 key derivation)
- Certificate pinning capable (via network layer)
- Secure logging via `SecureLogger` (token redaction)
- GDPR compliance infrastructure (consent service, data export, account deletion flow)
- Firebase App Check implemented (DeviceCheck for iOS, Play Integrity for Android)
- Rate limiting on auth endpoints (OTP, login, signup, password reset)
- Rate limiting on safety endpoints (report, block, unblock)
- HttpOnly auth cookies for web (CSRF protection)

### Architecture Strengths
- Feature-first architecture with 13 feature modules
- Proper dependency injection via `get_it` pattern in `lib/core/di.dart`
- 24 BLoCs/Cubits for state management (good separation)
- 77 use cases following single-responsibility principle
- Clean separation of repository interface and implementation (Firebase, HTTP, Stub)
- Three repository implementations per feature (Firebase, HTTP, Stub) enabling flexible deployment

### Web Strengths
- Next.js 16 with App Router
- TypeScript strict mode enabled
- Full SEO implementation (JSON-LD, sitemap, robots.txt, OG images)
- Comprehensive metadata on all pages
- 24/24 smoke tests passing
- GDPR cookie consent banner
- CSRF protection via Origin/Referer verification

---

## Finding Count Summary

| Priority | Open | Mitigated | Resolved | Total |
|----------|------|-----------|----------|-------|
| P0 | 2 | 2 | 0 | 4 |
| P1 | 5 | 0 | 2 | 7 |
| P2 | 11 | 0 | 1 | 12 |
| P3 | 3 | 0 | 0 | 3 |
| **Total** | **21** | **2** | **3** | **26** |
