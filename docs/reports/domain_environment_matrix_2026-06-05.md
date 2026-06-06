# Domain & Environment Matrix - 2026-06-05

**Purpose:** Establish canonical domain and environment configuration across mobile, web, and backend. Eliminates drift and ensures consistent CORS, metadata, notifications, and public URLs.

**Status:** Planning phase. Requires decision on canonical production domain before implementation.

---

## Current State (Audit Findings)

### Domains Referenced in Code
- `crush.app` — Primary branding domain
- `crushhour.app` — Backend CORS default
- `crush.dating` — Alternate marketing domain
- `crushapp.com` — Possible legacy/regional domain
- `app.crush.dating` — Possible alternate app domain

### Firebase Project
- **Firebase Project ID:** `crush-265f7`
- **Firestore Hosting Site:** `crushapp` (auto-assigns `crushapp.firebaseapp.com` and `crushapp.web.app`)
- **Cloud Functions Runtime:** `us-central1`

### Current Config Locations
| Config | Location | Current Value | Purpose |
|--------|----------|---------------|---------|
| CORS | `functions/src/index.ts` | `crushhour.app` | Allowed origins for REST API |
| CORS | `firestore.rules` | *(implicit)* | Firestore emulator allows localhost |
| Email From | `functions/src/index.ts` | `Crush <no-reply@crushhour.app>` | Outgoing emails |
| Web Metadata | `crush-web/next.config.js` | `crush.app` | OG tags, canonical URL |
| Stripe Success/Cancel URLs | `crush-web/pages/api/checkout.ts` | URL builder | Redirect after payment |
| Notification Routes | `functions/src/index.ts` | hardcoded patterns | Deep link targets |
| Apple Redirect URI | `functions/src/index.ts` | Generated | OAuth callback |
| Google OAuth Redirect | `functions/src/index.ts` | Generated | OAuth callback |

---

## Proposed Environment Matrix

### Environments

#### Development (Local)

| Property | Value | Notes |
|----------|-------|-------|
| **Domain** | `localhost:3000` | Web dev server |
| **API Domain** | `localhost:5001` | Functions emulator |
| **Firebase Project** | `crush-265f7` (shared) | Or local emulator suite |
| **Auth Callback Hosts** | `localhost` | Configured in Firebase Console |
| **CORS Origins** | `localhost:*` | Allow all ports for dev |
| **Email From** | `dev@localhost.local` | Non-production marker |
| **Stripe Key** | Test publishable/secret | Stripe test mode |
| **App Check** | Disabled | Emulator mode |
| **Notifications** | Console logs | FCM emulator |

#### Staging

| Property | Value | Notes |
|----------|-------|-------|
| **Domain** | `staging.crush.app` | (or `staging.crushhour.app`) |
| **API Domain** | `api.staging.crush.app` | Cloud Functions HTTP domain |
| **Firebase Project** | `crush-265f7-staging` | Separate staging project (recommended) OR same project, different settings |
| **Auth Callback Hosts** | `staging.crush.app` | Configured in Firebase Console |
| **CORS Origins** | `https://staging.crush.app`, `https://app.staging.crush.app` | Explicit allowlist |
| **Email From** | `Crush (Staging) <staging@crushhour.app>` | Identifies staging emails |
| **Stripe Key** | Test mode | Using Staging Stripe account |
| **App Check** | Enabled | Uses staging attestation |
| **Notifications** | Routing to staging clients | Debug tokens allowed |
| **Admin Console** | `console.firebase.google.com` (staging project) | Separate projects recommended |

#### Production

| Property | Value | Notes |
|----------|-------|-------|
| **Domain** | `crush.app` | **Canonical production domain** |
| **Alternate Domain** | `crushhour.app` | Redirects to `crush.app` (OR retire entirely) |
| **API Domain** | `api.crush.app` | Cloud Functions HTTPS endpoint |
| **App Domain** | `app.crush.app` | Optional: separate app subdomain |
| **Marketing Domain** | `crush.app` | Main site + app routes |
| **Firebase Project** | `crush-265f7` | Production project (current) |
| **Auth Callback Hosts** | `crush.app`, `crushhour.app` (if keeping redirect) | Firebase Console config |
| **CORS Origins** | `https://crush.app`, `https://app.crush.app`, `https://crushhour.app` | Strict allowlist |
| **Email From** | `Crush <noreply@crush.app>` | Remove crushhour.app references |
| **Stripe Key** | Live mode | Production Stripe account |
| **App Check** | Enforced | All clients must pass |
| **Notifications** | Production FCM project | Separate from staging |
| **SSL Cert** | Let's Encrypt / Google-managed | Auto-renewed for all domains |
| **Admin Console** | `console.firebase.google.com` (production project) | Restricted access |

---

## Subdomain Allocation Strategy

### Option A: Single Domain (`crush.app`)
```
crush.app                     → Marketing landing page + app web shell
api.crush.app                 → Cloud Functions REST/callable endpoints
admin.crush.app               → Admin console (if needed)
crushhour.app                 → DEPRECATED; redirect to crush.app
```

**Pros:** Simplest, consistent branding, easier CORS allowlist.
**Cons:** Requires Vercel/Firebase to serve both marketing and app web shell.

### Option B: Dual Domain (`crush.app` + `app.crush.app`)
```
crush.app                     → Marketing landing page only
app.crush.app                 → App web shell + web app
api.crush.app                 → Cloud Functions endpoints
crushhour.app                 → DEPRECATED; redirect to crush.app
```

**Pros:** Separates marketing from app; may allow different hosting.
**Cons:** More complexity; requires separate SSL certs (but Let's Encrypt handles this).

### Recommended: Option A
Start with `crush.app` as primary; if needed, introduce `app.crush.app` later without breaking existing links.

---

## Configuration Overrides by File

### Mobile (`my_first_project`)

#### `lib/core/config/app_config.dart` (or similar)
```dart
class AppConfig {
  static const String apiDomain = 'https://api.crush.app'; // Prod
  // OR for dev: 'http://localhost:5001' (Functions emulator)
  
  static const String deepLinkHost = 'crush.app';
  static const String universalLinkDomain = 'crush.app';
}
```

#### `google-services.json` (Android)
- Configured by Firebase Console
- Ensure redirect URIs include `crush.app`

#### `GoogleService-Info.plist` (iOS)
- Configured by Firebase Console
- Ensure redirect URIs include `crush.app`

---

### Web (`crush-web`)

#### `.env.local` (Development)
```bash
NEXT_PUBLIC_API_URL=http://localhost:5001
NEXT_PUBLIC_DOMAIN=localhost:3000
NEXT_PUBLIC_STRIPE_KEY=pk_test_...
```

#### `.env.staging`
```bash
NEXT_PUBLIC_API_URL=https://api.staging.crush.app
NEXT_PUBLIC_DOMAIN=staging.crush.app
NEXT_PUBLIC_STRIPE_KEY=pk_test_...
```

#### `.env.production`
```bash
NEXT_PUBLIC_API_URL=https://api.crush.app
NEXT_PUBLIC_DOMAIN=crush.app
NEXT_PUBLIC_STRIPE_KEY=pk_live_...
```

#### `next.config.js`
```javascript
module.exports = {
  domains: ['crush.app', 'api.crush.app'], // Image optimization domains
  redirects: async () => [
    {
      source: '/crushhour/:path*',
      destination: '/crush/:path*',
      permanent: true,
    },
  ],
};
```

#### `vercel.json` (Vercel deployment)
```json
{
  "env": {
    "NEXT_PUBLIC_API_URL": "@next_public_api_url",
    "NEXT_PUBLIC_STRIPE_KEY": "@next_public_stripe_key"
  },
  "domains": [
    { "name": "crush.app", "production": true },
    { "name": "app.crush.app", "production": true },
    { "name": "staging.crush.app", "production": false }
  ]
}
```

---

### Backend (`my_first_project/functions`)

#### `src/index.ts`
```typescript
// Environment-aware config
const getCorsAllowedOrigins = () => {
  const env = process.env.NODE_ENV;
  if (env === 'production') {
    return [
      'https://crush.app',
      'https://app.crush.app',
      'https://crushhour.app', // Deprecated, but allow for now
    ];
  } else if (env === 'staging') {
    return [
      'https://staging.crush.app',
      'https://app.staging.crush.app',
    ];
  } else {
    // Development/emulator
    return ['http://localhost:3000', 'http://localhost:19006']; // web/Expo
  }
};

const getEmailFrom = () => {
  const env = process.env.NODE_ENV;
  if (env === 'production') {
    return 'Crush <noreply@crush.app>';
  } else if (env === 'staging') {
    return 'Crush (Staging) <staging@crushhour.app>';
  } else {
    return 'Crush (Dev) <dev@localhost.local>';
  }
};

const getNotificationAllowedHosts = () => {
  // Used for notification routing, APNS certificate validation, etc.
  const env = process.env.NODE_ENV;
  if (env === 'production') {
    return ['crush.app', 'api.crush.app'];
  } else {
    return ['localhost', 'staging.crush.app'];
  }
};

app.use(cors({ origin: corsOriginValidator }));
```

#### `firebase.json` (Emulator config for local dev)
```json
{
  "emulators": {
    "auth": {
      "host": "localhost",
      "port": 9099
    },
    "firestore": {
      "host": "localhost",
      "port": 8080
    },
    "functions": {
      "host": "localhost",
      "port": 5001
    },
    "pubsub": {
      "host": "localhost",
      "port": 8085
    },
    "storage": {
      "host": "localhost",
      "port": 9199
    }
  }
}
```

#### `firebaserc` (Project selection)
```json
{
  "projects": {
    "default": "crush-265f7",
    "staging": "crush-265f7-staging",
    "development": "crush-265f7-dev"
  }
}
```

---

## Stripe Configuration

### Redirect URLs
These are set in **Stripe Dashboard** → Settings → API Keys.

| Environment | Redirect Host | Checkout Success | Checkout Cancel |
|-------------|---------------|------------------|-----------------|
| Production | `crush.app` | `https://crush.app/subscription/success?session_id={CHECKOUT_SESSION_ID}` | `https://crush.app/premium` |
| Staging | `staging.crush.app` | `https://staging.crush.app/subscription/success?session_id={CHECKOUT_SESSION_ID}` | `https://staging.crush.app/premium` |
| Development | `localhost:3000` | `http://localhost:3000/subscription/success?session_id={CHECKOUT_SESSION_ID}` | `http://localhost:3000/premium` |

### Webhook Endpoints
Stripe will POST to these URLs when payment events occur.

| Environment | Webhook URL |
|-------------|------------|
| Production | `https://api.crush.app/stripe-webhook` |
| Staging | `https://api.staging.crush.app/stripe-webhook` |
| Development | `http://localhost:5001/stripe-webhook` (not reachable from Stripe; use Stripe CLI) |

---

## Notification Route Mapping

All notification payloads must include `targetRoute` that resolves to the correct deep link.

### Mobile Routes
```
/chat/:matchId              → ChatScreen(matchId)
/message-requests           → MessageRequestsScreen()
/likes-you                  → LikesYouScreen()
/profile/:userId            → ProfileScreen(userId)
/paywall                    → PaywallScreen()
/calls                      → CallsScreen()
/notifications              → NotificationsScreen()
/settings/account           → AccountSettingsScreen()
```

### Web Routes
```
/messages/:matchId          → Messages page
/messages/requests          → Message requests page
/likes                      → Likes page
/profile/:userId            → Profile page
/premium                    → Premium/paywall page
/calls                      → Calls page
/account                    → Account settings page
```

### Notification Payload → Route Mapping
```json
{
  "type": "message",
  "targetRoute": "/chat/match123",      // Mobile deep link
  "targetPath": "/messages/match123"    // Web navigation path
}
```

**See:** `docs/reports/route_deeplink_matrix_2026-06-05.md` (TODO) for full mapping.

---

## Implementation Checklist

### Phase 0 (Before any other changes)
- [ ] **Decide canonical domain:** `crush.app` vs. `crushhour.app`
- [ ] **Plan subdomain strategy:** Single domain (crush.app) vs. dual (crush.app + app.crush.app)
- [ ] **Check DNS & SSL:** Ensure all target domains have CNAME records and valid certs
- [ ] **Firebase Console:** Configure allowed auth redirect URIs for chosen domain(s)
- [ ] **Stripe Dashboard:** Update redirect URLs and webhook endpoints
- [ ] **Apple App Store:** Update App Links configuration if domain changes
- [ ] **Google Play Store:** Update App Links configuration if domain changes

### Phase 1 (Environment-aware code)
- [ ] **Backend functions:** Add `getEmailFrom()`, `getCorsAllowedOrigins()`, `getNotificationAllowedHosts()` environment switches
- [ ] **Web environment files:** Create `.env.staging`, `.env.production` with correct API URLs
- [ ] **Mobile config:** Update `AppConfig` to use environment variable or build config
- [ ] **Firebase project:** Create separate staging project if not already done (recommended)

### Phase 2 (CI/CD gating)
- [ ] **Add domain validation script:** Fail CI if deprecated domains appear outside approved redirects
- [ ] **Add URL validation:** Ensure all email, metadata, and notification URLs use canonical domain
- [ ] **Test CORS:** Verify REST API accepts requests from all target origins

### Phase 3 (Documentation & runbooks)
- [ ] **Update onboarding docs:** Document how to add new environment or change domain
- [ ] **Create deployment runbook:** Step-by-step guide for environment-specific deployments
- [ ] **Add troubleshooting guide:** Common CORS, redirect, and notification routing issues

---

## Post-Implementation Verification

After applying this matrix:

1. **Curl each endpoint with correct origin header:**
   ```bash
   curl -H "Origin: https://crush.app" https://api.crush.app/v1/profile/me
   ```

2. **Verify SSL/TLS:**
   ```bash
   openssl s_client -connect api.crush.app:443
   ```

3. **Test notification routing:**
   - Send test notification with `targetRoute: "/chat/test123"`
   - Verify both mobile and web handle the link correctly

4. **Verify email headers:**
   - Send test email
   - Confirm `From` header matches environment

---

## Revision History

| Date | Changes |
|------|---------|
| 2026-06-05 | Initial domain matrix. Proposed canonical domain (crush.app), environment config by stage, CORS, Stripe, and notification routing. |
