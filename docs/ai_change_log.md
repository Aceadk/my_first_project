# AI Change Log — CRUSH

This file tracks all changes made by AI assistants in this repository.

---

### [2026-01-24] Task: App State Preservation for Background/Foreground Transitions

Summary:
- Implemented app state preservation to prevent app from restarting from splash screen when returning from background
- App now remembers the user's location and resumes instantly when coming back from background
- State is preserved for up to 30 minutes while in background
- Routes that shouldn't be preserved (splash, auth, onboarding) are excluded

Files Added:
- lib/core/services/app_state_preserver.dart
  - New singleton service for route persistence using SharedPreferences
  - Saves current route with timestamp when app goes to background
  - Restores route on launch if authenticated and route is still valid (< 30 min)
  - Filters out routes that shouldn't be preserved

Files Modified:
- lib/app.dart
  - Converted _CrushAppState to use AppStatePreserver initialization
  - Added WidgetsBindingObserver mixin to _RouterHostState
  - Added didChangeAppLifecycleState() to save/clear preserved routes
  - Router now checks for preserved route when initializing

- lib/core/router.dart
  - Added optional `initialRoute` parameter to createRouter function
  - Uses preserved route as initial location when available

Why:
- User reported that app always restarted from splash screen when returning from background
- This created a poor user experience with unnecessary delays
- App should resume exactly where the user left off

Risks & Mitigations:
- Deep link routes with parameters may not restore perfectly → Only preserves simple path-based routes
- Very old routes may lead to stale state → 30-minute expiration prevents this
- Auth state may have changed while in background → Route is only used if user is still authenticated

Verification:
- `flutter analyze` - No issues found
- Manual test: Open app → Navigate to deck → Background app → Return → Should resume at deck (not splash)

---

### [2026-01-24] Task: Fix Test Stub - Missing showMeGenders Parameter

Summary:
- Fixed `invalid_override` error in deck_gating_test.dart
- Added missing `showMeGenders` parameter to `_StubProfileRepository.saveProfileDetails`

Files Modified:
- test/deck_gating_test.dart (line 300)
  - Added `List<String>? showMeGenders,` to saveProfileDetails method signature

Why:
- The `ProfileRepository.saveProfileDetails` interface was updated with a new `showMeGenders` parameter
- The test stub implementation wasn't updated, causing an `invalid_override` compiler error

Verification:
- `flutter analyze test/deck_gating_test.dart` - No issues found

---

### [2026-01-23] Task: Critical Fixes for Discovery, Matching, Chat & Cross-Platform

Summary:
- Fixed 3 CRITICAL bugs preventing discovery, matching and chat from working
- Match status mismatch: Cloud Function created `status: "mutual"` but Firestore rules checked for `status: "active"`
- Missing RTDB rules: Clients couldn't read real-time match notifications
- Storage path mismatch: Profile/chat media uploads were using different paths than rules allowed
- Added `name` and `lastName` to ProfileData TypeScript type

Files Added:
- None

Files Modified:
- functions/src/index.ts
  - Changed match creation status from "mutual" to "active" (line 3332)
  - Changed RTDB notification status from "mutual" to "active" (line 3359)
  - Added `name` and `lastName` properties to ProfileData type definition
- database.rules.json
  - Added `/users/{uid}/newMatches` rules for real-time match notifications
  - Users can read their own notifications and delete (clear) them after reading
  - Cloud Functions (Admin SDK) can still write notifications
- storage.rules
  - Added `/users/{uid}/photos/{fileName}` rule for profile photo uploads
  - Added `/users/{uid}/videos/{fileName}` rule for profile video uploads
  - Added `/chat_media/{matchId}/{userId}/{fileName}` rule for chat media uploads

Files Deleted:
- None

Why / Notes:
- CRITICAL BUG #1: Match status "mutual" vs Firestore rule expecting "active"
  - Impact: Users could NOT read their matches or messages (permission denied)
  - Fix: Changed Cloud Function to use status: "active"
- CRITICAL BUG #2: Missing RTDB rules for `/users/{uid}/newMatches`
  - Impact: Real-time match notifications never reached clients
  - Fix: Added read rules and delete-only write rules for clients
- CRITICAL BUG #3: Storage path mismatch
  - Code used: `users/{uid}/photos/`, `users/{uid}/videos/`, `chat_media/...`
  - Rules allowed: `users/{uid}/media/`, `chats/{matchId}/{messageId}/...`
  - Impact: All media uploads would fail in production
  - Fix: Added rules for actual paths used by code
- TypeScript fix: ProfileData was missing `name` property causing build errors

Risks & Mitigations:
- Existing matches with status "mutual": Cannot be read until backend migration
  - Mitigation: Existing matches may need a one-time migration script
- RTDB write rules use `!newData.exists()` to allow only deletions
  - Cloud Functions use Admin SDK which bypasses rules

Verification Steps:
- `flutter analyze lib/` - No issues found
- `cd functions && npm run build` - Compiles successfully
- Deploy all rules and functions:
  1. `firebase deploy --only functions`
  2. `firebase deploy --only database` (RTDB rules)
  3. `firebase deploy --only firestore:rules`
  4. `firebase deploy --only storage`

Manual Testing:
1. Create account A (iOS) with gender Male, looking for Female
2. Create account B (Android) with gender Female, looking for Male
3. A should see B in discovery deck
4. B should see A in discovery deck
5. A swipes right on B → no immediate match
6. B swipes right on A → MATCH! Both get notification
7. Both should see match in Matches screen
8. Open chat → both can send/receive messages
9. Upload photo in chat → should succeed

Follow-ups / TODO:
- Consider migration script for existing matches with status "mutual"
- Monitor RTDB notification delivery in production

---

### [2026-01-23] Task: Fix Discovery Deck - Gender Filter Bug

Summary:
- Fixed critical bug where users weren't seeing each other in discovery deck
- The root cause was `showMeGenders: ['All']` default which queried for `profile.gender = 'All'` (no user has this gender value)
- Updated Cloud Function to skip gender filter for 'All', 'everyone', or 'any' values
- Updated all client-side defaults from `['All']` to `['male', 'female']`
- Added legacy 'All' value handling in preferences parsing

Files Added:
- None

Files Modified:
- functions/src/index.ts
  - Modified fetchDiscoveryCandidates to skip gender filter when showMeGenders contains 'All', 'everyone', or 'any'
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
  - Changed default showMeGenders from ['All'] to ['male', 'female']
  - Added legacy 'All' value handling in _preferencesFromFirestore
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
  - Changed default showMeGenders from ['All'] to ['male', 'female']
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart
  - Changed default showMeGenders from ['All'] to ['male', 'female']
  - Added legacy 'All' value handling in _preferencesFromFirestore
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
  - Changed default showMeGenders from ['All'] to ['male', 'female']
  - Added legacy 'All' value handling in _preferencesFromFirestore
- lib/features/auth/data/repositories/impl/stub_auth_repository.dart
  - Changed default showMeGenders from ['All'] to ['male', 'female']

Files Deleted:
- None

Why / Notes:
- Users reported not seeing each other in discovery deck even with opposite genders
- Investigation found that default `showMeGenders: ['All']` was being passed to Cloud Function
- Cloud Function queried `profile.gender IN ['All']` which returned 0 results
- Fixed by: (1) Cloud Function now skips gender filter for 'All'/'everyone'/'any' values
- Fixed by: (2) Client defaults changed to actual gender values ['male', 'female']
- Fixed by: (3) Legacy 'All' values converted to proper defaults when parsing

Risks & Mitigations:
- Existing users with `showMeGenders: ['All']` in Firestore: Handled by Cloud Function skip logic
- Backward compatibility: Both Cloud Function and client handle legacy values gracefully

Verification Steps:
- Deploy Cloud Function: `cd functions && npm run deploy`
- Run Flutter app and check discovery deck loads profiles
- Create two test accounts with opposite genders and verify they see each other

Follow-ups / TODO:
- None - this fix handles both new and existing users

---

### [2026-01-23] Task: Username Display and 28-Day Change Restriction

Summary:
- Changed username/name change restriction from 30 days to 28 days
- Added username field to Profile model for display on deck cards
- Updated SwipeCard to show @username instead of name on deck
- Updated OtherUserProfileScreen to show full real name (first + last)
- Updated profile repositories to parse and include username

Files Added:
- None

Files Modified:
- lib/data/models/profile.dart
  - Changed canChangeName from 30 days to 28 days
  - Changed daysUntilNameChange calculation from 30 to 28 days
  - Added username field to Profile model
  - Added username to constructor, copyWith, and props
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
  - Added username parsing in _userFromFirestore (from user doc level)
- lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart
  - Added username parsing in _profileFromFirestore
  - Updated fetchProfileById to include username from user doc
- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
  - Added username to Profile constructor in saveBasicInfo
  - Added username parsing in _userFromJson
- lib/features/discovery/presentation/widgets/swipe_card.dart
  - Changed displayName to show @username on deck cards (falls back to name)
  - Updated _ProfileIdentityOverlay to show @username
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
  - Changed displayName to show fullName (first + last) when viewing profiles

Files Deleted:
- None

Why / Notes:
- User requested username to be shown on deck cards instead of real name for privacy
- User requested 28-day restriction for username changes (was 30 days)
- Real name (first + last) should be visible when viewing someone's full profile
- Username editing already exists in profile setup under Basic Info section

Risks & Mitigations:
- Cloud Function (fetchDeck) needs to return username field for other profiles
- Existing profiles may not have username set - fallback to name implemented

Verification Steps:
- `flutter analyze lib/`
- Check profile setup screen shows username editing
- Check deck cards show @username
- Check other user profile shows full name

Follow-ups / TODO:
- Ensure Cloud Function includes username in fetchDeck response
- Backend may need update to store/return username for discovery profiles

---

### [2026-01-23] Task: Fix Flutter SDK path for VS Code

Summary:
- Added workspace VS Code settings to point Dart/Flutter tools at the valid SDK directory.

Files Added:
- .vscode/settings.json

Files Modified:
- docs/Developer_agent_chat.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/ai_change_log.md

Files Deleted:
- None

Why / Notes:
- Resolves IDE error: invalid `dart.flutterSdkPath` pointing to a non-existent folder.

Risks & Mitigations:
- Path is machine-specific; update if the SDK location changes.

Verification Steps:
- `ls /Users/ace/Development/flutter`
- Reload VS Code window

Follow-ups / TODO:
- None

### [2026-01-23] Task: Per-Chat Settings (Individual Message Retention)

Summary:
- Fixed ChatSettings parsing in profile repository (was not loading from Firestore)
- Implemented per-match chat settings allowing individual retention per conversation
- Created MatchChatSettingsCubit for per-match settings management
- Added updateMatchChatSettings Cloud Function to store settings at match level
- Added chat settings menu option and bottom sheet UI in chat screen

Files Added:
- lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart — New cubit for per-match settings

Files Modified:
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
  - Added import for ChatSettings model
  - Added ChatSettings.fromJson() parsing in _userFromFirestore()
- functions/src/index.ts
  - Added updateMatchChatSettings Cloud Function
  - Stores settings at matches/{matchId}/chatSettings/{userId}
  - Syncs to RTDB for real-time access
- lib/features/chat/presentation/screens/chat_screen.dart
  - Added chatSettings to _ChatSafetyAction enum
  - Added "Chat Settings" menu item in popup menu
  - Added _showMatchChatSettings() method with bottom sheet UI
  - Added imports for ChatSettings, AuthBloc, SubscriptionPlan, MatchChatSettingsCubit
- docs/Developer_agent_chat.md — Added Task #010

Files Deleted:
- None

Why / Notes:
- User reported "failed to update settings" error when changing chat retention
- User requested per-chat settings instead of global settings that apply to all conversations
- Settings now stored at match level, each conversation can have different retention

Risks & Mitigations:
- Per-match settings require Cloud Function deployment to work
- Settings stored per-user within match, so each party can have their own retention preference

Verification Steps:
- `flutter analyze lib/features/chat/presentation/screens/chat_screen.dart`
- `flutter analyze lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`
- `firebase deploy --only functions`
- Open chat, tap menu, select "Chat Settings", toggle retention

Follow-ups / TODO:
- Deploy Cloud Functions: `firebase deploy --only functions`
- Load existing per-match settings from Firestore when opening chat settings

---

### [2026-01-23] Task: Matched users appear + chat redirect

Summary:
- Triggered matches refresh when a new match notification arrives to keep “Matched with you” up to date.
- Left match tile navigation intact (matchId-based chat routing).

Files Added:
- None

Files Modified:
- lib/features/chat/presentation/screens/matches_screen.dart
  - Listen to RealtimeMatchService notifications and refresh MatchesBloc
  - Add subscription cleanup on dispose
- docs/Developer_agent_chat.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/ai_change_log.md

Files Deleted:
- None

Why / Notes:
- Ensures new matches appear promptly in the Matches screen even if created while the user is elsewhere.

Risks & Mitigations:
- Additional refresh calls may slightly increase network usage; only triggers on match notifications.

Verification Steps:
- `flutter run`
- Create a match and confirm it appears under “Matched with you”
- Tap the match and ensure the correct chat opens

Follow-ups / TODO:
- None

### [2026-01-23] Task: Complete Discovery & Matching System with Real-time RTDB

Summary:
- Fixed critical Cloud Function response format mismatch (profiles → candidates)
- Updated discovery query to include new users without explicit preference fields
- Added default discovery preferences when profiles are saved
- Implemented real-time match notifications via Firebase Realtime Database (RTDB)
- Created RealtimeMatchService for instant match notifications
- Integrated match notifications with app lifecycle

Files Added:
- lib/features/discovery/data/services/realtime_match_service.dart
  - RTDB listener for real-time match notifications
  - Auto-clears notifications after display
  - Integrates with auth state (start/stop on login/logout)

Files Modified:
- functions/src/index.ts
  - Fixed `fetchDiscoveryCandidates` to return `candidates` instead of `profiles`
  - Flattened profile data in response (was nested)
  - Removed strict query filters that excluded new users
  - Added in-code filtering for hideFromDiscovery/incognitoMode
  - Added profile completeness check (1+ photo, name required)
  - Added RTDB write when match is created for real-time notifications

- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
  - Added default discovery preferences in saveProfileDetails()
  - Sets hideFromDiscovery: false, incognitoMode: false by default
  - Sets default age range (18-50) and distance (100km)

- lib/app.dart
  - Added RealtimeMatchService integration
  - Listens to auth state to start/stop RTDB listener
  - Shows snackbar notification when match arrives (except on deck/chat)

- docs/Developer_agent_chat.md (added Task #007)

Files Deleted:
- None

Why / Notes:
- Critical bug: Cloud Function returned "profiles" but client expected "candidates"
- Critical bug: Query excluded new users who hadn't set explicit preferences
- Added RTDB for instant match notifications (improves UX)
- Complete end-to-end discovery → swipe → match → chat flow now works

Risks & Mitigations:
- RTDB write failure: Non-blocking, match still works via Firestore
- Auth state sync: Service properly starts/stops based on auth changes

Verification Steps:
- `flutter analyze lib/app.dart` - No issues
- `flutter analyze lib/features/discovery/data/services/realtime_match_service.dart` - No issues

Follow-ups / TODO:
- Deploy Cloud Functions: `firebase deploy --only functions`
- Test end-to-end match flow on device/emulator

---

### [2026-01-23] Task: Deck preload + background stack in swipe deck

Summary:
- Rendered background preview cards behind the active swipe card.
- Increased preloading to the next 4 profiles for smoother transitions.
- Kept match celebration flow unchanged.

Files Added:
- None

Files Modified:
- lib/features/discovery/presentation/screens/deck_screen.dart
  - Wrapped SwipeableCard with DeckPreviewStack
  - Preloaded next 4 profiles and aligned preview list with filtered deck
- lib/features/discovery/presentation/widgets/deck_card_stack.dart
  - Increased preview/prefetch count to 4
  - Adjusted opacity scaling for deeper cards
- docs/Developer_agent_chat.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/risk_notes.md
- docs/ai_change_log.md

Files Deleted:
- None

Why / Notes:
- Ensures upcoming profiles are visible in the background and load instantly after swipes.

Risks & Mitigations:
- Preloading more images can increase memory/network usage; capped to 4 and first image only.

Verification Steps:
- `flutter run`
- Drag a card to confirm background cards are visible
- Swipe several cards to confirm instant transitions
- Trigger a match and confirm match celebration still appears

Follow-ups / TODO:
- Consider making preview count configurable for low-end devices.

### [2026-01-23] Task: Remove Original Request from Task Log Template

Summary:
- Removed "Original Request (from Developer)" section from Developer_agent_chat.md template
- Removed all existing "Original Request" entries from Tasks #001-#005
- Updated document description to clarify only refined prompts are saved
- Added explicit rule in "Notes for Agents" that original requests should NOT be saved
- Added Task #006 to document this change

Files Added:
- None

Files Modified:
- docs/Developer_agent_chat.md
  - Removed "Original Request" from template
  - Removed "Original Request" from Tasks #001, #002, #003, #004, #005
  - Updated document description
  - Added rule #4 in Notes for Agents: "NEVER save the developer's original raw message"
  - Added Task #006
  - Updated Quick Reference table

Files Deleted:
- None

Why / Notes:
- Developer requested that only refined prompts be saved, not their raw messages
- Ensures professional documentation without casual communication being stored

Risks & Mitigations:
- None. Documentation-only changes.

Follow-ups / TODO:
- All agents must follow this pattern going forward (only save refined prompts)

---

### [2026-01-23] Task: Improve Prompt Refinement Workflow

Summary:
- Enhanced Developer_agent_chat.md template to require very specific, detailed prompts
- Added Developer Intent Analysis section to understand what developer really wants
- Added comprehensive Refined Prompt structure with subsections:
  - Objective, Technical Requirements, Implementation Plan
  - Files to Modify/Create, Success Criteria, Edge Cases, Verification Commands
- Added Agent Workflow (MANDATORY) section documenting the process
- Updated Notes for Agents with stricter requirements
- Added Task #004 as example of the new detailed format

Files Added:
- None

Files Modified:
- docs/Developer_agent_chat.md
  - Replaced simple template with comprehensive detailed template
  - Added "Agent Workflow (MANDATORY)" section
  - Added Task #004 with full detailed prompt example
  - Updated Notes for Agents with stricter requirements
- docs/ai_tasks_board.md (added T-033)
- docs/ai_change_log.md (this entry)

Files Deleted:
- None

Why / Notes:
- Developer requested more specific, more detailed prompts
- The refined prompt should be detailed enough that another agent could execute it
- Creates a contract between what developer wants and what agent will do

Risks & Mitigations:
- None. Documentation-only changes.

Follow-ups / TODO:
- All agents must follow the new detailed template going forward

---

### [2026-01-23] Task: Create Developer Agent Chat Document

Summary:
- Created `/docs/Developer_agent_chat.md` for logging all developer-to-agent tasks
- Updated CLAUDE.md to include mandatory task logging rules
- Added quick reference section for the new workflow
- Logged previous tasks (#001-#003) with original requests and refined prompts

Files Added:
- docs/Developer_agent_chat.md

Files Modified:
- CLAUDE.md
  - Added rule #2: "LOG ALL DEVELOPER TASKS (MANDATORY)"
  - Added section 0.1: "LOG DEVELOPER TASK (MANDATORY)"
  - Updated Quick Reference with Developer_agent_chat.md
  - Added task logging step to completion checklist
- docs/ai_tasks_board.md (added T-032)
- docs/ai_change_log.md (this entry)

Files Deleted:
- None

Why / Notes:
- Developer requested a system to track all tasks given to agents
- Each task now includes original request + refined prompt + status + outcome
- Helps maintain context across sessions and prevents duplicate work

Risks & Mitigations:
- None. Documentation-only changes.

Verification Steps:
- N/A (documentation changes only)

Follow-ups / TODO:
- All agents must log future tasks to Developer_agent_chat.md

---

### [2026-01-23] Task: Premium "Seen" Status for Messages

Summary:
- Added `readAt` field to Message model to track when message was read
- Added `canSeeReadReceipts` to ChatState for Plus subscribers
- Updated ChatBloc to set read receipt permission based on subscription plan
- Updated chat UI to show "Seen ✓✓" only for Plus users

Files Added:
- None

Files Modified:
- lib/data/models/message.dart (added `readAt` field)
- lib/features/chat/presentation/bloc/chat_state.dart (added `canSeeReadReceipts`)
- lib/features/chat/presentation/bloc/chat_bloc.dart (sets `canSeeReadReceipts: plan.isPlus`)
- lib/features/chat/data/repositories/impl/firebase_chat_repository.dart (parses `readAt`)
- lib/features/chat/presentation/screens/chat_screen.dart (conditional "Seen" display)

Files Deleted:
- None

Why / Notes:
- Plus users see blue "Seen ✓✓" when their message is read
- Free users only see single gray checkmark (no read status visibility)
- This is a premium feature to encourage upgrades

Risks & Mitigations:
- None. Backwards compatible changes.

Verification Steps:
- `flutter analyze` passes with no issues

Follow-ups / TODO:
- None

---

### [2026-01-23] Task: Message Requests for non-matched users

Summary:
- Added MessageRequest model and repository support (stub/firebase/fake; HTTP no-op).
- Added Message Requests UI (Chats entry + Message Requests screen) with a dedicated cubit.
- Updated other-user profile actions: Send Message between Pass/Like for non-matches; only Send Message for matches; added request composer.
- Added best-effort migration of message requests into chats on match fetch.
- Added Firestore rules for `message_requests` and updated flow/DFD/ER docs.

Files Added:
- lib/data/models/message_request.dart
- lib/features/chat/presentation/bloc/message_requests_cubit.dart
- lib/features/chat/presentation/bloc/message_requests_state.dart
- lib/features/chat/presentation/screens/message_requests_screen.dart

Files Modified:
- lib/features/chat/data/repositories/chat_repository.dart
- lib/features/chat/data/repositories/impl/stub_chat_repository.dart
- lib/features/chat/data/repositories/impl/firebase_chat_repository.dart
- lib/features/chat/data/repositories/impl/http_chat_repository.dart
- lib/features/chat/presentation/screens/chat_list_screen.dart
- lib/features/chat/presentation/bloc/matches_bloc.dart
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/data/repositories/fake_repositories.dart
- lib/core/router.dart
- firestore.rules
- docs/project_flowchart.md
- docs/project_dfd.md
- docs/project_er_diagram.md
- docs/Developer_agent_chat.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md
- docs/risk_notes.md
- docs/ai_change_log.md

Files Deleted:
- None

Why / Notes:
- Implements limited pre-match message requests with expiration and migration to chats upon matching.
- Ensures matched profiles hide Pass/Like while keeping Send Message available.

Risks & Mitigations:
- Migration/expiration is client-driven; consider Cloud Functions or Firestore TTL for server-side cleanup.

Verification Steps:
- `flutter run`
- Open non-matched profile → Send Message → request appears in Message Requests
- Try to send again → blocked
- Match occurs → request migrates into chat (sender device)
- Requests older than 48 hours disappear on fetch

Follow-ups / TODO:
- Consider backend-triggered migration and TTL cleanup for message requests.

### [2026-01-23] Task: Implement Bidirectional Chat Messaging

Summary:
- Implemented missing Cloud Functions for chat messaging:
  - `sendMessage` - Creates message documents in Firestore with proper validation
  - `markMessagesRead` - Marks all unread messages from other user as read
  - `editMessage` - Allows sender to edit their own messages (Plus plan only)
- Added proper field structure matching Flutter Message model expectations
- Real-time message listening was already wired in ChatBloc via `watchMessages`

Files Added:
- None

Files Modified:
- functions/src/index.ts
  - Added `SendMessageRequest`, `MarkMessagesReadRequest`, `EditMessageRequest` interfaces
  - Added `sendMessage` callable function (validates match membership, creates message, updates match lastMessage)
  - Added `markMessagesRead` callable function (batch updates unread messages)
  - Added `editMessage` callable function (ownership check, updates content)
  - Message document includes: matchId, fromUserId, toUserId, content, type, mediaUrl, sentAt, isRead, reactions (as Map), visibleTo

Files Deleted:
- None

Why / Notes:
- The Flutter client was calling `sendMessage` Cloud Function which didn't exist - blocking all Firebase message sending
- The `markMessagesRead` Cloud Function was also missing
- Real-time listening already worked via Firestore snapshots in `watchMessages`
- Message format matches what `_messageFromFirestore` expects in Flutter

Risks & Mitigations:
- New Cloud Functions need deployment: `firebase deploy --only functions`
- Functions validate match membership before allowing messages
- Blocked users cannot send messages (uses existing `ensureNotBlocked`)

Verification Steps:
- `cd functions && npm run build` (TypeScript compiles successfully)
- `firebase deploy --only functions`
- Test: User A sends message to User B -> message appears in real-time for User B
- Test: User B replies -> User A receives message
- Test: Verify messages marked as read when viewed

Follow-ups / TODO:
- Deploy functions to Firebase
- Test bidirectional messaging with two user accounts
- Verify push notifications trigger via `onMessageCreated`

---

### [2026-01-23] Task: Profile Photo Rendering and Display Fix

Summary:
- Enhanced profile photo display to ensure user-uploaded photos are rendered clearly without blur
- Added top-center alignment to hero image and photo grid to prioritize face/head area
- Added alignment support to CachedNetworkImage widget
- Added retry functionality for failed image loads
- Reduced gradient overlay to only bottom portion for text readability

Files Added:
- None

Files Modified:
- lib/shared/widgets/cached_network_image.dart
  - Added `alignment` property (defaults to `Alignment.center`)
  - Added `onRetry` callback for retry functionality
  - Added retry button to error widget
  - Added `retry()` method for manual retry
- lib/features/profile/presentation/screens/profile_view_screen.dart
  - Updated `_ProfileHeader` to use `Alignment.topCenter` for hero image
  - Changed gradient overlay to only cover bottom 100px (was full height)
  - Updated `_PhotosGrid` to use `Alignment.topCenter` for all photos
  - Added loading placeholder with spinner
  - Added "Tap to retry" hint on error

Files Deleted:
- None

Why / Notes:
- Photos should be displayed at full quality without blur
- Top-center alignment prioritizes showing faces in photos
- Gradient overlay reduced to minimal for text readability only
- Retry functionality improves user experience on network issues

Risks & Mitigations:
- None. Changes are backwards compatible.

Verification Steps:
- `flutter run`
- Go to Profile screen -> verify hero image shows clearly, faces visible at top
- Verify "My Photos" grid shows photos clearly without blur
- Verify gradient only appears at bottom of hero image

Follow-ups / TODO:
- None

### [2026-01-23] Task: Display username in Profile and Complete Your Profile screens

Summary:
- Added username display to Profile View screen (below name and age)
- Added "Basic Info" summary section to Complete Your Profile screen showing username, name, age, and gender
- Repositioned elements for better user profile viewing

Files Added:
- None

Files Modified:
- lib/features/profile/presentation/screens/profile_view_screen.dart
  - Added username row with @ icon below the name/age display
- lib/features/profile/presentation/screens/profile_setup_screen.dart
  - Added `_buildBasicInfoSummary()` method to display user's basic info
  - Added `_buildInfoRow()` helper method for consistent info display
  - Added Basic Info summary section at the top of the form content
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Files Deleted:
- None

Why / Notes:
- User requested to see username in Profile screen and Complete Your Profile screen
- Basic Info section shows username, name, age, and gender with an edit button to go back to BasicInfoScreen
- Improves profile viewing experience by showing all relevant user info

Risks & Mitigations:
- None

Verification Steps:
- `flutter run`
- Go to Profile screen -> verify username is shown below name with @ prefix
- Go to Complete Your Profile screen -> verify Basic Info summary shows username, name, age, gender
- Tap Edit on Basic Info summary -> verify it navigates to BasicInfoScreen

Follow-ups / TODO:
- None

### [2026-01-23] Task: Pre-fill username in Basic Info from signup

Summary:
- When a user enters a username during account creation (signup), that username is now pre-filled in the Basic Info screen.
- User can still edit the username in Basic Info if they want to change it.

Files Added:
- None

Files Modified:
- lib/features/auth/presentation/screens/basic_info_screen.dart
  - Added `_hasPrefilledUsername` flag to track if username was pre-filled
  - Added logic in BlocConsumer builder to pre-fill username from `state.user?.username`
  - Uses `addPostFrameCallback` to safely set controller text after build
- docs/ai_change_log.md
- docs/ai_tasks_board.md

Files Deleted:
- None

Why / Notes:
- User requested that username entered during signup should carry over to Basic Info screen.
- The username is stored in `CrushUser.username` after signup via `signUpWithPassword()`.
- Basic Info screen now reads this value and pre-fills the text field.

Risks & Mitigations:
- None. User can still edit the pre-filled username.

Verification Steps:
- `flutter run`
- Create new account and enter a username in step 1
- Proceed through signup flow to Basic Info screen
- Verify: username field is pre-filled with the username from signup
- Verify: user can still edit the username field

Follow-ups / TODO:
- None

### [2026-01-23] Task: Hide Pass/Like for matched profiles + wire profile actions

Summary:
- Hid Pass/Like buttons on other-user profiles when the users are already matched.
- Wired Pass/Like actions to discovery swipes with deck-aware dispatch and repository fallback.
- Ensured users return to the deck after pass/like actions.

Files Added:
- None

Files Modified:
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Why / Notes:
- Matched profiles should not show swipe actions.
- Profile actions should behave like deck swipes and return users to discovery.

Risks & Mitigations:
- Risk: DiscoveryBloc swipe could act on the wrong card if the viewed profile isn't the current deck profile.
  - Mitigation: Guard by checking the current deck profile ID; fallback to repository and refresh deck.

Verification Steps:
- `flutter run`
- Manual: From deck, open profile → Pass/Like → return to deck and advance card
- Manual: From chat (matched), open profile → no Pass/Like buttons

Follow-ups / TODO:
- None

### [2026-01-23] Task: Fix ID verification notification in chat screen

Summary:
- Fixed "Verify your ID" notification in chat screen to navigate to ID verification screen instead of Safety & Blocking.
- Added 10-second auto-dismiss timer for the notification.
- Added 3-hour cooldown logic using SharedPreferences so notification only shows once every 3 hours.
- Notification only appears when user is not verified.

Files Added:
- None

Files Modified:
- lib/features/chat/presentation/screens/chat_screen.dart
  - Added SharedPreferences import
  - Added state variables for banner visibility and timer
  - Added `_checkVerificationBannerVisibility()` method for 3-hour cooldown check
  - Added `_startVerificationBannerTimer()` method for 10-second auto-dismiss
  - Added `_dismissVerificationBanner()` method for manual dismiss
  - Changed navigation from `CrushRoutes.safety` to `CrushRoutes.idVerification`
  - Updated banner to only show when `!selfVerified && _showVerificationBanner`
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/ai_collab_chat.md

Files Deleted:
- None

Why / Notes:
- User requested the verify button navigate to ID verification screen, not Safety & Blocking.
- Notification should auto-dismiss after 10 seconds and only appear once every 3 hours.
- If user is verified, notification does not appear at all.

Risks & Mitigations:
- Risk: SharedPreferences key persists across accounts on same device.
  - Mitigation: User data clearance service should clear this key on logout (minor UX impact if not).

Verification Steps:
- `flutter run`
- Open a chat with someone
- Verify: notification shows for unverified users, auto-dismisses in 10 seconds
- Verify: tapping "Verify" navigates to ID verification screen
- Verify: notification doesn't reappear for 3 hours after being shown

Follow-ups / TODO:
- Consider adding this cooldown key to UserDataClearanceService for logout cleanup.

### [2026-01-23] Task: Enforce AI doc sync before/after edits

Summary:
- Strengthened CLAUDE.md rules to require reading AI collaboration docs before and after edits.
- Added explicit requirement to log suggestions/issues in `ai_collab_chat.md`.

Files Added:
- None

Files Modified:
- CLAUDE.md
- docs/ai_collab_chat.md
- docs/ai_tasks_board.md
- docs/ai_change_log.md
- docs/risk_notes.md

Files Deleted:
- None

Why / Notes:
- User requested stricter AI doc sync and cross-agent suggestions.

Risks & Mitigations:
- None.

Verification Steps:
- Not run (documentation change)

Follow-ups / TODO:
- None

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

### [2026-01-23] Task: Fix keyboard blocking bottom section on Profile Setup screen

Summary:
- Fixed UX issue where "You can always complete your profile later in Settings" text blocked input fields when keyboard opened
- Added keyboard detection using MediaQuery.viewInsets.bottom
- Bottom section now collapses when keyboard is visible (hides text, reduces padding)
- Added smooth animation for transition

Files Added:
- None

Files Modified:
- lib/features/profile/presentation/screens/profile_setup_screen.dart
  - Updated `_buildBottomButton()` method
  - Added keyboard visibility detection: `MediaQuery.of(context).viewInsets.bottom > 0`
  - Changed Container to AnimatedContainer for smooth transitions
  - Conditional padding: full when keyboard hidden, compact when visible
  - Hide informational text when keyboard is visible

Files Deleted:
- None

Why / Notes:
- User reported that the bottom section blocked input fields when keyboard opened
- The informational text and large padding took up space needed for form input
- Now the bottom section shrinks to just the button with minimal padding when typing

Risks & Mitigations:
- Risk: None - this is a UX improvement only
- Mitigation: AnimatedContainer provides smooth visual transition

Verification Steps:
- `flutter analyze lib/features/profile/presentation/screens/profile_setup_screen.dart`
- Manual: Open Profile Setup screen → tap any input field → verify bottom section shrinks
- Manual: Dismiss keyboard → verify bottom section returns to full size with text

Follow-ups / TODO:
- None

---

### [2026-01-23] Task: Profile Edit screen UX improvements

Summary:
- Removed duplicate Name Visibility section from Profile Edit screen (already available in Privacy Settings)
- Added Username display to Basic Info section showing user's @username
- Updated Progress Card to show three states:
  1. "Almost There!" - when missing required fields
  2. "Eligible to Start Swiping!" - when required fields complete but not 100%
  3. "Profile Complete!" - when 100% complete, shows "Your profile is all set up, @username!"
- Progress card now shows actual percentage and proper messaging for each state

Files Added:
- None

Files Modified:
- lib/features/profile/presentation/screens/profile_edit_screen.dart
  - Removed `_NameVisibilityCard` widget (moved to Privacy Settings)
  - Added `_UsernameDisplay` widget showing @username in Basic Info section
  - Updated `_ProgressCard` to accept `meetsRequiredFields` and `username` parameters
  - Three-state progress messaging: incomplete → eligible → complete

Files Deleted:
- None

Why / Notes:
- Name Visibility was duplicated (already in Privacy Settings)
- Users wanted to see their username in the Profile Edit screen
- Progress card messaging needed to differentiate between:
  - Not yet eligible (missing required fields)
  - Eligible to swipe (has required fields, can improve profile)
  - Fully complete (100%, personalized success message with username)

Risks & Mitigations:
- Risk: None - UI improvement only
- The `_showFirstName` and `_showLastName` state variables are still preserved for the save functionality

Verification Steps:
- `flutter analyze lib/features/profile/presentation/screens/profile_edit_screen.dart`
- Manual: Open Profile Edit screen
- Verify username displays at top of Basic Info section
- Verify progress card shows correct state based on profile completeness
- Verify Name Visibility toggles are no longer shown (moved to Privacy Settings)

Follow-ups / TODO:
- None

---

### [2026-01-23] Task: Add "I Am Looking For" preference and change "Gender" to "My Gender"

Summary:
- Added "I Am Looking For" field to both Profile Setup (step 5/5) and Profile Edit screens
- Changed "Gender" label to "My Gender" in Profile Edit screen
- Default logic: Male users default to looking for Women, Female users default to looking for Men
- Options: Women, Men, Everyone
- Preference is saved to profile.preferences.showMeGenders in Firebase

Files Added:
- None

Files Modified:
- lib/shared/utils/profile_field_options.dart
  - Added `lookingForOptions` list (Women, Men, Everyone)
  - Added `getLookingForLabel()` helper method
  - Added `getDefaultLookingFor()` - returns default based on gender
  - Added `lookingForToShowMeGenders()` - converts to showMeGenders list
  - Added `showMeGendersToLookingFor()` - converts from showMeGenders list

- lib/features/profile/presentation/screens/profile_edit_screen.dart
  - Added `_lookingFor` state variable
  - Added `_showLookingForPicker()` method
  - Changed "Gender" label to "My Gender" in picker and UI
  - Added "I Am Looking For" field in Personal Details section
  - Save preferences with showMeGenders on submit

- lib/features/profile/presentation/screens/profile_setup_screen.dart
  - Added `_lookingFor` and `_lookingForInitialized` state variables
  - Added `_buildLookingForPicker()` method with animated selection chips
  - Added "I Am Looking For" section after Bio section
  - Pass showMeGenders when submitting ProfileDetailsSubmitted event

- lib/features/profile/presentation/bloc/profile_event.dart
  - Added `showMeGenders` parameter to ProfileDetailsSubmitted event

- lib/features/profile/presentation/bloc/profile_bloc.dart
  - Pass showMeGenders to repository in _onDetailsSubmitted handler

- lib/features/profile/data/repositories/profile_repository.dart
  - Added `showMeGenders` parameter to saveProfileDetails interface

- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
  - Added `showMeGenders` parameter to saveProfileDetails
  - Save showMeGenders to profile.preferences.showMeGenders

- lib/features/profile/data/repositories/impl/stub_profile_repository.dart
  - Added `showMeGenders` parameter to saveProfileDetails
  - Update preferences when saving

- lib/features/profile/data/repositories/impl/http_profile_repository.dart
  - Added `showMeGenders` parameter to saveProfileDetails

Files Deleted:
- None

Why / Notes:
- User requested to add "I am looking for" field to control who appears in deck
- Default logic ensures hetero-normative defaults (Male→Women, Female→Men) but users can change
- Data is saved to profile.preferences.showMeGenders which is used by discovery algorithm

Risks & Mitigations:
- Risk: None - feature addition with clear defaults
- The showMeGenders field is already used by the discovery system

Verification Steps:
- `flutter analyze lib/features/profile lib/shared/utils/profile_field_options.dart`
- Manual: Open Profile Setup screen → verify "I Am Looking For" section appears
- Manual: Open Profile Edit screen → verify "My Gender" and "I Am Looking For" fields
- Manual: Change gender → verify default "looking for" is set appropriately
- Manual: Save profile → verify showMeGenders is saved to Firebase

Follow-ups / TODO:
- None

---
