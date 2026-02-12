# Routes and Endpoints Inventory (2026-02-12)

## Mobile Route Map (Flutter GoRouter)
Source: `lib/core/router.dart`
Raw extract: `audit/raw/mobile_routes_raw.txt`

Summary:
- Declared route constants: 55
- Route families include auth, onboarding, profile, discovery, chat, settings, legal, support, social.

Notable route groups:
- Auth/onboarding: `/auth/*`, `/terms-conditions`, `/basic-info`, `/profile-setup`, `/email-verification`.
- Core app: `/home`, `/chat`, `/message-requests`, `/profile`, `/settings`.
- Legal/safety: `/privacy-policy`, `/terms-of-service`, `/safety`, `/community-guidelines`.

## Backend API Surface (Express)
Source: `functions/src/index.ts`
Raw extracts:
- `audit/raw/express_routes_raw.txt`
- `audit/raw/api_paths_raw.txt`

Summary:
- REST endpoints under `/v1/*`: 29
- Domains: auth, profile, discovery, matches, chat, subscription, moderation/safety, chat settings.

Representative endpoints:
- `POST /v1/auth/otp/send`
- `POST /v1/auth/otp/verify`
- `GET /v1/discovery/deck`
- `POST /v1/discovery/swipe`
- `GET /v1/chat/conversations`
- `POST /v1/chat/:conversationId/send`
- `POST /v1/users/report`

## Cloud Functions Export Surface
Source: `functions/src/index.ts`
Raw extract: `audit/raw/functions_exports_raw.txt`

Summary:
- Callable functions: 36
- Firestore triggers: 5
- Pub/Sub jobs: 2
- HTTPS onRequest exports: 2 (`stripeWebhook`, `api`)

Notes:
- Callable pattern is wrapped in custom `callable<TData>()` middleware with auth/error handling.
- Express API is mounted as `export const api = functions.https.onRequest(app);`.
