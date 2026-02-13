# Quality Baseline -- CRUSH Dating App
**Date:** 2026-02-12
**Version:** 2.0 (Comprehensive Update)

---

## 1. Overall Quality Scores

| Domain | Score | Target | Gap |
|--------|-------|--------|-----|
| Security | 7.5/10 | 9.0/10 | -1.5 |
| Architecture | 7.2/10 | 8.5/10 | -1.3 |
| Web | 7.8/10 | 9.0/10 | -1.2 |
| Testing | 5.0/10 | 8.0/10 | -3.0 |
| **Weighted Overall** | **7.0/10** | **8.5/10** | **-1.5** |

---

## 2. Codebase Metrics

### File Counts
| Directory | Files | Description |
|-----------|-------|-------------|
| `lib/` | 493 | Flutter app source |
| `functions/src/` | 6 | Firebase Functions backend |
| `test/` | 58 | Unit/widget/service tests |
| `integration_test/` | 7 | End-to-end/integration tests |
| `web/` | 7 | Flutter web shell assets |
| `docs/` | 22 | Project documentation |
| **Total** | **593** | |

### Feature Module Breakdown (13 modules)
| Feature | Files | Description |
|---------|-------|-------------|
| discovery | 46 | Swiping, matching, boost, weekly picks |
| auth | 31 | Authentication, sessions, onboarding |
| chat | 33 | Messaging, reactions, media, voice notes |
| profile | 32 | Profile management, media, validation |
| settings | 19 | App settings, privacy, notifications |
| social | 21 | Date ideas, compatibility quiz |
| calls | 16 | Voice/video calls |
| feature_flags | 14 | Remote config feature flags |
| safety | 13 | Date safety, emergency contacts |
| subscription | 17 | Premium plans, checkout, promo codes |
| analytics | 11 | Profile insights |
| verification | 11 | Photo/ID verification |
| about | 2 | Product features, pricing screens |

### Architecture Components
| Component Type | Count |
|----------------|-------|
| BLoCs | 10 |
| Cubits | 14 + 1 (BadgeCounterCubit in core) |
| Use Cases | 77 |
| Repositories (interfaces) | ~10 |
| Repository Implementations | ~30 (Firebase + HTTP + Stub per interface) |
| Data Models | ~25 |
| Services | ~15 |
| Screens/Pages | ~40 |
| Widgets (custom) | ~35 |
| Routes (declared) | 56 |

---

## 3. Static Analysis

### Flutter Analyze
- **Command:** `flutter analyze --no-pub`
- **Result:** PASS
- **Output:** `No issues found!`
- **Errors:** 0
- **Warnings:** 0
- **Info:** 0

### Functions Lint
- **Command:** `cd functions && npm run lint`
- **Result:** PASS
- **Errors:** 0

### Functions Tests
- **Command:** `cd functions && npm test`
- **Result:** PASS
- **Passing:** 11
- **Failing:** 0

---

## 4. Test Coverage

### Flutter Test Suite
- **Command:** `flutter test`
- **Result:** PASS
- **Tests Passing:** 444
- **Tests Skipped:** 6
- **Tests Failing:** 0

### Test File Inventory
- **Total test files:** 46 (excluding mocks, goldens, credentials)
- **Lib files:** 472 (excluding generated)
- **Test-to-file ratio:** 9.7%
- **Target:** 80% business logic coverage

### Line Coverage
- **Command:** `flutter test --coverage`
- **Coverage artifact:** `coverage/lcov.info`
- **Lines covered:** 6,075
- **Lines total:** 59,435
- **Line coverage:** 10.22%
- **Target:** >= 80% business logic
- **Gap:** MAJOR (69.78 percentage points below target)
- **Note:** Latest full coverage run exited non-zero due an existing flaky timeout in `test/matches_bloc_test.dart`; LCOV was still generated and used for baseline math.

### Coverage by Area (Targeted Results)
| File | Coverage | Lines |
|------|----------|-------|
| `lib/core/theme/app_theme_mode.dart` | 100.00% | -- |
| `lib/features/settings/presentation/bloc/theme_cubit.dart` | 100.00% | -- |
| `lib/features/settings/presentation/bloc/notification_settings_cubit.dart` | 100.00% | 39/39 |
| `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart` | 100.00% | 71/71 |
| `lib/features/safety/data/models/date_plan.dart` | 98.37% | -- |
| `lib/features/profile/data/services/profile_validation_service.dart` | 88.46% | 46/52 |
| `lib/core/performance/performance_monitor.dart` | 87.58% | 134/153 |
| `lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart` | 85.78% | -- |
| `lib/features/safety/data/services/date_plan_service.dart` | 84.80% | 106/125 |
| `lib/features/settings/presentation/bloc/chat_settings_cubit.dart` | 81.82% | 18/22 |
| `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` | 79.17% | 19/24 |
| `lib/features/profile/data/services/profile_media_service.dart` | 61.39% | 62/101 |
| `lib/core/services/push_notification_service.dart` | 78.92% | 161/204 |
| `lib/core/router.dart` | 12.42% | 41/330 |

### Recently Added Tests (This Sprint)
| Test File | Tests | Coverage Area |
|-----------|-------|---------------|
| `test/content_moderation_test.dart` | 58 | Profanity detection, text analysis, report validation |
| `test/subscription_test.dart` | 42 | Plan enums, status model, BLoC transitions |
| `test/data_export_test.dart` | 19 | Data formatting, error handling, progress callbacks |
| `test/consent_service_test.dart` | 14 | Consent grant/revoke, persistence |
| `test/tracking_consent_test.dart` | 6 | ATT tracking status, platform behavior |
| **Total new** | **137** | |

### Test Coverage Gaps (Critical)
| Area | Status | Risk |
|------|--------|------|
| BLoC unit tests (24 BLoCs) | Missing | HIGH -- state transition regressions undetectable |
| Widget tests | Minimal | MEDIUM -- UI regressions |
| Integration tests | 7 files, timeout issues | MEDIUM -- flow regressions |
| Web unit tests | None | HIGH -- web logic untested |
| Repository integration tests | Minimal | MEDIUM -- data layer regressions |

---

## 5. Dependency Health

### Flutter Dependencies
- **Direct dependencies:** 50
- **Upgradable locked:** 60
- **Constrained below resolvable:** 12
- **Key packages:** flutter_bloc, go_router 17, firebase_* suite, sign_in_with_apple, crypto/cryptography

### Functions Dependencies
- **Runtime dependencies:** 10
- **Dev dependencies:** 11
- **NPM audit:** 0 high/critical vulnerabilities
- **Key packages:** firebase-functions, firebase-admin, express, stripe, agora-access-token

---

## 6. CI Gate Health

| Gate | Status | Notes |
|------|--------|-------|
| Flutter analyze | GREEN | No issues found |
| Flutter tests | GREEN | 444 passing, 6 skipped, 0 failing |
| Flutter coverage | RED | 10.22% vs 80% target |
| Functions lint | GREEN | 0 errors |
| Functions tests | GREEN | 11 passing |
| Web build | GREEN | 48 pages compiled, 0 errors |
| Web smoke tests | GREEN | 24/24 passing |
| Integration tests | YELLOW | 7 files exist but device timeout issues |

---

## 7. Architecture Compliance

### Clean Architecture Violations
- **Files violating layer boundaries:** 73
- **Pattern:** Presentation layer files importing directly from data layer
- **Most affected features:** auth, chat, discovery, profile
- **Target:** 0 violations

### BLoC Complexity
| BLoC/Cubit | LOC | Status |
|------------|-----|--------|
| ChatBloc | 824 | OVER LIMIT (target: <300) |
| DiscoveryBloc | ~500 | BORDERLINE |
| AuthBloc | ~400 | BORDERLINE |
| ProfileBloc | ~350 | BORDERLINE |
| All others | <300 | OK |

### Code Smells
| Smell | Count | Target |
|-------|-------|--------|
| `debugPrint` statements | ~260 | 0 |
| Duplicate DTOs | Multiple | Shared DTO layer |
| TypeScript `any` (web) | 3 files | 0 |
| `console.log` (web) | 25 files | 0 |

---

## 8. Interpretation and Trend

### Positive Trends
- Flutter analyzer is clean (0 issues)
- Functions lint and tests restored to green
- 137 new tests added this sprint (307 -> 444 total)
- Content moderation bug (R-125) discovered and fixed via testing
- Security mitigations applied for CORS and App Check

### Primary Remaining Risks
1. **Test coverage gap is the largest quality risk** -- 10.22% vs 80% target means most code paths are untested
2. **73 clean architecture violations** indicate structural debt that will compound
3. **ChatBloc at 824 LOC** is the most complex state management unit and has no dedicated tests
4. **No web unit tests** means all web-specific logic is verified only by smoke tests

### Recommended Quality Targets (Next 30 Days)
| Metric | Current | 2-Week Target | 4-Week Target |
|--------|---------|---------------|---------------|
| Test coverage (line) | 10.22% | 25% | 40% |
| Architecture violations | 73 | 50 | 30 |
| BLoC tests | 0/24 | 8/24 | 16/24 |
| debugPrint count | ~260 | 130 | 0 |
| Web unit tests | 0 | 15 | 40 |
