# TODO: Account Management Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_AUTH_SECURITY.md`, `docs/TODO_STORE_APPLE.md`, `docs/TODO_STORE_GOOGLE.md`
- Assigned: AI + Developer

## Tasks

### ACCT-001 - Verify in-app account deletion compliance
- Files: settings/account actions, backend deletion handlers, web account surfaces
- Description: Confirm users can find and complete account deletion from within the app without contacting support.
- Acceptance Criteria: deletion path is discoverable, complete, and documented for store compliance.
- Testing: manual deletion checklist and backend cleanup verification.
- Status: completed 2026-05-30
- Evidence: `docs/reports/account_management_compliance_2026-05-30.md`
- Verification: `flutter test test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart test/features/settings/domain/commands/account_action_commands_test.dart test/features/settings/presentation/screens/account_actions_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/bloc/safety_cubit.dart lib/presentation/screens/safety_screen.dart lib/features/settings/presentation/screens/privacy_settings_screen.dart test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/screens/account_actions_settings_screen.dart`, `npx mocha --exit test/callables.test.js` in `functions/`
- Manual Follow-up: run the staging account deletion checklist in `docs/reports/account_management_compliance_2026-05-30.md` before store submission.

### ACCT-002 - Audit data export and privacy-right workflows
- Files: privacy settings, export endpoints/jobs, support/help content
- Description: Verify data portability and privacy-right requests are possible, understandable, and appropriately secured.
- Acceptance Criteria: export flow has authentication, progress, and delivery semantics defined.
- Testing: manual export runbook and backend authorization tests.
- Status: completed 2026-05-30
- Evidence: `docs/reports/account_management_compliance_2026-05-30.md`
- Verification: `flutter test test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart test/features/settings/domain/commands/account_action_commands_test.dart test/features/settings/presentation/screens/account_actions_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/bloc/safety_cubit.dart lib/presentation/screens/safety_screen.dart lib/features/settings/presentation/screens/privacy_settings_screen.dart test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/screens/account_actions_settings_screen.dart`, `npx mocha --exit test/callables.test.js` in `functions/`
- Manual Follow-up: run the staging data-export checklist in `docs/reports/account_management_compliance_2026-05-30.md` before store submission.

### ACCT-003 - Audit block list, report history, and consent-management surfaces
- Files: privacy/account settings, support/report views
- Description: Ensure users can review block/report/account-consent state with clear consequences and next actions.
- Acceptance Criteria: block/report/account-control surfaces are internally consistent and accessible.
- Testing: widget/manual checks with representative account states.
- Status: completed 2026-05-30
- Evidence: `docs/reports/account_management_compliance_2026-05-30.md`
- Verification: `flutter test test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart test/features/settings/domain/commands/account_action_commands_test.dart test/features/settings/presentation/screens/account_actions_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/bloc/safety_cubit.dart lib/presentation/screens/safety_screen.dart lib/features/settings/presentation/screens/privacy_settings_screen.dart test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart`, `dart analyze lib/features/settings/presentation/screens/account_actions_settings_screen.dart`, `npx mocha --exit test/callables.test.js` in `functions/`
- Manual Follow-up: run the staging block/report/consent checklist in `docs/reports/account_management_compliance_2026-05-30.md` before store submission.
