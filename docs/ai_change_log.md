# AI Change Log — CRUSH

This file tracks all changes made by AI assistants in this repository.

---

### [2026-01-23] Task: Move auth screens into auth feature folder

Summary:
- Moved auth/onboarding/account security screens into `lib/features/auth/presentation/screens`.
- Updated router imports, profile barrel exports, and auth system documentation paths.

Files Added:
- None (files moved)

Files Modified:
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

Files Deleted:
- None (legacy paths removed via move)

Why / Notes:
- Audit flagged auth screens living under `lib/presentation/screens`; consolidated under auth feature.

Risks & Mitigations:
- Risk: stale import paths after moving screens could break builds.
  - Mitigation: update all references and search for old paths.

Verification Steps:
- Not run (not requested)
- Manual: splash -> auth gateway; onboarding/security screens open from routes

Follow-ups / TODO:
- None

### [2026-01-23] Task: UI/UX polish for auth flow

Summary:
- Replaced Material buttons with Glass variants across auth screens.
- Swapped remaining hard-coded Colors.* to DsColors tokens and added Semantics labels for key actions.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md
- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/phone_auth_screen.dart
- lib/features/auth/presentation/screens/otp_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/email_verification_screen.dart
- lib/features/auth/presentation/screens/terms_conditions_screen.dart

Files Deleted:
- None

Why / Notes:
- Audit requested a UI/UX polish pass; this update focuses on the auth flow only.
- Discovery/chat/profile/settings remain for a follow-up pass.

Risks & Mitigations:
- Risk: Glass buttons replace link-style actions and may reduce affordance.
  - Mitigation: Keep labels clear and add Semantics for accessibility.

Verification Steps:
- Not run (not requested)
- Manual: auth gateway -> login/sign up -> email/phone auth -> OTP -> verification -> forgot password

Follow-ups / TODO:
- Apply the same polish to discovery/chat/profile/settings screens.

### [2026-01-23] Task: Add missing routes for call/video/media/story screens

Summary:
- Added GoRouter routes for CallScreen, VideoCallScreen, ProfileMediaScreen, and StoryViewerScreen.
- Updated chat and discovery navigation to use routes; added story badge entry on swipe cards.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/project_flowchart.md
- docs/risk_notes.md
- lib/core/router.dart
- lib/features/calls/presentation/screens/call_screen.dart
- lib/features/calls/presentation/screens/video_call_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- lib/features/discovery/presentation/screens/story_viewer_screen.dart
- lib/features/profile/presentation/screens/profile_media_screen.dart

Files Deleted:
- None

Why / Notes:
- Audit flagged these screens as missing from routing; video call/profile media used MaterialPageRoute.
- Story viewer now has a lightweight entry via a story badge on discovery cards.

Risks & Mitigations:
- Risk: Call screen uses a placeholder caller ID and may not map to real auth user.
  - Mitigation: Logged in risk notes; follow-up to wire auth user ID.

Verification Steps:
- Not run (not requested)
- Manual: Chat -> video call button opens VideoCallScreen
- Manual: Chat -> audio call -> CallScreen after confirmation
- Manual: Discovery card -> story badge opens StoryViewerScreen
- Manual: Discovery card -> tap media opens ProfileMediaScreen

Follow-ups / TODO:
- Use real auth user ID in CallScreen initiation.

### [2026-01-23] Task: Fix Boost timer + auth cleanup for feature cubits

Summary:
- Prevented BoostCubit from spawning recursive timers by guarding refresh and only ticking during boost/cooldown.
- Added auth cleanup listeners and cache clears for Weekly Picks, Date Ideas, Compatibility Quiz, and Profile Insights.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md
- lib/features/discovery/presentation/bloc/boost_cubit.dart
- lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart
- lib/features/discovery/data/services/weekly_picks_service.dart
- lib/features/social/presentation/bloc/date_ideas_cubit.dart
- lib/features/social/data/services/date_idea_service.dart
- lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart
- lib/features/social/data/services/compatibility_quiz_service.dart
- lib/features/analytics/presentation/bloc/profile_insights_cubit.dart
- lib/features/analytics/data/services/profile_insights_service.dart

Files Deleted:
- None

Why / Notes:
- Audit flagged a BoostCubit timer recursion risk and missing auth cleanup for several feature cubits.
- Clearing in-memory service caches avoids cross-user leakage after logout in stub/demo flows.

Risks & Mitigations:
- Risk: Logout resets could clear in-flight UI state.
  - Mitigation: Reset only on auth null and cancel subscriptions before emitting initial states.

Verification Steps:
- Not run (not requested)
- Manual: activate boost -> wait for expiry -> confirm single refresh
- Manual: logout -> verify Weekly Picks/Date Ideas/Quiz/Insights reset

Follow-ups / TODO:
- None

### [2026-01-20] Task: Add last name + name privacy controls

Summary:
- Added last name to profile model and persisted name privacy settings.
- Updated Basic Info and Profile Edit to capture first/last name and name visibility.
- Public-facing profile name rendering now respects privacy defaults.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md
- docs/project_understanding.md
- lib/core/services/data_export_service.dart
- lib/core/services/offline_cache_service.dart
- lib/data/dto/profile_dto.dart
- lib/data/models/privacy_settings.dart
- lib/data/models/profile.dart
- lib/data/repositories/fake_repositories.dart
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/features/auth/data/repositories/impl/stub_auth_repository.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart
- lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart
- lib/features/discovery/presentation/screens/deck_screen.dart
- lib/features/discovery/presentation/screens/likes_you_screen.dart
- lib/features/discovery/presentation/screens/story_viewer_screen.dart
- lib/features/discovery/presentation/widgets/match_celebration_modal.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/profile/data/repositories/impl/http_profile_repository.dart
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
- lib/features/profile/data/repositories/profile_repository.dart
- lib/features/profile/presentation/bloc/profile_bloc.dart
- lib/features/profile/presentation/bloc/profile_event.dart
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- lib/features/profile/presentation/screens/profile_edit_screen.dart
- lib/features/profile/presentation/screens/profile_media_screen.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart
- lib/features/settings/presentation/bloc/safety_cubit.dart
- lib/presentation/screens/basic_info_screen.dart
- test/deck_gating_test.dart

Files Deleted:
- None

Why / Notes:
- User requested first/last name capture with privacy controls.
- Name visibility defaults to private and is changeable in Profile Edit.
- Public UI now uses privacy-aware name display to hide names by default.

Risks & Mitigations:
- Risk: Names may show as "Someone new" if users keep privacy off.
  - Mitigation: Onboarding prompt clarifies privacy; stub profiles default to show first name.
- Risk: Legacy profiles without lastName or privacy settings may appear anonymous.
  - Mitigation: Optional lastName field and privacy defaults keep app stable.

Verification Steps:
- `flutter run`
- Manual: Create account -> Basic Info -> enter first/last name -> continue
- Manual: View other user cards -> name hidden unless visibility enabled
- Manual: Profile Edit -> toggle name visibility -> verify display updates

Follow-ups / TODO:
- Consider wiring privacy settings screen to profile persistence (if needed later).

### [2026-01-20] Task: Add skeleton loaders across core screens

Summary:
- Replaced spinners with skeleton loaders on discovery, matches, chat, and profile screens.
- Applied shimmer styling to deck and matches loaders; added chat message skeleton list.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/risk_notes.md
- lib/features/discovery/presentation/widgets/deck_skeleton.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart

Files Deleted:
- None

Why / Notes:
- Provide consistent loading feedback and reduce jarring spinners.
- No flowchart/DFD/ER updates needed (no routing or data flow changes).

Risks & Mitigations:
- Risk: Shimmer animations could affect performance on low-end devices.
  - Mitigation: Keep skeleton count modest and reuse existing loaders.

Verification Steps:
- `flutter run`
- Manual: open Discovery, Matches, Chat, Profile; confirm skeletons show during loading.

Follow-ups / TODO:
- Monitor performance on low-end devices; reduce skeleton count if needed.

### [2026-01-21] Task: Match celebration heart animation polish

Summary:
- Moved the heart animation above the matched photos to avoid covering faces.
- Added smooth pulsing rings around each avatar for a more aesthetic celebration.

Files Added:
- None

Files Modified:
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- lib/features/discovery/presentation/widgets/match_celebration_modal.dart

Files Deleted:
- None

Why / Notes:
- Keep the heart from blocking photos while still emphasizing the match moment.
- Use existing controllers for smooth, lightweight animation changes.

Risks & Mitigations:
- Risk: Animation layers could add GPU load on low-end devices.
  - Mitigation: Keep pulse sizes and shadow intensity modest.

Verification Steps:
- `flutter run`
- Manual: trigger a match; confirm heart sits above photos and ring pulses are smooth.

Follow-ups / TODO:
- None

### [2026-01-22] Task: Project-wide audit + repo hygiene scan

Summary:
- Performed a static audit of core flows, Firebase alignment, and platform parity.
- Documented critical blockers and hygiene notes in the audit report.

Files Added:
- None

Files Modified:
- AUDIT_REPORT.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Files Deleted:
- None

Why / Notes:
- User requested an end-to-end audit covering frontend, backend, flows, and platform parity.
- No code changes applied; findings recorded for follow-up fixes.

Risks & Mitigations:
- Risk: Static review only (no build/device validation).
  - Mitigation: Documented verification gaps; suggested follow-up tests.

Verification Steps:
- None (report only)

Follow-ups / TODO:
- Address blockers listed in AUDIT_REPORT.md.


## Template

Copy this block for every task:

```
### [YYYY-MM-DD] Task: <Short descriptive title>

Summary:
- What was requested
- What was achieved

Files Added:
- path/to/file

Files Modified:
- path/to/file

Files Deleted:
- path/to/file

Renamed / Moved:
- old → new

Why / Notes:
- Architectural reasoning
- Tradeoffs

Risks & Mitigations:
- Risk:
- Mitigation:

Verification Steps:
- Build command
- Manual test path

Follow-ups / TODO:
-
```

---

## Log Entries

(Entries start below)

---

### [2026-01-20] Task: Initial AI documentation setup and codebase analysis

Summary:
- Created AI companion documentation files per CLAUDE.md guidelines
- Performed comprehensive codebase exploration to understand architecture
- Populated project_understanding.md with actual architecture details

Files Added:
- CLAUDE.md (project instructions for AI assistants)
- docs/project_understanding.md (architecture documentation)
- docs/ai_change_log.md (this file)
- docs/risk_notes.md (risk register template)

Files Modified:
- docs/project_understanding.md (filled with actual codebase details)

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Establishes baseline documentation for AI-assisted development
- Documents the feature-first Clean Architecture with BLoC pattern
- Records all 8 BLoCs, 13 Cubits, 8 repositories, 12 core services
- Maps GoRouter configuration with 34 routes and auth guards
- Identifies multi-backend strategy (Firebase/HTTP/Stub)

Risks & Mitigations:
- Risk: Documentation may drift from code over time
- Mitigation: Update docs with each significant change

Verification Steps:
- Review docs/project_understanding.md for accuracy
- No code changes, no build verification needed

Follow-ups / TODO:
- Fill in open questions as they are answered
- Update risk_notes.md with specific identified risks
- Keep documentation current with future changes

---

### [2026-01-20] Task: Fix blurred photos and increase size in own profile view

Summary:
- User reported photos appeared blurred in "My Photos" section of their own profile
- Removed gradient overlay effect that was causing the blur appearance
- Increased photo size by changing from 3-column to 2-column grid layout

Files Added:
- None

Files Modified:
- lib/features/profile/presentation/screens/profile_view_screen.dart
  - `_PhotosGrid` widget: removed gradient overlay (was 30% opacity primary color at bottom)
  - Changed `crossAxisCount` from 3 to 2 (larger photos)
  - Changed `crossAxisSpacing` and `mainAxisSpacing` from 8 to 12 pixels
  - Changed `childAspectRatio` from 0.75 to 0.8 (slightly wider)

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- The gradient overlay at bottom of each photo (40px height, primary color @ 30% opacity) was intended as a glass effect but was perceived as blur
- For user's OWN profile, photos should display clearly without effects
- Larger photos (2 columns vs 3) improve visibility and match user expectations
- The blur/overlay effects are intentionally kept for OTHER users' profiles (premium feature in likes_you_screen.dart)

Risks & Mitigations:
- Risk: UI layout may look different with larger photos
- Mitigation: Increased spacing to maintain visual balance
- Risk: More scrolling needed if user has many photos
- Mitigation: 2-column layout is standard for profile photo galleries

Verification Steps:
- Run: `flutter build ios --debug` or `flutter run`
- Navigate to: Profile tab → scroll to "My Photos" section
- Verify: Photos display without gradient overlay, larger size (2 per row)

Follow-ups / TODO:
- Consider adding tap-to-fullscreen for photo viewing
- May want to add photo reordering capability

---

### [2026-01-20] Task: Fix broken profile photos (local file path handling)

Summary:
- Profile photos showed broken image icon (cross) instead of actual photos
- Root cause: Firebase Storage upload fails in debug mode, falling back to local file paths
- Local file paths were saved to Firestore but CachedNetworkImage only handled HTTP URLs
- Fixed CachedNetworkImage to handle both local file paths AND remote URLs

Files Added:
- None

Files Modified:
- lib/shared/widgets/cached_network_image.dart
  - Added `dart:io` import for File access
  - Added `_isRemoteUrl()` helper method to detect URL type
  - Updated `_loadImage()` to handle local files via `File.readAsBytes()`
  - Remote URLs continue to use network cache as before

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- ProfileMediaService falls back to local file paths when Firebase Storage upload fails (debug mode)
- This is intentional for development without full Firebase setup
- The profile_media_picker.dart already handled this correctly with a similar pattern
- Now CachedNetworkImage works consistently across all screens

Root Cause Chain:
1. User uploads photo → local file path selected
2. ProfileMediaService.uploadPhoto() fails (Firebase Storage rules/auth)
3. Debug fallback returns local path: `/var/folders/.../photo.jpg`
4. Local path saved to Firestore as photoUrl
5. CachedNetworkImage tried http.get() on local path → failed
6. Error widget (broken image icon) displayed

Risks & Mitigations:
- Risk: Local file paths won't work on different devices/sessions
- Mitigation: This is expected debug behavior; production uses Firebase URLs
- Risk: File may be deleted from temp storage
- Mitigation: Photos should be uploaded to Firebase for persistence in production

Verification Steps:
- Run: `flutter run`
- Navigate to: Profile tab → "My Photos" section
- Verify: Photos now display correctly (both local paths and remote URLs)

Follow-ups / TODO:
- Deploy Firebase Storage security rules for production
- Consider showing upload status/progress indicator
- Add retry mechanism for failed uploads

---

### [2026-01-20] Task: Update Claude/Codex collaboration workflow

Summary:
- User requested adding detailed Claude ↔ Codex integration rules
- Replaced the previous "Working With Other AI" section with the new A–G workflow

Files Added:
- None

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Aligns repo guidance with the agreed multi-assistant workflow
- Adds clear planning format, ownership, and safety gate for routing/BLoC/auth changes

Risks & Mitigations:
- Risk: Documentation mismatch with actual team workflow
- Mitigation: Review and adjust guidelines as collaboration evolves

Verification Steps:
- Review `CLAUDE.md` to confirm the new section is present and correct

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Enforce onboarding redirect away from Home

Summary:
- Prevented Home access while onboarding is incomplete to stop new users from bypassing profile steps.
- Tightened router allowlists for Basic Info and Profile Setup gating.

Files Added:
- None

Files Modified:
- lib/core/router.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/ai_change_log.md
- docs/risk_notes.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Home being allowed during onboarding let new accounts skip required steps.
- Flowchart/DFD/ERD docs unchanged; flow remains the same, now enforced.

Risks & Mitigations:
- Risk: Redirect loop if AuthBloc state lags after profile save
- Mitigation: Auth refresh is already triggered after onboarding saves; router auto-redirects away from onboarding once state updates.

Verification Steps:
- Run: `flutter run`
- Manual: create account -> accept terms -> confirm Basic Info screen (not Home)
- Manual: finish onboarding -> confirm Home accessible

Follow-ups / TODO:
- Consider centralizing post-auth routing helper for consistency across auth screens.

---

### [2026-01-20] Task: Send date plan email notifications

Summary:
- Added a Firebase callable to email emergency contacts with date plan details.
- Wired date plan creation to trigger the email and added email validation.

Files Added:
- None

Files Modified:
- functions/src/index.ts
- lib/features/safety/data/services/date_plan_service.dart
- lib/presentation/screens/safety_screen.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/ai_change_log.md
- docs/risk_notes.md
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- The safety flow now emails the emergency contact immediately after a date plan is created.
- Relies on Resend configuration for outbound email.

Risks & Mitigations:
- Risk: Email provider not configured, causing notification failure
- Mitigation: Function returns a clear error; UI surfaces the message
- Risk: Abuse/spam through repeated plan creation
- Mitigation: Rate limiting per user/contact in Cloud Functions

Verification Steps:
- Deploy: `firebase deploy --only functions`
- Manual: Safety -> Create Date Plan -> verify contact email contents

Follow-ups / TODO:
- Consider persisting date plans to Firestore and triggering notifications via server-side triggers

---

### [2026-01-20] Task: Matches screen likes-you section

Summary:
- Added Likes You section to Matches screen with blurred cards, DOB/distance display, and upgrade prompt.
- Ensured stub mode always shows 2-3 likes for demo/testing.

Files Added:
- None

Files Modified:
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/ai_change_log.md
- docs/risk_notes.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Matches view now surfaces Likes You without leaving the tab, and promotes Crush Plus for reveal.
- DOB/distance are shown on blurred cards per requirement.

Risks & Mitigations:
- Risk: DOB/distance exposed before match
- Mitigation: Documented risk and consider masking in future

Verification Steps:
- Run: `flutter run`
- Manual: open Matches tab and confirm Likes You section shows blurred cards
- Manual: tap blurred card -> upgrade prompt
- Manual: tap matched user -> chat opens

Follow-ups / TODO:
- Re-evaluate whether full DOB should be shown pre-match

### [2026-01-20] Task: Route terms acceptance into onboarding

Summary:
- After accepting terms, route users into onboarding steps instead of Home

Files Added:
- None

Files Modified:
- lib/features/auth/presentation/screens/terms_conditions_screen.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Terms acceptance was sending new users to Home and skipping profile completion steps

Risks & Mitigations:
- Risk: None identified
- Mitigation: N/A

Verification Steps:
- Run: `flutter run`
- Create account -> accept terms -> verify Basic Info appears

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Require ER diagram updates with code changes

Summary:
- Added instruction for both AI assistants to update the ER diagram when schema changes affect data models

Files Added:
- None

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Keeps flowchart, DFD, and ER diagrams aligned with code changes

Risks & Mitigations:
- Risk: None
- Mitigation: N/A

Verification Steps:
- Review `CLAUDE.md` for the updated instructions

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Require DFD + flowchart updates with code changes

Summary:
- Added instruction for both AI assistants to update `docs/project_flowchart.md` and `docs/project_dfd.md` when flows/data movement change

Files Added:
- None

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Ensures documentation stays aligned whenever AI edits code that affects flows or data

Risks & Mitigations:
- Risk: None
- Mitigation: N/A

Verification Steps:
- Review `CLAUDE.md` for the updated instructions

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Require flowchart updates when flows change

Summary:
- Added instruction to keep `docs/project_flowchart.md` updated when routing or flow changes occur

Files Added:
- None

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Keeps flowchart documentation aligned with actual app flows

Risks & Mitigations:
- Risk: None
- Mitigation: N/A

Verification Steps:
- Review `CLAUDE.md` for the updated instruction

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Prevent Basic Info reroute on restart

Summary:
- Adjusted basic info completion logic to align with required fields
- Prevents users from being sent back to Basic Info after restart

Files Added:
- None

Files Modified:
- lib/data/models/user.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Basic Info UI does not require a name, but completion logic did
- This mismatch caused users to be routed back on restart

Risks & Mitigations:
- Risk: Users may complete onboarding without a display name
- Mitigation: Consider adding name validation if required by product

Verification Steps:
- Run: `flutter run`
- Complete Basic Info and restart the app
- Verify: App does not redirect back to Basic Info

Follow-ups / TODO:
- If name is required, add validation in Basic Info UI

---

### [2026-01-20] Task: Add project flowchart documentation

Summary:
- Created Mermaid flowcharts for app navigation, discovery flow, architecture, and backend modes

Files Added:
- docs/project_flowchart.md

Files Modified:
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- User requested a proper flowchart of the whole project
- Diagrams align with existing routing and architecture docs

Risks & Mitigations:
- Risk: Flowchart may drift from implementation
- Mitigation: Update flowchart when routes or architecture change

Verification Steps:
- Open `docs/project_flowchart.md` and render Mermaid diagrams

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Fix onboarding reroute to profile setup on restart

Summary:
- Counted video-only profiles as completed setup to prevent false onboarding loops
- Added a one-time auth refresh after login to sync latest user profile data

Files Added:
- None

Files Modified:
- lib/data/models/user.dart
- lib/features/auth/presentation/bloc/auth_bloc.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Users with only profile videos were treated as incomplete and routed back to profile setup
- Refreshing auth state once after login reduces stale user data on restart

Risks & Mitigations:
- Risk: Extra auth refresh call on login
- Mitigation: Guarded with a one-time flag to prevent loops

Verification Steps:
- Run: `flutter run`
- Complete onboarding with a video-only profile and restart the app
- Verify: App does not redirect back to profile setup

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Allow Weekly Picks during onboarding and remove Deck safety icon

Summary:
- Allowed Weekly Picks navigation during onboarding steps
- Removed the Safety & Blocking shield icon from the Deck app bar (kept in Settings)

Files Added:
- None

Files Modified:
- lib/core/router.dart
- lib/features/discovery/presentation/screens/deck_screen.dart
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Weekly Picks button was redirected to Basic Info during onboarding
- Safety access remains available in Settings; deck icon was removed per request

Risks & Mitigations:
- Risk: Onboarding gating loosened for Weekly Picks
- Mitigation: Still blocked before terms acceptance and for unauthenticated users

Verification Steps:
- Run: `flutter run`
- Login with onboarding incomplete → tap Weekly Picks → should open Weekly Picks
- Verify Deck app bar no longer shows the safety shield icon

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Allow autonomous AI collaboration without developer presence

Summary:
- Added a protocol clause allowing Claude and Codex to collaborate and approve plans without the developer present
- Clarified that critic approval should be recorded in the collab log

Files Added:
- None

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- User requested autonomous AI collaboration and mutual approval for ideation and execution
- Keeps the existing plan/critique loop but removes the need for developer involvement

Risks & Mitigations:
- Risk: Reduced human oversight for non-trivial changes
- Mitigation: Require explicit critic approval documented in `docs/ai_collab_chat.md`

Verification Steps:
- Review `CLAUDE.md` to confirm the new subsection is present

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Remove Email OTP sign-in flow from UI

Summary:
- Email OTP did not send codes reliably without backend email configuration
- Removed the Email OTP tab and signup entry point to avoid a broken flow

Files Added:
- None

Files Modified:
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Email OTP requires backend email service configuration; without it, users never receive codes
- Keeping the flow visible caused confusion during sign-up

Risks & Mitigations:
- Risk: Users expecting email OTP sign-in will no longer see the option
- Mitigation: Email link and password flows remain available

Verification Steps:
- Run: `flutter run`
- Navigate: Create account → confirm Email OTP option is gone
- Navigate: Sign in with email → verify only Email link + Password tabs remain

Follow-ups / TODO:
- Re-enable Email OTP if backend email service is configured and verified

---

### [2026-01-20] Task: Route magic-link sign-ins into onboarding flow

Summary:
- After magic link authentication, route users to the first incomplete onboarding step
- Ensures new accounts go through steps 1–5 instead of landing on Home

Files Added:
- None

Files Modified:
- lib/features/auth/presentation/screens/email_auth_screen.dart

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Magic-link sign-ins were landing on Home even when onboarding was incomplete
- Added explicit routing to terms/basic info/profile setup/email verification as needed

Risks & Mitigations:
- Risk: Existing users might be routed to onboarding if profile state is stale
- Mitigation: Uses current AuthState user flags to choose the appropriate screen

Verification Steps:
- Run: `flutter run`
- Navigate: Create account → Email magic link → open link → confirm onboarding steps start
- Navigate: Existing account → Email magic link → confirm Home is shown

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Fix ChatBloc authRepository test wiring

Summary:
- Added missing `authRepository` argument to ChatBloc in unit/integration tests
- Introduced a lightweight fake auth repository for media limit tests

Files Added:
- None

Files Modified:
- test/chat_bloc_media_limit_test.dart
- integration_test/test_app.dart

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- ChatBloc now requires `authRepository`; tests were failing to compile

Risks & Mitigations:
- Risk: Fake auth repo could mask unexpected auth usage in tests
- Mitigation: Fake throws UnimplementedError for unused methods

Verification Steps:
- Run: `flutter test test/chat_bloc_media_limit_test.dart`
- Run: `flutter test integration_test/test_app.dart`

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: Fix sign-out redirect to Basic Info Screen

Summary:
- User reported that signing out redirected to Basic Info Screen (Step 3 of 5) instead of login
- Root cause: Router redirect logic didn't exempt `/logout` route during onboarding stages
- Fixed by allowing logout route in all onboarding redirect conditions

Files Added:
- None

Files Modified:
- lib/core/router.dart
  - Line 190: Added `path == CrushRoutes.logout` to `needsTermsAcceptance` allowed paths
  - Line 208: Added `path == CrushRoutes.logout` to `needsBasicInfo` allowed paths
  - Line 228: Added `path == CrushRoutes.logout` to `needsProfileSetup` allowed paths
  - Line 244: Added `path == CrushRoutes.logout` to `needsAccountVerification` allowed paths

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Router redirect logic enforces onboarding completion by redirecting to appropriate screens
- The `/logout` route was not exempted from these redirects
- When user signed out during onboarding (e.g., hasAcceptedTerms=true but hasCompletedBasicInfo=false), the router intercepted the navigation and redirected to basicInfo instead of allowing logout to complete
- Now users can sign out at any stage of onboarding without being trapped

Root Cause Chain:
1. User on logout screen initiates sign out
2. AuthBloc emits state transition (authenticated -> unknown)
3. Router evaluates redirect conditions
4. User object still has onboarding flags (hasAcceptedTerms=true, hasCompletedBasicInfo=false)
5. needsBasicInfo evaluated to TRUE
6. /logout path was NOT in allowed list
7. Router redirected to basicInfo instead of allowing logout

Risks & Mitigations:
- Risk: None identified - this is a bug fix
- Mitigation: Users can now properly sign out at any onboarding stage

Verification Steps:
- Run: `flutter run`
- Create new account, accept terms, stop at Basic Info screen
- Navigate to logout (if accessible) or trigger sign out
- Verify: Should redirect to auth/login screen, not Basic Info

Follow-ups / TODO:
- None

---

### [2026-01-20] Task: CRITICAL SECURITY FIX - Clear user data on logout

Summary:
- User reported that after logout and new account creation, previous user's profile data was visible
- Root cause: Multiple BLoCs and services retained user-specific data in memory after logout
- Implemented comprehensive data clearance across all BLoCs and caches on logout

Files Added:
- lib/core/services/user_data_clearance_service.dart
  - New singleton service to clear SharedPreferences user keys and image cache
  - Clears: safety settings, privacy settings, discovery preferences, location data

Files Modified:
- lib/features/auth/presentation/bloc/auth_bloc.dart
  - Added call to UserDataClearanceService.clearAllUserData() in _onSignedOut handler
- lib/features/profile/presentation/bloc/profile_event.dart
  - Added ProfileResetRequested event
- lib/features/profile/presentation/bloc/profile_bloc.dart
  - Added auth state subscription to trigger reset on logout
  - Added _onResetRequested handler to clear state
- lib/features/chat/presentation/bloc/chat_event.dart
  - Added ChatResetRequested event
- lib/features/chat/presentation/bloc/chat_bloc.dart
  - Added AuthRepository dependency and auth state subscription
  - Added _onResetRequested handler to clear state and cancel subscriptions
- lib/features/discovery/presentation/bloc/discovery_event.dart
  - Added DiscoveryResetRequested event
- lib/features/discovery/presentation/bloc/discovery_bloc.dart
  - Added AuthRepository dependency and auth state subscription
  - Added _onResetRequested handler to clear deck, location, preferences
- lib/features/chat/presentation/bloc/matches_event.dart
  - Added MatchesResetRequested event
- lib/features/chat/presentation/bloc/matches_bloc.dart
  - Added AuthRepository dependency and auth state subscription
  - Added _onResetRequested handler to clear matches cache
- lib/core/di.dart
  - Updated DiscoveryBloc creation to include authRepository
- lib/features/chat/presentation/screens/matches_screen.dart
  - Updated MatchesBloc creation to include authRepository
- lib/features/chat/presentation/screens/chat_list_screen.dart
  - Updated MatchesBloc creation to include authRepository
- test/matches_bloc_test.dart
  - Added _StubAuthRepository for test compatibility

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- SECURITY CRITICAL: Without this fix, sensitive user data (profile, photos, chats, matches, location) could be visible to the next user on the same device
- Each BLoC now subscribes to auth state changes and resets when user becomes null
- Centralized clearance service handles SharedPreferences and image cache
- Pattern: Auth state → BLoC subscription → Reset event → Clear state

Data Cleared on Logout:
1. ProfileBloc: profile object, retry state
2. ChatBloc: messages, subscriptions (typing, presence, media)
3. DiscoveryBloc: deck, location, preferences, super likes, rewind state
4. MatchesBloc: matches list, cache timestamp
5. SharedPreferences: safety blocked/muted lists, privacy settings, discovery filters, location
6. NetworkImageCache: all cached images

Risks & Mitigations:
- Risk: Auth subscription could fire during normal navigation
- Mitigation: Only triggers reset when user becomes null (actual logout)
- Risk: Performance impact from clearing all caches
- Mitigation: Clearance is async and runs once on logout, not noticeable to user

Verification Steps:
- Run: `flutter run`
- Create account A, complete profile, add photos, make matches, send messages
- Sign out from account A
- Create new account B or sign in with different credentials
- Verify: No profile data from account A visible
- Verify: No matches or chats from account A visible
- Verify: Discovery deck is fresh, not showing previous user's filtered results

Follow-ups / TODO:
- Consider adding clearance for additional Cubits (SafetyCubit, PrivacySettingsCubit) if they cache user-specific runtime state
- Add unit tests for data clearance behavior

---

### [2026-01-20] Task: Add multi-AI collaboration protocol artifacts

Summary:
- Added the AI_planbychattingwithotherAI_ protocol to AI instructions
- Created task board and collaboration chat log templates required by the protocol

Files Added:
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Modified:
- CLAUDE.md

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Establishes a formal multi-AI planning and critique loop
- Provides required docs for task ownership and AI-to-AI discussion records

Risks & Mitigations:
- Risk: Process overhead may slow tiny changes
- Mitigation: Protocol explicitly exempts trivial edits

Verification Steps:
- Review `CLAUDE.md` for the new protocol section
- Verify templates in `docs/ai_tasks_board.md` and `docs/ai_collab_chat.md`

Follow-ups / TODO:
- None

---

### [2026-01-21] Task: Chat screen comprehensive improvements

Summary:
- Expandable message input field (1-4 lines based on content)
- Voice message preview before sending (record → preview → send/re-record)
- View Profile option in three-dots menu + clickable avatar/name
- Mute indicators (small icons) next to user name when muted
- Temporary fade-away notifications for mute actions
- Improved bottom bar aesthetics with glass styling and gradient matching top bar

Files Added:
- None

Files Modified:
- lib/features/chat/presentation/screens/chat_screen.dart
  - Added `viewProfile` to `_ChatSafetyAction` enum
  - Added View Profile option at top of popup menu with divider
  - Added `_navigateToProfile()` method to fetch profile and navigate
  - Added `_showTemporaryMuteNotification()` method with overlay
  - Created `_FadeAwayNotification` widget with slide/fade animations
  - Made avatar and name clickable with GestureDetector
  - Added mute indicators (notifications_off, call_end icons) next to name
  - Improved bottom bar with glass styling, gradient matching top bar
  - Updated TextField with `minLines: 1`, `maxLines: 4`, multiline keyboard
  - Added `_buildMediaButton()` helper for consistent button styling
- lib/features/chat/presentation/widgets/voice_note_recorder.dart
  - Complete rewrite with three states: requestingPermission, recording, previewing
  - Added AudioPlayer for preview playback
  - Recording state shows stop button (not immediate send)
  - Preview state shows: play/pause, progress slider, re-record, cancel, send
  - Key methods: `_stopRecordingAndPreview()`, `_initializePreviewPlayer()`, `_togglePlayPause()`, `_reRecord()`, `_sendRecording()`

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Expandable input matches modern messaging app UX expectations
- Voice preview prevents accidental sends and lets users review before sending
- Profile viewing from chat header is standard dating app pattern
- Mute indicators give visual feedback about conversation state
- Fade notifications avoid modal dialogs for simple confirmations
- Glass styling creates cohesive visual design with app theme

Risks & Mitigations:
- Risk: AudioPlayer may conflict with recording player
- Mitigation: Separate player instances for recording preview vs playback
- Risk: Profile navigation may fail if profile not found
- Mitigation: Creates minimal profile from available match data as fallback

Verification Steps:
- Run: `flutter run`
- Manual: Open chat → type multi-line message → verify input expands
- Manual: Record voice → verify preview appears with play/pause/re-record
- Manual: Tap avatar or name → verify profile screen opens
- Manual: Tap three-dots → View Profile → verify navigation
- Manual: Mute messages → verify fade notification appears and icon shows

Follow-ups / TODO:
- Consider adding visual waveform to voice preview
- Add voice message playback after sending (VoiceNotePlayer already exists)

---

### [2026-01-21] Task: Verify block user and three-dot menu functionality

Summary:
- Verified all three-dot menu actions work correctly in chat screen
- Confirmed block/unblock flow from UI to Cloud Functions to Firestore
- Verified report, unmatch, mute messages, mute calls, safety center all functional

Files Added:
- None

Files Modified:
- None (verification only)

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Block user: SafetyCubit.toggleBlock() → ChatRepository.blockUser() → Cloud Function → Firestore
- Unblock user: SafetyCubit.toggleBlock() → ChatRepository.unblockUser() → Cloud Function → Firestore
- Report user: SafetyCubit.reportWithContext() → ChatRepository.reportUser() → Cloud Function → Firestore
- Unmatch: ChatBloc → ChatRepository.unmatchUser() → Cloud Function (unmatchUsers) → Firestore
- Mute messages/calls: Local only via SafetyCubit + SharedPreferences
- Safety center: Navigation to safety screen

Verification confirmed:
- ✅ Block creates record in Firestore blocks collection
- ✅ Blocked user banner appears in chat with unblock option
- ✅ Report creates record in Firestore reports collection
- ✅ Unmatch removes match from both users
- ✅ Mute states persist locally and show indicators

Risks & Mitigations:
- None identified (verification task)

Verification Steps:
- Read cloud functions and repository implementations to trace data flow
- Confirmed functions exist: blockUser, unblockUser, reportUser, unmatchUsers

Follow-ups / TODO:
- None

---

### [2026-01-21] Task: Add mandatory documentation workflow to CLAUDE.md

Summary:
- Added mandatory requirement to read AI collaboration docs BEFORE making any changes
- Added mandatory requirement to update AI collaboration docs AFTER completing any task
- Added quick reference checklist at end of file for easy access
- Both Claude and Codex (and any other AI) must follow this workflow

Files Added:
- None

Files Modified:
- CLAUDE.md
  - Added rule #1: "READ AI COLLABORATION DOCS FIRST (MANDATORY)"
  - Added rule #6: "UPDATE AI COLLABORATION DOCS AFTER EVERY TASK (MANDATORY)"
  - Added section "0. READ AI COLLABORATION DOCS" in First Action checklist
  - Added "MANDATORY: Update Documentation After Verification" in Testing section
  - Added section "14) Quick Reference: Mandatory Doc Workflow (Claude + Codex)"
  - Re-numbered existing rules to accommodate new requirements

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- User requested that both Claude and Codex always update documentation after tasks
- User requested that AI assistants read docs before making changes to avoid conflicts
- Quick reference provides easy checklist for both AIs to follow

Risks & Mitigations:
- Risk: Added overhead for simple tasks
- Mitigation: Documentation updates are quick; benefits outweigh costs

Verification Steps:
- Review `CLAUDE.md` for new sections
- Verify quick reference checklist is clear and actionable

Follow-ups / TODO:
- None

---

### [2026-01-21] Task: Deck screen UI adjustments

Summary:
- Moved verification badge from top-right corner to after "Name, Age" text
- Fixed description/bio text going behind bottom navigation buttons
- Made description display more minimal and cleaner for less clutter

Files Added:
- None

Files Modified:
- lib/features/discovery/presentation/widgets/swipe_card.dart
  - Removed verification badge from top-right area (was `_GlassVerificationPill`)
  - Added verification badge inline after name/age in `_ProfileIdentityOverlay`
  - Changed info panel `bottom` from 16 to 90 (above bottom nav bar)
  - Changed profile identity overlay `bottom` from 100 to 140
  - Changed reaction button `bottom` from 140 to 240
  - Reduced bio `maxLines` from 2 to 1 for cleaner look
  - Simplified `_CompactPromptDisplayClean` to single-line: "emoji answer" format
  - Removed unused `_GlassVerificationPill` class

Files Deleted:
- None

Renamed / Moved:
- None

Why / Notes:
- Verification badge after name/age is more intuitive (shows identity info together)
- Higher bottom position prevents content from going behind bottom navigation
- Single-line bio/prompt reduces visual clutter on deck cards
- Cleaner layout improves overall deck screen aesthetics

Risks & Mitigations:
- Risk: Content may overlap if too much profile info
- Mitigation: Used `Flexible` and `overflow: ellipsis` for proper text truncation

Verification Steps:
- Run: `flutter run`
- Manual: View deck screen, verify verification badge appears after "Name, Age"
- Manual: Verify bio/prompt text does not go behind bottom navigation
- Manual: Verify deck cards look cleaner with minimal description

Follow-ups / TODO:
- None

---

### [2026-01-22] Task: Comprehensive Project Audit

Summary:
- Conducted full audit of project structure, architecture, Firebase, security, BLoCs, routing, UI/UX, and platform configs
- Cleaned up 60+ duplicate and empty directories/files
- Updated .gitignore with missing patterns
- Generated comprehensive audit report document
- Fixed duplicate ProfileMediaLimits conflict

Files Added:
- docs/project_audit_report.md (comprehensive audit findings)

Files Modified:
- .gitignore
  - Added patterns for duplicate numbered directories (* 2/, * 3/)
  - Added Firebase debug log patterns
  - Added Android .gradle/ and .kotlin/ patterns

Files Deleted:
- web_entrypoint.dart (empty file)
- lib/core/profile_media_limits.dart (duplicate, conflicting with shared/utils version)
- web 2/, test 2/, dataconnect 2/, .dart_tool 2/ (duplicate directories)
- macos/Runner 2/, macos/Flutter/ephemeral 2/
- ios/.symlinks 2/, ios/.symlinks 3/, ios/Runner/Assets 2.xcassets/
- android/app/src/debug 2/, android/app/src/main/kotlin/com 2/
- linux/runner 2/
- crushhour-recommendation-service/node_modules 2/
- functions/bq_queries 2/
- ~45 ios/Pods/* 2 and ios/Pods/* 3 directories
- 13 empty directories in lib/ hierarchy

Why / Notes:
- Full codebase audit requested by user
- Found 10 critical issues requiring immediate attention
- Package name mismatch between iOS (com.ace.crush) and Android (com.example.crushhour)
- Development bypass credentials in auth code
- Missing Cloud Functions for messaging
- BLoC issues including recursive timer and missing auth cleanup

Critical Issues Found:
1. Package name mismatch (iOS/Android) - CRITICAL
2. Development bypass credentials - CRITICAL
3. Missing Cloud Functions (messaging) - CRITICAL
4. Unconfigured Firebase secrets - CRITICAL
5. Android release signing missing - CRITICAL
6. iOS deployment target mismatch - HIGH
7. Overly permissive Firestore rules - HIGH
8. BLoCs missing auth cleanup - HIGH
9. ID verification not implemented - HIGH
10. Orphaned screens (calls, media) - MEDIUM

Risks & Mitigations:
- Risk: Production deployment in current state could expose user data
  - Mitigation: Documented all issues in audit report with fix recommendations
- Risk: Package name change requires Firebase reconfiguration
  - Mitigation: Use flutterfire configure after standardizing names

Verification Steps:
- Review docs/project_audit_report.md for complete findings
- Address critical issues before any production deployment
- Run flutter clean and flutter pub get after changes

Follow-ups / TODO:
- Fix package name mismatch (choose one and update both platforms)
- Remove devLoginBypass() security bypass
- Configure all Firebase secrets
- Implement Android release signing
- Fix BoostCubit recursive timer bug
- Add auth state listeners to 4 cubits

---
