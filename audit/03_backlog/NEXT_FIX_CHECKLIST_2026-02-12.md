# Next Fix Checklist (2026-02-12)

Source inputs:
- `audit/raw/coverage_logic_lowest_raw.txt`
- `audit/raw/coverage_targeted_delta_raw.csv`
- `audit/raw/coverage_overall_summary_raw.csv`

Current baseline:
- Overall `lib/` line coverage: **7.67%** (`4522/58952`)
- Tranche completed: theme/discovery/date-plan model coverage uplift

## Priority 1 (Start Immediately)

- [x] `CR-AUD-019` Add tests for `lib/features/settings/presentation/bloc/chat_settings_cubit.dart`
  - Cover: loading state, success state, error state, retention label behavior
- [x] `CR-AUD-019` Add tests for `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`
  - Cover: per-match overrides, reset flows, persistence paths
- [ ] `CR-AUD-020` Add tests for `lib/features/settings/presentation/bloc/notification_settings_cubit.dart`
  - Cover: toggle matrix, permission denied handling, persistence
- [ ] `CR-AUD-020` Add tests for `lib/features/settings/presentation/bloc/privacy_settings_cubit.dart`
  - Cover: privacy flags, visibility edge cases, state hydration
- [ ] `CR-AUD-021` Add tests for `lib/features/safety/data/services/date_plan_service.dart`
  - Cover: plan creation, check-in overdue detection, escalation path triggers

## Priority 2 (Immediately After P1)

- [ ] `CR-AUD-022` Add tests for `lib/core/services/push_notification_service.dart`
  - Cover: payload parsing, route mapping, foreground/background handlers
- [ ] `CR-AUD-022` Add tests for `lib/core/performance/performance_monitor.dart`
  - Cover: timer/measurement capture, threshold warnings, no-op safety paths
- [ ] Add tests for `lib/features/profile/data/services/profile_media_service.dart`
  - Cover: validation, ordering, limits, failure handling
- [ ] Add tests for `lib/features/profile/data/services/profile_validation_service.dart`
  - Cover: required fields, edge-case validation, message mapping

## Priority 3 (Stability + Architecture)

- [ ] Add focused router tests for `lib/core/router.dart`
  - Cover: auth guard redirects, onboarding gates, deep-link routing
- [ ] Add integration flow for web path: onboarding -> discovery -> match -> chat
  - Cover: end-to-end route transitions and protected-route behavior
- [ ] Add integration flow for settings logout confirm UX
  - Cover: confirm snackbar/dialog -> cancel/confirm behavior

## Exit Criteria for This Phase

- [ ] All new tests deterministic and green in CI/local
- [ ] Coverage for P1 target files above 70%
- [ ] Overall `lib/` coverage reaches at least 12% as interim milestone
- [ ] `CR-AUD-006` moves from `in_progress` to next milestone review

## Tranche Update (2026-02-12, latest)

- `lib/features/settings/presentation/bloc/chat_settings_cubit.dart`: **81.82%** in targeted coverage run (`18/22`)
- `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`: **79.17%** in targeted coverage run (`19/24`)
- Raw evidence: `audit/raw/coverage_chat_settings_targeted_raw.csv`
