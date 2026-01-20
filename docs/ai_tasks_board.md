# AI Tasks Board

This file tracks task assignments and ownership for multi-AI collaboration.

---

## Template

```
Task: <short title>
ID: T-XXX
Owner AI: <Claude/Codex/Other>
Critic AI: <Claude/Codex/Other>
Status: Proposed / Planned / In-Review / Executing / Done / Blocked
Goal:
...
Scope (in/out):
In:
Out:
Files expected to change:
...
Risks:
...
Acceptance criteria:
...
Verification:
Commands:
Manual flow:
```

---

## Active Tasks

(None currently)

---

## Completed Tasks

### Task: CRITICAL - Fix user data leakage on logout
ID: T-001
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Prevent previous user's data (profile, chats, matches, photos, settings) from being visible to next user after logout.

Scope (in/out):
In:
- ProfileBloc, ChatBloc, DiscoveryBloc, MatchesBloc state reset
- SharedPreferences clearance (safety, privacy, discovery settings)
- NetworkImageCache clearance
Out:
- Cubits (SafetyCubit, PrivacySettingsCubit) - future enhancement

Files changed:
- lib/core/services/user_data_clearance_service.dart (NEW)
- lib/features/auth/presentation/bloc/auth_bloc.dart
- lib/features/profile/presentation/bloc/profile_bloc.dart
- lib/features/profile/presentation/bloc/profile_event.dart
- lib/features/chat/presentation/bloc/chat_bloc.dart
- lib/features/chat/presentation/bloc/chat_event.dart
- lib/features/discovery/presentation/bloc/discovery_bloc.dart
- lib/features/discovery/presentation/bloc/discovery_event.dart
- lib/features/chat/presentation/bloc/matches_bloc.dart
- lib/features/chat/presentation/bloc/matches_event.dart
- lib/core/di.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/chat/presentation/screens/chat_list_screen.dart
- test/matches_bloc_test.dart

Risks:
- Auth subscription could fire during normal navigation → Mitigated: only resets when user is null
- Performance impact → Mitigated: async clearance runs once on logout

Acceptance criteria:
- ✅ App builds without errors
- ✅ No profile/chat/match data visible after logout and new login
- ✅ BLoC state properly reset to initial values
- ✅ SharedPreferences user keys cleared
- ✅ Image cache cleared

Verification:
Commands: `flutter run`
Manual flow:
1. Create account A, complete profile, add photos, make matches
2. Sign out from account A
3. Create new account B
4. Verify: No data from account A visible

Completed: 2026-01-20

---

### Task: Send date plan email to emergency contact
ID: T-011
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
Send an email notification to the emergency contact when a date plan is created.

Scope (in/out):
In:
- Firebase callable to send date plan email (Resend)
- Client-side call after date plan creation
Out:
- Persistent date plan storage

Files changed:
- functions/src/index.ts
- lib/features/safety/data/services/date_plan_service.dart
- lib/presentation/screens/safety_screen.dart

Risks:
- Email notifications depend on Resend configuration
- Rate limits may block frequent plan creation

Acceptance criteria:
- ✅ Contact email receives date plan details after creation
- ✅ Invalid contact email is rejected in UI
- ✅ Clear error shown if notification fails

Verification:
Commands: `firebase deploy --only functions`
Manual flow:
1. Open Safety screen -> Create Date Plan
2. Enter valid contact email and submit
3. Verify contact receives email with date details

Completed: 2026-01-20

---

### Task: Matches screen likes-you section + dummy likes
ID: T-012
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Show matched users under "Matched with you" and show blurred "Likes You" cards with DOB/distance and upgrade prompt.

Scope (in/out):
In:
- Matches screen UI sections for matched/likes
- Likes You card blur + upgrade prompt
- Stub likes to ensure 2-3 dummy accounts
Out:
- Backend likes storage changes

Files changed:
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart

Risks:
- Exposing DOB/distance before match
- Premium upsell prompt may be intrusive

Acceptance criteria:
- ✅ Matched users listed under "Matched with you"
- ✅ Likes You shows 2-3 blurred dummy profiles in stub mode
- ✅ Tapping blurred card prompts upgrade
- ✅ Tapping matched user opens chat

Verification:
Commands: `flutter run`
Manual flow:
1. Swipe right on a profile -> match appears in "Matched with you"
2. Open Matches -> Likes You section shows blurred cards
3. Tap blurred card -> upgrade prompt appears
4. Tap matched user -> chat opens

Completed: 2026-01-20

---

### Task: Fix sign-out redirect to Basic Info Screen
ID: T-002
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Allow users to sign out from any onboarding stage without being redirected back to onboarding screens.

Scope (in/out):
In: Router redirect conditions
Out: Auth flow logic

Files changed:
- lib/core/router.dart (lines 190, 208, 228, 244)

Risks:
- None identified

Acceptance criteria:
- ✅ Users can sign out during any onboarding stage
- ✅ Redirect goes to login screen, not back to onboarding

Verification:
Commands: `flutter run`
Manual flow:
1. Create account, accept terms, stop at Basic Info
2. Trigger sign out
3. Verify redirect to login screen

Completed: 2026-01-20

---

### Task: Fix broken profile photos
ID: T-003
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Display profile photos correctly for both local file paths and remote URLs.

Scope (in/out):
In: CachedNetworkImage widget
Out: Firebase Storage upload logic

Files changed:
- lib/shared/widgets/cached_network_image.dart

Risks:
- Local paths won't persist across sessions → Expected debug behavior

Acceptance criteria:
- ✅ Photos display from local file paths
- ✅ Photos display from remote URLs
- ✅ No broken image icons

Completed: 2026-01-20

---

### Task: Remove blur effect from own profile photos
ID: T-004
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Display user's own photos clearly without gradient overlay effect.

Scope (in/out):
In: profile_view_screen.dart _PhotosGrid widget
Out: Other users' photo display (intentionally blurred for premium)

Files changed:
- lib/features/profile/presentation/screens/profile_view_screen.dart

Risks:
- Layout changes → Mitigated: increased spacing

Acceptance criteria:
- ✅ Own photos display without blur/gradient
- ✅ Photos are larger (2-column vs 3-column grid)

Completed: 2026-01-20

---

### Task: Allow weekly picks during onboarding and remove Deck safety icon
ID: T-005
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
Prevent the Weekly Picks button from redirecting to onboarding and remove the deck app bar safety icon.

Scope (in/out):
In:
- Router guard allowlist for Weekly Picks during onboarding
- Deck app bar action icons
Out:
- In-card safety menu (kept)

Files changed:
- lib/core/router.dart
- lib/features/discovery/presentation/screens/deck_screen.dart

Risks:
- Onboarding gating loosened for Weekly Picks only

Acceptance criteria:
- ✅ Weekly Picks opens during onboarding instead of redirecting to Basic Info
- ✅ Safety shield icon removed from Deck app bar
- ✅ Safety & Blocking remains in Settings

Verification:
Commands: `flutter run`
Manual flow:
1. Login with account missing Basic Info
2. Tap Weekly Picks button in Deck app bar
3. Verify Weekly Picks opens
4. Verify no safety shield icon in Deck app bar

Completed: 2026-01-20

---

### Task: Enforce onboarding redirect away from Home
ID: T-010
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Ensure users with incomplete onboarding cannot land on Home after accepting terms or signing in.

Scope (in/out):
In:
- Router guard allowlist for needsBasicInfo/needsProfileSetup
Out:
- Onboarding step screens and profile completion logic

Files changed:
- lib/core/router.dart

Risks:
- Potential redirect loop if AuthBloc state is stale right after profile save

Acceptance criteria:
- New accounts go to onboarding steps after accepting terms
- Home is blocked until basic info and profile setup are complete

Verification:
Commands: `flutter run`
Manual flow:
1. Create account -> accept terms
2. Verify redirect to Basic Info (not Home)
3. Complete onboarding, verify Home becomes available

Completed: 2026-01-20

---

### Task: Prevent onboarding reroute to profile setup on restart
ID: T-006
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
Avoid incorrect onboarding redirects on app restart by ensuring profile setup completion recognizes video-only profiles and auth state is refreshed once after login.

Scope (in/out):
In:
- CrushUser onboarding completion logic
- AuthBloc initial refresh behavior
Out:
- Router redirect rules

Files changed:
- lib/data/models/user.dart
- lib/features/auth/presentation/bloc/auth_bloc.dart

Risks:
- Extra auth refresh call after login

Acceptance criteria:
- ✅ Users with videos but no photos are not forced back into profile setup
- ✅ Auth state refreshes once on login to use latest profile data

Verification:
Commands: `flutter run`
Manual flow:
1. Sign in, add only a profile video, finish onboarding
2. Restart app
3. Verify app does not redirect back to profile setup

Completed: 2026-01-20

---

### Task: Prevent onboarding reroute to Basic Info on restart
ID: T-007
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
Avoid Basic Info reroute after restart by aligning completion logic with required fields.

Scope (in/out):
In:
- CrushUser basic info completion logic
Out:
- Basic Info UI validation

Files changed:
- lib/data/models/user.dart

Risks:
- Users can complete onboarding without a display name if they left it blank

Acceptance criteria:
- ✅ Users who already completed Basic Info are not routed back after restart

Verification:
Commands: `flutter run`
Manual flow:
1. Complete Basic Info (username + DOB + gender)
2. Restart app
3. Verify: not routed to Basic Info

Completed: 2026-01-20

---

### Task: Create project flowchart documentation
ID: T-008
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
Provide a clear, repo-wide flowchart covering navigation and architecture.

Scope (in/out):
In:
- New flowchart doc in docs/
Out:
- Code changes

Files changed:
- docs/project_flowchart.md

Risks:
- Flowchart could drift from code if routes change

Acceptance criteria:
- ✅ Flowchart includes app navigation and architecture/data flow

Verification:
Commands: None
Manual flow:
- Render Mermaid diagrams in a Markdown viewer

Completed: 2026-01-20

---

### Task: Route T&C acceptance into onboarding steps
ID: T-009
Owner AI: Codex
Critic AI: Codex (self-critique; developer approved)
Status: Done

Goal:
After accepting terms, route new users into the onboarding steps instead of Home.

Scope (in/out):
In:
- Terms & Conditions acceptance handler routing
Out:
- Router guard logic

Files changed:
- lib/features/auth/presentation/screens/terms_conditions_screen.dart

Risks:
- None identified

Acceptance criteria:
- ✅ New users go to Basic Info after accepting terms
- ✅ Existing completed users still reach Home

Verification:
Commands: `flutter run`
Manual flow:
1. Create account -> accept terms
2. Verify routed to Basic Info (not Home)

Completed: 2026-01-20
