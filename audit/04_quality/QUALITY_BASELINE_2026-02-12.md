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
- Line coverage baseline: 4185 / 58952 = **7.10%**
- Target from directive: >= 80% business logic coverage
- Gap: **major**

### Functions Test
- Command: `cd functions && npm test`
- Result: FAIL
- Passing: 8
- Failing: 3
- Failing suite: `profile completeness helpers`
- Error: `TypeError: evaluateProfileCompleteness is not a function`
- Error: `ensureProfileQuality ... expected HttpsError`

### Functions Lint
- Command: `cd functions && npm run lint`
- Result: FAIL
- Errors: 14
- Includes:
- ESLint/TS config mismatch for generated d.ts (`src/dataconnect-admin-generated/index.d.ts`)
- Unused vars and typed-lint issues in `functions/src/index.ts`

## CI Gate Health (Current)
- Flutter analyze gate: green locally
- Flutter tests gate: green locally (coverage low)
- Functions lint gate: red locally
- Functions tests gate: red locally

## Interpretation
Release-quality gates are currently blocked by backend lint/test failures and very low effective coverage baseline against directive thresholds.
