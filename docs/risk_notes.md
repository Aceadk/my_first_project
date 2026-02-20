# Risk Register — CRUSH Dating App

This document tracks technical, product, security, and architectural risks.

---

### R-167 — SemanticsHelper Uses Global Locale Instead of App Locale (LOW)

Category: Accessibility / I18N
Severity: Low
Description: `semantics_helper.dart` is a static utility with no `BuildContext`, so it uses `intl.Intl.getCurrentLocale()` for date formatting instead of `Localizations.localeOf(context)`. If the user changes the app locale at runtime without restarting, semantics date strings may briefly use the previous locale until the intl default locale is updated.
Mitigation: The `Intl.defaultLocale` is typically set at app startup and when locale changes. Accessibility strings are not user-visible (screen reader only), so a brief mismatch is not noticeable. The app's locale change via LocaleCubit triggers a full rebuild which re-sets the default locale.
Status: Accepted
Owner: AI
Created: 2026-02-20

---

### R-161 — Location Permission Rationale Timing (LOW)

Category: UX
Severity: Low
Description: Location permission rationale is now shown as a bottom sheet after the first frame of ProfileSetupScreen instead of auto-requesting in initState. This introduces a brief moment where the screen renders before the rationale appears.
Mitigation: The delay is imperceptible (single frame, ~16ms). The rationale sheet is non-dismissible (isDismissible: false, enableDrag: false), ensuring the user must choose Allow or Not Now. If user taps Not Now, they can enable location later in Settings. Discovery still works without location but user won't appear in distance-based results.
Task: T-2026-02-19-ONBOARD001-002

---

### R-160 — Chat Memory Cap Reduced to 100 Messages (MITIGATED)

Category: UX
Severity: Low
Description: `_maxMessagesInMemory` reduced from 200 to 100 for virtualization. Very active chats may trim context faster.
Mitigation: Scroll-based pagination reloads trimmed messages. Page size increased to 50 for smoother experience.
Task: T-2026-02-19-10

### R-159 — Enter-to-Send on External Keyboard (LOW)

Category: UX
Severity: Low
Description: iPad external keyboard users may expect Enter to insert newline (not send). Our behavior: Enter=send, Shift+Enter=newline (matches WhatsApp/Telegram desktop).
Mitigation: Consistent with major chat apps. Shift+Enter available for newline. Documented in future onboarding.
Task: T-2026-02-19-10

### R-158 — iPad Split-View ChatScreen Inline Rendering (MITIGATED)

Category: Architecture
Severity: Medium
Description: ChatScreen rendered inline as child of ChatListScreen's Row on iPad. BLoC lifecycle must properly reset when switching conversations.
Mitigation: `ValueKey(_selectedChat!.matchId)` forces full rebuild on conversation switch. ChatScreen disposes old BLoC and creates new one via ChatOpened event.
Task: T-2026-02-19-10

### R-157 — Notification Image Download May Delay Foreground Display (LOW)

Category: Performance
Severity: Low
Description: `_showLocalNotification` downloads images via HTTP before displaying the notification. On slow connections, this could delay notification appearance.
Mitigation: Falls back to text-only notification if download fails. HttpClient used with standard timeout.

---

### R-156 — flushNotificationQueue Runs Every 60 Minutes (LOW)

Category: UX
Severity: Low
Description: Queued notifications (from quiet hours) are flushed via Cloud Functions scheduled every 60 minutes. Users may experience up to 60min delay after quiet hours end.
Mitigation: Acceptable trade-off for V1. Can reduce to 15min if UX feedback warrants it.

---

### R-155 — iOS Notification Service Extension Requires Xcode Target Setup (MANUAL)

Category: Build
Severity: Medium
Description: The iOS NSE source files (`ios/NotificationServiceExtension/NotificationService.swift` + `Info.plist`) are created but the Xcode project target must be added manually by the developer.
Mitigation: Files are ready to use. Developer needs to: 1) Add new Notification Service Extension target in Xcode, 2) Point to existing source files, 3) Set deployment target to match app, 4) Add to same App Group.

---

### R-154 — ImageOptimizer Uses PNG Encoding Instead of JPEG (KNOWN)

Category: Performance
Severity: Low (KNOWN)
- `dart:ui` only supports PNG encoding natively (no JPEG encoder in Dart SDK)
- Optimized images are resized and EXIF-stripped but encoded as PNG (lossless, larger than JPEG)
- For production: recommend server-side re-compression to JPEG/WebP after upload
- Current benefit: resize from 12MP→2048px and EXIF removal still provides significant size reduction

---

### R-153 — Chat Message Memory Cap May Trim Visible Context (MITIGATED)

Category: Performance/UX
Severity: Low (MITIGATED)
- Chat messages capped at 200 in memory to prevent unbounded growth
- When receiving new messages, oldest are trimmed; when loading more, newest are trimmed
- Risk: rapid scrolling between old and new messages could cause context loss
- Mitigated: 200 is generous (6.6 pages of 30), trimmed messages re-fetchable via pagination
- User leaving and re-entering chat resets to fresh 30 messages

---

### R-152 — ErrorBoundary Analytics Calls in Test Context (MITIGATED)

Category: Testing
Severity: Low (MITIGATED)
- ErrorBoundary now calls AnalyticsService on reportError/retry/goHome
- Tests must install StubAnalyticsService via setUpAll to avoid FirebaseException
- Already handled: test/error_boundary_test.dart has setUp/tearDown
- Risk: New tests using ErrorBoundary without stub will fail — pattern documented

---

### R-151 — Circuit Breaker State Lost on App Restart (EXPECTED)

Category: Architecture
Severity: Low (EXPECTED)
- CircuitBreakerRegistry is in-memory only — resets on cold start
- This is intentional: ensures fresh start, avoids persisting stale state
- If persistent circuit state is needed later, add SharedPreferences backing

---

### R-150 — ConnectivityCubit DNS Polling in Restricted Environments (MITIGATED)

Category: Reliability
Severity: Low (MITIGATED)
- Uses InternetAddress.lookup('dns.google') which may fail in:
  - Airplane mode (SocketException — handled)
  - DNS-blocking VPNs (may appear offline when online)
  - China/restricted networks (dns.google blocked)
- Mitigation: All exceptions caught → defaults to offline. Host is configurable.
- Future: Consider fallback to connectivity_plus package for native API checks.

---

### R-147 — BoostCubit User ID Persisted After Logout (FIXED)

Category: Security
Severity: Medium (FIXED)
Description: BoostCubit held `_userId` after logout. If another user logged in, boost API calls could reference the old user until `initialize()` was called again.
Mitigation: Added `authStateChanges()` listener that clears `_userId`, cancels timers, and resets state on logout.
Status: RESOLVED — Auth listener added in STATE-007 implementation.

---

### R-148 — SubscriptionBloc Held Stale Plan After Logout (FIXED)

Category: Security
Severity: Medium (FIXED)
Description: SubscriptionBloc continued watching the old user's plan stream after logout. State could show Plus features for a Free user.
Mitigation: Added `authStateChanges()` listener that cancels the plan watcher and resets to `SubscriptionPlan.free` on logout.
Status: RESOLVED — Auth listener and SubscriptionResetRequested event added in STATE-007 implementation.

---

### R-149 — Foreground Resume Refresh Could Race With Active Operations

Category: Performance
Severity: Low
Description: When app resumes from background, `_refreshOnResume()` triggers SubscriptionRestoreRequested and ProfileLoadRequested. If the user was already mid-operation (e.g., saving profile), the refresh could interfere.
Mitigation: 30-second debounce prevents rapid-fire refreshes. Both BLoC handlers are idempotent. ProfileLoadRequested only loads if no save is in progress. SubscriptionRestoreRequested is a read-only operation.
Status: ACCEPTED — Low risk, mitigations adequate.

---

### R-144 — In-Memory Rate Limiter Resets on Cloud Functions Cold Start

Category: Security
Severity: Low
Status: Accepted

**Risk:** Express rate limiter uses in-memory `Map` which resets on Cloud Functions cold start. Attacker could time requests to exploit cold starts.
**Mitigation:** Acceptable for serverless. Provides best-effort protection for normal usage patterns. Callable functions use persistent Firestore-based `applyRateLimit()`. For stronger enforcement, consider Redis (Memorystore) in production.

---

### R-145 — Firestore Backup Bucket Requires Manual Creation

Category: Operations / Data Loss
Severity: Medium
Status: Open

**Risk:** `scheduledFirestoreBackup` function will fail until the backup bucket (`{projectId}-firestore-backups`) is manually created in GCP Console with 30-day lifecycle policy.
**Mitigation:** Document bucket creation in deployment checklist. Function logs errors but doesn't crash. Create bucket with: `gsutil mb gs://{projectId}-firestore-backups && gsutil lifecycle set lifecycle.json gs://{projectId}-firestore-backups`.

---

### R-146 — Legacy Chat Media Storage Path Now Blocked

Category: Compatibility
Severity: Medium
Status: Accepted

**Risk:** Legacy `chats/{matchId}/` storage path now returns 403 for all operations. Any older clients using direct storage reads will fail.
**Mitigation:** Current app code uses `getChatMediaSignedUrl` Cloud Function for cross-user access and `chat_media/` path for uploads. Legacy path was insecure (any authenticated user could read). Migration is intentional — verify no clients still reference the old path.

---

### R-141 — Clipboard Auto-Clear Timer Lost on App Kill

Category: Security / Privacy
Severity: Low
Status: Accepted

**Risk:** `SecureClipboard` uses a Dart `Timer` for 60s auto-clear. If the app is killed before the timer fires, clipboard content persists.
**Mitigation:** Acceptable trade-off. Users can manually clear clipboard. No persistent sensitive data (chat messages are ephemeral). The timer provides best-effort privacy protection.

---

### R-142 — Root/Jailbreak Detection Heuristics Bypassable

Category: Security
Severity: Low
Status: Accepted

**Risk:** `DeviceIntegrityService` uses file-path heuristics that sophisticated users can bypass (e.g., Magisk Hide, path relocation).
**Mitigation:** Detection is informational only — does not block app usage. Results logged for fraud analytics. Consider server-side attestation (Play Integrity / App Attest via App Check) for stronger protection.

---

### R-143 — FLAG_SECURE Not Implemented for Sensitive Screens

Category: Privacy
Severity: Medium
Status: Open

**Risk:** Android `FLAG_SECURE` (screenshot/screen recording prevention) not yet applied to chat or profile screens. Users' private conversations could be screen-captured.
**Mitigation:** Deferred to future iteration. Requires platform channel implementation. Chat content is user-generated and not credentials, so risk is moderate.

---

### R-131 — Discovery browsing no longer requires email verification (Cloud Function)

Category: Security / Auth

Description:
`requireEmailVerified` was removed from `fetchDiscoveryCandidates` Cloud Function to fix discovery showing no users for email/password accounts that haven't verified. Browsing is now open to all authenticated users.

Impact: Low (read-only operation; all write operations like swiping, messaging still require verification)

Likelihood: Low (Flutter routing already gates unverified users at the UI level)

Mitigation:
* Write operations (swipeRight, swipeLeft, sendMessage, reportUser, etc.) still enforce `requireEmailVerified`
* Flutter routing prevents unverified email users from reaching discovery screen
* No PII is exposed through discovery browsing (profiles are public-facing data)

Status: Open (monitoring)

Owner: AI

Created: 2026-02-18

---

### R-130 — CallState.copyWith Cannot Set Nullable Fields to Null (RESOLVED)

Category: State Management / Bug

Description:
`CallState.copyWith(remoteUid: null)` did NOT actually clear the `remoteUid` field. The standard Dart `copyWith` pattern uses `remoteUid: remoteUid ?? this.remoteUid`, which treats a null argument as "keep the current value". This meant when the BLoC processes a `userOffline` engine event and calls `state.copyWith(remoteUid: null)`, the remoteUid retained its previous value.

Impact: Low-Medium (remote user going offline did not clear their UID from state)

Likelihood: High (confirmed via unit test in call_bloc_test.dart)

Affected Areas:
* `lib/features/calls/presentation/bloc/call_state.dart` — copyWith method
* `lib/features/calls/presentation/bloc/call_bloc.dart` — _onCallEngineUpdated handler for userOffline

Resolution:
* ✅ Applied sentinel value pattern: `const _sentinel = Object()` used as default for nullable params
* ✅ All nullable fields (matchId, localUid, remoteUid, errorMessage) now support explicit null
* ✅ `copyWith(remoteUid: null)` correctly creates a new state with null remoteUid
* ✅ 20 call_bloc tests pass including new nullability test
* ✅ `flutter analyze` clean

Status: Closed

Owner: AI

Created: 2026-02-12
Resolved: 2026-02-13

---

### R-126 — 73 Presentation Layer Files Import Data Layer Directly

Category: Architecture / Clean Architecture

Description:
73 files in `*/presentation/**/*.dart` directly import from `*/data/` layer, violating the clean architecture dependency rule. Screens and BLoCs import repository implementations, DTOs, and data models instead of going through domain layer abstractions. Additionally, 6+ screens access singleton services directly (e.g., `CallService.instance`, `IncognitoService.instance`) bypassing DI.

Impact: Medium (testability, maintainability)

Likelihood: High (confirmed — 73 files affected)

Affected Areas:
* lib/features/*/presentation/ — 73 files importing from data layer
* Key violators: discovery_bloc.dart, chat_bloc.dart, other_user_profile_screen.dart

Mitigation Plan:
* Phase 1: Register singleton services in DI container (CrushDI)
* Phase 2: Refactor BLoCs to use repository interfaces, not implementations
* Phase 3: Remove direct data layer imports from presentation screens
* Estimated effort: 80-120 hours

Status: Open (documented for future refactoring)

Owner: Developer / AI

Created: 2026-02-12

---

### R-127 — Orphaned /lib/core/result.dart Dead Code (RESOLVED)

Category: Code Quality

Description:
`/lib/core/result.dart` had 0 imports anywhere in the codebase — it was dead code. The active Result class is at `/lib/core/utils/result.dart` (80 imports). Both files defined a `Result<T>` class but only the utils version was used.

Impact: Low

Likelihood: High (confirmed — 0 imports)

Resolution:
* ✅ Deleted `/lib/core/result.dart`
* ✅ `flutter analyze --no-pub` clean after deletion
* ✅ Active `/lib/core/utils/result.dart` continues to work (80 imports)

Status: Closed

Owner: AI

Created: 2026-02-12
Resolved: 2026-02-12

---

### R-128 — Large Widget/BLoC Files Need Splitting

Category: Code Quality / Performance

Description:
Several key files exceed recommended size limits, making them harder to maintain, test, and optimize for rebuilds:
* ChatScreen: 3,226 lines
* SignUpScreen: 1,935 lines
* DiscoveryFiltersScreen: 1,850 lines
* ProfileEditScreen: ~2,000 lines
* ChatBloc: 824 lines (largest BLoC)
* DiscoveryBloc: 700 lines

Impact: Medium (maintainability, performance)

Likelihood: High (confirmed file sizes)

Mitigation Plan:
* Split ChatBloc into smaller cubits (typing, reactions, media, message sending)
* Extract reusable widgets from large screens (ChatBubble, ChatInput, ChatHeader)
* Use `BlocSelector` for fine-grained rebuilds instead of full `BlocBuilder`

Status: Open (documented for future refactoring)

Owner: Developer / AI

Created: 2026-02-12

---

### R-129 — Android Play Integrity Not Fully Configured

Category: Security / Store Compliance

Description:
Firebase App Check is configured with DeviceCheck (iOS) and Play Integrity (Android), but Play Integrity may not be fully registered in Google Play Console. The ENFORCE_APP_CHECK flag is set to false (monitoring mode). Without proper Play Integrity configuration, Android requests could be forged.

Impact: High

Likelihood: Medium

Affected Areas:
* lib/core/services/app_check_service.dart
* functions/src/index.ts (ENFORCE_APP_CHECK flag)
* Google Play Console configuration

Mitigation Plan:
* Configure Play Integrity API in Google Play Console
* Register app signing certificate
* Test with real Play Integrity tokens
* Enable enforcement: set ENFORCE_APP_CHECK=true after verification

Status: Open — requires manual Google Play Console action

Owner: Developer

Created: 2026-02-12

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

### R-116 — CRITICAL: Missing Sign in with Apple (RESOLVED)

Category: Compliance

Description:
Apple App Store requires Sign in with Apple if any social login is offered. Firebase Auth supports it but it's not implemented in the app.

Impact: Critical

Likelihood: High

Affected Areas:
* lib/features/auth/presentation/screens/auth_gateway_screen.dart
* lib/features/auth/data/repositories/impl/firebase_auth_repository.dart

Resolution:
* ✅ `sign_in_with_apple` package added to pubspec.yaml
* ✅ Sign in with Apple implemented in `firebase_auth_repository.dart` (lines 9, 529-537)
* ✅ Apple credentials configuration documented
* Note: Verified during 2026-02-12 comprehensive audit — feature was already implemented

Status: Closed

Owner: Developer / AI

Created: 2026-01-31
Resolved: 2026-02-12

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
Originally only 21 test files for 457 Dart files (~200,330 LOC), representing 4.6% test-to-code ratio. As of 2026-02-12, added 9 new test files with 292 tests covering critical service areas and untested features. Test files added: content_moderation (56), consent (14), tracking_consent (6), data_export (19), subscription (42), feature_flags (27), call_bloc (18), social_cubits (64), verification (46). Total now ~30 test files.

Impact: Medium

Likelihood: Medium (improving)

Affected Areas:
* test/
* All feature modules

Mitigation Plan:
* ~~Add service-layer unit tests~~ (done: 5 critical service areas covered with 137 tests)
* ~~Add feature-area unit tests~~ (done: 4 feature areas covered with 155 tests — feature flags, calls, social, verification)
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

### R-120 — E2E Chat Encryption Not Implemented (RESOLVED)

Category: Security

Description:
Chat messages are not end-to-end encrypted. While Firebase provides transport encryption, messages are readable in Firestore. For a dating app, this poses privacy risk.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
* lib/features/chat/presentation/bloc/chat_bloc.dart

Resolution:
* ✅ E2E encryption implemented using AES-GCM 256-bit cipher (`Cipher = AesGcm.with256bits()`)
* ✅ Enabled by default via `bool.fromEnvironment('ENABLE_CHAT_E2EE', defaultValue: true)`
* ✅ Key derivation: SHA-256(matchId + sorted userIds + pepper)
* ✅ Messages encrypted before Firestore write, decrypted on read
* Note: Verified during 2026-02-12 comprehensive audit — feature was already implemented

Status: Closed

Owner: Developer / AI

Created: 2026-01-31
Resolved: 2026-02-12

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

### R-131 — Account Deletion Without Cascading Data Erasure (RESOLVED)

Category: Data Privacy / Compliance

Description:
Mobile app only flagged accounts for deletion (`isPendingDeletion=true`) but no Cloud Function processed the actual deletion. Web app did immediate Firestore doc delete without cascading to related data (matches, messages, Storage files, RTDB, Auth user). This left orphaned data across Firebase services.

Impact: High (GDPR/CCPA violation; orphaned data; incomplete account deletion)

Resolution:
* Added `cascadeDeleteUserData()` Cloud Function helper
* Added `processScheduledAccountDeletions` scheduled function (every 6h)
* Added `requestAccountDeletion` / `cancelAccountDeletion` callables
* Aligned web app to use scheduled approach
* Added `_recoverAccountIfWithinGracePeriod()` on mobile sign-in

Status: Closed | Owner: AI | Resolved: 2026-02-13

---

### R-132 — CSP unsafe-inline Vulnerability (RESOLVED)

Category: Web Security

Description:
CSP in Next.js used `unsafe-inline` for script-src, allowing inline script injection (XSS attack surface).

Resolution:
* Per-request nonces via `crypto.randomUUID()` in middleware.ts
* script-src uses `'nonce-{nonce}'` instead of `'unsafe-inline'`

Status: Closed | Owner: AI | Resolved: 2026-02-13

---

### R-133 — Rate Limiting Ineffective on Serverless (RESOLVED)

Category: Web Security

Description:
In-memory rate limiter reset on Vercel serverless cold starts.

Resolution:
* Upstash Redis REST client for distributed rate limiting
* Graceful fallback to in-memory when Redis unavailable

Status: Closed (pending Upstash env vars in Vercel) | Owner: AI | Resolved: 2026-02-13

---

### R-134 — CRITICAL: No In-App Purchase Package — Subscription Uses Mock Stripe (SHIP BLOCKER)

Category: Store Compliance / Revenue

Description:
No `in_app_purchase` or `in_app_purchase_storekit` package exists in pubspec.yaml. The subscription feature uses a mock Stripe checkout flow which is explicitly prohibited by both Apple (Guideline 3.1.1) and Google Play (Play Billing requirement). App Store and Play Store will reject the app on first review. This is the single most critical blocker for store submission.

Impact: Critical (P0 — app cannot ship without this)

Likelihood: Confirmed (verified — no IAP package in pubspec.yaml)

Affected Areas:
* pubspec.yaml (missing `in_app_purchase` package)
* lib/features/subscription/data/services/native_billing_service.dart (needs creation)
* lib/features/subscription/data/repositories/ (needs IAP integration)
* functions/src/ (needs server-side receipt validation)
* App Store Connect (subscription products not created)
* Google Play Console (subscription products not created)

Mitigation Plan:
* See TODO_SUBSCRIPTION.md (SUB-001 through SUB-010) for full implementation plan
* See TODO_STORE_APPLE.md (STORE-APL-001) and TODO_STORE_GOOGLE.md (STORE-GPG-001)
* Estimated effort: 40-60 hours across client + server + store console setup

Status: Open (SHIP BLOCKER)

Owner: Developer / AI

Created: 2026-02-19

---

### R-135 — Photos Uploaded Without EXIF Stripping — GPS Coordinates Exposed

Category: Security & Privacy

Description:
Profile photos and chat media are uploaded to Firebase Storage without stripping EXIF metadata. EXIF data can contain GPS coordinates, device info, timestamps, and other sensitive metadata. This is a significant privacy risk for a dating app where user location safety is paramount.

Impact: High (privacy violation, potential stalking risk)

Likelihood: High (confirmed — no EXIF stripping code found in upload paths)

Affected Areas:
* lib/features/profile/data/services/profile_media_service.dart
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
* Any photo upload path in the app

Mitigation Plan:
* See TODO_PROFILE_FRONTEND.md (PROF-FE-004) for EXIF stripping implementation
* See TODO_CHAT_UI.md (CHAT-UI-006) for chat media EXIF stripping
* Use `image` package or platform channels to strip EXIF before upload
* Server-side backup: Cloud Function to strip EXIF on Storage trigger

Status: Open

Owner: AI

Created: 2026-02-19

---

### R-136 — ChatScreen Has Zero Accessibility (3,230 Lines, 0 Semantics Calls) (PARTIALLY MITIGATED)

Category: Accessibility / Compliance

Description:
ChatScreen at 3,230 lines is the largest file in the codebase and has ZERO Semantics widget calls. This means the entire chat experience — the core feature of a messaging app — is completely inaccessible to screen reader users. Messages, input, send button, media, actions — none have semantic labels. This affects WCAG 2.1 AA compliance and may trigger App Store accessibility review flags.

Impact: High (accessibility compliance, user exclusion)

Likelihood: Medium (reduced — 9 chat widgets now have Semantics, but ChatScreen itself still needs work)

Affected Areas:
* lib/features/chat/presentation/screens/chat_screen.dart (3,230 lines) — still needs Semantics
* ~~Chat-related widgets~~ — RESOLVED: 9 widgets now have proper Semantics wrappers

Partial Resolution (2026-02-19):
* ✅ Added Semantics to 9 chat widgets: typing indicator, reaction button, attachment tile, date separator, voice note player, voice note recorder, send status bar, fade notification, empty state
* ✅ Added semanticLabel parameter to all 5 GlassButton variants
* ✅ Added live region announcements for dynamic content (typing, upload status, notifications)
* ✅ Added reduced motion support to 4 animation widgets
* ✅ Added DsContrastColors for glass fallback colors
* ✅ Added DsTextScaleCap for text scaling (max 2.0x)
* ✅ Added DsFocusTraversalScreen for keyboard navigation
* ⏳ ChatScreen itself (3,230 lines) still needs Semantics on message bubbles, input bar, action sheets

Remaining Work:
* See TODO_CHAT_UI.md (CHAT-UI-003) for chat-screen-specific accessibility
* Priority: Add Semantics to message bubbles, input bar, send button, action sheets in ChatScreen

Status: Partially Mitigated

Owner: AI

Created: 2026-02-19
Updated: 2026-02-19

---

### R-138 — Biometric Auth Emulator/Simulator Behavior

Category: Security / Testing

Description:
Biometric authentication (local_auth v3.0.0) may behave differently on emulators/simulators vs real devices. iOS Simulator supports Face ID simulation but Android emulators may not always support fingerprint simulation correctly.

Impact: Low (development/testing only)

Likelihood: Medium (emulators are primary test environment)

Mitigation:
* Always test biometric flows on physical devices before release
* BiometricCubit handles `unavailable` state gracefully (skips biometric gate)

Status: Open (monitoring)

Owner: AI

Created: 2026-02-19

---

### R-139 — Age Validation Gap for Direct Firestore Writes

Category: Security / Compliance

Description:
Server-side age validation (`validateMinimumAge()`) is enforced on the REST `PATCH /v1/profile/me` endpoint but NOT on direct Firestore writes from the mobile app. A user with Firestore access could potentially bypass the 18+ restriction by writing directly to their profile document.

Impact: Medium (compliance violation if bypassed)

Likelihood: Low (requires Firestore security rules bypass or direct SDK access)

Mitigation:
* Client-side DOB picker already prevents selecting dates making user < 18
* Add Firestore security rules or a Firestore trigger to validate DOB on write
* Consider moving all profile writes through the REST API

Status: Open

Owner: AI

Created: 2026-02-19

---

### R-140 — Apple Revocation JWT Not Cryptographically Verified

Category: Security

Description:
The Apple credential revocation webhook at `/v1/auth/apple/revocation` parses the JWT payload from Apple's server-to-server notification but does not cryptographically verify the JWT signature against Apple's public keys. An attacker could forge a revocation request.

Impact: Medium (could deactivate arbitrary accounts if endpoint is discovered)

Likelihood: Low (endpoint not publicly documented, requires knowledge of user Apple UIDs)

Mitigation:
* Endpoint is obscure and requires specific Apple user sub claims
* Before production deployment: add Apple public key fetching and JWT signature verification
* Consider IP allowlisting for Apple's server IPs

Status: Open

Owner: AI

Created: 2026-02-19

---

### R-137 — Most Screens Not Using Adaptive Layout System (iPad Compliance)

Category: iPad Compliance / UX

Description:
The design system has AdaptiveLayout, AdaptiveScaffold, AdaptiveGrid, and DsBreakpoints infrastructure, but the vast majority of the 48+ screens don't use it. Most screens use hardcoded widths, fixed layouts, and mobile-only assumptions. This will cause poor iPad experience (stretched layouts, wasted space, touch target issues) and may trigger App Store rejection for inadequate iPad support.

Impact: High (iPad UX, App Store rejection risk)

Likelihood: High (confirmed — audit found most screens bypass adaptive infrastructure)

Affected Areas:
* All 48+ screens in lib/features/*/presentation/screens/
* lib/design_system/layout/ (infrastructure exists but underutilized)

Mitigation Plan:
* See TODO_IPAD_COMPLIANCE.md (IPAD-001 through IPAD-011) for full screen-by-screen plan
* See TODO_RESPONSIVE_DESIGN.md (RESP-001 through RESP-008) for responsive design tasks
* Priority: Start with core flows (auth, discovery, chat, profile) then secondary screens

Status: Partially Mitigated (RESP-001–008 complete, 21/56 screens responsive)

Owner: AI

Created: 2026-02-19

---

### R-161: NavigationRail state preservation on window resize

Severity: Low

Description: When resizing the window between mobile and tablet breakpoints, the NavigationRail replaces GlassBottomNavBar. The selected index is preserved via _index in StatefulWidget state, so no state loss occurs. However, rapid resizing during animations could theoretically cause layout jank.

Mitigation: _index is held in StatefulWidget state, surviving rebuilds. LayoutBuilder only triggers rebuild on actual constraint changes. No animation state is tied to navigation mode.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-162: Content clipping on very narrow tablet in split-view

Severity: Low

Description: On iPad in split-view mode, the available width may be between 320-500px, which is above the phone size but narrower than normal tablet. Content constrained to contentMaxWidth could still be appropriate since DsBreakpoints.isMobile returns true for widths <600px, falling back to unconstrained layout.

Mitigation: DsBreakpoints.isMobile threshold at 600px ensures split-view narrow layouts use mobile (unconstrained) mode. No clipping expected.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-164: ExploreGridView shows same deck profiles

Severity: Low

Description: ExploreGridView shows profiles from filteredDeck starting at currentIndex. When the user swipes in deck (swipe) mode, those profiles are consumed and the index advances. If the user switches to explore mode, the grid reflects the remaining profiles. If a profile is tapped and liked from the full profile view, the discovery bloc doesn't currently advance the deck index — the user returns to the grid with the same profile still visible.

Mitigation: Profiles in the grid are for browsing; the full profile view (OtherUserProfileArgs) handles like/pass. The deck index only advances on swipe events, not profile view actions. This is by design — the grid is a browse view, not a swipe replacement.

Status: Accepted

Owner: AI

Created: 2026-02-19

---

### R-165: Keyboard shortcuts may conflict with web scroll

Severity: Low

Description: Arrow key shortcuts (← → ↑ ↓) in deck_screen could conflict with browser/system scroll behavior on web platform. The Focus widget captures KeyDownEvent before propagation, but on web, some browsers may still intercept arrow keys for page scrolling.

Mitigation: Focus widget with autofocus captures events first. On web, this is standard behavior for focused interactive widgets. If issues arise, can add platform check to disable on web.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-166: Video timeout may be aggressive on slow connections

Severity: Low

Description: 10-second timeout on video initialization may trigger on slow cellular connections, showing "Video unavailable" prematurely.

Mitigation: 10 seconds is generous for most connections. Fallback shows first photo instead of infinite spinner, which is better UX. User can navigate to next media slot and back to retry.

Status: Accepted

Owner: AI

Created: 2026-02-19

---
