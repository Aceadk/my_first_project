# Risk Register — CRUSH Dating App

This document tracks technical, product, security, and architectural risks.

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

### R-104 — Discovery payload mismatch blocks real users

Category: Backend dependencies

Description:
`fetchDiscoveryCandidates` returns `profiles` with nested `profile` objects, while the client expects `candidates` and flattens fields.

Impact: High

Likelihood: High

Affected Areas:
* functions/src/index.ts
* lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart

Mitigation:
* Align Cloud Function response shape with client expectation.
* Update client mapping to handle `profiles` if kept.

Status: Open

Owner: AI

Created: 2026-01-22

---

### R-105 — Missing chat callables in Firebase Functions

Category: Backend dependencies

Description:
Client calls `sendMessage`, `markMessagesRead`, and `editMessage` callables that are not defined in Functions.

Impact: High

Likelihood: High

Affected Areas:
* functions/src/index.ts
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart

Mitigation:
* Implement the missing callables or switch the client to Firestore writes with matching rules.

Status: Open

Owner: AI

Created: 2026-01-22

---

### R-106 — Storage rules mismatch for profile/chat media

Category: Backend dependencies

Description:
Storage rules allow `users/{uid}/media` and `chats/{matchId}/{messageId}`, but the app uploads to `users/{uid}/photos|videos` and `chat_media/...`.

Impact: High

Likelihood: High

Affected Areas:
* storage.rules
* lib/features/profile/data/services/profile_media_service.dart
* lib/features/chat/data/repositories/impl/firebase_chat_repository.dart

Mitigation:
* Align storage paths in code with rules (or update rules to allow current paths).

Status: Open

Owner: AI

Created: 2026-01-22

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

### R-109 — Call screen uses placeholder caller ID (now reachable)

Category: Backend dependencies

Description:
CallScreen initiates calls with a hardcoded `callerId: 'current_user'`. Now that the call route is reachable from chat, this may break call identity tracking.

Impact: Medium

Likelihood: Medium

Affected Areas:
* lib/features/calls/presentation/screens/call_screen.dart
* lib/features/chat/presentation/screens/chat_screen.dart

Mitigation:
* Pass the authenticated user ID into CallScreen and wire to CallService.

Status: Open

Owner: AI

Created: 2026-01-23

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

### R-004 — BoostRepository only has Stub implementation

Category: Backend dependencies

Description:
BoostRepository only has StubBoostRepository. Firebase/HTTP implementations are TBD. Profile boost feature won't work in production until implemented.

Impact: Medium

Likelihood: High

Affected Areas:
* lib/features/discovery/data/repositories/boost_repository.dart
* lib/core/di.dart

Mitigation Plan:
* Implement FirebaseBoostRepository
* Gate the boost UI behind feature flag until ready

Status: Open

Owner: Developer

Last Reviewed: 2026-01-20

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
