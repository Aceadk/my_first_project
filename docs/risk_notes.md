# Risk Register — CRUSH Dating App

This document tracks technical, product, security, and architectural risks.

---

### R-125 — Profanity filter leetspeak normalization makes some patterns unmatchable (RESOLVED)

Category: Content Moderation / Safety

Description:
ContentModerationService._normalizeText() applies a leetspeak map that converts characters like '1' to 'i', '3' to 'e', '4' to 'a', etc. This normalization was applied to input text but NOT to the profanity patterns, making patterns containing mapped characters (e.g., 'badword1') unmatchable dead code.

Impact: Medium

Likelihood: High (confirmed via unit tests — 'badword1' never matched any input)

Affected Areas:
* `lib/core/services/content_moderation_service.dart` — `_profanityPatterns` set and `_normalizeText()` method

Resolution:
* ✅ Applied Option A+D: Pre-normalize patterns at initialization via `_normalizedProfanityPatterns` static set
* ✅ Both `containsProfanity()` and `filterProfanity()` now use normalized patterns
* ✅ Added `_buildLeetAwarePattern()` for replacement regex — handles all leetspeak variants in original text (e.g., 'b4dw0rd1' is correctly filtered)
* ✅ 58 content moderation tests pass including new R-125 regression tests
* ✅ Full suite: 446 passed, 6 skipped, 0 failures

Status: Closed

Owner: AI

Created: 2026-02-12
Resolved: 2026-02-12

---

### R-124 — Flat vs nested Firestore document structure mismatch (web vs mobile)

Category: Architecture / Data Integrity

Description:
Web-created user profiles store fields at the document root (flat structure: `doc.displayName`, `doc.birthDate`, etc.) while mobile-created profiles store them nested under a `profile` sub-object (`doc.profile.displayName`, `doc.profile.birthDate`, etc.). This caused Firestore security rules to fail for web profiles because rules assumed the nested structure. The `isFemale()` helper and user read rules were also affected.

Impact: High

Likelihood: High (confirmed — discovery was completely broken for web users)

Affected Areas:
* `firestore.rules` — read rules and helper functions must handle both structures
* `packages/core/src/services/match.ts` — discovery profile mapping
* Any new Firestore rules or Cloud Functions that access user profile fields

Resolution (Partial):
* Made Firestore security rules null-safe: checks `resource.data.profile.hideFromDiscovery` with null fallback to `resource.data.hideFromDiscovery`
* Fixed `isFemale()` to check both `resource.data.profile.gender` and `resource.data.gender`
* Discovery now works for both web and mobile users

Remaining Risk:
* Any NEW Firestore rules or Cloud Functions that access user profile fields must handle both flat and nested structures
* Long-term fix: normalize the document structure across web and mobile (either both flat or both nested)
* Until normalized, every rule/function touching user docs is a potential regression point

Status: Mitigated (short-term fix applied, structural normalization still needed)

Owner: AI

Created: 2026-02-11

---

### R-123 — Firestore env var contamination (%0A in projectId) (RESOLVED)

Category: Infrastructure / Production

Description:
Firebase environment variables set in Vercel 15 days ago contained trailing whitespace/newline characters. This caused Firestore project path to include `%0A` (URL-encoded newline), resulting in "client is offline" errors for all Firestore operations in production.

Impact: Critical (P0)

Likelihood: Confirmed (was actively breaking production)

Affected Areas:
* packages/core/src/firebase/config.ts
* All Firestore reads/writes in production
* User authentication persistence

Resolution:
* ✅ Added `.trim()` to all 7 Firebase env var reads in config.ts (defensive)
* ✅ Removed and re-added all 8 Firebase env vars in Vercel (clean values)
* ✅ Fixed tab character in `.env.crush-web-web` API key value
* ✅ Deployed and verified — 48 pages build, all routes return expected status

Status: Resolved

Owner: AI

Created: 2026-02-11
Resolved: 2026-02-11

---

### R-120 — Minimum Flutter/Dart toolchain bumped by dependency upgrades

Category: Build / Tooling

Description:
Upgrading go_router (17) and google_fonts (8) raises the minimum required
toolchain to Flutter 3.35 and Dart 3.9. Developers using older SDKs will see
dependency resolution failures.

Impact: Medium

Likelihood: Medium

Affected Areas:
* pubspec.yaml environment constraints
* Local developer toolchains / CI images

Mitigation:
* ✅ Documented new minimum toolchain in `pubspec.yaml` and project docs
* ✅ CI pinned to Flutter 3.35.0
* ✅ Notify collaborators to update Flutter/Dart or use FVM

Status: Mitigated

Owner: AI

Created: 2026-02-01

---

### R-122 — Firebase Functions config deprecation (March 2026)

Category: Build / Operations

Description:
Cloud Functions previously used `functions.config()` for runtime config (Stripe, Agora, OTP, email). Firebase is deprecating the legacy config API in March 2026.

Impact: Medium

Likelihood: High

Affected Areas:
* functions/src/index.ts (config usage)
* functions deployment pipeline

Mitigation:
* ✅ Migrated to `firebase-functions/params` with .env-backed values
* ✅ Removed `functions.config()` usage from functions code

Status: Mitigated

Owner: AI

Created: 2026-02-06

---

### R-121 — Firebase Storage not initialized in production project

Category: Product / Infrastructure

Description:
Firebase Storage is not enabled for project `crush-265f7`, blocking deployment of `storage.rules` and preventing profile photo uploads.

Impact: High

Likelihood: High

Affected Areas:
* storage.rules
* Profile photo uploads
* Media features

Mitigation:
* ⏳ Enable Firebase Storage in console and run `firebase deploy --only storage`

Status: Open

Owner: AI

Created: 2026-02-06

---

### R-117 — Tokens exposed in logs/crash reports (RESOLVED)

Category: Security / Privacy

Description:
FCM tokens and App Check tokens were being logged in full to debug output. These could leak via log aggregation, crash reporting, or shared development environments.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/core/services/app_check_service.dart
* lib/core/services/push_notification_service.dart

Resolution:
* ✅ Enhanced SecureLogger with token-specific redaction methods
* ✅ All token logging now uses SecureLogger (shows "dK7x...9mN2 (152 chars)")
* ✅ Tokens never appear in full in any logs
* ✅ Auth repositories verified - no token logging
* ✅ Network layer verified - no token logging

Status: Closed

Owner: AI

Resolved: 2026-01-31

---

### R-116 — Backend API abuse from forged requests (MITIGATED)

Category: Security

Description:
Without App Check, malicious actors could forge API requests to Cloud Functions, potentially abusing the discovery, matching, or messaging systems.

Impact: High

Likelihood: Medium

Affected Areas:
* functions/src/index.ts (all callable functions)
* lib/core/services/app_check_service.dart

Resolution:
* ✅ Added Firebase App Check with DeviceCheck (iOS) and Play Integrity (Android)
* ✅ Added `verifyAppCheck()` helper to Cloud Functions
* ✅ `ENFORCE_APP_CHECK` flag for gradual rollout (currently false for monitoring)
* ⏳ Enable enforcement after confirming all clients have App Check

Status: In Progress (monitoring mode)

Owner: AI

Opened: 2026-01-31

---

### R-115 — Stub/mock profiles could leak to production builds (RESOLVED)

Category: Security / Data Integrity

Description:
HybridDiscoveryRepository combines Firebase and stub data for development, but had no production guard to prevent mock profiles (mock_* IDs) from appearing in release builds.

Impact: High

Likelihood: Low (but embarrassing)

Affected Areas:
* lib/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart

Resolution:
* ✅ Added `kReleaseMode` check: `_stubRepo = kReleaseMode ? null : StubDiscoveryRepository()`
* ✅ Added `_includeStubData` getter that returns false in release mode
* ✅ All fetch methods now check `_includeStubData` before using stub data
* ✅ Debug print indicates mode on initialization

Status: Closed

Owner: AI

Resolved: 2026-01-31

---

### R-114 — Aggressive deck preloading may increase memory/network usage (RESOLVED)

Category: Performance / UX

Description:
Preloading multiple upcoming profile images and rendering background cards can increase memory usage and network bandwidth, especially on low-end devices or slow networks.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/discovery/presentation/screens/deck_screen.dart
* lib/features/discovery/presentation/widgets/deck_card_stack.dart
* lib/shared/widgets/cached_network_image.dart

Resolution:
* ✅ Implemented priority-based image preloading (immediate > high > low)
* ✅ Added memory pressure thresholds (40MB low, 45MB critical)
* ✅ Smart cache eviction protects visible/upcoming card images
* ✅ Low-priority preloads skipped under critical memory pressure
* ✅ Added shimmer loading placeholders for better perceived performance
* ✅ WidgetsBindingObserver handles system memory warnings
* ✅ trimCache() method for aggressive eviction when needed

Status: Closed

Owner: AI

Resolved: 2026-01-25

---

### R-113 — Message request migration/expiration is client-driven (RESOLVED)

Category: UX / Data Integrity

Description:
Message requests are migrated into chats and expired via client-side fetch/cleanup. If the sender doesn't sync after a match (or neither user opens Message Requests), the request may linger in the Message Requests list after a match or past the 48-hour window.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
* lib/features/chat/presentation/bloc/matches_bloc.dart
* lib/features/chat/presentation/bloc/message_requests_cubit.dart
* functions/src/index.ts

Resolution:
* ✅ Added `cleanupExpiredMessageRequests` Cloud Function (runs hourly)
* ✅ Enhanced `onMatchCreated` to auto-migrate pending message requests to match
* ✅ Added accept/decline actions to MessageRequestsCubit
* ✅ Improved UI with real-time countdown timer and action buttons
* ✅ Added match celebration dialog with navigation to chat
* ✅ Haptic feedback for all interactions

Status: Closed

Owner: AI

Resolved: 2026-01-25

---

### R-112 — AI collaboration docs may drift without after-edit sync

Category: Process / Quality

Description:
If agents do not re-read and update collaboration docs after edits, changes can be missed and tasks can diverge.

Impact: Medium

Likelihood: Medium

Affected Areas:
* docs/ai_change_log.md
* docs/ai_tasks_board.md
* docs/ai_collab_chat.md
* docs/risk_notes.md

Mitigation:
* CLAUDE.md now explicitly requires before/after doc reads and AI-to-AI suggestions.

Status: Mitigated

Owner: AI

Created: 2026-01-23

---

### R-111 — Auth screen moves could leave stale import paths

Category: Build / Architecture

Description:
Auth/onboarding screens were moved into `lib/features/auth/presentation/screens`. Any missed imports or stale references could break builds or routing.

Impact: Low

Likelihood: Low

Affected Areas:
* lib/core/router.dart
* lib/features/profile/profile.dart
* lib/features/auth/presentation/screens/*.dart

Mitigation:
* Search for old `lib/presentation/screens/...` paths and update imports.
* Run `flutter analyze` or build to confirm.

Status: Monitoring

Owner: AI

Created: 2026-01-23

---

### R-102 — Name privacy defaults hide public names

Category: UX / Privacy

Description:
First/last name visibility now defaults to private. If users do not opt in, public cards and matches may show placeholder names, which could reduce clarity or engagement.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/auth/presentation/screens/basic_info_screen.dart
* lib/features/profile/presentation/screens/profile_edit_screen.dart
* lib/features/discovery/presentation/widgets/swipe_card.dart

Mitigation:
* Onboarding prompt explains privacy default and toggle.
* Profile Edit exposes name visibility controls.
* Stub profiles opt-in to show first name for demo UX.

Status: Open

Owner: AI

Created: 2026-01-20

---

### R-103 — Skeleton shimmer performance on low-end devices

Category: Performance / UX

Description:
Animated skeletons during loading could increase GPU/CPU usage and cause jank on lower-end devices if too many are visible at once.

Impact: Low

Likelihood: Medium

Affected Areas:
* lib/features/discovery/presentation/widgets/deck_skeleton.dart
* lib/features/chat/presentation/screens/matches_screen.dart
* lib/features/chat/presentation/screens/chat_screen.dart
* lib/features/profile/presentation/screens/profile_view_screen.dart

Mitigation:
* Keep skeleton counts modest.
* Prefer a single shimmer wrapper where possible.
* Revisit animation duration and density if jank is observed.

Status: Monitoring

Owner: AI

Created: 2026-01-20

---

### R-104 — Discovery payload mismatch blocks real users (RESOLVED)

Category: Backend dependencies

Description:
`fetchDiscoveryCandidates` returns `profiles` with nested `profile` objects, while the client expects `candidates` and flattens fields.

Impact: High

Likelihood: High

Affected Areas:
* functions/src/index.ts
* lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart

Resolution:
* ✅ Verified Cloud Function (index.ts:3335-3346) returns `candidates` key with flattened profile data
* ✅ Client (firebase_discovery_repository.dart:29) correctly expects `candidates`
* ✅ Profile data is properly flattened via `...c.profile` spread in Cloud Function
* ✅ `_profileFromFirestore()` correctly maps flat data to Profile model
* ✅ REST API `/v1/discovery/deck` updated to return `candidates` (line 4858) with backward compatible `profiles`
* ✅ `DiscoveryDeckDto` updated to parse `candidates` first, fall back to `profiles`
* ✅ `HttpDiscoveryRepository` updated to try `candidates` first
* Both callable function and REST API now aligned

Status: Closed

Owner: AI

Created: 2026-01-22

Resolved: 2026-01-31

---

### R-105 — Missing chat callables in Firebase Functions (RESOLVED)

Category: Backend dependencies

Description:
Client calls `sendMessage`, `markMessagesRead`, `editMessage`, and `unsendMessage` callables that were originally not defined in Functions.

Impact: High

Likelihood: High

Affected Areas:
* functions/src/index.ts
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart

Resolution:
* ✅ `sendMessage` — Line 3846: Creates message doc, validates match membership/blocks, updates match metadata (lastMessageAt, lastMessageContent, etc.)
* ✅ `markMessagesRead` — Line 3930: Batch marks unread messages as read, updates match readBy timestamp
* ✅ `editMessage` — Line 3985: Sender-only edit with isEdited flag and editedAt timestamp
* ✅ `unsendMessage` — Line 3778: Soft delete (Plus plan required), sets isDeletedForSender + unsentAt
* ✅ Cloud Functions build succeeds (`npm run build`)
* Deploy with: `firebase deploy --only functions`

Status: Closed

Owner: AI

Created: 2026-01-22
Resolved: 2026-02-12

---

### R-106 — Storage rules mismatch for profile/chat media (RESOLVED)

Category: Backend dependencies

Description:
Storage rules allow `users/{uid}/media` and `chats/{matchId}/{messageId}`, but the app uploads to `users/{uid}/photos|videos` and `chat_media/...`.

Impact: High

Likelihood: High

Affected Areas:
* storage.rules
* lib/features/profile/data/services/profile_media_service.dart
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart

Resolution:
* ✅ Storage rules already include correct paths (verified 2026-01-31):
  - `users/{uid}/photos/{fileName}` (lines 44-49) — matches ProfileMediaService
  - `users/{uid}/videos/{fileName}` (lines 52-57) — matches ProfileMediaService
  - `chat_media/{matchId}/{userId}/{fileName}` (lines 82-90) — matches FirebaseChatRepository
* ✅ Legacy paths kept for backwards compatibility but don't cause conflicts
* ✅ All code upload paths align with storage rules

Status: Closed

Owner: AI

Created: 2026-01-22

Resolved: 2026-01-31

---

### R-107 — Android permissions missing for camera/microphone

Category: Build & deployment

Description:
Android manifest does not declare `CAMERA` or `RECORD_AUDIO`, risking failures for video calls and voice notes.

Impact: Medium

Likelihood: Medium

Affected Areas:
* android/app/src/main/AndroidManifest.xml

Mitigation:
* Add required permissions and verify runtime requests on Android 13+.

Status: Open

Owner: AI

Created: 2026-01-22

---

### R-108 — Feature cubit data persists after logout (mitigated)

Category: Security & privacy

Description:
Weekly Picks, Date Ideas, Compatibility Quiz, and Profile Insights retained cached state without auth cleanup, risking cross-user leakage.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart
* lib/features/social/presentation/bloc/date_ideas_cubit.dart
* lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart
* lib/features/analytics/presentation/bloc/profile_insights_cubit.dart
* lib/features/discovery/data/services/weekly_picks_service.dart
* lib/features/social/data/services/date_idea_service.dart
* lib/features/social/data/services/compatibility_quiz_service.dart
* lib/features/analytics/data/services/profile_insights_service.dart

Mitigation:
* Added auth state listeners to reset cubit state on logout.
* Cleared in-memory service caches when auth becomes null.

Status: Mitigated

Owner: AI

Created: 2026-01-23

---

### R-109 — Call screen uses placeholder caller ID (RESOLVED)

Category: Backend dependencies

Description:
CallScreen initiates calls with a hardcoded `callerId: 'current_user'`. Now that the call route is reachable from chat, this may break call identity tracking.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/calls/presentation/screens/call_screen.dart
* lib/features/chat/presentation/screens/chat_screen.dart

Resolution:
* ✅ CallScreen now retrieves authenticated user ID from AuthBloc
* ✅ Passes actual user ID, name, and photo URL to CallService
* ✅ Added haptic feedback for all call state transitions
* ✅ Improved UI with glassmorphism effects and modern animations
* ✅ Added connection quality indicator and better visual feedback

Status: Closed

Owner: AI

Resolved: 2026-01-25

---

### R-110 — Glass buttons reduce link affordance in auth flow

Category: UX

Description:
Replacing TextButton/OutlinedButton with Glass variants in the auth flow may reduce perceived affordance for secondary actions (e.g., "Forgot password", "Resend").

Impact: Low

Likelihood: Medium

Affected Areas:
* lib/features/auth/presentation/screens/auth_gateway_screen.dart
* lib/features/auth/presentation/screens/login_screen.dart
* lib/features/auth/presentation/screens/sign_up_screen.dart
* lib/features/auth/presentation/screens/email_auth_screen.dart
* lib/features/auth/presentation/screens/phone_auth_screen.dart
* lib/features/auth/presentation/screens/otp_screen.dart
* lib/features/auth/presentation/screens/forgot_password_screen.dart
* lib/features/auth/presentation/screens/email_verification_screen.dart
* lib/features/auth/presentation/screens/terms_conditions_screen.dart

Mitigation:
* Keep labels explicit and ensure proper spacing for tap targets.
* Add Semantics labels for screen readers.

Status: Monitoring

Owner: AI

Created: 2026-01-23

---

## Risk Categories

* Architecture
* State management
* Routing/navigation
* Security & privacy
* Performance
* UX/product
* Backend dependencies
* Build & deployment

---

## Risk Template

```
### Risk ID: R-XXX
Title: <short title>

Category:

Description:

Impact:
- Low / Medium / High / Critical

Likelihood:
- Low / Medium / High

Affected Areas:
- Files / features / flows

Mitigation Plan:
- Step 1
- Step 2

Status:
- Open / Mitigated / Monitoring / Closed

Owner:
- AI / Developer

Last Reviewed:
- YYYY-MM-DD
```

---

## Active Risks

### R-115 — Age Gate (18+) for Dating App (RESOLVED)

Category: Security & Compliance

Description:
Dating apps require explicit age verification (18+) at signup. Both App Store and Play Store require this for dating apps.

Impact: Critical

Likelihood: High

Affected Areas:
* lib/features/auth/presentation/screens/auth_gateway_screen.dart
* lib/features/auth/presentation/screens/basic_info_screen.dart

Resolution:
* Added age gate dialog at AuthGatewayScreen entry point
* Users must confirm they are 18+ before proceeding to signup
* Dialog is non-dismissible to ensure compliance
* BasicInfoScreen still has DOB validation as secondary check (ages 18-75)
* Clear messaging about dating app being for adults only

Status: Closed

Owner: AI

Resolved: 2026-01-31

---

### R-116 — CRITICAL: Missing Sign in with Apple

Category: Compliance

Description:
Apple App Store requires Sign in with Apple if any social login is offered. Firebase Auth supports it but it's not implemented in the app.

Impact: Critical

Likelihood: High

Affected Areas:
* lib/features/auth/presentation/screens/auth_gateway_screen.dart
* lib/features/auth/data/repositories/impl/firebase_auth_repository.dart

Mitigation Plan:
* Implement apple_sign_in package
* Add Sign in with Apple button to auth gateway
* Configure Apple Developer credentials

Status: Open - BLOCKER for App Store submission

Owner: Developer

Created: 2026-01-31

---

### R-117 — Privacy Policy and Terms URLs (RESOLVED)

Category: Compliance

Description:
Privacy Policy and Terms of Service URLs are required for both App Store and Play Store submission.

Impact: High

Likelihood: High

Affected Areas:
* public/privacy.html
* public/terms.html
* lib/config/legal_config.dart

Resolution:
* Created public HTML pages at /public/privacy.html and /public/terms.html
* Configured Firebase Hosting rewrites for /privacy and /terms routes
* Created centralized LegalConfig with all legal URLs
* URLs accessible at https://crushhour.app/privacy and https://crushhour.app/terms
* Updated Flutter screens to use LegalConfig

Status: Closed

Owner: AI

Resolved: 2026-01-31

Note: Requires `firebase deploy --only hosting` to publish pages

---

### R-118 — Low Test Coverage (improving)

Category: Quality

Description:
Originally only 21 test files for 457 Dart files (~200,330 LOC), representing 4.6% test-to-code ratio. As of 2026-02-12, added 5 new test files with 137 tests covering critical service areas (content moderation, consent, tracking consent, data export, subscription). Total now ~26 test files.

Impact: Medium

Likelihood: Medium (improving)

Affected Areas:
* test/
* All feature modules

Mitigation Plan:
* ~~Add service-layer unit tests~~ (done: 5 critical service areas covered with 137 tests)
* Add BLoC unit tests for remaining 22+ BLoCs/Cubits
* Add repository integration tests
* Add widget tests for design system
* Target 40% coverage for MVP, 60% for v1.0

Status: In Progress (partially mitigated)

Owner: Developer / AI

Created: 2026-01-31
Updated: 2026-02-12

---

### R-119 — iOS Privacy Manifest (RESOLVED)

Category: Compliance

Description:
iOS 17+ requires PrivacyInfo.xcprivacy file declaring API usage.

Impact: High

Likelihood: High

Affected Areas:
* ios/Runner/PrivacyInfo.xcprivacy
* ios/Runner.xcodeproj/project.pbxproj

Resolution:
* PrivacyInfo.xcprivacy file already existed with comprehensive declarations
* File was NOT included in Xcode project build (critical oversight)
* Added file reference to project.pbxproj (PBXFileReference, PBXGroup, PBXBuildFile, PBXResourcesBuildPhase)
* Manifest properly declares:
  - NSPrivacyAccessedAPICategoryUserDefaults (CA92.1)
  - NSPrivacyAccessedAPICategoryFileTimestamp (C617.1)
  - NSPrivacyAccessedAPICategorySystemBootTime (35F9.1)
  - NSPrivacyAccessedAPICategoryDiskSpace (E174.1)
* Collected data types declared: Name, Email, Phone, DOB, Photos, Location, UserID

Status: Closed

Owner: AI

Resolved: 2026-01-31

---

### R-120 — E2E Chat Encryption Not Implemented

Category: Security

Description:
Chat messages are not end-to-end encrypted. While Firebase provides transport encryption, messages are readable in Firestore. For a dating app, this poses privacy risk.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
* lib/features/chat/presentation/bloc/chat_bloc.dart

Mitigation Plan:
* Implement Signal Protocol or similar E2E encryption
* Store encrypted messages in Firestore
* Key exchange during match creation

Status: Open

Owner: Developer

Created: 2026-01-31

---

### R-001 — BLoC state complexity growth

Category: State management

Description:
AuthBloc handles multiple auth methods (phone OTP, email, password, magic link). DiscoveryBloc manages deck + matches + super likes + rewind. As features grow, these BLoCs may become difficult to maintain.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/auth/presentation/bloc/auth_bloc.dart
* lib/features/discovery/presentation/bloc/discovery_bloc.dart

Mitigation Plan:
* Consider splitting into sub-BLoCs if complexity increases
* Add comprehensive unit tests for state transitions
* Document state machine flows

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-002 — Firebase Storage upload failures in debug mode

Category: Backend dependencies

Description:
Firebase Storage uploads fail in debug mode due to security rules, causing fallback to local file paths. Local paths are saved to Firestore but won't work across devices/sessions.

Impact: Low (debug only)

Likelihood: High (in debug)

Affected Areas:
* lib/core/services/profile_media_service.dart
* lib/shared/widgets/cached_network_image.dart

Mitigation Plan:
* ✅ CachedNetworkImage handles both local and remote URLs
* Deploy proper Firebase Storage security rules for production
* Add upload status/retry mechanism

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-003 — Cubits not reset on logout

Category: Security & privacy

Description:
SafetyCubit, PrivacySettingsCubit, DiscoverySettingsCubit store user preferences in SharedPreferences. While the clearance service clears the SharedPreferences keys, the Cubits may hold stale runtime state until reloaded.

Impact: Low

Likelihood: Low

Affected Areas:
* lib/features/settings/presentation/bloc/safety_cubit.dart
* lib/features/settings/presentation/bloc/privacy_settings_cubit.dart
* lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart

Mitigation Plan:
* Add auth state subscription to these Cubits (similar to BLoCs)
* Or rely on app restart after logout

Status: Open

Owner: AI

Last Reviewed: 2026-01-20

---

### R-004 — BoostRepository only has Stub implementation (RESOLVED)

Category: Backend dependencies

Description:
BoostRepository only has StubBoostRepository. Firebase/HTTP implementations are TBD. Profile boost feature won't work in production until implemented.

Impact: Medium

Likelihood: High

Affected Areas:
* lib/features/discovery/data/repositories/boost_repository.dart
* lib/core/di.dart

Resolution:
* ✅ Implemented FirebaseBoostRepository
* ✅ Updated DI to use Firebase implementation for production
* Boost data stored in Firestore `boosts` collection
* Subscription-based cooldowns and durations working

Status: Closed

Owner: AI

Resolved: 2026-01-25

---

### R-005 — Onboarding redirect loop if auth state is stale

Category: Routing/navigation

Description:
Home is blocked while onboarding is incomplete. If AuthBloc lags behind profile updates, users could be redirected back to onboarding briefly after saving.

Impact: Low

Likelihood: Medium

Affected Areas:
* lib/core/router.dart
* lib/features/profile/presentation/screens/profile_setup_screen.dart
* lib/features/auth/presentation/screens/basic_info_screen.dart

Mitigation Plan:
* Ensure AuthUserRefreshRequested is fired after onboarding saves (already in place)
* Consider awaiting refresh or showing a transient loading state before navigation

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-006 — Date plan email notifications depend on Resend configuration

Category: Backend dependencies

Description:
Emergency contact emails require a configured Resend API key and sender address. Missing configuration or provider outages will prevent notifications.

Impact: Medium

Likelihood: Medium

Affected Areas:
* functions/src/index.ts
* lib/features/safety/data/services/date_plan_service.dart
* lib/presentation/screens/safety_screen.dart

Mitigation Plan:
* Return clear errors when email is not configured
* Rate limit notifications to reduce abuse
* Add monitoring/alerts for failed sends

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-007 — Exposing DOB and distance for non-matched likes

Category: Security & privacy

Description:
Likes You cards display date of birth and distance even before a mutual match, which may surface sensitive information to non-premium users.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/chat/presentation/screens/matches_screen.dart
* lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart

Mitigation Plan:
* Consider showing age instead of full DOB
* Add privacy setting to hide DOB/distance until match

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

## Resolved Risks

### R-100 — CRITICAL: User data leakage on logout (RESOLVED)

Category: Security & privacy

Description:
After logout, previous user's profile, chats, matches, photos, and settings were visible to the next user logging in on the same device. BLoCs retained user-specific data in memory after logout.

Impact: Critical

Likelihood: High

Affected Areas:
* All user-facing BLoCs (ProfileBloc, ChatBloc, DiscoveryBloc, MatchesBloc)
* SharedPreferences user keys
* NetworkImageCache

Resolution:
* Created UserDataClearanceService for SharedPreferences and cache clearing
* Added auth state subscriptions to all major BLoCs
* Added reset events and handlers to clear state on logout
* Called clearance service from AuthBloc._onSignedOut

Status: Closed

Owner: AI

Resolved: 2026-01-20

---

### R-101 — Sign-out trapped in onboarding (RESOLVED)

Category: Routing/navigation

Description:
Users could not sign out while in onboarding flow. Router redirect conditions didn't exempt the logout route, causing redirect back to onboarding screens.

Impact: High

Likelihood: Medium

Affected Areas:
* lib/core/router.dart

Resolution:
* Added `path == CrushRoutes.logout` to all onboarding redirect allowed paths

Status: Closed

Owner: AI

Resolved: 2026-01-20

---
