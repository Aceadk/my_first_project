# Route & Deep-Link Matrix - 2026-06-05

**Purpose:** Canonical routing table for mobile routes, web routes, public URLs, notification targets, and redirect/backward-compatibility aliases. Ensures consistent user navigation across all platforms.

---

## Route Categories

1. **Navigation Routes** — In-app navigation (screens/pages)
2. **Deep-Link Schemes** — Mobile app deep links (`crush://`, `https://crush.app/`)
3. **Public URLs** — User-facing canonical URLs for sharing
4. **Notification Routes** — Route names used in push notification payloads
5. **Redirects & Aliases** — Deprecated paths and backward-compat mappings

---

## Master Route Table

### Onboarding & Auth

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Onboarding Start | `/onboarding` | `/onboarding` | *(not shared)* | `onboarding` | — |
| Phone Verification | `/onboarding/verify-phone` | `/onboarding/verify-phone` | — | `onboarding.verify_phone` | — |
| OTP Entry | `/onboarding/otp` | `/onboarding/otp` | — | `onboarding.otp` | — |
| Email Verification | `/onboarding/verify-email` | `/onboarding/verify-email` | — | `onboarding.verify_email` | — |
| Profile Setup | `/onboarding/profile` | `/onboarding/profile` | — | `onboarding.profile` | — |
| Login | `/login` | `/login` | — | `auth.login` | `/sign-in` (alias) |
| Sign Up | `/sign-up` | `/sign-up` | — | `auth.signup` | `/register` (deprecated) |
| Forgot Password | `/forgot-password` | `/forgot-password` | — | `auth.reset_password` | — |
| Account Deleted Confirmation | `/account-deleted` | `/account-deleted` | — | `account.deletion_complete` | — |

### Discovery & Matching

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Discovery Deck | `/discovery` | `/discovery` | `crush.app/discovery` | `discovery.deck` | `/swipe` (deprecated) |
| Likes You | `/likes-you` | `/likes` | `crush.app/likes` | `discovery.likes_you` | `/likes-you` (mobile compat) |
| Matches List | `/matches` | `/messages` | `crush.app/matches` | `matches.list` | `/conversations` (deprecated) |
| Match Profile Preview | `/matches/:matchId/profile` | `/matches/:matchId/profile` | `crush.app/matches/:id` | `matches.profile` | — |
| Boost / Promo | `/discovery/boost` | `/discovery/boost` | `crush.app/discovery/boost` | `discovery.boost` | — |

### Chat & Messages

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Chat Thread | `/chat/:matchId` | `/messages/:matchId` | `crush.app/chat/:id` | `chat.thread` | `/messages/:id` (web format) |
| Message Requests | `/message-requests` | `/messages/requests` | `crush.app/message-requests` | `chat.message_requests` | `/message-requests` (mobile compat) |
| Chat List (Matches) | `/matches` | `/messages` | `crush.app/matches` | `chat.list` | `/conversations` (deprecated) |
| Chat Settings | `/settings/chat` | `/settings/chat` | — | `chat.settings` | — |
| Audio/Video Call | `/call/:matchId` | *(not yet implemented)* | — | `call.incoming` | — |

### Calls & Connections

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Incoming Call | *(CallKit/native)* | `/call/incoming/:callId` | — | `call.incoming` | — |
| Call History | `/calls` | `/calls` | `crush.app/calls` | `calls.history` | — |
| Call Settings | `/settings/calls` | `/settings/calls` | — | `calls.settings` | — |

### Profile & Account

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| My Profile | `/profile/me` | `/profile` | `crush.app/profile` | `profile.me` | — |
| View User Profile | `/profile/:userId` | `/profile/:userId` | `crush.app/profile/:id` | `profile.view` | — |
| Edit Profile | `/profile/edit` | `/profile/edit` | — | `profile.edit` | — |
| Profile Insights | `/profile-insights` | `/insights` | `crush.app/insights` | `profile.insights` | `/profile-insights` (mobile compat) |
| Profile Safety | `/safety` | `/safety` | `crush.app/safety` | `safety.center` | — |
| Date Plans | `/safety/date-plans` | `/safety/date-plans` | `crush.app/date-plans` | `safety.date_plans` | — |

### Settings & Account Management

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Settings Home | `/settings` | `/settings` | — | `settings.home` | — |
| Account Settings | `/settings/account` | `/settings/account` | — | `settings.account` | — |
| Privacy Settings | `/settings/privacy` | `/settings/privacy` | — | `settings.privacy` | — |
| Notification Prefs | `/settings/notifications` | `/settings/notifications` | — | `settings.notifications` | — |
| Blocked Users | `/settings/blocked-users` | `/settings/blocked-users` | — | `settings.blocked_users` | — |
| Device/Security | `/settings/device-trust` | `/settings/device-trust` | — | `settings.device_trust` | — |
| Email Management | `/settings/email` | `/settings/email` | — | `settings.email_address` | — |
| Phone Management | `/settings/phone` | `/settings/phone` | — | `settings.phone_number` | — |
| Data & Privacy | `/settings/data` | `/settings/data` | — | `settings.data_privacy` | — |
| Help & Support | `/settings/help` | `/settings/help` | `crush.app/help` | `settings.help` | — |
| Delete Account | `/settings/delete-account` | `/settings/delete-account` | — | `account.deletion_initiated` | — |

### Subscription & Premium

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Paywall / Premium | `/paywall` | `/premium` | `crush.app/premium` | `subscription.paywall` | `/premium` (web) |
| Subscription Plans | `/subscription/plans` | `/subscription/plans` | `crush.app/premium/plans` | `subscription.plans` | — |
| Manage Subscription | `/subscription/manage` | `/subscription/manage` | — | `subscription.manage` | — |
| Payment Success | `/subscription/success` | `/subscription/success?session_id=...` | — | `subscription.success` | — |
| Payment Failed | `/subscription/failed` | `/subscription/failed` | — | `subscription.failed` | — |

### Legal & Marketing

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| Privacy Policy | `/privacy-policy` | `/privacy` | `crush.app/privacy` | `legal.privacy_policy` | `/privacy` (web) |
| Terms of Service | `/terms-of-service` | `/terms` | `crush.app/terms` | `legal.terms_of_service` | `/terms` (web) |
| Community Guidelines | `/community-guidelines` | `/community` | `crush.app/community` | `legal.community_guidelines` | — |
| FAQ | — | `/faq` | `crush.app/faq` | `help.faq` | — |
| Contact Support | `/help` | `/contact` | `crush.app/contact` | `help.contact` | — |

### Errors & Fallbacks

| Feature | Mobile Route | Web Route | Public URL | Notification Route | Aliases |
|---------|--------------|-----------|-----------|-------------------|---------|
| 404 Not Found | *(system dialog)* | `/404` | — | — | — |
| 500 Server Error | *(system dialog)* | `/500` | — | — | — |
| Network Error | *(offline screen)* | `/offline` | — | — | — |
| Maintenance | `/maintenance` | `/maintenance` | `crush.app/maintenance` | — | — |

---

## Deep-Link Scheme Resolution

### Mobile Deep-Link Format
```
crush://[path]?[query_params]

Examples:
  crush://chat/match123                          → /chat/:matchId
  crush://profile/user456?from=notification      → /profile/:userId + source tracking
  crush://matches                                → /matches
  crush://paywall?offer=month                    → /paywall?offer=month
  crush://discovery                              → /discovery
```

### Web Deep-Link Format (HTTP/HTTPS)
```
https://crush.app[/path]?[query_params]

Examples:
  https://crush.app/messages/match123            → /messages/:matchId
  https://crush.app/profile/user456              → /profile/:userId
  https://crush.app/matches                      → /matches
  https://crush.app/premium?offer=month          → /premium?offer=month
  https://crush.app/discovery                    → /discovery
```

### Universal Links (iOS) & App Links (Android)
Configured via:
- **iOS:** `apple-app-site-association` hosted at `https://crush.app/.well-known/apple-app-site-association`
- **Android:** `assetlinks.json` hosted at `https://crush.app/.well-known/assetlinks.json`

Both files whitelist routes that should open in native app instead of browser:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "com.gyanendra.myfirstproject",
        "paths": [
          "/chat/*",
          "/messages/*",
          "/profile/*",
          "/matches",
          "/calls",
          "/discovery",
          "/premium",
          "/safety/*"
        ]
      }
    ]
  }
}
```

---

## Notification Payload Mapping

### Notification Payload Structure
```json
{
  "notification": {
    "title": "...",
    "body": "..."
  },
  "data": {
    "type": "message|match|like|call|system|promo",
    "targetRoute": "/chat/match123",           // Mobile deep-link (crush://)
    "targetPath": "/messages/match123",        // Web route (/path)
    "targetUrl": "https://crush.app/...",      // Full public URL (fallback)
    "priority": "high|normal",
    "from_user_id": "uid",
    "match_id": "matchId",
    "context": "additional_data"
  }
}
```

### Example Payloads

#### Message Notification
```json
{
  "notification": {
    "title": "Sarah",
    "body": "Hey, how are you?"
  },
  "data": {
    "type": "message",
    "targetRoute": "/chat/alice_bob123",
    "targetPath": "/messages/alice_bob123",
    "from_user_id": "bob_uid",
    "match_id": "alice_bob123"
  }
}
```

#### Match Notification
```json
{
  "notification": {
    "title": "It's a match! 💗",
    "body": "You and Sarah have matched."
  },
  "data": {
    "type": "match",
    "targetRoute": "/chat/alice_bob123",
    "targetPath": "/messages/alice_bob123",
    "match_id": "alice_bob123"
  }
}
```

#### Like Notification
```json
{
  "notification": {
    "title": "Sarah likes you ❤️",
    "body": "Tap to see her profile"
  },
  "data": {
    "type": "like",
    "targetRoute": "/likes-you",
    "targetPath": "/likes",
    "from_user_id": "sarah_uid"
  }
}
```

#### Call Notification
```json
{
  "notification": {
    "title": "Sarah is calling...",
    "body": ""
  },
  "data": {
    "type": "call",
    "targetRoute": "/call/call_id_123",
    "callId": "call_id_123",
    "from_user_id": "sarah_uid",
    "priority": "high"
  }
}
```

#### Subscription Notification
```json
{
  "notification": {
    "title": "Your subscription renewed",
    "body": "Enjoy Crush Plus benefits!"
  },
  "data": {
    "type": "system",
    "targetRoute": "/subscription/manage",
    "targetPath": "/subscription/manage"
  }
}
```

---

## Redirect & Backward-Compatibility Rules

### 301 Permanent Redirects (Use Sparingly)
These indicate a route was permanently renamed/retired.

```
/swipe                    → /discovery
/conversations            → /messages
/likes-you (web)          → /likes
/terms-of-service         → /terms
/privacy-policy           → /privacy
/message-requests (web)   → /messages/requests
/profile-insights (web)   → /insights
/chat (web)               → /messages
```

### 302 Temporary Redirects (For A/B Testing)
```
/premium-trial            → /premium?offer=trial
/boost-today              → /discovery/boost?source=banner
```

### Alias Routes (No Redirect; Both Accepted)
For backward compatibility without changing public URLs:

```
Mobile routes accept both:
  /paywall  ← Primary
  /premium  ← Alias (web compat)

Web routes accept both:
  /premium           ← Primary
  /paywall           ← Alias (mobile compat)

Both platforms accept:
  /chat/:id          → /messages/:id (web only)
  /likes-you         ← /likes (web only)
```

### Domain Redirects
```
crushhour.app            → crush.app (301)
www.crush.app            → crush.app (optional, if no www)
staging.crush.app        → staging environment (not a redirect; separate env)
```

---

## Implementation Checklist

### Mobile Router (`lib/core/routing/*.dart`)
- [ ] Implement route path constants (avoid string literals in Go Router definitions)
- [ ] Add deep-link handlers for all public routes
- [ ] Ensure notification taps route to correct screen
- [ ] Test universal link resolution (`https://crush.app/chat/test123`)

### Web Router (`crush-web/app/router.tsx` or equivalent)
- [ ] Implement Next.js route structure matching `Route` table
- [ ] Add redirect rules for deprecated paths (301 for permanent, 302 for temporary)
- [ ] Implement query parameter handling (`?from=notification`, `?session_id=...`)
- [ ] Test browser back/forward with deep links

### Backend (`functions/src/index.ts`)
- [ ] Add `targetRoute` resolution logic in notification sending
- [ ] Validate `targetRoute` against this matrix before sending
- [ ] Add tests for payload mapping by notification type

### Infrastructure
- [ ] Upload `apple-app-site-association` to `https://crush.app/.well-known/`
- [ ] Upload `assetlinks.json` to `https://crush.app/.well-known/`
- [ ] Configure web server redirect rules for deprecated routes
- [ ] Test redirect chain doesn't exceed 5 hops

---

## Testing Routes & Deep Links

### Manual Testing Checklist

#### Mobile App
```bash
# Test deep links via adb (Android)
adb shell am start -a android.intent.action.VIEW -d "crush://chat/match123" com.gyanendra.myfirstproject

# Test deep links via xcrun (iOS)
xcrun simctl openurl booted "crush://profile/user456?from=notification"

# Test universal links
xcrun simctl openurl booted "https://crush.app/chat/match123"
```

#### Web App
```bash
# Test route navigation
- Navigate to https://crush.app/messages/match123
- Verify route resolves and chat loads
- Test browser back button

# Test redirect
- Navigate to https://crush.app/swipe
- Verify redirects to https://crush.app/discovery (301)

# Test query params
- Navigate to https://crush.app/premium?offer=month
- Verify offer param is read and applied
```

#### Notifications
```bash
# Send test notification with targetRoute
firebase functions:shell
> notifyUser("user_uid", "message", { targetRoute: "/chat/match123" })

# On mobile: tap notification, verify it opens correct screen
# On web: simulate notification click, verify route navigation
```

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-06-05 | Initial route matrix. 50+ routes mapped across mobile, web, public URLs, notifications. Aliases and redirects for backward compatibility. |
