# Account Management Compliance Audit - 2026-05-30

Scope: `ACCT-001`, `ACCT-002`, and `ACCT-003` from `docs/TODO_ACCOUNT_MGMT.md`.

## Result

The account-management backlog is complete for the current codebase with one remaining release-gate follow-up: run the checklist below against a real staging account before store submission.

## ACCT-001 - Account Deletion Compliance

Status: Pass

Evidence:
- Mobile deletion is discoverable from Settings -> Account Actions -> Delete Account.
- The flow explains deleted data, offers data export first, asks for an optional reason, requires type-to-confirm plus password, schedules deletion with a 14-day grace period, signs the user out, and tells the user how to recover.
- Backend `requestAccountDeletion` requires an authenticated callable context, marks `users/{uid}` as pending deletion, records `account_deletions/{uid}`, and schedules deletion for the grace period.
- Backend `cancelAccountDeletion` clears pending deletion flags when the user recovers within the grace period.
- Backend `processScheduledAccountDeletions` calls `cascadeDeleteUserData`, which deletes user-owned Firestore records, Storage paths, RTDB presence/typing data, auth credentials, and finally the Firebase Auth user.
- Web account surfaces expose account deletion through `/settings/account`, backed by `/Users/ace/crush-web/packages/core/src/services/user.ts`.

Manual staging checklist:
- Sign in with a staging user and navigate Settings -> Account Actions -> Delete Account.
- Request an export when prompted, then continue deletion.
- Confirm that `users/{uid}.isPendingDeletion`, `deletionRequestedAt`, `deletionScheduledAt`, and `account_deletions/{uid}` are written.
- Sign in during the 14-day grace period and verify cancellation clears pending deletion fields.
- For a disposable staging account, force the scheduled deletion path and verify user, profile, messages, matches, likes, blocks, reports, account-tracking records, storage objects, RTDB records, and Firebase Auth user are removed or intentionally retained only where policy requires it.

## ACCT-002 - Data Export And Privacy Rights

Status: Pass

Evidence:
- Mobile data export is discoverable from Settings -> Account Actions -> Export your data and now cross-linked from Settings -> Privacy through the Privacy rights & consent panel.
- Export requests require a signed-in user and use the `requestDataExport` callable.
- Backend `requestDataExport` requires auth, requires verified email for email/password users, enforces a seven-day cooldown, and creates `users/{uid}/dataExportRequests/{requestId}`.
- Backend `processDataExportRequest` produces a JSON export containing account, profile, preferences, matches, likes, messages, and aggregate stats, writes it to private Storage, records the download URL on the request, and sends a completion notification.
- The app keeps a local export fallback for unsupported environments and shares the generated export file only after explicit user confirmation.
- Privacy Policy copy directs users to Settings -> Account -> Account Actions for rights requests.

Manual staging checklist:
- Request an export from mobile and verify the request document transitions from `queued` to `processing` to `completed`.
- Verify unverified email/password users are rejected and phone/Apple/Google authenticated users follow the intended verification rule.
- Verify the export URL opens only for the intended recipient and expires or tokenizes according to the backend-generated URL semantics.
- Verify a second request inside seven days returns the cooldown message.
- Confirm web settings/privacy surfaces route users to the same export/delete support path.

## ACCT-003 - Block, Report, And Consent Surfaces

Status: Pass

Evidence:
- Mobile Safety & Blocking already exposes blocked users, muted message users, muted call users, unblock/unmute actions, reporting guidance, and safety appeal entry.
- Safety & Blocking now exposes report history for recent reports, explains that reports are private, and states that reported profiles are hidden from discovery for 10 days during review.
- `SafetyCubit` now loads profile display data for reported users as well as blocked/muted users.
- `SafetyCubit` now parses persisted report timestamps with full ISO timestamps, matching the format written by `_persist`.
- Privacy settings now shows the local consent timestamp when present, links to Account Actions for export/deletion, and links to the Privacy Policy.
- Web settings expose `/settings/blocked`, privacy-right guidance, and cookie consent through existing web surfaces.

Manual staging checklist:
- Block a user from profile/chat, then verify they appear in Settings -> Safety & Blocking and can be unblocked.
- Report a user from discovery, chat, and call surfaces, then verify they appear in Report history and are hidden from discovery for the 10-day client window.
- Verify report and block backend calls still enforce auth, email verification where applicable, self-action rejection, and rate limiting.
- Accept consent during onboarding or cookie flow, then verify the consent timestamp/status appears in privacy settings on the relevant platform.

## Verification

- `flutter test test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart test/features/settings/domain/commands/account_action_commands_test.dart test/features/settings/presentation/screens/account_actions_settings_screen_localization_test.dart`
- `dart analyze lib/features/settings/presentation/bloc/safety_cubit.dart lib/presentation/screens/safety_screen.dart lib/features/settings/presentation/screens/privacy_settings_screen.dart test/safety_cubit_test.dart test/features/settings/presentation/screens/privacy_settings_screen_localization_test.dart`
- `dart analyze lib/features/settings/presentation/screens/account_actions_settings_screen.dart`
- `npx mocha --exit test/callables.test.js` in `functions/`
