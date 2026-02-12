# System Inventory (2026-02-12)

## Repository Topology
- Flutter app root: `/Users/ace/my_first_project`
- Major code domains:
- `lib/` (Flutter app source)
- `functions/src/` (Firebase Functions backend)
- `test/` (unit/widget/service tests)
- `integration_test/` (end-to-end/integration tests)
- `web/` (Flutter web shell assets)
- `docs/` (project documentation)

## File Counts (baseline)
Source: `audit/raw/file_counts_raw.csv`
- `lib`: 493 files
- `functions/src`: 6 files
- `test`: 58 files
- `integration_test`: 7 files
- `web`: 7 files
- `docs`: 22 files

## Feature Modules (Flutter)
Source: `audit/raw/feature_modules_raw.txt`
- about
- analytics
- auth
- calls
- chat
- discovery
- feature_flags
- profile
- safety
- settings
- social
- subscription
- verification

## Testing Asset Inventory
Sources:
- `audit/raw/test_files_raw.txt`
- `audit/raw/integration_files_raw.txt`

Counts:
- Unit/widget/service tests: 58 files
- Integration tests: 7 files

Integration suites currently present:
- `integration_test/app_test.dart`
- `integration_test/auth_flow_test.dart`
- `integration_test/chat_flow_test.dart`
- `integration_test/discovery_flow_test.dart`
- `integration_test/e2e_onboarding_to_chat_test.dart`
- `integration_test/test_app.dart`
- `integration_test/test_credentials.dart`
