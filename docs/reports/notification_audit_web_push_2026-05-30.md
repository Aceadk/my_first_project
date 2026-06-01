# Notification Audit + Web Push Parity — 2026-05-30

Scope: `NOTIF-001`, `NOTIF-002`, `NOTIF-003`, and `NOTIF-004` from
`docs/TODO_NOTIFICATIONS.md`. Surfaces: Flutter mobile notification service and
settings, notification route handling, Cloud Functions delivery filters, call
signaling pushes, and the web app in `/Users/ace/crush-web`.

## Summary

The notification module now uses contextual permission prompts instead of asking
on startup, validates notification tap routes through a shared allowlist, syncs
canonical preference fields across clients, and suppresses unwanted server-side
delivery for disabled categories, muted users, and blocked relationships.
Browser push parity was added in the web app with FCM token lifecycle handling,
foreground toasts, background service-worker display, and allowlisted click
routing.

Real OS push delivery still needs device/browser smoke tests because local unit
tests cannot exercise APNs/FCM delivery states.

## NOTIF-001 — Permission Timing

| Surface | Before | Now |
| --- | --- | --- |
| Mobile app startup | `PushNotificationService.initialize()` requested OS notification permission and printed the token during initialization. | Startup only configures channels/handlers; permission is requested from settings/onboarding user action via `requestPushPermissionForCurrentUser`. |
| Mobile token sync | `registerForUser` attempted token persistence immediately. | Token persistence is skipped unless authorization is `authorized` or `provisional`. |
| Web login | No browser push lifecycle. | Login silently syncs only when browser permission is already `granted`; no browser permission prompt is shown at page load. |
| Web settings | No push UX. | The Notifications settings page requests browser permission only when the user enables push. Denied/unsupported states are surfaced without retry loops. |

## NOTIF-002 — Deep-Link Routing Matrix

All mobile notification taps now resolve through `NotificationRouteResolver`,
which accepts only known app routes and known notification types. Malformed,
external, or arbitrary payload routes fall back to the notification center.

| Notification type / payload | Destination |
| --- | --- |
| `message` + `matchId` / `/chat/{matchId}` | `/chat/{matchId}` |
| `match` + `matchId` / `/chat/{matchId}` | `/chat/{matchId}` |
| `like`, `super_like`, like batch | `/likes-you` |
| `profile_view` + `targetId` | `/user-profile/{targetId}` |
| `weekly_picks` | `/weekly-picks` |
| `subscription` | `/settings/subscription` |
| `data_export_ready` or legacy `/settings/account-actions` | account settings route |
| `incoming_call` / `missed_call` / `call_safety_alert` | call or notification-center fallback with call context |
| unknown route, external URL, malformed payload | `/notifications` |

The web service worker and foreground notification initializer use the same
allowlist approach for web paths, mapping mobile payload routes to the matching
web route where needed.

## NOTIF-003 — Preference Sync + Enforcement

| Preference / rule | Client write | Backend enforcement |
| --- | --- | --- |
| `push` | Mobile/web settings write canonical `notificationPrefs.push`; disabling push also deletes the current FCM token. | Optional categories are suppressed when `push` is false. |
| `sound`, `vibration`, `email`, category flags | Mobile/web settings write canonical `notificationPrefs.*` dotted fields without replacing the whole map. | `isNotificationCategoryAllowed` normalizes defaults and checks category flags. |
| `mutedMessages` | Safety mute sync writes `notificationPrefs.mutedMessages`. | Message notifications from muted sender IDs are suppressed. |
| `mutedCalls` | Safety mute sync writes `notificationPrefs.mutedCalls`. | Call notifications from muted caller IDs are suppressed. |
| Blocks | Existing block relationships remain the safety source. | Non-safety push delivery is suppressed when sender/recipient have a direct block relationship. |
| Safety alerts | Read-only always-on in web settings; server category bypasses optional suppression. | Safety alerts remain deliverable even when general push/categories are off. |
| Queue flush | Existing queued notifications are re-evaluated before send. | Current preferences are checked again in `flushNotificationQueue`. |

## NOTIF-004 — Web Push Parity

Implemented in `/Users/ace/crush-web`:

- `packages/core/src/services/notification.ts`: FCM support detection,
  permission request, web token registration/deletion under
  `/users/{uid}/fcmTokens/{token}`, foreground message listener, and shared
  route resolution.
- `apps/web/public/firebase-messaging-sw.js`: Firebase Messaging service
  worker for background notifications and allowlisted notification-click
  navigation.
- `apps/web/src/shared/providers/notification-initializer.tsx`: login-time
  granted-permission token sync and foreground toast display.
- `apps/web/src/app/(app)/settings/notifications/page.tsx`: canonical
  notification preferences and browser push enable/disable UX.
- Shared user/core types now expose `notificationPrefs` and the canonical
  backend preference fields.

## Verification

- `flutter test test/push_notification_service_test.dart test/notification_settings_cubit_test.dart test/core/routing/notification_routes_test.dart test/safety_cubit_test.dart` — passing.
- `flutter analyze lib/core/services/push_notification_service.dart lib/features/settings/data/preferences/notification_preference_sync_service.dart lib/features/settings/presentation/bloc/notification_settings_cubit.dart lib/features/settings/presentation/bloc/safety_cubit.dart lib/features/settings/presentation/screens/notifications_settings_screen.dart lib/app.dart lib/core/routing/notification_routes.dart test/push_notification_service_test.dart test/notification_settings_cubit_test.dart test/core/routing/notification_routes_test.dart test/safety_cubit_test.dart` — no issues.
- `npm run build` and `npm run lint` in `functions/` — clean.
- `npx mocha --exit test/notificationPrefsSyncContract.test.js test/call-signaling.test.js` in `functions/` — 18 passing.
- `pnpm --filter @crush/web typecheck` in `/Users/ace/crush-web` — clean.
- `pnpm --filter @crush/web lint` in `/Users/ace/crush-web` — 0 errors, 37 pre-existing warnings outside this notification slice.

## Manual Smoke Still Required

Before release submission, verify live notification delivery on:

1. iOS foreground, background, and terminated taps.
2. Android foreground, background, and terminated taps.
3. Chrome web push foreground/background notification-click routing.
4. Safari web push on a supported installed/PWA context.
5. Firefox behavior: supported permission UX and graceful unsupported fallback if
   FCM web push is unavailable for the environment.
