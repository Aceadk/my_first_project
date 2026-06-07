# As-Built Route Manifest (Phase 6 Step 11)

- Date: 2026-06-07
- Supersedes the aspirational matrix in `route_deeplink_matrix_2026-06-05.md`
  (which listed target routes as if implemented).
- Sources: mobile `lib/core/routing/crush_routes.dart`; web
  `crush-web/apps/web/src/app/**/page.tsx` (validated by
  `apps/web/src/lib/__tests__/route-existence.test.ts` against
  `route-manifest.ts`).

Status legend: **impl** = implemented on that platform · **target** = planned,
not built · **alias** = accepted alternate that maps to the canonical route ·
**n/a** = intentionally not on that platform.

| Feature | Mobile route | Web route | Status |
|---|---|---|---|
| Root/launch | `/` `/splash` `/home` | `/` | impl both |
| Login | `/auth/login` | `/auth/login` | impl both |
| Sign up | `/auth/signup` | `/auth/signup` | impl both |
| Phone auth | `/auth/phone` | `/auth/phone` | impl both |
| OTP | `/auth/otp` | (in `/auth/phone` flow) | impl mobile; web inline |
| Email auth | `/auth/email` | (login/signup) | impl mobile |
| Forgot password | `/auth/forgot` | `/auth/forgot-password` | impl both (alias names) |
| Reset password | `/auth/reset` | (email-link flow) | impl mobile |
| Email verification | `/email-verification` | `/auth/verify-email` | impl both |
| Email link finish | n/a | `/finishSignIn` | impl web |
| Device verify | `/new-device` | `/auth/device-verify` (+ `/complete`) | impl both |
| Auth callback | n/a | `/auth/callback` | impl web |
| Onboarding | `/basic-info` `/profile-setup` `/id-verification` | `/onboarding` | impl both (web single-flow) |
| Discovery | `/home` (deck) | `/discover` | impl both |
| Matches | (chats list) | `/matches` | impl both |
| Chat list | (in app) | `/messages` | impl both |
| Chat thread | `/chat/:matchId` | `/messages/:matchId` | impl both |
| Message requests | `/message-requests` | `/messages/requests` | impl both |
| Likes you | `/likes-you` | `/likes` | impl both (alias) |
| Weekly picks | `/weekly-picks` | `/weekly-picks` | impl both |
| Compatibility quiz | `/compatibility-quiz` | `/compatibility-quiz` | impl both |
| Date ideas | `/date-ideas` | `/date-ideas` | impl both |
| Profile (own) | `/profile` | `/profile` | impl both |
| Profile edit | `/profile/edit` | `/profile/edit` | impl both |
| Profile media | `/profile/media` | (in edit) | impl mobile |
| Profile preview | n/a | `/profile/preview` | impl web |
| **View other profile** | `/user-profile/:id` | **— (no page)** | **impl mobile; web target** |
| Profile insights | `/profile-insights` | `/insights` | impl both (alias) |
| Safety center | `/safety` | `/date-safety` | impl both (alias) |
| Story viewer | `/story-viewer` | **— (target)** | impl mobile; web target |
| Paywall / premium | `/paywall` | `/premium` | impl both (alias) |
| Premium success/cancel | (native IAP) | `/premium/success` `/premium/cancel` | impl web |
| Settings home | `/settings` | `/settings` | impl both |
| Account settings | `/settings/account` | `/settings/account` | impl both |
| Subscription settings | `/settings/subscription` | `/settings/account` (subsumed) | impl mobile; web subsumes → alias |
| Notifications settings | `/settings/notifications` | `/settings/notifications` | impl both |
| Privacy settings | `/settings/privacy` | `/settings/privacy` | impl both |
| Discovery settings | `/settings/discovery` | `/settings/discovery` | impl both |
| Blocked users | (in settings) | `/settings/blocked` | impl both |
| Incognito | (premium toggle) | `/settings/incognito` | impl both |
| Chat settings | `/settings/chat` | **— (target)** | impl mobile; web target |
| Security settings | `/settings/security` | (device-verify) | impl mobile |
| Notifications center | `/notifications` | → `/messages` (no inbox) | impl mobile; web redirect |
| Calls | `/call` `/call-history` `/incoming-call` `/video-call` | **— (blocked: no web WebRTC)** | impl mobile; web blocked |
| Privacy policy | `/privacy-policy` | `/privacy` | impl both (alias) |
| Terms | `/terms-of-service` | `/terms` | impl both (alias) |
| Community guidelines | `/community-guidelines` | `/guidelines` | impl both (alias) |
| Help / support | `/support` | `/help` `/contact` | impl both |
| Marketing | n/a | `/about` `/features` `/pricing` `/faq` `/safety` | impl web |

## Notification / deep-link alignment

- The web notification resolver (`resolveNotificationRoute`) only navigates to
  **implemented** web routes — enforced by `route-existence.test.ts`
  (`NOTIFICATION_REACHABLE_ROUTES` ⊆ `WEB_ROUTES`). Backend `targetRoute` values
  (`/likes-you`, `/notifications`, `/settings/subscription`, `/call-history`,
  `/incoming-call`, `/safety`, `/chat/:id`) are mapped to real web routes
  (see notification-route-parity tests).
- Legacy deep-link hosts: `crushhour.app`/`www.crushhour.app` accepted as
  redirects to canonical `crush.app` (mobile still emits them pre-infra-migration).

## Aliases / redirects (supported legacy links)

`/chat/:id`→`/messages/:id`, `/likes-you`→`/likes`, `/paywall`→`/premium`,
`/profile-insights`→`/insights`, `/safety`→`/date-safety`,
`/privacy-policy`→`/privacy`, `/terms-of-service`→`/terms`,
`/community-guidelines`→`/guidelines`, `/settings/subscription`→`/settings/account`,
`/notifications`→`/messages`, `/call-history`/`/incoming-call`→`/messages`.

## Web gaps (target / blocked)

- **target:** view-other-profile (`/profile/:userId`), story viewer, chat
  settings page.
- **blocked:** calls (no web WebRTC — Phase: feature parity).
