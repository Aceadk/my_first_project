# CrushHour

Dating-style Flutter app with Firebase backend, Stripe billing, and optional BigQuery ML pipelines.

## What this app does
- Discovery deck with swipes, mutual matches, and pre-match message requests.
- Chat with read receipts and Plus-only unsend.
- Stripe Checkout for CrushHour Plus; webhook updates user plan in Firestore.
- Data Connect client stubs (generated) for server-side operations.
- Example BigQuery pipelines for recommendations/ranking (optional, offline/analytics).

## Project layout (key folders/files)
- `lib/`
  - `main.dart`: boots Firebase via `firebase_options.dart` and runs `CrushApp`.
  - `app.dart`: DI, BLoC providers, router, theme.
  - `core/`: `di.dart`, `router.dart`, `theme.dart`.
  - `logic/`: BLoCs for auth, profile, discovery, chat, subscription, call.
  - `data/`
    - `models/`: Profile, Match, Message, SubscriptionPlan, etc.
    - `repositories/`: Interfaces; `firebase/` implementations (chat, discovery, subscription, auth/profile).
    - `services/`: `CheckoutService` (Stripe checkout callable), `PreMatchService` (pre-match message callable).
    - `dataconnect_generated/`: generated client for Data Connect operations.
  - `presentation/`: screens (`deck_screen`, `chat_screen`, `settings_screen`, etc.) and widgets (`swipe_card`, `primary_button`).
  - `config/billing_config.dart`: Stripe price id + success/cancel URLs (replace with real values).
- `functions/`
  - `src/index.ts`: Firebase Functions + Stripe webhook. Callables: `swipeRight`, `sendPreMatchMessageRequest`, `createCheckoutSession`; HTTP webhook: `stripeWebhook`.
  - `package.json`, `tsconfig.json`.
- `dataconnect/`: schema + connector config for Data Connect codegen.
- `pubspec.yaml`: Flutter deps (Firebase, Stripe client helpers, url_launcher, etc.).
- `test/`: placeholder widget test.

## Push notifications
- Mobile client requests FCM permission via `firebase_messaging` and stores tokens under `users/{uid}/fcmTokens/{token}` with platform metadata.
- Backend/Functions should target those tokens for new matches, new chat messages, and subscription/billing changes (topics or direct send). Add callables/trigger functions to publish to the user’s tokens using that collection.
- iOS: add APNs key/certs to Firebase, enable push capability. Android: ensure google-services.json includes `project_number`.

## Profile completeness & gating
- Completeness is calculated client-side with weighted rules (photos, longer bio, interests, work/school, location).
- Swiping and messaging are gated until the profile meets the minimum threshold; UI surfaces progress + missing items.
- Optionally enforce server-side in Functions before processing swipes/messages by reading `users/{uid}/profile`.

## Backend functions (functions/src/index.ts)
- `swipeRight`: writes like, checks reverse like, creates/reuses match doc.
- `sendPreMatchMessageRequest`: limits to 3 requests per sender before reply; stores requests under `preMatchPairs`.
- `createCheckoutSession`: Stripe Checkout subscription session (reuses/creates Stripe customer, attaches metadata).
- `stripeWebhook` (HTTP): handles checkout completion and subscription updates; sets Firestore `plan`, `stripeCustomerId`, `stripeSubscriptionId`.
- Helpers: `getUser`, `setUserPlan`.
- Requirements: set functions config `stripe.secret` and `stripe.webhook_secret` (`firebase functions:config:set ...`).

## App flows
- **Discovery**: `DeckScreen` fetches profiles via `FirebaseDiscoveryRepository`; swipes call `swipeRight` callable; pre-match dialog sends `sendPreMatchMessageRequest`.
- **Chat**: Messages in Firestore under `matches/{matchId}/messages`; long-press unsend calls `unsendMessage` callable; read receipts marked in repo.
- **Subscription**: `SettingsScreen` starts Stripe Checkout via `CheckoutService` → `createCheckoutSession`; webhook updates plan in Firestore; Plus gates chat unsend.
- **Data Connect**: Generated client for example operations (list users, posts, likes); lint ignores kept because generated.

## Setup
1) Install Flutter (3.24+), Dart SDK, Xcode/Android toolchains.
2) `flutter pub get`
3) Firebase config: ensure `firebase_options.dart` is generated via `flutterfire configure`.
4) Stripe: set `BillingConfig.plusPriceId/successUrl/cancelUrl` in `lib/config/billing_config.dart`; set function config `stripe.secret` and `stripe.webhook_secret`.
5) Functions: `cd functions && npm install && npm run build`; deploy with `firebase deploy --only functions`.

## Running
- Android/iOS: `flutter run` (pick device). iOS: open Simulator (`open -a Simulator`) then `flutter run -d ios`.
- Web: `flutter run -d chrome` (Firebase config already uses `DefaultFirebaseOptions.currentPlatform`).

## Testing/Lint
- Flutter: `flutter analyze`, `flutter test`.
- Functions: `npm --prefix functions run lint`, `npm --prefix functions run build`.

## Optional BigQuery / ML (examples)
- Tables: `interaction_events`, `user_profiles_base`, `user_profiles` (with `popularity_score`), `likes_flat`, `matches_flat`, `user_stats`, `ranking_candidates_for_user`, `user_user_implicit_ratings`, `ranking_examples`.
- Models: `user_recs_mf` (matrix factorization), `ranking_dnn` (DNN classifier).
- Sample SQL provided in previous snippets to flatten Firestore exports and run `ML.PREDICT`.

## What to focus on next
- Verify backend enforcement: auth checks and ownership in callables (unsend, swipe, pre-match).
- Harden security: auth checks and ownership in callables (unsend, swipe, pre-match).
- Improve UX: error states, loading, empty decks, retry/backoff.
- Web polish: test callables for CORS; verify RTC/calls behavior on web.
- Payments: confirm Stripe price IDs/URLs; test webhook end-to-end; handle deep links.
- Tests: add integration tests (Functions with `firebase-functions-test`), widget tests for chat/swipe flows.
- CI/CD: add lint/test steps for Flutter and Functions in your pipeline.
