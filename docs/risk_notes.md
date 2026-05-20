# Risk Register — CRUSH Dating App

This document tracks technical, product, security, and architectural risks.

---

## Active Risks (Ordered by Severity: Low -> Medium -> High -> Critical)

### R-001 — Firebase Storage upload failures in debug mode (was R-002)

Category: Backend dependencies

Description:
Firebase Storage uploads fail in debug mode due to security rules, causing fallback to local file paths. Local paths are saved to Firestore but won't work across devices/sessions.

Impact: Low (debug only)

Likelihood: High (in debug)

Affected Areas:

- lib/core/services/profile_media_service.dart
- lib/shared/widgets/cached_network_image.dart

Mitigation Plan:

- ✅ CachedNetworkImage handles both local and remote URLs
- Deploy proper Firebase Storage security rules for production
- Add upload status/retry mechanism

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-002 — Cubits not reset on logout (was R-003)

Category: Security & privacy

Description:
SafetyCubit, PrivacySettingsCubit, DiscoverySettingsCubit store user preferences in SharedPreferences. While the clearance service clears the SharedPreferences keys, the Cubits may hold stale runtime state until reloaded.

Impact: Low

Likelihood: Low

Affected Areas:

- lib/features/settings/presentation/bloc/safety_cubit.dart
- lib/features/settings/presentation/bloc/privacy_settings_cubit.dart
- lib/features/discovery/presentation/bloc/discovery_settings_cubit.dart

Mitigation Plan:

- Add auth state subscription to these Cubits (similar to BLoCs)
- Or rely on app restart after logout

Status: Open

Owner: AI

Last Reviewed: 2026-01-20

---

### R-003 — Onboarding redirect loop if auth state is stale (was R-005)

Category: Routing/navigation

Description:
Home is blocked while onboarding is incomplete. If AuthBloc lags behind profile updates, users could be redirected back to onboarding briefly after saving.

Impact: Low

Likelihood: Medium

Affected Areas:

- lib/core/router.dart
- lib/features/profile/presentation/screens/profile_setup_screen.dart
- lib/features/auth/presentation/screens/basic_info_screen.dart

Mitigation Plan:

- Ensure AuthUserRefreshRequested is fired after onboarding saves (already in place)
- Consider awaiting refresh or showing a transient loading state before navigation

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-004 — Skeleton shimmer performance on low-end devices (was R-103)

Category: Performance / UX

Description:
Animated skeletons during loading could increase GPU/CPU usage and cause jank on lower-end devices if too many are visible at once.

Impact: Low

Likelihood: Medium

Affected Areas:

- lib/features/discovery/presentation/widgets/deck_skeleton.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart

Mitigation:

- Keep skeleton counts modest.
- Prefer a single shimmer wrapper where possible.
- Revisit animation duration and density if jank is observed.

Status: Monitoring

Owner: AI

Created: 2026-01-20

---

### R-005 — Glass buttons reduce link affordance in auth flow (was R-110)

Category: UX

Description:
Replacing TextButton/OutlinedButton with Glass variants in the auth flow may reduce perceived affordance for secondary actions (e.g., "Forgot password", "Resend").

Impact: Low

Likelihood: Medium

Affected Areas:

- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/phone_auth_screen.dart
- lib/features/auth/presentation/screens/otp_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/email_verification_screen.dart
- lib/features/auth/presentation/screens/terms_conditions_screen.dart

Mitigation:

- Keep labels explicit and ensure proper spacing for tap targets.
- Add Semantics labels for screen readers.

Status: Monitoring

Owner: AI

Created: 2026-01-23

---

### R-006 — Auth screen moves could leave stale import paths (was R-111)

Category: Build / Architecture

Description:
Auth/onboarding screens were moved into `lib/features/auth/presentation/screens`. Any missed imports or stale references could break builds or routing.

Impact: Low

Likelihood: Low

Affected Areas:

- lib/core/router.dart
- lib/features/profile/profile.dart
- lib/features/auth/presentation/screens/\*.dart

Mitigation:

- Search for old `lib/presentation/screens/...` paths and update imports.
- Run `flutter analyze` or build to confirm.

Status: Monitoring

Owner: AI

Created: 2026-01-23

---

### R-007 — Discovery browsing no longer requires email verification (Cloud Function) (was R-131)

Category: Security / Auth

Description:
`requireEmailVerified` was removed from `fetchDiscoveryCandidates` Cloud Function to fix discovery showing no users for email/password accounts that haven't verified. Browsing is now open to all authenticated users.

Impact: Low (read-only operation; all write operations like swiping, messaging still require verification)

Likelihood: Low (Flutter routing already gates unverified users at the UI level)

Mitigation:

- Write operations (swipeRight, swipeLeft, sendMessage, reportUser, etc.) still enforce `requireEmailVerified`
- Flutter routing prevents unverified email users from reaching discovery screen
- No PII is exposed through discovery browsing (profiles are public-facing data)

Status: Open (monitoring)

Owner: AI

Created: 2026-02-18

---

### R-008 — iOS project still uses CocoaPods while Flutter SPM adoption is pending

Category: Build / Toolchain

Description:
The direct `permission_handler` and `app_tracking_transparency` dependencies were removed to eliminate the current unsupported-iOS-SPM plugin warning, but the Runner project is still kept on the existing CocoaPods integration path with `enable-swift-package-manager: false`.

Impact: Low

Likelihood: Medium

Affected Areas:

- pubspec.yaml
- ios/Runner.xcodeproj/project.pbxproj
- ios/Podfile
- ios/Podfile.lock

Mitigation:

- Plan a deliberate iOS generated-project migration to Swift Package Manager after validating Firebase/plugin compatibility.
- Keep future Flutter upgrades paired with an iOS no-codesign build check.
- Revisit `enable-swift-package-manager` before Flutter turns SPM migration warnings into build errors.

Status: Open

Owner: AI

Created: 2026-05-20

---

### R-009 — Android Kotlin Gradle Plugin migration warning

Category: Build / Toolchain

Description:
`flutter build apk --debug` succeeds, but Flutter warns that the app and several plugins still apply the Kotlin Gradle Plugin path that will fail in a future Flutter version unless migrated to Built-in Kotlin or upgraded to compatible plugin versions.

Impact: Low

Likelihood: Medium

Affected Areas:

- android/app/build.gradle.kts
- android/gradle.properties
- Flutter plugins that still apply Kotlin Gradle Plugin

Mitigation:

- Plan a separate Android Built-in Kotlin migration.
- Upgrade plugins as compatible releases become available.
- Keep Android debug build verification in future Flutter upgrade tasks.

Status: Open

Owner: AI

Created: 2026-05-20

---

### R-008 — Some iOS plugins do not yet support Swift Package Manager

Category: Build / Toolchain

Description:
Flutter 3.44 warns that `permission_handler_apple` and `app_tracking_transparency` do not support Swift Package Manager for iOS. The current build still succeeds through CocoaPods/Flutter compatibility handling, but Flutter says this will become an error in a future version.

Impact: Low

Likelihood: Medium

Affected Areas:

- `pubspec.yaml`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`

Mitigation:

- Track plugin releases for Swift Package Manager support.
- Update or replace affected plugins before Flutter removes the compatibility fallback.
- Keep CocoaPods build verification in place while mixed SPM/CocoaPods support is still required.

Status: Monitoring

Owner: AI

Created: 2026-05-20

---

### R-008 — Biometric Auth Emulator/Simulator Behavior (was R-138)

Category: Security / Testing

Description:
Biometric authentication (local_auth v3.0.0) may behave differently on emulators/simulators vs real devices. iOS Simulator supports Face ID simulation but Android emulators may not always support fingerprint simulation correctly.

Impact: Low (development/testing only)

Likelihood: Medium (emulators are primary test environment)

Mitigation:

- Always test biometric flows on physical devices before release
- BiometricCubit handles `unavailable` state gracefully (skips biometric gate)

Status: Open (monitoring)

Owner: AI

Created: 2026-02-19

---

### R-009 — Clipboard Auto-Clear Timer Lost on App Kill (was R-141)

Category: Security / Privacy
Severity: Low
Status: Accepted

**Risk:** `SecureClipboard` uses a Dart `Timer` for 60s auto-clear. If the app is killed before the timer fires, clipboard content persists.
**Mitigation:** Acceptable trade-off. Users can manually clear clipboard. No persistent sensitive data (chat messages are ephemeral). The timer provides best-effort privacy protection.

---

### R-010 — Root/Jailbreak Detection Heuristics Bypassable (was R-142)

Category: Security
Severity: Low
Status: Accepted

**Risk:** `DeviceIntegrityService` uses file-path heuristics that sophisticated users can bypass (e.g., Magisk Hide, path relocation).
**Mitigation:** Detection is informational only — does not block app usage. Results logged for fraud analytics. Consider server-side attestation (Play Integrity / App Attest via App Check) for stronger protection.

---

### R-011 — In-Memory Rate Limiter Resets on Cloud Functions Cold Start (was R-144)

Category: Security
Severity: Low
Status: Accepted

**Risk:** Express rate limiter uses in-memory `Map` which resets on Cloud Functions cold start. Attacker could time requests to exploit cold starts.
**Mitigation:** Acceptable for serverless. Provides best-effort protection for normal usage patterns. Callable functions use persistent Firestore-based `applyRateLimit()`. For stronger enforcement, consider Redis (Memorystore) in production.

---

### R-012 — Foreground Resume Refresh Could Race With Active Operations (was R-149)

Category: Performance
Severity: Low
Description: When app resumes from background, `_refreshOnResume()` triggers SubscriptionRestoreRequested and ProfileLoadRequested. If the user was already mid-operation (e.g., saving profile), the refresh could interfere.
Mitigation: 30-second debounce prevents rapid-fire refreshes. Both BLoC handlers are idempotent. ProfileLoadRequested only loads if no save is in progress. SubscriptionRestoreRequested is a read-only operation.
Status: ACCEPTED — Low risk, mitigations adequate.

---

### R-013 — ConnectivityCubit DNS Polling in Restricted Environments (MITIGATED) (was R-150)

Category: Reliability
Severity: Low (MITIGATED)

- Uses InternetAddress.lookup('dns.google') which may fail in:
  - Airplane mode (SocketException — handled)
  - DNS-blocking VPNs (may appear offline when online)
  - China/restricted networks (dns.google blocked)
- Mitigation: All exceptions caught → defaults to offline. Host is configurable.
- Future: Consider fallback to connectivity_plus package for native API checks.

---

### R-014 — Circuit Breaker State Lost on App Restart (EXPECTED) (was R-151)

Category: Architecture
Severity: Low (EXPECTED)

- CircuitBreakerRegistry is in-memory only — resets on cold start
- This is intentional: ensures fresh start, avoids persisting stale state
- If persistent circuit state is needed later, add SharedPreferences backing

---

### R-015 — ErrorBoundary Analytics Calls in Test Context (MITIGATED) (was R-152)

Category: Testing
Severity: Low (MITIGATED)

- ErrorBoundary now calls AnalyticsService on reportError/retry/goHome
- Tests must install StubAnalyticsService via setUpAll to avoid FirebaseException
- Already handled: test/error_boundary_test.dart has setUp/tearDown
- Risk: New tests using ErrorBoundary without stub will fail — pattern documented

---

### R-016 — Chat Message Memory Cap May Trim Visible Context (MITIGATED) (was R-153)

Category: Performance/UX
Severity: Low (MITIGATED)

- Chat messages capped at 200 in memory to prevent unbounded growth
- When receiving new messages, oldest are trimmed; when loading more, newest are trimmed
- Risk: rapid scrolling between old and new messages could cause context loss
- Mitigated: 200 is generous (6.6 pages of 30), trimmed messages re-fetchable via pagination
- User leaving and re-entering chat resets to fresh 30 messages

---

### R-017 — ImageOptimizer Uses PNG Encoding Instead of JPEG (KNOWN) (was R-154)

Category: Performance
Severity: Low (KNOWN)

- `dart:ui` only supports PNG encoding natively (no JPEG encoder in Dart SDK)
- Optimized images are resized and EXIF-stripped but encoded as PNG (lossless, larger than JPEG)
- For production: recommend server-side re-compression to JPEG/WebP after upload
- Current benefit: resize from 12MP→2048px and EXIF removal still provides significant size reduction

---

### R-018 — flushNotificationQueue Runs Every 60 Minutes (LOW) (was R-156)

Category: UX
Severity: Low
Description: Queued notifications (from quiet hours) are flushed via Cloud Functions scheduled every 60 minutes. Users may experience up to 60min delay after quiet hours end.
Mitigation: Acceptable trade-off for V1. Can reduce to 15min if UX feedback warrants it.

---

### R-019 — Notification Image Download May Delay Foreground Display (LOW) (was R-157)

Category: Performance
Severity: Low
Description: `_showLocalNotification` downloads images via HTTP before displaying the notification. On slow connections, this could delay notification appearance.
Mitigation: Falls back to text-only notification if download fails. HttpClient used with standard timeout.

---

### R-020 — Enter-to-Send on External Keyboard (LOW) (was R-159)

Category: UX
Severity: Low
Description: iPad external keyboard users may expect Enter to insert newline (not send). Our behavior: Enter=send, Shift+Enter=newline (matches WhatsApp/Telegram desktop).
Mitigation: Consistent with major chat apps. Shift+Enter available for newline. Documented in future onboarding.
Task: T-2026-02-19-10

---

### R-021 — Chat Memory Cap Reduced to 100 Messages (MITIGATED) (was R-160)

Category: UX
Severity: Low
Description: `_maxMessagesInMemory` reduced from 200 to 100 for virtualization. Very active chats may trim context faster.
Mitigation: Scroll-based pagination reloads trimmed messages. Page size increased to 50 for smoother experience.
Task: T-2026-02-19-10

---

### R-022 — Location Permission Rationale Timing (LOW) (was R-161)

Category: UX
Severity: Low
Description: Location permission rationale is now shown as a bottom sheet after the first frame of ProfileSetupScreen instead of auto-requesting in initState. This introduces a brief moment where the screen renders before the rationale appears.
Mitigation: The delay is imperceptible (single frame, ~16ms). The rationale sheet is non-dismissible (isDismissible: false, enableDrag: false), ensuring the user must choose Allow or Not Now. If user taps Not Now, they can enable location later in Settings. Discovery still works without location but user won't appear in distance-based results.
Task: T-2026-02-19-ONBOARD001-002

---

### R-023 — NavigationRail state preservation on window resize (was R-161)

Severity: Low

Description: When resizing the window between mobile and tablet breakpoints, the NavigationRail replaces GlassBottomNavBar. The selected index is preserved via \_index in StatefulWidget state, so no state loss occurs. However, rapid resizing during animations could theoretically cause layout jank.

Mitigation: \_index is held in StatefulWidget state, surviving rebuilds. LayoutBuilder only triggers rebuild on actual constraint changes. No animation state is tied to navigation mode.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-024 — Content clipping on very narrow tablet in split-view (was R-162)

Severity: Low

Description: On iPad in split-view mode, the available width may be between 320-500px, which is above the phone size but narrower than normal tablet. Content constrained to contentMaxWidth could still be appropriate since DsBreakpoints.isMobile returns true for widths <600px, falling back to unconstrained layout.

Mitigation: DsBreakpoints.isMobile threshold at 600px ensures split-view narrow layouts use mobile (unconstrained) mode. No clipping expected.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-025 — ExploreGridView shows same deck profiles (was R-164)

Severity: Low

Description: ExploreGridView shows profiles from filteredDeck starting at currentIndex. When the user swipes in deck (swipe) mode, those profiles are consumed and the index advances. If the user switches to explore mode, the grid reflects the remaining profiles. If a profile is tapped and liked from the full profile view, the discovery bloc doesn't currently advance the deck index — the user returns to the grid with the same profile still visible.

Mitigation: Profiles in the grid are for browsing; the full profile view (OtherUserProfileArgs) handles like/pass. The deck index only advances on swipe events, not profile view actions. This is by design — the grid is a browse view, not a swipe replacement.

Status: Accepted

Owner: AI

Created: 2026-02-19

---

### R-026 — Keyboard shortcuts may conflict with web scroll (was R-165)

Severity: Low

Description: Arrow key shortcuts (← → ↑ ↓) in deck_screen could conflict with browser/system scroll behavior on web platform. The Focus widget captures KeyDownEvent before propagation, but on web, some browsers may still intercept arrow keys for page scrolling.

Mitigation: Focus widget with autofocus captures events first. On web, this is standard behavior for focused interactive widgets. If issues arise, can add platform check to disable on web.

Status: Mitigated

Owner: AI

Created: 2026-02-19

---

### R-027 — Video timeout may be aggressive on slow connections (was R-166)

Severity: Low

Description: 10-second timeout on video initialization may trigger on slow cellular connections, showing "Video unavailable" prematurely.

Mitigation: 10 seconds is generous for most connections. Fallback shows first photo instead of infinite spinner, which is better UX. User can navigate to next media slot and back to retry.

Status: Accepted

Owner: AI

Created: 2026-02-19

---

### R-028 — SemanticsHelper Uses Global Locale Instead of App Locale (LOW) (was R-167)

Category: Accessibility / I18N
Severity: Low
Description: `semantics_helper.dart` is a static utility with no `BuildContext`, so it uses `intl.Intl.getCurrentLocale()` for date formatting instead of `Localizations.localeOf(context)`. If the user changes the app locale at runtime without restarting, semantics date strings may briefly use the previous locale until the intl default locale is updated.
Mitigation: The `Intl.defaultLocale` is typically set at app startup and when locale changes. Accessibility strings are not user-visible (screen reader only), so a brief mismatch is not noticeable. The app's locale change via LocaleCubit triggers a full rebuild which re-sets the default locale.
Status: Accepted
Owner: AI
Created: 2026-02-20

---

### R-029 — BLoC state complexity growth (was R-001)

Category: State management

Description:
AuthBloc handles multiple auth methods (phone OTP, email, password, magic link). DiscoveryBloc manages deck + matches + super likes + rewind. As features grow, these BLoCs may become difficult to maintain.

Impact: Medium

Likelihood: Medium

Affected Areas:

- lib/features/auth/presentation/bloc/auth_bloc.dart
- lib/features/discovery/presentation/bloc/discovery_bloc.dart

Mitigation Plan:

- Consider splitting into sub-BLoCs if complexity increases
- Add comprehensive unit tests for state transitions
- Document state machine flows

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-030 — Date plan email notifications depend on Resend configuration (was R-006)

Category: Backend dependencies

Description:
Emergency contact emails require a configured Resend API key and sender address. Missing configuration or provider outages will prevent notifications.

Impact: Medium

Likelihood: Medium

Affected Areas:

- functions/src/index.ts
- lib/features/safety/data/services/date_plan_service.dart
- lib/presentation/screens/safety_screen.dart

Mitigation Plan:

- Return clear errors when email is not configured
- Rate limit notifications to reduce abuse
- Add monitoring/alerts for failed sends

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-031 — Exposing DOB and distance for non-matched likes (was R-007)

Category: Security & privacy

Description:
Likes You cards display date of birth and distance even before a mutual match, which may surface sensitive information to non-premium users.

Impact: Medium

Likelihood: Medium

Affected Areas:

- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart

Mitigation Plan:

- Consider showing age instead of full DOB
- Add privacy setting to hide DOB/distance until match

Status: Monitoring

Owner: AI

Last Reviewed: 2026-01-20

---

### R-032 — Name privacy defaults hide public names (was R-102)

Category: UX / Privacy

Description:
First/last name visibility now defaults to private. If users do not opt in, public cards and matches may show placeholder names, which could reduce clarity or engagement.

Impact: Medium

Likelihood: Medium

Affected Areas:

- lib/features/auth/presentation/screens/basic_info_screen.dart
- lib/features/profile/presentation/screens/profile_edit_screen.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart

Mitigation:

- Onboarding prompt explains privacy default and toggle.
- Profile Edit exposes name visibility controls.
- Stub profiles opt-in to show first name for demo UX.

Status: Open

Owner: AI

Created: 2026-01-20

---

### R-033 — Android permissions missing for camera/microphone (was R-107)

Category: Build & deployment

Description:
Android manifest does not declare `CAMERA` or `RECORD_AUDIO`, risking failures for video calls and voice notes.

Impact: Medium

Likelihood: Medium

Affected Areas:

- android/app/src/main/AndroidManifest.xml

Mitigation:

- Add required permissions and verify runtime requests on Android 13+.

Status: Open

Owner: AI

Created: 2026-01-22

---

### R-034 — Feature cubit data persists after logout (mitigated) (was R-108)

Category: Security & privacy

Description:
Weekly Picks, Date Ideas, Compatibility Quiz, and Profile Insights retained cached state without auth cleanup, risking cross-user leakage.

Impact: Medium

Likelihood: Medium

Affected Areas:

- lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart
- lib/features/social/presentation/bloc/date_ideas_cubit.dart
- lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart
- lib/features/analytics/presentation/bloc/profile_insights_cubit.dart
- lib/features/discovery/data/services/weekly_picks_service.dart
- lib/features/social/data/services/date_idea_service.dart
- lib/features/social/data/services/compatibility_quiz_service.dart
- lib/features/analytics/data/services/profile_insights_service.dart

Mitigation:

- Added auth state listeners to reset cubit state on logout.
- Cleared in-memory service caches when auth becomes null.

Status: Mitigated

Owner: AI

Created: 2026-01-23

---

### R-035 — AI collaboration docs may drift without after-edit sync (was R-112)

Category: Process / Quality

Description:
If agents do not re-read and update collaboration docs after edits, changes can be missed and tasks can diverge.

Impact: Medium

Likelihood: Low

Affected Areas:

- docs/ai_workboard.md
- docs/Developer_agent_chat.md
- docs/risk_notes.md
- scripts/check_ai_docs_sync.sh
- .github/workflows/ci.yml

Mitigation:

- Added automated docs sync guard: `scripts/check_ai_docs_sync.sh`.
- CI now enforces the guard on every push/PR via `.github/workflows/ci.yml`.
- Guard fails when required docs are missing from the change set:
  - `docs/ai_workboard.md`
  - `docs/Developer_agent_chat.md`
- Guard fails if deprecated docs are reintroduced/modified:
  - `docs/ai_change_log.md`
  - `docs/ai_tasks_board.md`
  - `docs/ai_collab_chat.md`
- AGENTS.md now includes the guard as mandatory closeout verification.

Status: Closed

Owner: AI

Created: 2026-01-23
Updated: 2026-02-22

---

### R-036 — Low Test Coverage (improving) (was R-118)

Category: Quality

Description:
Originally only 21 test files for 457 Dart files (~200,330 LOC), representing 4.6% test-to-code ratio. As of 2026-02-12, added 9 new test files with 292 tests covering critical service areas and untested features. Test files added: content_moderation (56), consent (14), tracking_consent (6), data_export (19), subscription (42), feature_flags (27), call_bloc (18), social_cubits (64), verification (46). Total now ~30 test files.

Impact: Medium

Likelihood: Medium (improving)

Affected Areas:

- test/
- All feature modules

Mitigation Plan:

- ~~Add service-layer unit tests~~ (done: 5 critical service areas covered with 137 tests)
- ~~Add feature-area unit tests~~ (done: 4 feature areas covered with 155 tests — feature flags, calls, social, verification)
- Add BLoC unit tests for remaining 22+ BLoCs/Cubits
- Add repository integration tests
- Add widget tests for design system
- Target 40% coverage for MVP, 60% for v1.0

Status: In Progress (partially mitigated)

Owner: Developer / AI

Created: 2026-01-31
Updated: 2026-02-12

---

### R-037 — Minimum Flutter/Dart toolchain bumped by dependency upgrades (was R-120)

Category: Build / Tooling

Description:
Upgrading go_router (17) and google_fonts (8) raises the minimum required
toolchain to Flutter 3.35 and Dart 3.9. Developers using older SDKs will see
dependency resolution failures.

Impact: Medium

Likelihood: Medium

Affected Areas:

- pubspec.yaml environment constraints
- Local developer toolchains / CI images

Mitigation:

- ✅ Documented new minimum toolchain in `pubspec.yaml` and project docs
- ✅ CI pinned to Flutter 3.35.0
- ✅ Notify collaborators to update Flutter/Dart or use FVM

Status: Mitigated

Owner: AI

Created: 2026-02-01

---

### R-038 — Firebase Functions config deprecation (March 2026) (was R-122)

Category: Build / Operations

Description:
Cloud Functions previously used `functions.config()` for runtime config (Stripe, Agora, OTP, email). Firebase is deprecating the legacy config API in March 2026.

Impact: Medium

Likelihood: High

Affected Areas:

- functions/src/index.ts (config usage)
- functions deployment pipeline

Mitigation:

- ✅ Migrated to `firebase-functions/params` with .env-backed values
- ✅ Removed `functions.config()` usage from functions code

Status: Mitigated

Owner: AI

Created: 2026-02-06

---

### R-039 — 73 Presentation Layer Files Import Data Layer Directly (was R-126)

Category: Architecture / Clean Architecture

Description:
73 files in `*/presentation/**/*.dart` directly import from `*/data/` layer, violating the clean architecture dependency rule. Screens and BLoCs import repository implementations, DTOs, and data models instead of going through domain layer abstractions. Additionally, 6+ screens access singleton services directly (e.g., `CallService.instance`, `IncognitoService.instance`) bypassing DI.

Impact: Medium (testability, maintainability)

Likelihood: High (confirmed — 73 files affected)

Affected Areas:

- lib/features/\*/presentation/ — 73 files importing from data layer
- Key violators: discovery_bloc.dart, chat_bloc.dart, other_user_profile_screen.dart

Mitigation Plan:

- Phase 1: Register singleton services in DI container (CrushDI)
- Phase 2: Refactor BLoCs to use repository interfaces, not implementations
- Phase 3: Remove direct data layer imports from presentation screens
- Estimated effort: 80-120 hours

Status: Open (documented for future refactoring)

Owner: Developer / AI

Created: 2026-02-12

---

### R-040 — Large Widget/BLoC Files Need Splitting (was R-128)

Category: Code Quality / Performance

Description:
Several key files exceed recommended size limits, making them harder to maintain, test, and optimize for rebuilds:

- ChatScreen: 3,226 lines
- SignUpScreen: 1,935 lines
- DiscoveryFiltersScreen: 1,850 lines
- ProfileEditScreen: ~2,000 lines
- ChatBloc: 824 lines (largest BLoC)
- DiscoveryBloc: 700 lines

Impact: Medium (maintainability, performance)

Likelihood: High (confirmed file sizes)

Mitigation Plan:

- Split ChatBloc into smaller cubits (typing, reactions, media, message sending)
- Extract reusable widgets from large screens (ChatBubble, ChatInput, ChatHeader)
- Use `BlocSelector` for fine-grained rebuilds instead of full `BlocBuilder`

Status: Open (documented for future refactoring)

Owner: Developer / AI

Created: 2026-02-12

---

### R-041 — Age Validation Gap for Direct Firestore Writes (was R-139)

Category: Security / Compliance

Description:
Server-side age validation (`validateMinimumAge()`) is enforced on the REST `PATCH /v1/profile/me` endpoint but NOT on direct Firestore writes from the mobile app. A user with Firestore access could potentially bypass the 18+ restriction by writing directly to their profile document.

Impact: Medium (compliance violation if bypassed)

Likelihood: Low (requires Firestore security rules bypass or direct SDK access)

Mitigation:

- Client-side DOB picker already prevents selecting dates making user < 18
- Add Firestore security rules or a Firestore trigger to validate DOB on write
- Consider moving all profile writes through the REST API

Status: Open

Owner: AI

Created: 2026-02-19

---

### R-042 — Apple Revocation JWT Not Cryptographically Verified (was R-140)

Category: Security

Description:
The Apple credential revocation webhook at `/v1/auth/apple/revocation` parses the JWT payload from Apple's server-to-server notification but does not cryptographically verify the JWT signature against Apple's public keys. An attacker could forge a revocation request.

Impact: Medium (could deactivate arbitrary accounts if endpoint is discovered)

Likelihood: Low (endpoint not publicly documented, requires knowledge of user Apple UIDs)

Mitigation:

- Endpoint is obscure and requires specific Apple user sub claims
- Before production deployment: add Apple public key fetching and JWT signature verification
- Consider IP allowlisting for Apple's server IPs

Status: Open

Owner: AI

Created: 2026-02-19

---

### R-043 — FLAG_SECURE Not Implemented for Sensitive Screens (was R-143)

Category: Privacy
Severity: Medium
Status: Open

**Risk:** Android `FLAG_SECURE` (screenshot/screen recording prevention) not yet applied to chat or profile screens. Users' private conversations could be screen-captured.
**Mitigation:** Deferred to future iteration. Requires platform channel implementation. Chat content is user-generated and not credentials, so risk is moderate.

---

### R-044 — Firestore Backup Bucket Requires Manual Creation (was R-145)

Category: Operations / Data Loss
Severity: Medium
Status: Open

**Risk:** `scheduledFirestoreBackup` function will fail until the backup bucket (`{projectId}-firestore-backups`) is manually created in GCP Console with 30-day lifecycle policy.
**Mitigation:** Document bucket creation in deployment checklist. Function logs errors but doesn't crash. Create bucket with: `gsutil mb gs://{projectId}-firestore-backups && gsutil lifecycle set lifecycle.json gs://{projectId}-firestore-backups`.

---

### R-045 — Legacy Chat Media Storage Path Now Blocked (was R-146)

Category: Compatibility
Severity: Medium
Status: Accepted

**Risk:** Legacy `chats/{matchId}/` storage path now returns 403 for all operations. Any older clients using direct storage reads will fail.
**Mitigation:** Current app code uses `getChatMediaSignedUrl` Cloud Function for cross-user access and `chat_media/` path for uploads. Legacy path was insecure (any authenticated user could read). Migration is intentional — verify no clients still reference the old path.

---

### R-046 — iOS Notification Service Extension Requires Xcode Target Setup (MANUAL) (was R-155)

Category: Build
Severity: Medium
Description: The iOS NSE source files (`ios/NotificationServiceExtension/NotificationService.swift` + `Info.plist`) are created but the Xcode project target must be added manually by the developer.
Mitigation: Files are ready to use. Developer needs to: 1) Add new Notification Service Extension target in Xcode, 2) Point to existing source files, 3) Set deployment target to match app, 4) Add to same App Group.

---

### R-047 — iPad Split-View ChatScreen Inline Rendering (MITIGATED) (was R-158)

Category: Architecture
Severity: Medium
Description: ChatScreen rendered inline as child of ChatListScreen's Row on iPad. BLoC lifecycle must properly reset when switching conversations.
Mitigation: `ValueKey(_selectedChat!.matchId)` forces full rebuild on conversation switch. ChatScreen disposes old BLoC and creates new one via ChatOpened event.
Task: T-2026-02-19-10

---

### R-048 — Backend API abuse from forged requests (MITIGATED) (was R-116)

Category: Security

Description:
Without App Check, malicious actors could forge API requests to Cloud Functions, potentially abusing the discovery, matching, or messaging systems.

Impact: High

Likelihood: Medium

Affected Areas:

- functions/src/index.ts (all callable functions)
- lib/core/services/app_check_service.dart

Resolution:

- ✅ Added Firebase App Check with DeviceCheck (iOS) and Play Integrity (Android)
- ✅ Added `verifyAppCheck()` helper to Cloud Functions
- ✅ `ENFORCE_APP_CHECK` flag for gradual rollout (currently false for monitoring)
- ⏳ Enable enforcement after confirming all clients have App Check

Status: In Progress (monitoring mode)

Owner: AI

Opened: 2026-01-31

---

### R-049 — Firebase Storage not initialized in production project (was R-121)

Category: Product / Infrastructure

Description:
Firebase Storage is not enabled for project `crush-265f7`, blocking deployment of `storage.rules` and preventing profile photo uploads.

Impact: High

Likelihood: High

Affected Areas:

- storage.rules
- Profile photo uploads
- Media features

Mitigation:

- ⏳ Enable Firebase Storage in console and run `firebase deploy --only storage`

Status: Open

Owner: AI

Created: 2026-02-06

---

### R-050 — Flat vs nested Firestore document structure mismatch (web vs mobile) (was R-124)

Category: Architecture / Data Integrity

Description:
Web-created user profiles store fields at the document root (flat structure: `doc.displayName`, `doc.birthDate`, etc.) while mobile-created profiles store them nested under a `profile` sub-object (`doc.profile.displayName`, `doc.profile.birthDate`, etc.). This caused Firestore security rules to fail for web profiles because rules assumed the nested structure. The `isFemale()` helper and user read rules were also affected.

Impact: High

Likelihood: High (confirmed — discovery was completely broken for web users)

Affected Areas:

- `firestore.rules` — read rules and helper functions must handle both structures
- `packages/core/src/services/match.ts` — discovery profile mapping
- Any new Firestore rules or Cloud Functions that access user profile fields

Resolution (Partial):

- Made Firestore security rules null-safe: checks `resource.data.profile.hideFromDiscovery` with null fallback to `resource.data.hideFromDiscovery`
- Fixed `isFemale()` to check both `resource.data.profile.gender` and `resource.data.gender`
- Discovery now works for both web and mobile users

Remaining Risk:

- Any NEW Firestore rules or Cloud Functions that access user profile fields must handle both flat and nested structures
- Long-term fix: normalize the document structure across web and mobile (either both flat or both nested)
- Until normalized, every rule/function touching user docs is a potential regression point

Status: Mitigated (short-term fix applied, structural normalization still needed)

Owner: AI

Created: 2026-02-11

---

### R-051 — Android Play Integrity Not Fully Configured (was R-129)

Category: Security / Store Compliance

Description:
Firebase App Check is configured with DeviceCheck (iOS) and Play Integrity (Android), but Play Integrity may not be fully registered in Google Play Console. The ENFORCE_APP_CHECK flag is set to false (monitoring mode). Without proper Play Integrity configuration, Android requests could be forged.

Impact: High

Likelihood: Medium

Affected Areas:

- lib/core/services/app_check_service.dart
- functions/src/index.ts (ENFORCE_APP_CHECK flag)
- Google Play Console configuration

Mitigation Plan:

- Configure Play Integrity API in Google Play Console
- Register app signing certificate
- Test with real Play Integrity tokens
- Enable enforcement: set ENFORCE_APP_CHECK=true after verification

Status: Open — requires manual Google Play Console action

Owner: Developer

Created: 2026-02-12

---

### R-052 — Photos Uploaded Without EXIF Stripping — GPS Coordinates Exposed (PARTIALLY MITIGATED) (was R-135)

Category: Security & Privacy

Description:
Profile uploads now pass through `ImageOptimizer` before upload, and a regression test verifies EXIF GPS/device metadata is removed from a fabricated JPEG prior to transmission. Chat image uploads also call the same optimizer path, but dedicated chat-path EXIF regression coverage is still pending.

Impact: Medium (remaining risk is regression drift and missing direct chat-path proof coverage)

Likelihood: Low-Medium (current upload paths strip via re-encode; risk is primarily coverage/contract drift)

Affected Areas:

- lib/features/profile/data/services/profile_media_service.dart
- lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
- test/profile_media_service_hotspot_test.dart (profile EXIF regression coverage)

Mitigation Plan:

- Keep profile EXIF stripping regression test in CI (`PROF-FE-004`)
- Add explicit chat upload EXIF regression test coverage (`TODO_CHAT_UI.md`, CHAT-UI-006)
- Keep server-side backup option (Storage-triggered metadata scrub) for defense in depth

Status: Partially Mitigated

Owner: AI

Created: 2026-02-19
Last Reviewed: 2026-03-07

---

### R-053 — ChatScreen Has Zero Accessibility (3,230 Lines, 0 Semantics Calls) (PARTIALLY MITIGATED) (was R-136)

Category: Accessibility / Compliance

Description:
ChatScreen at 3,230 lines is the largest file in the codebase and has ZERO Semantics widget calls. This means the entire chat experience — the core feature of a messaging app — is completely inaccessible to screen reader users. Messages, input, send button, media, actions — none have semantic labels. This affects WCAG 2.1 AA compliance and may trigger App Store accessibility review flags.

Impact: High (accessibility compliance, user exclusion)

Likelihood: Medium (reduced — 9 chat widgets now have Semantics, but ChatScreen itself still needs work)

Affected Areas:

- lib/features/chat/presentation/screens/chat_screen.dart (3,230 lines) — still needs Semantics
- ~~Chat-related widgets~~ — RESOLVED: 9 widgets now have proper Semantics wrappers

Partial Resolution (2026-02-19):

- ✅ Added Semantics to 9 chat widgets: typing indicator, reaction button, attachment tile, date separator, voice note player, voice note recorder, send status bar, fade notification, empty state
- ✅ Added semanticLabel parameter to all 5 GlassButton variants
- ✅ Added live region announcements for dynamic content (typing, upload status, notifications)
- ✅ Added reduced motion support to 4 animation widgets
- ✅ Added DsContrastColors for glass fallback colors
- ✅ Added DsTextScaleCap for text scaling (max 2.0x)
- ✅ Added DsFocusTraversalScreen for keyboard navigation
- ⏳ ChatScreen itself (3,230 lines) still needs Semantics on message bubbles, input bar, action sheets

Remaining Work:

- See TODO_CHAT_UI.md (CHAT-UI-003) for chat-screen-specific accessibility
- Priority: Add Semantics to message bubbles, input bar, send button, action sheets in ChatScreen

Status: Partially Mitigated

Owner: AI

Created: 2026-02-19
Updated: 2026-02-19

---

### R-054 — Most Screens Not Using Adaptive Layout System (iPad Compliance) (was R-137)

Category: iPad Compliance / UX

Description:
Responsive coverage was previously incomplete, but all audited `presentation/screens` now use breakpoint-aware layout constraints.

Impact: High (iPad UX, App Store rejection risk)

Likelihood: Low (current responsive audit indicates full coverage; regression risk remains)

Affected Areas:

- No remaining non-adaptive `presentation/screens` in 2026-03-07 audit (`54/54` responsive).

Mitigation Plan:

- Keep responsive checks in follow-up UI changes.
- Re-run coverage audit after each responsive or layout-heavy pass.
- Re-open this risk if any non-adaptive screens reappear in audit results.

Status: Mitigated (2026-03-07 audit: 54/54 responsive; 0 non-adaptive remaining)

Owner: AI

Created: 2026-02-19
Last Reviewed: 2026-03-07

---

### R-055 — CRITICAL: Native Billing Partially Integrated — Receipt Validation and Store Lifecycle Incomplete (SHIP BLOCKER) (was R-134)

Category: Store Compliance / Revenue

Description:
`in_app_purchase` dependencies and mobile native checkout routing are integrated in the client (`SubscriptionBloc -> purchasePlusPlan`, Firebase iOS/Android path -> `NativeBillingService`), and backend lifecycle coverage now includes Google token validation + RTDN sync and Apple transaction validation + Apple S2S webhook sync with iOS restore verification. End-to-end store-compliant billing is still incomplete because final App Store Connect and Play Console submission execution/reviewer configuration remain outstanding. Store submission remains blocked until those release-operations steps are complete.

Impact: Critical (P0 — app cannot ship without this)

Likelihood: Confirmed (verified — server-side receipt validation and full subscription lifecycle handling are not yet implemented end-to-end)

Affected Areas:

- lib/features/subscription/data/services/checkout_service.dart (legacy web checkout helper remains in codebase)
- lib/features/subscription/data/services/native_billing_service.dart (native purchase + restore/ack completion present; iOS transaction-id handoff now included for server verification)
- lib/features/subscription/data/repositories/impl/firebase_subscription_repository.dart (Google + Apple restore verification paths present; remaining provider lifecycle sync work is webhook-side)
- lib/features/subscription/presentation/bloc/subscription_bloc.dart (restore path surfaces no-purchase/error outcomes; deeper purchase-state UX still pending)
- functions/src/ (Google + Apple validation and lifecycle webhooks implemented; requires production credential wiring and monitoring during rollout)
- App Store Connect (review checklist docs are complete; subscription product/reviewer setup + submission execution still pending)
- Google Play Console (release checklist documentation complete; reviewer setup + submission execution still pending)

Mitigation Plan:

- See TODO_SUBSCRIPTION.md (SUB-001 through SUB-010) for full implementation plan
- See TODO_STORE_APPLE.md (STORE-APL-001 through STORE-APL-005) and TODO_STORE_GOOGLE.md
- Estimated effort: 8-16 hours across store console/reviewer setup + release execution

Status: Open (SHIP BLOCKER)

Owner: Developer / AI

Created: 2026-02-19
Last Reviewed: 2026-03-08

---

### R-056 — Profile Completeness Backend Fallback Previously Granted Full Eligibility (MITIGATED)

Category: Backend dependencies / Trust & Safety

Description:
`ProfileValidationService` previously returned a hardcoded permissive completeness response (`score=1.0`, all gates true) whenever `checkProfileCompleteness` failed. During backend outages, this silently bypassed messaging/swipe gating expectations.

Impact: High (gating bypass during backend failure windows)

Likelihood: Low (reduced — mitigated with explicit degraded-mode handling)

Affected Areas:

- lib/features/profile/data/services/profile_validation_service.dart
- test/profile_validation_service_test.dart

Mitigation Plan:

- Cache last-known successful completeness per minimum (`swipe`/`messaging`)
- On validation failures:
  - use cached result when available
  - otherwise throw explicit unavailable exception so callers fall back to local checks
- Keep timeout/network degraded-mode behavior covered by unit tests

Status: Mitigated (2026-03-07)

Owner: AI

Created: 2026-03-07
Updated: 2026-03-07

---

## Risk Categories

- Architecture
- State management
- Routing/navigation
- Security & privacy
- Performance
- UX/product
- Backend dependencies
- Build & deployment

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
- Multi Steps

Status:
- Open / Mitigated / Monitoring / Closed

Owner:
- AI / Developer

Last Reviewed:
- YYYY-MM-DD
```

---

### R-057 — Deep-Link Handling Split Across Bootstrap and Route Parser (MITIGATED)

Category: Routing/navigation

Description:
Deep-link route handling was previously split and duplicated between `lib/core/deep_link_bootstrap.dart` and `lib/core/routing/deep_links.dart`. Bootstrap now delegates route decisions to shared `DeepLinkHandler`, including queued processing for auth-required links after authentication.
App shell now passes explicit `onNavigate` callback from `lib/app.dart`. Guarded-route and deep-link regressions now cover chat/profile/settings/support-category links, `match` alias mapping, `premium/upgrade` auth-replay flows, and unauthenticated access rules for public legal/support routes.

Impact: Low (residual risk is mainly integration permutation coverage)

Likelihood: Low

Affected Areas:

- lib/core/deep_link_bootstrap.dart
- lib/core/routing/deep_links.dart
- lib/app.dart
- test/core/deep_link_bootstrap_test.dart
- test/core/routing/deep_links_test.dart
- test/core/deep_link_auth_transition_integration_test.dart

Mitigation Plan:

- Keep route deep-link handling centralized through `DeepLinkHandler`.
- Keep app-shell integration regression for pending-link replay green in CI.
- Expand integration coverage when new deep-link routes are added.
- Document accepted platform-specific deep-link differences explicitly.

Status: Mitigated (expanded coverage on 2026-03-11)

Owner: AI

Created: 2026-03-10
Updated: 2026-03-11

---

### R-058 — User Document Schema Dual-Shape Compatibility Migration Tail (MONITORING)

Category: Architecture / Security & privacy

Description:
Canonicalization safeguards are now in place:

- app auth repository normalizes legacy flat user docs into nested `profile.*` and persists cleanup,
- Firestore rules now block new/mutated legacy flat profile writes on `/users/{uid}`,
- backend preferences updates remove the top-level `preferences` mirror.
  Legacy read compatibility is now instrumented and time-bounded:
- Cloud Functions logs `legacy_profile_preferences_fallback_read` when legacy top-level `preferences` fallback is used,
- fallback is cutoff-controlled by `PROFILE_PREFERENCES_LEGACY_FALLBACK_CUTOFF` (default `2026-06-30T00:00:00.000Z`),
- after cutoff, backend stops returning legacy fallback preferences and logs `legacy_profile_preferences_fallback_blocked_after_cutoff`.

Impact: Medium (reduced from high; residual migration/deprecation execution risk)

Likelihood: Low

Affected Areas:

- firestore.rules
- functions/firestore.rules
- functions/src/index.ts
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/core/schema/user_document_schema.dart

Mitigation Plan:

- Monitor legacy fallback telemetry logs and confirm zero legacy reads.
- Keep cutoff date explicit via env param and adjust only through controlled rollout.
- Remove fallback code path and associated logs once telemetry is consistently zero.

Status: Monitoring (telemetry + cutoff implemented on 2026-03-10)

Owner: AI

Created: 2026-03-10
Updated: 2026-03-10

---

### R-059 — Branding and Localization Drift Across Runtime and Legal Surfaces (MITIGATED)

Category: UX/product

Description:
Branding has been normalized to `Crush` on high-visibility app/web/backend runtime surfaces and localized ARB value strings.
Legal and high-traffic non-legal runtime surfaces are normalized and covered by regression tests (`Crush` product naming, `CrushHour Inc.` legal entity wording in legal contexts), including onboarding/discovery/premium hotspots and contiguous-script localization cases (`zh`, `yue`).
Residual risk is limited to future-copy drift and intentional noun-style localization vocabulary (`wordCrush`) that is tracked separately as glossary policy.

Impact: Low (user-facing product-brand inconsistency significantly reduced)

Likelihood: Low

Affected Areas:

- lib/l10n/app\_\*.arb
- lib/l10n/generated/\*
- lib/presentation/screens/terms_of_service_screen.dart
- lib/presentation/screens/privacy_policy_screen.dart
- test/presentation/screens/legal_branding_copy_test.dart
- lib/core/widgets/update_dialog.dart
- test/core/update_dialog_branding_test.dart
- test/brand_copy_case_regression_test.dart
- lib/presentation/screens/safety_screen.dart
- lib/presentation/screens/community_guidelines_screen.dart
- lib/presentation/screens/home/settings_screen.dart
- lib/features/about/presentation/screens/pricing_screen.dart
- lib/features/about/presentation/screens/product_features_screen.dart
- lib/features/discovery/presentation/screens/likes_you_screen.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/widgets/biometric_prompt.dart

Mitigation Plan:

- Keep runtime/localized brand references on `Crush`.
- Preserve legal entity wording as `CrushHour Inc.` in legal/policy contexts.
- Maintain regression coverage for legal + update-dialog + onboarding/discovery/localization brand copy contracts.
- Run periodic copy sweeps for new high-traffic screens and update localization glossary policy as needed.

Status: Mitigated (2026-03-10; monitor long-tail glossary/regression coverage)

Owner: AI

Created: 2026-03-10
Updated: 2026-03-10

---

### R-060 — Overlapping Environment Entry Points Caused Flavor/Mode Drift (MITIGATED)

Category: Architecture / Configuration

Description:
`AppConfig` and `AppEnvConfig` previously resolved runtime mode from different sources with conflicting defaults (`FLAVOR=development` vs `APP_ENV=prod`). This could produce inconsistent behavior for dev-only gates and made environment setup brittle across local/dev pipelines.
Canonical key policy and deprecation dates are now documented in `docs/ENV_KEY_MATRIX.md`, and release-script compatibility warnings are in place for `APP_ENV`.
CI now enforces deprecated-alias usage boundaries via `scripts/check_deprecated_env_aliases.sh` and operator migration checkpoints via `scripts/check_env_alias_migration_status.sh`.
Operator audit artifacts are now generated via `scripts/generate_env_alias_migration_audit_report.sh` and stored in `docs/reports/`.

Impact: Low-Medium (behavior drift in development/debug safeguards; low production impact)

Likelihood: Low (after mitigation)

Affected Areas:

- lib/config/app_config.dart
- lib/core/app_env.dart
- lib/core/utils/constants.dart
- test/config/app_config_env_resolution_test.dart
- test/core/app_env_mode_resolution_test.dart

Mitigation Plan:

- Keep one canonical flavor resolver in `AppConfig` (`FLAVOR` -> legacy `APP_ENV` -> fallback `development`).
- Derive `AppEnvConfig` mode from resolved `AppConfig.flavor` instead of parsing `APP_ENV` independently.
- Preserve legacy key compatibility for migration safety and keep regression tests for precedence/mapping behavior.
- Enforce migration timeline from `docs/ENV_KEY_MATRIX.md`:
  - freeze canonical-key migration by 2026-06-30,
  - remove legacy fallback aliases by 2026-09-30 unless explicitly re-approved.
- Keep deprecated-alias allowlist guard green in CI and only extend allowlist through explicit risk review.
- Keep migration checkpoint guard green in CI and treat any emitter hit as release-blocking remediation work.
- Require dated migration audit artifact generation before production release cutover.
- Apply explicit release go/no-go gates from `docs/RELEASE_GUIDE.md`:
  - `Checkpoint status: PASS`
  - `Allowlist guard status: PASS`
  - pass markers present in artifact output sections.
- Enforce cutover ticket contract:
  - keep `scripts/check_release_cutover_ticket_contract.sh` green in CI (template contract),
  - validate each concrete cutover ticket includes exact dated audit artifact reference + `PASS` statuses.
- Use `scripts/create_production_cutover_ticket.sh` to reduce manual ticket-path/date entry errors before validation.
- Enforce concrete ticket validation on release refs via CI gate:
  - `scripts/check_release_cutover_ticket_release_ref_gate.sh` (release branches/tags).
- Keep release-ref gate regression script green in CI:
  - `scripts/test_release_cutover_ticket_release_ref_gate.sh`.
- Keep cutover scaffold/contract invalid-input regression script green in CI:
  - `scripts/test_release_cutover_ticket_invalid_input_cases.sh`.
- Keep release-ref gate fallback-no-ticket scenario covered by regression tests (custom empty-glob override path).
- Keep release-ref gate `GITHUB_REF`-unset + path-over-glob precedence scenarios covered by regression tests.
- Keep path-precedence failure semantics covered: invalid `RELEASE_CUTOVER_TICKET_PATH` must fail even if glob fallback would resolve a valid ticket.
- Keep branch/tag classification edge patterns (`refs/heads/release-*`, `refs/tags/*`) and non-release near-matches covered by regression tests.

Status: Mitigated (2026-03-11)

Owner: AI

Created: 2026-03-11
Updated: 2026-03-11

---

### R-061 — Discovery Eligibility Diverged Across App/Web Creation Paths (MITIGATED)

Category: Product / Architecture

Description:
Newly created users could satisfy the intended minimum appearance conditions and still fail to appear in discovery because signup/profile writes and discovery reads had drifted apart across platforms.
Web profile creation wrote a flat user shape (`displayName`, `photos`, `location`, `interestedIn`, root completion flags), while mobile/backend discovery primarily evaluated nested `profile.*` fields.
At the same time, web discovery queried Firestore directly with root-only completion filters, while the mobile app used a backend callable with nested-profile filters. This created a silent exclusion class where:
- web-created users were invisible to backend/mobile discovery,
- mobile-created users were invisible to web discovery,
- discovery exclusions were not explainable from one centralized rule.
The backend REST discovery deck also depended on `profile.isComplete`, which was not the canonical completion signal for newly created accounts.

Impact: High (new-user activation and matching broken across platforms)

Likelihood: Low (after mitigation)

Affected Areas:

- functions/src/index.ts
- functions/test/discoveryEligibility.test.js
- functions/test/profileRestValidation.test.js
- lib/core/schema/user_document_schema.dart
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- test/core/schema/user_document_schema_test.dart
- ../crush-web/packages/core/src/services/match.ts
- ../crush-web/packages/core/src/services/user.ts
- ../crush-web/packages/core/src/services/user_document.ts
- ../crush-web/packages/core/src/services/discovery_rest.ts
- ../crush-web/apps/web/src/lib/__tests__/discovery-schema.test.ts

Mitigation Plan:

- Keep one canonical backend discovery pipeline (`buildDiscoveryDeckPayload`) for both app and web clients.
- Keep one centralized eligibility evaluator (`buildDiscoveryUserSnapshot` + `evaluateDiscoveryEligibility`) that accepts both nested and legacy-flat user documents.
- Keep explicit exclusion-stage diagnostics (`relationship`, `eligibility`, `filter`) via `evaluateDiscoveryCandidateForRequester` and requester-facing `requester_status` / `getMyDiscoveryStatus` outputs.
- Mirror new web writes into canonical nested `profile.*` fields while preserving read compatibility for existing flat web documents during migration.
- Preserve root onboarding/profile flags on mobile writes so old readers and analytics continue to observe the expected lifecycle markers.
- Keep focused backend, Flutter schema, and web helper regression coverage green for flat-web ↔ nested-mobile discovery compatibility.

Rollout Update (2026-03-13):

- `fetchDiscoveryCandidates`, `api`, and `getMyDiscoveryStatus` are deployed in `crush-265f7`.
- Live synthetic validation against the production discovery deck confirmed an eligible legacy-flat web-shaped profile and an eligible canonical-nested mobile-shaped profile are mutually discoverable, and the temporary Firestore docs/auth accounts were deleted after the check.
- Live browser validation against `https://crush-web-chi.vercel.app` confirmed the public web app is still on the old Firestore-only discovery client path, so a compatibility layer was required instead of waiting on a Vercel deploy.
- `syncLegacyDiscoveryFields` is now deployed on `users/{uid}` writes; it mirrors canonical nested discovery fields back into the legacy flat root fields (`displayName`, `photos`, `location`, `interestedIn`, root completion flags, etc.) that the stale web client still reads directly from Firestore.
- A one-time Firestore REST backfill scanned `8` production user docs and patched `2` existing docs that still lacked the mirrored legacy fields.
- Live production validation against the old Firestore query shape (`where(onboardingComplete == true, profileComplete == true)`) now includes both freshly created canonical nested docs and the two previously missing production user IDs, so stale web discovery is no longer blocked by the pending Vercel rollout.

Status: Mitigated (2026-03-13; backend deck + legacy Firestore compatibility live, Vercel rollout now non-blocking)

Owner: AI

Created: 2026-03-13
Updated: 2026-03-13 (compatibility trigger deployed, production backfill complete, stale web query validated)

---

### R-062 — Backlog and Workboard References Drifted From Existing TODO Docs (CLOSED)

Category: Process / Documentation

Description:
Backlog discovery had drifted away from the real repository state.
Earlier planning docs referenced a broad set of removed `docs/TODO_*.md` backlog files, which created audit noise and made it harder to tell which TODOs were still actionable.
On 2026-04-16 the repo first reconciled the surviving backlog docs, then performed a deliberate fresh-start reset back to a module-specific audit structure aligned with the CEO directive.
The active backlog surface is now explicit again through `docs/TODO_MASTER_AUDIT_V2_2026-02-20.md` plus the restored module TODO files.
Historical references inside older task-log entries remain as history, but they no longer define current planning.

Impact: Low (historical references remain, but active task selection is now grounded)

Likelihood: Very Low

Affected Areas:

- docs/ai_workboard.md
- docs/Developer_agent_chat.md
- docs/TODO_MASTER_AUDIT_V2_2026-02-20.md

Mitigation Plan:

- Keep `docs/TODO_MASTER_AUDIT_V2_2026-02-20.md` as the canonical audit entrypoint.
- Keep active work in module-specific `docs/TODO_*.md` files rather than rebuilding duplicate consolidated lists.
- Treat historical references in old task logs as archival context only, not as active backlog sources.
- Treat any future TODO-module reference as invalid unless the target file exists in `docs/`.

Status: Closed (2026-04-16)

Owner: AI

Created: 2026-03-30
Updated: 2026-04-21

---

### R-063 — Samsung ADB Instability Is Blocking Manual Accessibility Verification

Category: Environment / Verification

Description:
On 2026-04-16 the accessibility auth/profile slice passed targeted analyzer and widget coverage, and the requested Samsung device (`SM A037F`, serial `R9PT70YAHJE`) was initially discoverable via `flutter devices`.
However, the subsequent `flutter run -d R9PT70YAHJE` attempt failed during startup because `adb` lost the device before log capture (`adb: device 'R9PT70YAHJE' not found`).
That means the automated accessibility work is verified locally, but the requested manual Android hardware validation on the small-screen target is still blocked by an unstable device connection rather than app-code failure.

Impact: Medium (manual Android validation for the current accessibility slice is delayed)

Likelihood: Medium

Affected Areas:

- `docs/TODO_ACCESSIBILITY.md`
- `lib/features/auth/presentation/screens/auth_gateway_screen.dart`
- `lib/features/auth/presentation/screens/permission_rationale_screen.dart`
- `lib/features/profile/presentation/screens/profile_setup_screen.dart`

Mitigation Plan:

- Keep the targeted accessibility widget lane green so semantics/large-text regressions are still caught without hardware.
- Retry `adb devices -l` and `flutter run -d R9PT70YAHJE` once the handset connection is stable.
- Do not close `A11Y-001` or `A11Y-002` until the manual Samsung/TalkBack checks actually run on hardware.

Status: Open

Owner: AI

Created: 2026-04-16
Updated: 2026-04-21

---

### R-064 — Client / Backend API Contract Drift Is Leaving Dead Runtime Paths

Category: Architecture / Client-Backend Integration

Description:
The 2026-04-19 inventory audit originally found live dead-path risk across
discovery, chat safety appeal, calls, subscription, profile utility wrappers,
and HTTP auth.
The 2026-04-19 API-004 remediation slice plus the 2026-04-21 API-005 follow-up
removed the production dead paths in the active client wrappers, replaced HTTP
auth's nonexistent-route assumptions with callable-backed Firebase session
bridging, and retired discovery rewind explicitly at the runtime/product layer.
The 2026-04-21 API-006 remediation slice moved the call-signaling callable
exports onto the same shared callable App Check/error-normalization wrapper
used elsewhere in the backend, closing the last documented contract-enforcement
gap from that audit thread.

Impact: Low

Likelihood: Low

Affected Areas:

- `docs/API_CATALOG.md`
- `functions/src/index.ts`
- `functions/src/calls/signaling.ts`
- `functions/src/shared/callable.ts`

Mitigation Plan:

- Keep `docs/API_CATALOG.md` as the canonical current surface and update it
  before changing client wrappers or routes.
- Treat `API-004`, `API-005`, and `API-006` as completed
  contract-reconciliation slices.
- Keep the shared callable wrapper in `functions/src/shared/callable.ts` as the
  single enforcement path for callable App Check unless there is a documented,
  explicitly tested reason to diverge.
- Keep the corrected contract smoke tests in place so discovery, auth, safety
  appeal, calls, and subscription paths do not regress back to dead endpoints.

Status: Closed

Owner: AI

Created: 2026-04-19
Updated: 2026-04-21

---
