# Risk Register — CRUSH Dating App

This document tracks technical, product, security, and architectural risks.

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
* lib/presentation/screens/basic_info_screen.dart

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
