# Unified Notification-Preferences Schema (Phase 7 Step 14)

- Date: 2026-06-07
- Sources: backend `NotificationCategory` + `isNotificationCategoryAllowed`
  (`functions/src/index.ts`); web `WebNotificationPrefs`
  (`packages/core/src/services/notification.ts`).

## Canonical schema (`users/{uid}.notificationPrefs`)

Two channel toggles + the content categories. Category keys MUST match the
backend `NotificationCategory` union so a preference actually gates delivery.

```ts
notificationPrefs: {
  // Channels
  push: boolean;          // device/web push
  email: boolean;         // transactional/email digests
  // Categories (backend NotificationCategory)
  matches: boolean;
  messages: boolean;
  likes: boolean;
  calls: boolean;
  profileViews: boolean;
  promotions: boolean;
  subscriptions: boolean;
  safetyAlerts: boolean;  // NOT user-disableable (always delivered)
}
```

Backend categories (authoritative, 8): `calls, messages, matches, subscriptions,
likes, profileViews, promotions, safetyAlerts`.

### Rules
- A missing category key defaults to **enabled** (opt-out model).
- `safetyAlerts` is always delivered regardless of preference
  (`isNotificationCategoryAllowed` returns true for it).
- `messages` has additional backend gating (e.g. mute windows) layered on top.
- The web `WebNotificationPrefs` now includes `calls` (was missing) so its keys
  are a superset-compatible match of the backend categories + the channel toggles.

## Token metadata + lifecycle

Path: `users/{uid}/fcmTokens/{token}` (owner-scoped rule; backend reads via admin).

```ts
fcmTokens/{token}: {
  platform: 'ios' | 'android' | 'web';
  browser?: string;        // web only (userAgent)
  createdAt: Timestamp;
  updatedAt?: Timestamp;   // web refresh
}
```

Lifecycle:
- **Register:** on permission grant (web: `registerToken`; mobile: on FCM token).
- **Refresh:** SDK token rotation re-writes the doc (`updatedAt`).
- **Revoke:** on sign-out / permission loss — delete the token doc (web
  `deleteCurrentTokenForUser`; mobile `_deleteTokenFromFirestore`).
- **Server cleanup:** the backend prunes invalid tokens on send failure.

## Route targets

Notification `data.targetRoute` is resolved to a real web route by
`resolveNotificationRoute` (validated by `notification-route-parity` +
`route-existence` tests). Every category's destination is an implemented route
(see `route_manifest_2026-06-07.md`).

## Done-when status (Step 14)

- ✅ One preferences schema defined (channels + 8 categories); web aligned to
  include `calls`.
- ✅ Token metadata + lifecycle documented; `users/{uid}/fcmTokens` owner-scoped
  rule (both clients) with rules-emulator coverage.
- ✅ Every notification category's route target is a real route (route-existence
  + parity tests).
- ⏳ **Web push registration/revocation validation across supported browsers** and
  the **mobile device matrix** — operational (needs real browsers/devices +
  VAPID/APNs config). Tracked as release-gate evidence.
