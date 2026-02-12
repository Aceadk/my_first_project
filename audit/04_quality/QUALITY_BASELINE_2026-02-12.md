# Quality Baseline (2026-02-12)

## Command Results

### Flutter Analyze
- Command: `flutter analyze`
- Result: PASS
- Output: `No issues found!`

### Flutter Test + Coverage
- Command: `flutter test --coverage`
- Result: PASS
- Coverage artifact: `coverage/lcov.info`
- Line coverage baseline: 4522 / 58952 = **7.67%**
- Target from directive: >= 80% business logic coverage
- Gap: **major**
- Raw reports:
  - `audit/raw/coverage_lib_file_counts_raw.csv`
  - `audit/raw/coverage_by_file_lowest_raw.txt`
  - `audit/raw/coverage_logic_lowest_raw.txt`
  - `audit/raw/coverage_targeted_delta_raw.csv`

### Coverage Delta (This Tranche)
- `lib/core/theme/app_theme_mode.dart`: `0.00% -> 100.00%` (`+100.00`)
- `lib/features/settings/presentation/bloc/theme_cubit.dart`: `0.00% -> 100.00%` (`+100.00`)
- `lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart`: `0.00% -> 85.78%` (`+85.78`)
- `lib/features/safety/data/models/date_plan.dart`: `0.00% -> 83.74%` (`+83.74`)

### Additional Targeted Coverage (Post-Baseline)
- Command: `flutter test --coverage test/chat_settings_cubit_test.dart`
- `lib/features/settings/presentation/bloc/chat_settings_cubit.dart`: `81.82%` (`18/22`)
- `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`: `79.17%` (`19/24`)
- Raw report: `audit/raw/coverage_chat_settings_targeted_raw.csv`

### Functions Test
- Command: `cd functions && npm test`
- Result: PASS
- Passing: 11
- Failing: 0

### Functions Lint
- Command: `cd functions && npm run lint`
- Result: PASS
- Errors: 0

## CI Gate Health (Current)
- Flutter analyze gate: green locally
- Flutter tests gate: green locally (coverage low)
- Functions lint gate: green locally
- Functions tests gate: green locally

## Interpretation
Major backend gate blockers were resolved in this iteration; primary remaining quality risk is low effective coverage versus directive thresholds.
