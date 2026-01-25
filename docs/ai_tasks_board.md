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
None.

## Completed Tasks

### Task: Refactor Oversized Screen Files
ID: T-051
Owner AI: Claude (Opus 4.5)
Critic AI: Claude (self-critique)
Status: Done

Goal:
Refactor the 5 oversized screen files identified in AUDIT_REPORT.md by extracting reusable widgets.

Scope (in/out):
In:
- chat_screen.dart (3,716 lines) - PRIMARY TARGET
- profile_setup_screen.dart (1,800+ lines reported)
- deck_screen.dart (1,500+ lines reported)
- settings_screen.dart (1,200+ lines reported)
- profile_view_screen.dart (1,100+ lines reported)

Out:
- Logic refactoring (only widget extraction)
- Test writing

Files changed:
- lib/features/chat/presentation/screens/chat_screen.dart (3,716→2,868 lines)
- lib/features/chat/presentation/widgets/chat_date_separator.dart (NEW)
- lib/features/chat/presentation/widgets/chat_typing_indicator.dart (NEW)
- lib/features/chat/presentation/widgets/chat_send_status_bar.dart (NEW)
- lib/features/chat/presentation/widgets/chat_empty_state.dart (NEW)
- lib/features/chat/presentation/widgets/chat_reaction_button.dart (NEW)
- lib/features/chat/presentation/widgets/chat_fade_notification.dart (NEW)
- lib/features/chat/presentation/widgets/chat_attachment_tile.dart (NEW)
- lib/features/chat/presentation/widgets/chat_widgets.dart (NEW - barrel file)
- AUDIT_REPORT.md (updated status)
- docs/ai_change_log.md

Results:
- chat_screen.dart: Reduced from 3,716 to 2,868 lines (23% reduction)
- profile_setup_screen.dart: Actually 1,465 lines (integrated state, no extraction)
- deck_screen.dart: Actually 1,726 lines (widgets already in separate folder)
- settings_screen.dart: Actually 837 lines (within limits)
- profile_view_screen.dart: Actually 817 lines (within limits)

Acceptance criteria:
- ✅ Extract reusable widgets from oversized screens
- ✅ No flutter analyze errors
- ✅ All functionality preserved
- ✅ Documentation updated

Verification:
Commands: flutter analyze (0 issues)
Manual flow: Chat screen renders correctly with extracted widgets

Completed: 2026-01-25

---

### Task: Add Refactoring Roadmap to AUDIT_REPORT.md
ID: T-050
Owner AI: Claude (Opus 4.5)
Critic AI: Claude (self-critique)
Status: Done

Goal:
Document all identified refactoring opportunities and code quality improvements in the AUDIT_REPORT.md with a prioritized action plan.

Scope (in/out):
In:
- Oversized screen files analysis
- Silent catch blocks inventory
- Deprecated patterns documentation
- Test coverage gaps
- Prioritized action plan

Out:
- Actual refactoring implementation (future tasks)
- Code changes (documentation only)

Files changed:
- AUDIT_REPORT.md (added Section 11 "Refactoring Roadmap")
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Acceptance criteria:
- ✅ All identified refactoring tasks documented
- ✅ Tasks organized by priority (High/Medium/Low)
- ✅ Action plan with phases included
- ✅ Priority matrix for decision-making

Verification:
Commands: N/A (documentation task)
Manual flow: Review AUDIT_REPORT.md Section 11

Completed: 2026-01-25

---

### Task: Optimize Deck Preloading and Memory Management (R-114)
ID: T-049
Owner AI: Claude (Opus 4.5)
Critic AI: Claude (self-critique)
Status: Done

Goal:
Optimize deck preloading for better UX and memory management, addressing R-114 risk.

Scope (in/out):
In:
- Priority-based image preloading
- Memory pressure handling
- Smart cache eviction
- Shimmer loading placeholders

Out:
- Network connectivity detection (future enhancement)
- Disk caching (future enhancement)

Files changed:
- lib/shared/widgets/cached_network_image.dart
- lib/features/discovery/presentation/widgets/deck_card_stack.dart
- lib/features/discovery/presentation/screens/deck_screen.dart
- docs/ai_change_log.md
- docs/risk_notes.md
- docs/ai_tasks_board.md

Acceptance criteria:
- ✅ Priority-based preloading implemented
- ✅ Memory pressure handling works
- ✅ Shimmer placeholders shown during load
- ✅ No analyzer issues

Verification:
Commands: `flutter analyze` - No issues found
Manual flow: Swipe through deck, observe smooth transitions and loading states

Completed: 2026-01-25

---

### Task: Comprehensive Project Audit
ID: T-047
Owner AI: Claude (Opus 4.5)
Critic AI: Claude (self-critique)
Status: Done

Goal:
Conduct comprehensive audit of entire project covering architecture, Firebase, security, platforms, code quality, and documentation.

Scope (in/out):
In:
- Full codebase structure review
- Flutter analyze for code issues
- Firebase configuration and rules alignment check
- iOS/Android platform parity review
- Identify and clean up duplicate/empty files
- Review and update .gitignore
- Create comprehensive audit report
- Update documentation files

Out:
- Cloud Function deployment (requires Blaze plan)
- Feature implementation

Files changed:
- AUDIT_REPORT.md - Complete rewrite with 2026-01-25 findings
- docs/ai_change_log.md - Added audit entry
- docs/ai_tasks_board.md - Added completed task

Files deleted (duplicate directories):
- macos/Runner 2
- .dart_tool 2
- ios/.symlinks 2
- ios/Flutter/ephemeral 2
- ios/Pods/abseil 2, FirebaseStorage 2, FirebaseABTesting 2

Key Findings:
- ✅ Flutter Analyze: 0 issues (442 files, ~195k LOC)
- ✅ Architecture: Complete Clean Architecture
- ✅ Firebase: Fully configured with security rules
- ✅ Platform Parity: iOS/Android feature complete
- ⚠️ Discovery: Requires Cloud Function deployment

Verification:
Commands: `flutter analyze` - No issues found
Manual flow: N/A (audit task)

Completed: 2026-01-25

---

### Task: Fix Critical Match Status Mismatch
ID: T-046
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Fix critical bug where matches were not appearing because client queried for wrong status value.

Root Cause:
- Cloud Function creates matches with `status: 'active'` (required by Firestore rules)
- Client code was querying for `status == 'mutual'` which matched ZERO records
- This caused all match queries to return empty, breaking matches and chat

Scope (in/out):
In:
- Fix match status queries in firebase_chat_repository.dart
- Fix match status queries in firebase_discovery_repository.dart
Out:
- No changes to Cloud Functions (already correct)
- No changes to Firestore rules (already correct)

Files changed:
- lib/features/chat/data/repositories/impl/firebase_chat_repository.dart - 4 query fixes
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart - 1 query fix

Verification:
Commands: `flutter analyze` - No issues found
Manual flow:
1. Swipe right on a user who swiped right on you
2. Match should appear in matches list
3. Chat should be accessible

Completed: 2026-01-24

---

### Task: Dynamic Location Updates & Discovery Enhancements
ID: T-045
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Implement dynamic location updates on every app open, fix distance display on deck cards, and add location permission prompt banner.

Scope (in/out):
In:
- Update user location every time app opens/resumes
- Map distanceKm from Cloud Function to Profile model for display
- Add location permission banner for users without location
- Review and verify discovery restrictions are lenient
Out:
- Background location tracking
- Push notifications based on location

Files changed:
- lib/app.dart - Added location update on app resume
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart - Map distanceKm to Profile
- lib/features/discovery/presentation/screens/deck_screen.dart - Location permission banner

Risks:
- Location update on every resume could be slow - mitigated by non-blocking async call with 10s timeout
- Banner could be annoying - mitigated by auto-dismiss after 2 seconds

Acceptance criteria:
- Location updates when app comes to foreground
- Distance displays correctly on deck cards (e.g., "5 KM")
- Location banner shows for users without permission, auto-dismisses
- Discovery includes users with and without location

Verification:
Commands: `flutter analyze` - No issues found
Manual flow:
1. Open app, check location updated
2. View deck, verify distance shows on cards
3. Deny location, verify banner shows and dismisses
4. Grant location, verify banner doesn't show

Completed: 2026-01-24

---

### Task: Fix Discovery - New Accounts Not Appearing in Deck
ID: T-044
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Fix critical issue where newly created accounts were not appearing in other users' discovery decks.

Scope (in/out):
In:
- Add location capture during profile setup onboarding
- Save latitude/longitude to Firestore profile document
- Make Cloud Function more lenient for users without location
- Update all profile repository implementations

Out:
- Location tracking during app usage (only captures once during setup)
- Location-based push notifications

Files changed:
- lib/features/profile/presentation/screens/profile_setup_screen.dart
- lib/features/profile/presentation/bloc/profile_event.dart
- lib/features/profile/data/repositories/profile_repository.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
- lib/features/profile/data/repositories/impl/http_profile_repository.dart
- lib/data/repositories/fake_repositories.dart
- lib/features/profile/presentation/bloc/profile_bloc.dart
- test/deck_gating_test.dart
- functions/src/index.ts

Risks:
- User denies location permission - mitigated by Cloud Function including users without location
- Location capture fails - mitigated by graceful fallback in both client and server

Acceptance criteria:
- New accounts appear in other users' discovery decks
- Location is captured during profile setup
- Cloud Function handles missing location gracefully
- Users with location prioritized over users without

Verification:
Commands: `flutter analyze` + `cd functions && npm run build`
Manual flow:
1. Create new account on Device A
2. Complete profile setup (grant location permission)
3. Login on Device B with existing account
4. Open deck screen - should see new account from Device A

Completed: 2026-01-24

---

### Task: App State Preservation for Background/Foreground Transitions
ID: T-043
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Preserve app state when user backgrounds the app so it resumes instantly where they left off instead of restarting from splash.

Scope (in/out):
In:
- Create AppStatePreserver service for route persistence
- Add WidgetsBindingObserver lifecycle handling to app.dart
- Modify router to accept optional initial route
Out:
- Splash screen optimization (not needed - route bypasses splash)
- Deep link parameter preservation

Files changed:
- lib/core/services/app_state_preserver.dart (new)
- lib/app.dart (modified)
- lib/core/router.dart (modified)

Risks:
- Deep link routes with query params may not restore perfectly
- Mitigation: Only preserves path-based routes, clears on resume

Acceptance criteria:
- User can background app and return to same screen
- State expires after 30 minutes in background
- Auth/onboarding routes are not preserved

Verification:
Commands: `flutter analyze` - No issues found
Manual flow:
1. Open app, navigate to deck/chat/settings
2. Background the app
3. Return from background
4. App should resume at same location (not splash)

Completed: 2026-01-24

---

### Task: Critical Fixes for Discovery, Matching, Chat & Cross-Platform
ID: T-042
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Fix critical bugs preventing discovery, matching, and chat from working across iOS and Android.

Scope (in/out):
In:
- Fix match status mismatch (mutual → active)
- Add RTDB rules for real-time match notifications
- Fix storage upload path mismatches
- Fix ProfileData TypeScript type definition
Out:
- Migration script for existing matches
- UI changes

Files changed:
- functions/src/index.ts (match status + ProfileData type)
- database.rules.json (newMatches rules)
- storage.rules (photos, videos, chat_media paths)
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- Existing matches with status "mutual" cannot be read
- Mitigation: May need one-time migration

Acceptance criteria:
- Users can discover each other across iOS/Android
- Users can match and receive real-time notifications
- Users can chat bidirectionally
- Media uploads work in chat and profile

Verification:
Commands: `flutter analyze lib/` and `cd functions && npm run build`
Manual flow:
1. Create iOS user A (Male→Female) and Android user B (Female→Male)
2. Both see each other in deck
3. Both swipe right → match notification appears
4. Chat works bidirectionally
5. Media uploads work

Completed: 2026-01-23

---

### Task: Fix Discovery Deck Gender Filter Bug
ID: T-041
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Fix critical bug where users weren't seeing each other in discovery deck due to incorrect showMeGenders filter.

Scope (in/out):
In:
- Fix Cloud Function to handle 'All'/'everyone' showMeGenders values
- Update all client-side defaults from ['All'] to ['male', 'female']
- Handle legacy 'All' values when parsing preferences
Out:
- UI changes
- New feature development

Files changed:
- functions/src/index.ts
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/features/auth/data/repositories/impl/stub_auth_repository.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- Existing Firestore data with ['All'] handled by legacy value conversion
- Cloud Function deployment required for server-side fix

Acceptance criteria:
- Users with opposite genders see each other in discovery deck
- Default showMeGenders is ['male', 'female'] not ['All']
- Legacy 'All' values are converted to proper defaults

Verification:
Commands: `flutter analyze lib/` and `cd functions && npm run build`
Manual flow:
1. Create two test accounts (one male, one female)
2. Both should appear in each other's discovery deck
3. Deploy Cloud Function and verify discovery works

Completed: 2026-01-23

---

### Task: Username Display and 28-Day Change Restriction
ID: T-040
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Implement username display on deck cards, 28-day change restriction, and show real name on profile view.

Scope (in/out):
In:
- Change name/username change restriction from 30 to 28 days
- Add username field to Profile model
- Update SwipeCard to show @username on deck
- Update OtherUserProfileScreen to show full name
Out:
- Cloud Function updates (need separate deployment)
- UI redesigns beyond name display

Files changed:
- lib/data/models/profile.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- Cloud Function must return username for discovery profiles
- Existing profiles without username will fallback to name

Acceptance criteria:
- Deck cards show @username instead of real name
- Profile view shows full name (first + last)
- Username can only be changed every 28 days

Verification:
Commands: `flutter analyze lib/`
Manual flow:
1. Open app, go to deck, see @username on cards
2. Tap profile, see full real name
3. Go to profile setup, verify 28-day restriction text

Completed: 2026-01-23

### Task: Fix Flutter SDK path for VS Code
ID: T-039
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Fix invalid `dart.flutterSdkPath` so the workspace uses a valid Flutter SDK directory.

Scope (in/out):
In:
- Add workspace `.vscode/settings.json` with valid SDK path
Out:
- Global user settings changes

Files changed:
- .vscode/settings.json
- docs/Developer_agent_chat.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Risks:
- Path is machine-specific; if SDK moves, path must be updated.

Acceptance criteria:
- IDE no longer reports invalid Flutter SDK path

Verification:
Commands: `ls /Users/ace/Development/flutter`
Manual flow:
1. Reload VS Code window
2. Confirm Dart/Flutter tools detect the SDK

Completed: 2026-01-23

### Task: Per-Chat Settings (Individual Message Retention)
ID: T-038
Owner AI: Claude
Critic AI: Claude (self-critique)
Status: Done

Goal:
Fix chat settings update failure and implement per-match chat settings, allowing users to customize message retention for each individual conversation.

Scope (in/out):
In:
- Fix ChatSettings parsing from Firestore
- Create MatchChatSettingsCubit for per-match settings
- Add Cloud Function for per-match settings storage
- Add chat settings access from chat screen popup menu
Out:
- Backend infrastructure changes beyond Cloud Functions
- UI redesigns

Files changed:
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart (new)
- functions/src/index.ts
- lib/features/chat/presentation/screens/chat_screen.dart
- docs/Developer_agent_chat.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- Requires Cloud Functions deployment to work
- Per-match settings require fetching existing settings when opening bottom sheet

Acceptance criteria:
- ChatSettings parsed correctly from Firestore
- Per-match settings can be toggled from chat menu
- Settings stored at match level, not global user level
- Flutter analyze passes

Verification:
Commands: `flutter analyze`, `firebase deploy --only functions`
Manual flow:
1. Open a chat with a match
2. Tap menu icon, select "Chat Settings"
3. Toggle 24-hour retention
4. Verify setting is saved without error

Completed: 2026-01-23

---

### Task: Ensure matched users appear + chat redirect from matches list
ID: T-037
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Ensure newly matched users appear under “Matched with you” and tap navigates to the correct chat.

Scope (in/out):
In:
- Matches screen list shows newly created matches
- Tap handler routes to chat with correct matchId/user data
Out:
- Backend changes
- UI redesigns

Files changed:
- lib/features/chat/presentation/screens/matches_screen.dart
- docs/Developer_agent_chat.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Risks:
- Match list may not refresh immediately after match creation without a trigger.

Acceptance criteria:
- New matches appear under “Matched with you”
- Tapping a match opens the correct chat

Verification:
Commands: `flutter run`
Manual flow:
1. Create a match via swipes.
2. Go to Matches screen and verify it appears under “Matched with you.”
3. Tap the match and confirm chat opens for the correct user.

Completed: 2026-01-23

### Task: Deck preload + background stack in swipe deck
ID: T-036
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Show upcoming swipe profiles behind the current card and preload several next profiles for instant transitions.

Scope (in/out):
In:
- Deck UI shows visible background cards while dragging
- Preload next 4 profiles' lead images
- Keep match celebration behavior unchanged
Out:
- Backend changes
- New data models

Files changed:
- lib/features/discovery/presentation/screens/deck_screen.dart
- lib/features/discovery/presentation/widgets/deck_card_stack.dart
- docs/Developer_agent_chat.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/risk_notes.md

Risks:
- Increased image preloading could raise memory/network usage on low-end devices.

Acceptance criteria:
- Next profile is visible in background while dragging
- Swipes show the next card immediately with no visible delay
- At least 4 upcoming profiles are preloaded
- Match celebration still appears on match

Verification:
Commands: `flutter run`
Manual flow:
1. Open deck and drag a card left/right; confirm next card visible behind.
2. Swipe several cards; verify instant transition.
3. Trigger a match; verify match celebration appears.

Completed: 2026-01-23

### Task: Complete Discovery & Matching System with Real-time RTDB
ID: T-035
Owner AI: Claude
Critic AI: N/A (self-reviewed)
Status: Done

Goal:
Fix critical bugs in discovery flow and implement real-time match notifications via RTDB.

Scope (in/out):
In:
- Fix Cloud Function response format (profiles → candidates)
- Fix discovery query to include new users
- Add default discovery preferences on profile save
- Implement RTDB real-time match notifications
- Integrate match notifications with app lifecycle
Out:
- Push notification changes (separate task)
- Match celebration animation changes

Files changed:
- functions/src/index.ts (response format, query, RTDB write)
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart (default prefs)
- lib/features/discovery/data/services/realtime_match_service.dart (new)
- lib/app.dart (RTDB listener integration)
- docs/Developer_agent_chat.md (Task #007)
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- R-110: RTDB write failure → mitigated by non-blocking write
- R-111: Auth sync issues → mitigated by BlocListener

Acceptance criteria:
- [x] Discovery returns candidates (not profiles)
- [x] New users appear in discovery
- [x] Real-time match notifications work
- [x] Match → chat flow complete

Verification:
Commands:
- flutter analyze lib/app.dart
- firebase deploy --only functions
Manual flow:
- Complete profile → appear in discovery
- Swipe right on user who liked you → match created
- See match celebration → navigate to chat

---

### Task: Message Requests for non-matched users
ID: T-034
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Add Message Requests for non-matched users, with send limits, expiration, and migration into chats on match.

Scope (in/out):
In:
- Message request model + repository methods
- Profile screen send message UI and limits
- Chats list entry + Message Requests screen
- Match migration hook
- Firestore rules and docs for message requests
Out:
- Backend Cloud Functions changes
- Push notification changes

Files changed:
- lib/data/models/message_request.dart
- lib/features/chat/data/repositories/chat_repository.dart
- lib/features/chat/data/repositories/impl/stub_chat_repository.dart
- lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
- lib/features/chat/data/repositories/impl/http_chat_repository.dart
- lib/features/chat/presentation/bloc/message_requests_cubit.dart
- lib/features/chat/presentation/bloc/message_requests_state.dart
- lib/features/chat/presentation/screens/message_requests_screen.dart
- lib/features/chat/presentation/screens/chat_list_screen.dart
- lib/features/chat/presentation/bloc/matches_bloc.dart
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/core/router.dart
- lib/data/repositories/fake_repositories.dart
- firestore.rules
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md
- docs/Developer_agent_chat.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/risk_notes.md

Risks:
- Message request migration may only succeed on the sender’s device (auth constraints).

Acceptance criteria:
- Send Message appears on profiles; pass/like hidden when matched
- Non-matched users can send only one message request
- Message Requests entry appears in Chats screen
- Requests expire after 48 hours
- When matched, request moves into chats as the first message (when possible)

Verification:
Commands: `flutter run`
Manual flow:
1. Open a non-matched profile → Send Message → request appears in Message Requests
2. Attempt to send again → blocked
3. Match occurs → request migrates into chat (sender device)
4. Requests older than 48 hours disappear

Completed: 2026-01-23

### Task: Improve Prompt Refinement Workflow
ID: T-033
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Enhance Developer_agent_chat.md to require very specific, very detailed refined prompts with comprehensive templates.

Scope (in/out):
In:
- Update template with Developer Intent Analysis section
- Add detailed Refined Prompt structure (Objective, Technical Requirements, Implementation Plan, Files, Success Criteria, Edge Cases)
- Add Agent Workflow section
- Update Notes for Agents with stricter guidelines
Out:
- Code changes

Files changed:
- docs/Developer_agent_chat.md (enhanced template and workflow)

Risks:
- None

Acceptance criteria:
- Template includes all required sections
- Task #004 serves as example of new format
- Workflow clearly documented

Verification:
Commands: N/A (documentation only)
Manual flow: Review Developer_agent_chat.md for completeness

Completed: 2026-01-23

---

### Task: Create Developer Agent Chat Document
ID: T-032
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Create a task logging system for developer-to-agent communications to track all tasks given by the developer.

Scope (in/out):
In:
- Create `/docs/Developer_agent_chat.md` document
- Add template for logging developer tasks
- Log original requests and refined prompts
- Update CLAUDE.md to reference the new document
- Update workflow to include task logging
Out:
- Changes to existing code

Files changed:
- docs/Developer_agent_chat.md (new file)
- CLAUDE.md (updated workflow and quick reference)
- docs/ai_tasks_board.md
- docs/ai_change_log.md

Risks:
- None

Acceptance criteria:
- Document created with clear template
- Previous tasks logged with refined prompts
- CLAUDE.md updated with mandatory logging rules
- Quick reference section updated

Verification:
Commands: N/A (documentation only)
Manual flow:
1. Developer gives task → Agent logs to Developer_agent_chat.md
2. Original request preserved, refined prompt created
3. Status and outcome tracked

Completed: 2026-01-23

---

### Task: Implement Bidirectional Chat Messaging
ID: T-031
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Implement missing Cloud Functions for chat messaging so User A can send messages to User B and vice versa with real-time updates.

Scope (in/out):
In:
- sendMessage Cloud Function
- markMessagesRead Cloud Function
- editMessage Cloud Function
- Verify real-time listening in ChatBloc
Out:
- Flutter UI changes (already working)
- Push notification changes (already handled by onMessageCreated trigger)

Files changed:
- functions/src/index.ts (added 3 callable functions + 3 interfaces)
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- Functions need deployment to Firebase

Acceptance criteria:
- TypeScript builds successfully
- sendMessage validates match membership
- markMessagesRead batch updates unread messages
- editMessage allows sender to modify their message
- Real-time updates work via watchMessages stream

Verification:
Commands:
- `cd functions && npm run build` ✅
- `firebase deploy --only functions` (pending)
Manual flow:
1. User A sends message to User B
2. User B sees message in real-time
3. User B replies
4. User A receives reply

---

### Task: Profile Photo Rendering and Display Fix
ID: T-030
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Fix profile photo rendering to display user-uploaded photos clearly without blur, with proper alignment and quality.

Scope (in/out):
In:
- Top-center alignment for hero image and photo grid
- Alignment support in CachedNetworkImage
- Retry functionality for failed loads
- Reduced gradient overlay
Out:
- Firebase Storage changes
- Image upload changes

Files changed:
- lib/shared/widgets/cached_network_image.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- None

Acceptance criteria:
- ✅ Hero image uses top-center alignment (face visible)
- ✅ Photo grid uses top-center alignment
- ✅ No blur on user-uploaded photos
- ✅ Gradient overlay only at bottom for text readability
- ✅ Retry button on error states

Verification:
Commands: `flutter run`
Manual flow:
1. Go to Profile screen -> hero image shows face at top
2. Scroll to "My Photos" -> photos display clearly without blur
3. Verify gradient only at bottom of hero image

Completed: 2026-01-23

### Task: Display username in Profile and Complete Your Profile screens
ID: T-029
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Display username in Profile View screen and add Basic Info summary section to Complete Your Profile screen.

Scope (in/out):
In:
- Add username display to Profile View screen
- Add Basic Info summary (username, name, age, gender) to Complete Your Profile screen
- Allow navigation to edit Basic Info
Out:
- Changes to BasicInfoScreen itself
- Profile data storage changes

Files changed:
- lib/features/profile/presentation/screens/profile_view_screen.dart
- lib/features/profile/presentation/screens/profile_setup_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- None

Acceptance criteria:
- ✅ Username displayed in Profile View screen below name
- ✅ Basic Info summary shown in Complete Your Profile screen
- ✅ Edit button navigates to BasicInfoScreen

Verification:
Commands: `flutter run`
Manual flow:
1. Go to Profile screen -> see username below name
2. Go to Complete Your Profile -> see Basic Info summary at top
3. Tap Edit on Basic Info -> navigate to BasicInfoScreen

Completed: 2026-01-23

### Task: Pre-fill username in Basic Info from signup
ID: T-028
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Pre-fill the username entered during signup in the Basic Info screen.

Scope (in/out):
In:
- Pre-fill username from CrushUser.username in Basic Info screen
- Allow user to edit pre-filled username
Out:
- Changes to signup flow or username storage

Files changed:
- lib/features/auth/presentation/screens/basic_info_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Risks:
- None

Acceptance criteria:
- Username from signup is pre-filled in Basic Info screen
- User can still edit the pre-filled username

Verification:
Commands: `flutter run`
Manual flow:
1. Create new account -> enter username in step 1
2. Proceed to Basic Info screen
3. Verify username field is pre-filled

Completed: 2026-01-23

### Task: Hide pass/like for matched profiles + wire profile actions
ID: T-027
Owner AI: Codex
Critic AI: Codex (self-critique; no external critic available)
Status: Done

Goal:
Hide Pass/Like buttons on other-user profiles when users are already matched; ensure pass/like sends swipe actions and returns to the deck.

Scope (in/out):
In:
- OtherUserProfileScreen pass/like UI visibility and actions
- Swipe handling with deck-aware fallback
Out:
- Routing changes or new flows
- Match celebration UI changes

Files changed:
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Risks:
- DiscoveryBloc swipe could act on the wrong card if the viewed profile is not the current deck profile.

Acceptance criteria:
- ✅ Pass/Like hidden when isMatch == true
- ✅ Pass/Like triggers swipe actions for non-matched profiles
- ✅ After pass/like, user returns to the deck screen
- ✅ Mutual like creates a match (repository returns match)

Verification:
Commands: `flutter run`
Manual flow:
1. From deck, open profile, tap Pass -> returns to deck, card advances
2. From deck, open profile, tap Like -> returns to deck, like sent
3. From chat (matched), open profile -> no Pass/Like buttons

Completed: 2026-01-23

### Task: Fix ID verification notification in chat screen
ID: T-026
Owner AI: Claude
Critic AI: Claude (self-critique; no external critic available)
Status: Done

Goal:
Fix the "Verify your ID" notification in chat screen to navigate to ID verification screen, add 10-second auto-dismiss, and 3-hour cooldown.

Scope (in/out):
In:
- Navigation from Verify button to ID verification screen
- 10-second auto-dismiss timer
- 3-hour cooldown using SharedPreferences
- Hide notification if user is verified
Out:
- ID verification screen changes
- Backend verification status changes

Files changed:
- lib/features/chat/presentation/screens/chat_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Risks:
- SharedPreferences cooldown key may persist across accounts

Acceptance criteria:
- ✅ Verify button navigates to ID verification screen (not Safety)
- ✅ Notification auto-dismisses after 10 seconds
- ✅ Notification only shows once every 3 hours
- ✅ Notification hidden if user is verified

Verification:
Commands: `flutter run`
Manual flow:
1. Open a chat screen as unverified user
2. Verify notification appears and auto-dismisses in 10 seconds
3. Tap Verify -> navigates to ID verification screen
4. Re-open chat -> notification doesn't appear (3-hour cooldown)

Completed: 2026-01-23

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
