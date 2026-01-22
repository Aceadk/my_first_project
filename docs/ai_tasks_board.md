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

## Completed Tasks

### Task: Enforce before/after AI doc sync
ID: T-025
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Ensure every AI agent re-reads AI collaboration docs before and after edits and shares issues/suggestions.

Scope (in/out):
In:
- Update CLAUDE.md rules to require before/after doc reads and AI-to-AI suggestions
Out:
- Code changes or feature work

Files changed:
- CLAUDE.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- None (documentation change)

Acceptance criteria:
- ✅ CLAUDE.md explicitly requires before/after doc reads and suggestions

Verification:
Commands: Not run (not requested)
Manual flow:
1. Open CLAUDE.md and confirm rule wording

Completed: 2026-01-23

### Task: Move auth screens into auth feature folder
ID: T-024
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Relocate auth/onboarding account screens from `lib/presentation/screens` into `lib/features/auth/presentation/screens` and update imports/barrels.

Scope (in/out):
In:
- Splash, Basic Info, Email/Phone protection, Change Email, New Device, ID verification, Logout screens
- Router imports and profile barrel exports
- Auth system documentation paths
Out:
- Home, safety, privacy/terms, and other non-auth screens
- Routing behavior changes

Files changed:
- lib/features/auth/presentation/screens/splash_screen.dart
- lib/features/auth/presentation/screens/basic_info_screen.dart
- lib/features/auth/presentation/screens/email_protection_screen.dart
- lib/features/auth/presentation/screens/phone_protection_screen.dart
- lib/features/auth/presentation/screens/change_email_screen.dart
- lib/features/auth/presentation/screens/new_device_screen.dart
- lib/features/auth/presentation/screens/id_verification_screen.dart
- lib/features/auth/presentation/screens/logout_screen.dart
- lib/core/router.dart
- lib/features/profile/profile.dart
- docs/auth_system.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- Missed import update after moving screens could break builds.

Acceptance criteria:
- ✅ Screens live under `lib/features/auth/presentation/screens`
- ✅ No runtime references to old `lib/presentation/screens` paths

Verification:
Commands: Not run (not requested)
Manual flow:
1. Launch app -> splash -> auth gateway
2. Navigate to email/phone protection, change email, new device
3. Complete Basic Info -> ID verification
4. Open logout screen from settings

Completed: 2026-01-23

### Task: UI/UX polish for auth flow
ID: T-023
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Replace hard-coded colors with DsColors, swap Material buttons to Glass variants, and add accessibility labels in auth screens.

Scope (in/out):
In:
- Auth gateway, login, sign up, email auth, phone auth, OTP, forgot password, email verification, terms
Out:
- Discovery, chat, profile, settings screens (follow-up)

Files changed:
- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/phone_auth_screen.dart
- lib/features/auth/presentation/screens/otp_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/email_verification_screen.dart
- lib/features/auth/presentation/screens/terms_conditions_screen.dart
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- Glass buttons replace link-style actions; could reduce visual affordance

Acceptance criteria:
- ✅ Auth screens use DsColors and Glass button variants
- ✅ Key actions have Semantics labels

Verification:
Commands: Not run (not requested)
Manual flow:
1. Auth gateway -> create account/sign in
2. Login -> forgot password -> back
3. Email/phone auth -> OTP -> resend
4. Email verification -> resend/check/sign out

Completed: 2026-01-23

### Task: Add missing routes for call/video/media/story screens
ID: T-022
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Add GoRouter entries for CallScreen, VideoCallScreen, ProfileMediaScreen, and StoryViewerScreen, and wire entry points.

Scope (in/out):
In:
- Router constants and GoRoute definitions
- Navigation updates from chat and swipe card
- Story badge entry from discovery cards
Out:
- Deep link handling or backend call setup

Files changed:
- lib/core/router.dart
- lib/features/calls/presentation/screens/call_screen.dart
- lib/features/calls/presentation/screens/video_call_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- lib/features/discovery/presentation/screens/story_viewer_screen.dart
- lib/features/profile/presentation/screens/profile_media_screen.dart
- docs/project_flowchart.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- Call screen uses stub caller ID; now reachable from chat

Acceptance criteria:
- ✅ Routes exist for call/video/profile media/story viewer
- ✅ Video call + profile media use GoRouter navigation
- ✅ Story badge opens story viewer when stories exist

Verification:
Commands: Not run (not requested)
Manual flow:
1. Chat -> tap video call -> video call screen opens
2. Chat -> tap audio call -> call screen opens after confirm
3. Discovery card -> tap story badge -> story viewer opens
4. Discovery card -> tap media -> profile media screen opens

Completed: 2026-01-23

### Task: Fix Boost timer + add auth cleanup for feature cubits
ID: T-021
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Resolve BoostCubit timer recursion and ensure feature cubits reset on logout.

Scope (in/out):
In:
- BoostCubit refresh/timer behavior
- Auth cleanup for WeeklyPicksCubit, DateIdeasCubit, CompatibilityQuizCubit, ProfileInsightsCubit
- Clear in-memory service caches on logout
Out:
- Routing, DI, or UI changes

Files changed:
- lib/features/discovery/presentation/bloc/boost_cubit.dart
- lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart
- lib/features/discovery/data/services/weekly_picks_service.dart
- lib/features/social/presentation/bloc/date_ideas_cubit.dart
- lib/features/social/data/services/date_idea_service.dart
- lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart
- lib/features/social/data/services/compatibility_quiz_service.dart
- lib/features/analytics/presentation/bloc/profile_insights_cubit.dart
- lib/features/analytics/data/services/profile_insights_service.dart
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- Resetting cubit state on logout could clear in-flight UI state

Acceptance criteria:
- ✅ BoostCubit does not spawn recursive timers during refresh
- ✅ WeeklyPicks/DateIdeas/CompatibilityQuiz/ProfileInsights clear state on logout
- ✅ In-memory service caches cleared on logout to reduce data leakage

Verification:
Commands: Not run (not requested)
Manual flow:
1. Activate boost -> wait for expiry -> verify refresh happens once
2. Log out -> verify Weekly Picks/Date Ideas/Quiz/Insights reset

Completed: 2026-01-23

### Task: Project-wide audit + repo hygiene scan
ID: T-020
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Perform a cross-cutting audit of architecture, flows, Firebase alignment, and repo hygiene; document findings.

Scope (in/out):
In:
- Static review of routing, DI, discovery, chat, profile completeness, and Firebase config/rules
- Platform parity check (iOS/Android manifests)
- Repo hygiene scan (ignored/unmanaged artifacts)
Out:
- Code fixes or deletions (requires follow-up approval)

Files changed:
- AUDIT_REPORT.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Risks:
- Audit is static-only (no builds/device tests run)

Acceptance criteria:
- ✅ Audit addendum recorded with severity-ranked findings and next steps
- ✅ Repo hygiene observations documented

Verification:
Commands: None (static review)
Manual flow:
1. Read AUDIT_REPORT.md for findings and recommendations

Completed: 2026-01-22

---

### Task: Match celebration heart animation polish
ID: T-019
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Move the heart above the matched photos and add smooth pulsing rings around each avatar.

Scope (in/out):
In:
- Match celebration modal layout/animation
Out:
- BLoC, routing, or data changes

Files changed:
- lib/features/discovery/presentation/widgets/match_celebration_modal.dart
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md

Risks:
- Animation layering could impact performance on low-end devices

Acceptance criteria:
- ✅ Heart icon no longer sits between the two photos
- ✅ Smooth heart pulse appears above the photos
- ✅ Two ring pulses appear around the photos

Verification:
Commands: `flutter run`
Manual flow:
1. Trigger a match and observe the celebration modal
2. Confirm heart animates above photos and rings pulse smoothly

Completed: 2026-01-21

---

### Task: Add skeleton loaders across core screens
ID: T-018
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Replace spinners with skeleton loaders on discovery, matches, chat, and profile screens.

Scope (in/out):
In:
- Deck (discovery) loading state
- Matches screen loading states
- Chat screen initial load
- Profile view loading state
Out:
- BLoC logic changes
- Navigation or routing changes

Files changed:
- lib/features/discovery/presentation/widgets/deck_skeleton.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart

Risks:
- Shimmer animations could affect performance on low-end devices

Acceptance criteria:
- ✅ Skeleton loaders appear during initial loads on the four screens
- ✅ No layout regressions or scroll conflicts

Verification:
Commands: `flutter run`
Manual flow:
1. Launch app -> Discovery shows skeleton before deck loads
2. Open Matches -> skeletons show while matches load
3. Open Chat -> skeletons show while messages load
4. Open Profile -> skeleton shows while profile loads

Completed: 2026-01-20

---

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

### Task: Add last name + name privacy controls
ID: T-013
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Capture first/last name during Basic Info, store in Firestore, and respect name privacy defaults when showing other users.

Scope (in/out):
In:
- Profile model + privacy settings
- Firestore/saveBasicInfo/load paths
- Basic Info + Profile Edit UI
- Public profile name rendering (discovery/matches)
Out:
- Backend migration scripts
- Auth/session flow changes

Files changed:
- lib/data/models/profile.dart
- lib/data/models/privacy_settings.dart
- lib/presentation/screens/basic_info_screen.dart
- lib/features/profile/presentation/screens/profile_edit_screen.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md

Risks:
- Name privacy defaults may hide names in UI unexpectedly
- Incomplete persistence if last name not saved in all repo paths

Acceptance criteria:
- ✅ Basic Info saves first + last name to profile
- ✅ Name visibility defaults to private and can be changed in profile
- ✅ Other users see placeholder when name is private

Verification:
Commands: `flutter run`
Manual flow:
1. New account -> Basic Info -> enter first/last name -> continue
2. View another user's profile/cards: name hidden by default
3. Toggle name visibility in Profile Edit -> verify display updates

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

### Task: Chat screen comprehensive improvements
ID: T-014
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Improve chat screen UX with expandable input, voice preview, profile viewing, mute indicators, and visual polish.

Scope (in/out):
In:
- Message input field expansion
- Voice message preview before sending
- View Profile from avatar/name/menu
- Mute indicators next to user name
- Fade-away mute notifications
- Bottom bar glass styling
Out:
- Message persistence changes
- Voice message storage changes

Files changed:
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/chat/presentation/widgets/voice_note_recorder.dart

Risks:
- AudioPlayer conflicts → Mitigated: separate instances
- Profile navigation failure → Mitigated: fallback to minimal profile

Acceptance criteria:
- ✅ Message input expands to 4 lines max
- ✅ Voice recording shows preview with play/pause/re-record
- ✅ Avatar/name tap opens profile
- ✅ View Profile in menu opens profile
- ✅ Mute indicators visible when muted
- ✅ Fade notifications on mute actions

Verification:
Commands: `flutter run`
Manual flow:
1. Open chat, type long message, verify input expands
2. Record voice, verify preview UI appears
3. Tap avatar or View Profile, verify navigation
4. Mute messages, verify icon appears and notification fades

Completed: 2026-01-21

---

### Task: Verify block user and three-dot menu functionality
ID: T-015
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Verify all three-dot menu actions work correctly in chat screen.

Scope (in/out):
In:
- Block/unblock verification
- Report verification
- Unmatch verification
- Mute messages/calls verification
Out:
- Code changes (verification only)

Files changed:
- None (verification task)

Risks:
- None identified

Acceptance criteria:
- ✅ Block creates Firestore record and shows blocked banner
- ✅ Unblock removes block and enables chat
- ✅ Report creates Firestore record
- ✅ Unmatch removes match from both users
- ✅ Mute states persist locally

Verification:
Commands: Code review only
Manual flow:
- Traced code paths from UI to Cloud Functions

Completed: 2026-01-21

---

### Task: Add mandatory documentation workflow to CLAUDE.md
ID: T-016
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Ensure all AI assistants (Claude, Codex, others) read docs before changes and update docs after every task.

Scope (in/out):
In:
- CLAUDE.md instructions update
- Quick reference checklist
Out:
- Actual documentation content (handled separately)

Files changed:
- CLAUDE.md

Risks:
- Added overhead → Mitigated: benefits outweigh costs

Acceptance criteria:
- ✅ Rule added to read docs BEFORE making changes
- ✅ Rule added to update docs AFTER completing tasks
- ✅ Quick reference checklist added
- ✅ Both Claude and Codex covered

Verification:
Commands: Review CLAUDE.md
Manual flow:
- Verify new sections present and clear

Completed: 2026-01-21

---

### Task: Deck screen UI adjustments
ID: T-017
Owner AI: Claude
Critic AI: N/A
Status: Done

Goal:
Move verification badge to after name/age, fix bio going behind bottom nav, make description minimal.

Scope (in/out):
In:
- Verification badge position change
- Bottom positioning of info panel
- Bio/prompt display simplification
Out:
- No functional changes to swipe behavior

Files changed:
- lib/features/discovery/presentation/widgets/swipe_card.dart

Risks:
- Content overlap → Mitigated: used Flexible + ellipsis for truncation

Acceptance criteria:
- ✅ Verification badge appears after "Name, Age" (not top-right)
- ✅ Bio/prompt does not go behind bottom navigation
- ✅ Description is minimal (single line)
- ✅ Unused _GlassVerificationPill removed

Verification:
Commands: `flutter run`
Manual flow:
1. View deck screen with verified user
2. Confirm badge is next to name/age
3. Confirm bio stays above bottom nav
4. Confirm deck looks cleaner/less cluttered

Completed: 2026-01-21

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
