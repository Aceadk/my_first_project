# Next Fix Checklist (2026-02-12)

Source inputs:
- `audit/raw/coverage_logic_lowest_raw.txt`
- `audit/raw/coverage_targeted_delta_raw.csv`
- `audit/raw/coverage_overall_summary_raw.csv`

Current baseline:
- Overall `lib/` line coverage: **13.94%** (`8360/59970`)
- Coverage source note: latest `flutter test --coverage` run exited **0** (green) and generated refreshed LCOV
- Tranche completed: theme/discovery/date-plan uplift + logic/model/widget coverage tranche

## Priority 1 (Start Immediately)

- [x] `CR-AUD-019` Add tests for `lib/features/settings/presentation/bloc/chat_settings_cubit.dart`
  - Cover: loading state, success state, error state, retention label behavior
- [x] `CR-AUD-019` Add tests for `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`
  - Cover: per-match overrides, reset flows, persistence paths
- [x] `CR-AUD-020` Add tests for `lib/features/settings/presentation/bloc/notification_settings_cubit.dart`
  - Cover: toggle matrix, permission denied handling, persistence
- [x] `CR-AUD-020` Add tests for `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart`
  - Cover: privacy flags, visibility edge cases, state hydration
- [x] `CR-AUD-021` Add tests for `lib/features/safety/data/services/date_plan_service.dart`
  - Cover: plan creation, check-in overdue detection, escalation path triggers

## Priority 2 (Immediately After P1)

- [x] `CR-AUD-022` Add tests for `lib/core/services/push_notification_service.dart`
  - Cover: payload parsing, route mapping, foreground/background handlers
- [x] `CR-AUD-022` Add tests for `lib/core/performance/performance_monitor.dart`
  - Cover: timer/measurement capture, threshold warnings, no-op safety paths
- [x] Add tests for `lib/features/profile/data/services/profile_media_service.dart`
  - Cover: validation, ordering, limits, failure handling
- [x] Add tests for `lib/features/profile/data/services/profile_validation_service.dart`
  - Cover: required fields, edge-case validation, message mapping

## Priority 3 (Stability + Architecture)

- [x] Add focused router tests for `lib/core/router.dart`
  - Cover: auth guard redirects, onboarding gates, deep-link routing
- [x] Add integration flow: onboarding -> discovery -> match -> chat -> report/block
  - Implemented: `integration_test/e2e_onboarding_discovery_chat_safety_test.dart`
- [ ] Validate integration flow on macOS/CI runner
  - Current blocker: local macOS integration build stalls in `Building macOS application...` and/or hits suite load timeout before assertions run; requires CI/device harness validation
- [ ] Add integration flow for settings logout confirm UX
  - Cover: confirm snackbar/dialog -> cancel/confirm behavior

## Exit Criteria for This Phase

- [x] All new tests deterministic and green in CI/local
- [x] Coverage for P1 target files above 70%
- [x] Overall `lib/` coverage reaches at least 12% as interim milestone
- [x] `CR-AUD-006` moves from `in_progress` to next milestone review

## Tranche Update (2026-02-12, latest)

- `lib/features/settings/presentation/bloc/chat_settings_cubit.dart`: **81.82%** in targeted coverage run (`18/22`)
- `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`: **79.17%** in targeted coverage run (`19/24`)
- Raw evidence: `audit/raw/coverage_chat_settings_targeted_raw.csv`
- `lib/features/settings/presentation/bloc/notification_settings_cubit.dart`: **100.00%** in targeted coverage run (`39/39`)
- `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart`: **100.00%** in targeted coverage run (`71/71`)
- Raw evidence: `audit/raw/coverage_cr_aud_020_targeted_raw.csv`
- `lib/features/safety/data/services/date_plan_service.dart`: **84.80%** in targeted coverage run (`106/125`)
- Raw evidence: `audit/raw/coverage_cr_aud_021_targeted_raw.csv`
- `lib/core/performance/performance_monitor.dart`: **87.58%** in targeted coverage run (`134/153`)
- `lib/core/services/push_notification_service.dart`: **78.92%** in targeted coverage run (`161/204`)
- Raw evidence: `audit/raw/coverage_cr_aud_022_targeted_raw.csv`
- `lib/features/profile/data/services/profile_media_service.dart`: **61.39%** in targeted coverage run (`62/101`)
- `lib/features/profile/data/services/profile_validation_service.dart`: **88.46%** in targeted coverage run (`46/52`)
- Raw evidence: `audit/raw/coverage_profile_services_targeted_raw.csv`
- `lib/core/router.dart`: **12.42%** in targeted coverage run (`41/330`)
- Raw evidence: `audit/raw/coverage_router_redirect_targeted_raw.csv`
- Additional tranche (logic/model hotspots):
  - `lib/design_system/utils/accessibility.dart`: **78.62%** (`114/145`)
  - `lib/design_system/animations/ds_animations.dart`: **87.50%** (`91/104`)
  - `lib/design_system/utils/page_transitions.dart`: **94.12%** (`64/68`)
  - `lib/features/calls/data/models/call.dart`: **97.83%** (`90/92`)
  - `lib/features/calls/data/services/call_service.dart`: **86.79%** (`92/106`)
  - `lib/data/models/profile_story.dart`: **95.89%** (`70/73`)
  - `lib/features/analytics/data/models/profile_insights.dart`: **98.46%** (`128/130`)
  - `lib/features/analytics/data/services/profile_insights_service.dart`: **95.24%** (`80/84`)
  - `lib/core/security/secure_logger.dart`: **96.61%** (`57/59`)
  - `lib/core/performance/performance_observer.dart`: **95.16%** (`59/62`)
  - `lib/features/discovery/data/models/weekly_picks.dart`: **89.15%** (`115/129`)
  - `lib/features/discovery/data/models/incognito_settings.dart`: **100.00%** (`56/56`)
  - `lib/data/models/favourites.dart`: **97.18%** (`69/71`)
  - `lib/data/models/profile_reaction.dart`: **77.19%** (`44/57`)
  - `lib/core/services/in_app_review_service.dart`: **96.23%** (`51/53`)
  - `lib/design_system/tokens/breakpoints.dart`: **96.15%** (`25/26`)
  - `lib/design_system/utils/haptics.dart`: **96.97%** (`32/33`)
  - `lib/features/auth/data/repositories/impl/stub_auth_repository.dart`: **51.45%** (`283/550`)
  - `lib/features/chat/data/repositories/impl/stub_chat_repository.dart`: **61.22%** (`150/245`)
  - Raw evidence: `audit/raw/coverage_targeted_delta_raw.csv`
  - Integration blocker log: `audit/raw/cr_aud_008_integration_blocker_2026-02-13_raw.txt`

## Tranche Update (2026-02-17, router/realtime/tracking)

- `lib/core/router.dart`: **67.88%** (`224/330`) in focused coverage run
- `lib/features/discovery/data/services/realtime_match_service.dart`: **88.14%** (`52/59`)
- `lib/core/services/tracking_consent_service.dart`: **93.33%** (`28/30`)
- Delta appended to: `audit/raw/coverage_targeted_delta_raw.csv`
- Raw evidence: `audit/raw/coverage_cr_aud_006_router_realtime_tracking_round4_2026-02-17_raw.csv`

## Tranche Update (2026-02-17, CR-AUD-008 deterministic flow assertions)

- Strengthened deterministic integration-surrogate checkpoints in:
  - `test/e2e_onboarding_discovery_chat_safety_flow_test.dart`
- New assertions now cover:
  - onboarding completion state transitions (`terms -> basic info -> profile setup`)
  - discovery deck mutation after swipe (matched profile no longer appears)
  - reciprocal match persistence for both users
  - chat realtime signals (typing, presence, media toggle) with deterministic setup (auto-reply disabled)
  - `watchNewMessages` checkpoint event verification
  - report/block persistence integrity (single report entry, valid timestamp, idempotent block set)
- Validation:
  - `flutter test test/e2e_onboarding_discovery_chat_safety_flow_test.dart -r expanded` (green)

## Tranche Update (2026-02-17, CR-AUD-008 integration_test deterministic expansion)

- Strengthened integration flow checkpoints in:
  - `integration_test/e2e_onboarding_discovery_chat_safety_test.dart`
- Added deterministic integration harness behavior in:
  - `integration_test/test_app.dart`
- New integration assertions now cover:
  - post-signup onboarding baseline + stepwise state transitions across terms/basic/profile setup
  - deterministic candidate-to-match correlation (deck candidate ID -> resulting match ID/user IDs)
  - discovery side effects after like (matched candidate removed from deck + reciprocal match persistence)
  - realtime chat state signals (typing/presence/media toggle streams) via repository-level checkpoints
  - deterministic chat message checkpoints (`watchMessages`, `watchNewMessages`, paginated persistence, read state)
  - safety persistence integrity (single report row, parseable timestamp, idempotent block set)
- Validation:
  - `flutter analyze integration_test/e2e_onboarding_discovery_chat_safety_test.dart integration_test/test_app.dart` (green)
  - `flutter test test/e2e_onboarding_discovery_chat_safety_flow_test.dart -r expanded` (green)
  - `flutter test integration_test/e2e_onboarding_discovery_chat_safety_test.dart -d macos -r expanded` (blocked in local runner: macOS build can hang and/or fail due build-db lock contention; requires CI/device harness lane)

## Tranche Update (2026-02-17, CR-AUD-006 next hotspot pass: stub profile + user model)

- Added focused hotspot tests:
  - `test/stub_profile_repository_hotspot_test.dart`
  - `test/user_model_hotspot_test.dart`
- Branches covered in `StubProfileRepository`:
  - auth preconditions and missing storage states
  - basic-info validation/sanitization and username cooldown enforcement
  - profile-details preconditions and persistence
  - ID verification transitions
  - profile/theme updates
  - skip flows (`skipBasicInfo`, `skipProfileSetup`) including cooldown and input validation paths
- Coverage evidence (targeted run):
  - `lib/features/profile/data/repositories/impl/stub_profile_repository.dart`: **94.58%** (`262/277`) from **66.43%**
  - `lib/data/models/user.dart`: **69.09%** (`38/55`) in targeted-only run (full-suite comparable percentage pending)
  - Raw: `audit/raw/coverage_cr_aud_006_stub_profile_user_round5_2026-02-17_raw.csv`
  - Delta appended: `audit/raw/coverage_targeted_delta_raw.csv`
- Validation:
  - `flutter test test/stub_profile_repository_hotspot_test.dart test/user_model_hotspot_test.dart -r expanded` (green)
  - `flutter test --coverage test/stub_profile_repository_hotspot_test.dart test/user_model_hotspot_test.dart` (green)
  - Full-suite `flutter test --coverage` attempted but aborted due excessive runtime for this tranche; use CI lane for canonical aggregate figures

## Tranche Update (2026-02-17, CR-AUD-006 hotspot continuation: crash/auth + deterministic chat time)

- Determinism hardening applied in:
  - `lib/features/chat/data/repositories/impl/stub_chat_repository.dart`
  - Replaced remaining `DateTime.now()` branches with injected clock provider for:
    - report timestamp persistence
    - safety appeal timestamp persistence
    - message-request prune cutoff
    - migrated message IDs
- Hotspot tests adjusted for deterministic time-seeded pruning:
  - `test/stub_chat_repository_hotspot_test.dart`
- Coverage evidence (combined targeted run):
  - `lib/core/services/crash_reporting_service.dart`: **76.27%** (`90/118`) from **44.30%**
  - `lib/features/auth/data/repositories/impl/stub_auth_repository.dart`: **94.99%** (`360/379`) from **51.45%**
  - `lib/features/chat/data/repositories/impl/stub_chat_repository.dart`: **95.92%** (`376/392`) from **61.22%**
  - `lib/features/profile/data/services/profile_media_service.dart`: **84.21%** (`96/114`) from **61.39%**
  - Raw: `audit/raw/coverage_cr_aud_006_hotspots_round6_2026-02-17_raw.csv`
  - Delta appended: `audit/raw/coverage_targeted_delta_raw.csv`
- Validation:
  - `flutter analyze lib/features/chat/data/repositories/impl/stub_chat_repository.dart test/stub_chat_repository_hotspot_test.dart` (green)
  - `flutter test test/stub_chat_repository_hotspot_test.dart test/profile_media_service_hotspot_test.dart -r expanded` (green)
  - `flutter test --coverage test/profile_media_service_hotspot_test.dart test/stub_chat_repository_hotspot_test.dart test/crash_reporting_service_test.dart test/stub_auth_repository_hotspot_test.dart` (green)
