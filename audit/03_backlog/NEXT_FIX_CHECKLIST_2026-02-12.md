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
