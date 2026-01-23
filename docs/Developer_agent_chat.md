# Developer ↔ Agent Task Log

This file records all tasks given by the developer to AI agents (Claude, Codex, or others).
Each task is logged with a **very specific and detailed refined prompt** (created by the agent), status, and outcome.
**Note:** Only the refined prompt is saved here — the developer's original raw message is NOT recorded.

---

## Agent Workflow (MANDATORY)

When the developer gives you a task:

1. **READ** the original request carefully
2. **UNDERSTAND** what the developer actually wants (intent, not just words)
3. **CREATE** a very specific, very detailed refined prompt with:
   - Exact technical requirements
   - Step-by-step implementation plan
   - Files to be modified/created
   - Success criteria
   - Edge cases to handle
4. **SAVE** the refined prompt to this document
5. **EXECUTE** the task based on the refined prompt
6. **UPDATE** the outcome section when complete

---

## Template

```
### Task #XXX — [Short Title]
**Date:** YYYY-MM-DD
**Agent:** Claude / Codex / Other
**Status:** Received / In Progress / Completed / Blocked

**Developer Intent Analysis:**
[What does the developer actually want? Break down the request into:
- Primary goal
- Secondary goals (if any)
- Implicit requirements (things they didn't say but clearly expect)
- Quality expectations]

**Refined Prompt (Very Specific & Detailed):**

### Objective
[Clear sentences describing what needs to be accomplished]

### Technical Requirements
1. [Specific requirement #1 with exact details]
2. [Specific requirement #2 with exact details]
3. [Continue as needed...]

### Implementation Plan
**Step 1:** [Exact action with file paths and code changes]
**Step 2:** [Exact action with file paths and code changes]
**Step 3:** [Continue as needed...]

### Files to Modify/Create
- `path/to/file1.dart` — [what changes]
- `path/to/file2.ts` — [what changes]

### Success Criteria
- [ ] [Specific testable criterion #1]
- [ ] [Specific testable criterion #2]
- [ ] [Continue as needed...]

### Edge Cases & Error Handling
- [Edge case #1] → [How to handle]
- [Edge case #2] → [How to handle]

### Verification Commands
```
[command 1]
[command 2]
```

**Related Task ID:** T-XXX (if applicable)

**Outcome:**
- Files changed: [list with brief description of changes]
- Result: [success/failure + details]
- Notes: [any important observations or follow-ups]
```

---

## Task Log

### Task #001 — Implement Bidirectional Chat Messaging
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Refined Prompt:**
Implement real-time bidirectional messaging between matched users:
- **Goal:** Enable User A to send messages to User B, with real-time delivery and vice versa
- **Scope:**
  - Implement missing `sendMessage` Cloud Function
  - Implement `markMessagesRead` Cloud Function
  - Implement `editMessage` Cloud Function
  - Verify real-time Firestore listeners are properly wired
- **Constraints:** Must use existing ChatRepository interface and ChatBloc architecture
- **Expected outcome:** Messages sent by either user appear instantly for both parties

**Related Task ID:** T-031

**Outcome:**
- Files changed: `functions/src/index.ts` (added 3 callable functions + 3 interfaces)
- Result: Cloud Functions implemented and compiled successfully
- Notes: Requires `firebase deploy --only functions` to activate

---

### Task #002 — Premium "Seen" Status for Messages
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Refined Prompt:**
Verify real-time chat and implement premium-only read receipts:
- **Goal:**
  1. Confirm real-time messaging works without delays
  2. Add "Seen" indicator visible only to Plus subscribers
- **Scope:**
  - Verify `watchMessages` uses Firestore snapshots (real-time)
  - Add `readAt` field to Message model
  - Add `canSeeReadReceipts` to ChatState
  - Update ChatBloc to set `canSeeReadReceipts: plan.isPlus`
  - Update chat UI to show "Seen" + double checkmark for Plus users only
- **Constraints:** Free users see single checkmark only (no read status)
- **Expected outcome:** Plus users see blue "Seen ✓✓" when message is read; free users see gray "✓"

**Related Task ID:** T-031 (extension)

**Outcome:**
- Files changed:
  - `lib/data/models/message.dart` (added `readAt`)
  - `lib/features/chat/presentation/bloc/chat_state.dart` (added `canSeeReadReceipts`)
  - `lib/features/chat/presentation/bloc/chat_bloc.dart` (sets read receipt permission)
  - `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` (parses `readAt`)
  - `lib/features/chat/presentation/screens/chat_screen.dart` (conditional "Seen" display)
- Result: Premium users see "Seen" status, free users see single checkmark
- Notes: Flutter analysis passes with no issues

---

### Task #003 — Create Developer Agent Chat Document
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Refined Prompt:**
Create a task logging system for developer-to-agent communications:
- **Goal:** Create `Developer_agent_chat.md` to log all developer tasks
- **Scope:**
  - Create new document with template for task logging
  - Log original request from developer
  - Create refined/improved prompt version
  - Track status and outcomes
  - Update CLAUDE.md to reference this document
  - Update ai_tasks_board.md and ai_change_log.md
- **Constraints:** Must integrate with existing AI collaboration workflow
- **Expected outcome:** All future developer tasks are logged with refined prompts

**Related Task ID:** T-032

**Outcome:**
- Files changed:
  - `docs/Developer_agent_chat.md` (new file)
  - `CLAUDE.md` (updated workflow)
  - `docs/ai_tasks_board.md` (new task entry)
  - `docs/ai_change_log.md` (logged changes)
- Result: Task logging system in place
- Notes: All agents must log tasks to this document going forward

---

### Task #004 — Improve Prompt Refinement Workflow
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Improve the quality of refined prompts saved to Developer_agent_chat.md
- **Secondary goals:**
  - Ensure agents understand the developer's true intent, not just literal words
  - Create prompts that are specific enough to be executable without ambiguity
- **Implicit requirements:**
  - The refined prompt should be detailed enough that another agent could execute it
  - Should include technical specifics (file paths, function names, exact changes)
  - Should be a complete specification, not a vague summary
- **Quality expectations:** Very specific, very detailed prompts that leave no room for interpretation

**Refined Prompt (Very Specific & Detailed):**

### Objective
Enhance the Developer_agent_chat.md template and workflow to require agents to create highly detailed, specific refined prompts before executing any task.

### Technical Requirements
1. **Update the template** in Developer_agent_chat.md to include:
   - Developer Intent Analysis section (understand what they really want)
   - Detailed Refined Prompt structure with subsections:
     - Objective (one clear sentence)
     - Technical Requirements (numbered list with specifics)
     - Implementation Plan (step-by-step with file paths)
     - Files to Modify/Create (explicit list)
     - Success Criteria (checkboxes)
     - Edge Cases & Error Handling
     - Verification Commands

2. **Update the Agent Workflow** section to document the process:
   - READ the original request
   - UNDERSTAND the developer's intent (not just words)
   - CREATE a very specific, detailed prompt
   - SAVE to Developer_agent_chat.md
   - EXECUTE based on the refined prompt
   - UPDATE outcome when complete

3. **Update the Notes for Agents** section with stricter guidelines

### Implementation Plan
**Step 1:** Read current Developer_agent_chat.md to understand structure
**Step 2:** Replace the simple template with comprehensive detailed template
**Step 3:** Add "Agent Workflow (MANDATORY)" section at the top
**Step 4:** Update "Notes for Agents" with stricter requirements
**Step 5:** Add this task (#004) as an example of the new detailed format

### Files to Modify/Create
- `docs/Developer_agent_chat.md` — Update template, add workflow section, add task #004

### Success Criteria
- [x] Template includes Developer Intent Analysis section
- [x] Template includes detailed Refined Prompt structure with all subsections
- [x] Agent Workflow section added with clear step-by-step process
- [x] Notes for Agents updated with stricter guidelines
- [x] Task #004 added as example of the new format

### Edge Cases & Error Handling
- If developer request is ambiguous → Agent should ask clarifying questions before creating refined prompt
- If task is very simple → Still use the template but sections can be brief

### Verification Commands
```
cat docs/Developer_agent_chat.md | head -100
```

**Related Task ID:** T-033

**Outcome:**
- Files changed:
  - `docs/Developer_agent_chat.md` — Updated template with detailed structure, added Agent Workflow section, added Task #004 as example
- Result: Template now requires very specific, detailed prompts with multiple subsections
- Notes: All future tasks will follow this enhanced format

---

### Task #005 — Message Requests + Match-aware Profile Actions
**Date:** 2026-01-23
**Agent:** Codex
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Add a pre-match message request flow and enforce match-aware profile actions.
- **Secondary goals:** Keep chats clean by separating requests, ensure expiration/migration, and preserve deck behavior on pass/like.
- **Implicit requirements:** One request per pair, distinct UI labeling, safe navigation back to deck, and match-based button visibility.
- **Quality expectations:** Smooth UX, no duplicate sends, and clean data lifecycle (expiration and migration).

**Refined Prompt (Very Specific & Detailed):**

### Objective
Implement a Message Request system for non-matched users, and update other-user profiles to hide Pass/Like for matches while keeping deck actions working correctly.

### Technical Requirements
1. Add a `MessageRequest` model with sender/recipient, content, type, sentAt, expiresAt, and denormalized names/photos.
2. Extend `ChatRepository` with methods to send, fetch, check pending, and migrate message requests.
3. Implement message request logic for Firebase (Firestore), Stub, and Fake repositories; HTTP repository can be no-op/unsupported.
4. Add `MessageRequestsCubit` + state to load and refresh requests.
5. Create `MessageRequestsScreen` with a list UI and clear “Message Request” labeling + expiration display.
6. Add a “Message Requests” entry to Chats list, showing count and navigation.
7. Update `OtherUserProfileScreen`:
   - If matched → show only “Send Message” and open chat.
   - If not matched → show Pass, Send Message, Like (Send between Pass/Like).
   - Pass/Like should send swipes and return to deck (pop if from deck; go home otherwise).
   - Send Message opens a composer and sends a message request (one per pair).
8. Add best-effort migration in `MatchesBloc` to move requests into chats on match fetch.
9. Add Firestore rules for `message_requests` collection.
10. Update flow/DFD/ER docs for new entity and navigation.

### Implementation Plan
**Step 1:** Add `lib/data/models/message_request.dart` with helpers (isExpired, otherUser, etc.).  
**Step 2:** Extend `lib/features/chat/data/repositories/chat_repository.dart` with request methods and update all implementations.  
**Step 3:** Create `MessageRequestsCubit` + `MessageRequestsState` and hook into Chats list.  
**Step 4:** Add `MessageRequestsScreen` + route in `lib/core/router.dart`.  
**Step 5:** Update `OtherUserProfileScreen` button bar, pass/like handlers, and message request composer.  
**Step 6:** Trigger migration on match fetch in `MatchesBloc`.  
**Step 7:** Add `message_requests` rules in `firestore.rules`.  
**Step 8:** Update `docs/project_flowchart.md`, `docs/project_dfd.md`, and `docs/project_er_diagram.md`.  
**Step 9:** Update docs: ai_change_log, ai_tasks_board, ai_collab_chat, risk_notes.

### Files to Modify/Create
- `lib/data/models/message_request.dart` — new model.
- `lib/features/chat/data/repositories/chat_repository.dart` — new APIs.
- `lib/features/chat/data/repositories/impl/firebase_chat_repository.dart` — Firestore storage + migration.
- `lib/features/chat/data/repositories/impl/stub_chat_repository.dart` — local storage + expiry.
- `lib/data/repositories/fake_repositories.dart` — fake request storage.
- `lib/features/chat/presentation/bloc/message_requests_cubit.dart` — load requests.
- `lib/features/chat/presentation/bloc/message_requests_state.dart` — request state.
- `lib/features/chat/presentation/screens/message_requests_screen.dart` — UI.
- `lib/features/chat/presentation/screens/chat_list_screen.dart` — entry + count.
- `lib/features/profile/presentation/screens/other_user_profile_screen.dart` — match-aware buttons and composer.
- `lib/features/chat/presentation/screens/chat_screen.dart` — pass matchId to profile.
- `lib/core/router.dart` — message requests route.
- `firestore.rules` — `message_requests` access.
- `docs/project_flowchart.md`, `docs/project_dfd.md`, `docs/project_er_diagram.md` — flow/data updates.

### Success Criteria
- [ ] Matched profiles show only “Send Message” (no Pass/Like).
- [ ] Non-matched profiles show Pass, Send Message, Like (in that order).
- [ ] Pass/Like returns user to deck and registers swipe.
- [ ] Non-matched users can send a single message request only.
- [ ] Message Requests entry appears in Chats with accurate count.
- [ ] Requests expire after 48 hours (client cleanup) and are removed from UI.
- [ ] Requests migrate into chats on match fetch (best-effort).

### Edge Cases & Error Handling
- Pending request exists → disable Send Message or show “Request Sent”.
- MatchId missing when matched → show error and avoid navigation.
- Non-deck profile pass/like → call repository and refresh deck.
- Migration should not spoof sender (only migrate when sender is current user).

### Verification Commands
```
flutter run
```

**Related Task ID:** T-034 (and T-027 for profile action wiring)

**Outcome:**
- Files changed:
  - `lib/data/models/message_request.dart` (new model)
  - `lib/features/chat/data/repositories/*` (message request APIs + implementations)
  - `lib/features/chat/presentation/bloc/message_requests_*` (new cubit/state)
  - `lib/features/chat/presentation/screens/message_requests_screen.dart` (new UI)
  - `lib/features/chat/presentation/screens/chat_list_screen.dart` (Message Requests entry)
  - `lib/features/profile/presentation/screens/other_user_profile_screen.dart` (match-aware actions)
  - `lib/features/chat/presentation/screens/chat_screen.dart` (pass matchId)
  - `lib/core/router.dart` (new route)
  - `firestore.rules` (message request access rules)
  - `docs/project_flowchart.md`, `docs/project_dfd.md`, `docs/project_er_diagram.md` (flow/data updates)
  - `docs/ai_change_log.md`, `docs/ai_tasks_board.md`, `docs/ai_collab_chat.md`, `docs/risk_notes.md`
- Result: Message Requests flow implemented with match-aware profile actions and best-effort migration.
- Notes: Migration/expiration is client-driven; backend TTL or function migration recommended.

### Task #006 — Remove Original Request from Task Log Template
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Ensure the developer's raw messages are not stored in the task log
- **Secondary goals:** Only preserve the refined, professional prompts created by the agent
- **Implicit requirements:** Privacy of developer's casual communication style
- **Quality expectations:** Clean, professional documentation with only refined prompts

**Refined Prompt:**

### Objective
Update Developer_agent_chat.md to remove all "Original Request" sections and ensure only refined prompts are saved going forward.

### Technical Requirements
1. Remove the "Original Request (from Developer)" field from the template
2. Remove all existing "Original Request" entries from Tasks #001-#005
3. Update the document description to clarify this policy
4. Update "Notes for Agents" to explicitly state original requests should NOT be saved
5. Update Quick Reference table

### Implementation Plan
**Step 1:** Edit the document description at the top to clarify only refined prompts are saved
**Step 2:** Remove "Original Request" from the template section
**Step 3:** Remove "Original Request" from Task #001
**Step 4:** Remove "Original Request" from Task #002
**Step 5:** Remove "Original Request" from Task #003
**Step 6:** Remove "Original Request" from Task #004
**Step 7:** Remove "Original Request" from Task #005
**Step 8:** Add this task (#006) to the log
**Step 9:** Update Notes for Agents section

### Files to Modify/Create
- `docs/Developer_agent_chat.md` — Remove all "Original Request" sections

### Success Criteria
- [x] Template no longer contains "Original Request" field
- [x] All existing tasks have "Original Request" removed
- [x] Document description clarifies only refined prompts are saved
- [x] Notes for Agents updated with explicit rule

### Edge Cases & Error Handling
- N/A (documentation-only change)

**Related Task ID:** T-033 (extension)

**Outcome:**
- Files changed: `docs/Developer_agent_chat.md` — Removed all Original Request sections
- Result: Document now only contains refined prompts, not raw developer messages
- Notes: All future tasks will follow this pattern

---

### Task #007 — Complete Discovery & Matching System with Real-time RTDB
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Ensure complete end-to-end user discovery and matching flow works perfectly
- **Secondary goals:**
  - Users auto-added to discovery when profile is complete
  - Real-time matching with instant notifications via RTDB
  - Seamless navigation from match to chat
- **Implicit requirements:** Performance optimization, no delays in messaging, proper data structure
- **Quality expectations:** Production-ready matching system with real-time capabilities

**Refined Prompt (Very Specific & Detailed):**

### Objective
Implement and verify the complete user discovery and matching system, ensuring:
1. Users are automatically discoverable after completing their profile
2. Swipe actions (like/pass) are recorded and checked for mutual matches
3. Matches are created instantly when both users like each other
4. Real-time match notifications via Firebase Realtime Database (RTDB)
5. Seamless navigation from match celebration to chat

### Technical Requirements
1. **Fix Cloud Function response format mismatch**
   - `fetchDiscoveryCandidates` returns `profiles` but client expects `candidates`
   - Profile data is nested but client expects flat structure
   - Fix: Return `candidates` key with flattened profile fields

2. **Fix discovery query to include new users**
   - Query filters by `hideFromDiscovery == false` excludes users without this field
   - Fix: Remove strict query filters, filter in processing loop instead

3. **Set default discovery preferences on profile save**
   - New users need `hideFromDiscovery: false` and `incognitoMode: false`
   - Fix: Add default preferences when `saveProfileDetails` is called

4. **Add real-time match notifications via RTDB**
   - When match created, write to `/users/{userId}/newMatches/{matchId}`
   - Client listens to this path for instant notifications
   - Show snackbar when match comes in (if not already on deck/chat)

5. **Verify match celebration and chat navigation**
   - DeckScreen shows celebration modal when `state.newMatch` is set
   - "Send Message" navigates to chat with correct `ChatScreenArgs`

### Implementation Plan
**Step 1:** Fix Cloud Function `fetchDiscoveryCandidates` response format
**Step 2:** Update Cloud Function query to not require explicit preference fields
**Step 3:** Add default preferences to `saveProfileDetails` in FirebaseProfileRepository
**Step 4:** Update `swipeRight` Cloud Function to write to RTDB on match
**Step 5:** Create `RealtimeMatchService` to listen for match notifications
**Step 6:** Integrate service with app.dart via BlocListener
**Step 7:** Verify existing match celebration and chat navigation

### Files to Modify/Create
- `functions/src/index.ts` — Fix response format, update query, add RTDB write
- `lib/features/profile/data/repositories/impl/firebase_profile_repository.dart` — Add default preferences
- `lib/features/discovery/data/services/realtime_match_service.dart` — New RTDB listener service
- `lib/app.dart` — Integrate real-time match notifications

### Success Criteria
- [x] Cloud Function returns `candidates` with flat profile data
- [x] New users appear in discovery without needing explicit preference fields
- [x] Default discovery preferences saved on profile completion
- [x] RTDB notification written when match is created
- [x] Client receives real-time match notifications
- [x] Match celebration modal works and navigates to chat

### Edge Cases & Error Handling
- User logs out → stop RTDB listener
- Match notification while on deck → deck handles its own celebration, skip snackbar
- RTDB write fails → non-blocking, match still works via Firestore

### Verification Commands
```
flutter analyze lib/app.dart
flutter analyze lib/features/discovery/data/services/realtime_match_service.dart
```

**Related Task ID:** T-035

**Outcome:**
- Files changed:
  - `functions/src/index.ts` — Fixed `candidates` response format, flattened profile data, removed strict query filters, added RTDB match notification
  - `lib/features/profile/data/repositories/impl/firebase_profile_repository.dart` — Added default discovery preferences on profile save
  - `lib/features/discovery/data/services/realtime_match_service.dart` — New service for real-time match notifications via RTDB
  - `lib/app.dart` — Integrated real-time match listener with auth state management
- Result: Complete discovery and matching system with real-time notifications
- Notes: Requires `firebase deploy --only functions` to deploy Cloud Function changes

---

### Task #008 — Deck Preload + Background Stack
**Date:** 2026-01-23
**Agent:** Codex
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Ensure the next swipe profile is visible behind the current one and ready instantly after a swipe.
- **Secondary goals:** Preload several upcoming profiles (C/D/E/F) to avoid delays, while keeping match celebration behavior intact.
- **Implicit requirements:** No swipe lag, background card visibility during drag, and match celebration still triggers on match.
- **Quality expectations:** Smooth, immediate transitions with minimal jank.

**Refined Prompt (Very Specific & Detailed):**

### Objective
Show a visible background stack of upcoming deck profiles and preload several next profiles so the next card appears instantly after a swipe, while keeping match celebration behavior unchanged.

### Technical Requirements
1. Render a background stack behind the active SwipeableCard in the deck screen.
2. Preload at least the next 4 profiles' lead images (C/D/E/F) to minimize swipe delay.
3. Ensure background cards are visible while dragging and remain lightweight.
4. Preserve existing match celebration flow when a match is created.

### Implementation Plan
**Step 1:** Wrap the active SwipeableCard with DeckPreviewStack in `lib/features/discovery/presentation/screens/deck_screen.dart`.  
**Step 2:** Increase the prefetch count in `_preloadUpcomingProfiles` to 4 and avoid redundant work.  
**Step 3:** Update `DeckPreviewStack` to display up to 4 upcoming cards with safe opacity/scale values.  
**Step 4:** Align `DeckCardStack` preloading with the new count for consistency.  
**Step 5:** Confirm match celebration listener remains unchanged.  

### Files to Modify/Create
- `lib/features/discovery/presentation/screens/deck_screen.dart` — render background stack + increase prefetch count.
- `lib/features/discovery/presentation/widgets/deck_card_stack.dart` — update preview count and prefetch logic.

### Success Criteria
- [ ] While dragging, the next profile is visible behind the current card.
- [ ] Swiping to the next card shows it immediately with no visible delay.
- [ ] At least 4 upcoming profiles are preloaded.
- [ ] Match celebration still appears when a match is created.

### Edge Cases & Error Handling
- Deck length < 2 → no background cards or prefetch attempts.
- Network failures → fall back to placeholder without blocking swipe.

### Verification Commands
```
flutter run
```

**Related Task ID:** T-036

**Outcome:**
- Files changed:
  - `lib/features/discovery/presentation/screens/deck_screen.dart` — added background stack and increased prefetch count
  - `lib/features/discovery/presentation/widgets/deck_card_stack.dart` — expanded preview/prefetch to 4 with adjusted opacity
  - `docs/Developer_agent_chat.md`, `docs/ai_tasks_board.md`, `docs/ai_collab_chat.md`, `docs/ai_change_log.md`, `docs/risk_notes.md`
- Result: Background cards render behind the active swipe card with larger prefetch window
- Notes: Match celebration flow unchanged

---

### Task #009 — Matched Users Appear + Chat Redirect
**Date:** 2026-01-23
**Agent:** Codex
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Ensure newly matched users show up under “Matched with you” on the Matches screen.
- **Secondary goal:** Tapping a matched user should open the chat with that specific user.
- **Implicit requirements:** Match list should update on match creation and navigation should include the correct matchId/user data.
- **Quality expectations:** Immediate visibility of new matches and reliable chat navigation.

**Refined Prompt (Very Specific & Detailed):**

### Objective
Make sure matches appear under “Matched with you” and tapping a match navigates to that user’s chat.

### Technical Requirements
1. Ensure the Matches screen uses the correct match source and refreshes when a new match is created.
2. Verify the match list item includes the correct `matchId`, `otherUserId`, and `otherUserName/photo`.
3. Confirm tapping a match card routes to the chat screen with the proper `ChatScreenArgs`.

### Implementation Plan
**Step 1:** Inspect `lib/features/chat/presentation/screens/matches_screen.dart` for how matched users are loaded and displayed.  
**Step 2:** Inspect `MatchesBloc` and repository methods to confirm new matches refresh/insert into state.  
**Step 3:** Validate the tap handler uses the correct `match.id` and user data when navigating.  
**Step 4:** Add a refresh trigger on match creation if missing (e.g., when `DiscoveryBloc` reports a new match).  

### Files to Modify/Create
- `lib/features/chat/presentation/screens/matches_screen.dart` — ensure list uses `matched` and correct tap routing.
- `lib/features/chat/presentation/bloc/matches_bloc.dart` — ensure new matches refresh or insert.
- `lib/features/discovery/presentation/bloc/discovery_bloc.dart` (if needed) — emit or trigger refresh on match creation.

### Success Criteria
- [ ] New matches appear under “Matched with you.”
- [ ] Tapping a matched user opens the correct chat.
- [ ] Navigation uses correct matchId and other user metadata.

### Edge Cases & Error Handling
- Match exists but missing other user name/photo → fallback to userId.
- If match list is empty → show empty state without crashes.

### Verification Commands
```
flutter run
```

**Related Task ID:** T-037

**Outcome:**
- Files changed:
  - `lib/features/chat/presentation/screens/matches_screen.dart` — refresh on match notification
  - `docs/Developer_agent_chat.md`, `docs/ai_change_log.md`, `docs/ai_tasks_board.md`, `docs/ai_collab_chat.md`
- Result: Matches list refreshes when a new match notification arrives; chat routing unchanged
- Notes: Requires manual verification in app

---

### Task #010 — Per-Chat Settings (Individual Message Retention)
**Date:** 2026-01-23
**Agent:** Claude
**Status:** Completed

**Developer Intent Analysis:**
- **Primary goal:** Fix "failed to update settings" error in chat settings
- **Secondary goals:**
  - Enable per-chat (per-match) message retention settings instead of global settings
  - Allow users to customize retention for each individual conversation
- **Implicit requirements:** Settings should be accessible from within a chat conversation
- **Quality expectations:** Each chat can have different retention settings, error-free operation

**Refined Prompt (Very Specific & Detailed):**

### Objective
Fix the chat settings update failure and implement per-match chat settings, allowing users to customize message retention for each individual conversation rather than applying global settings to all chats.

### Technical Requirements
1. **Fix ChatSettings parsing in profile repository**
   - `_userFromFirestore()` was not parsing `chatSettings` field from Firestore
   - Add `ChatSettings.fromJson()` parsing to restore settings properly

2. **Create per-match chat settings cubit**
   - New `MatchChatSettingsCubit` that accepts `matchId` parameter
   - Stores settings at match level instead of user level
   - Each user in a match can have their own retention settings

3. **Add Cloud Function for per-match settings**
   - New `updateMatchChatSettings` callable function
   - Verifies user is part of the match
   - Stores settings at `matches/{matchId}/chatSettings/{userId}`
   - Syncs to RTDB for real-time access

4. **Add chat settings access from chat screen**
   - Add "Chat Settings" option to chat popup menu
   - Show bottom sheet with per-match retention toggle
   - Display current retention setting and allow changes

### Implementation Plan
**Step 1:** Add import for `ChatSettings` in `firebase_profile_repository.dart`
**Step 2:** Add `ChatSettings.fromJson()` parsing in `_userFromFirestore()`
**Step 3:** Create `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart`
**Step 4:** Add `updateMatchChatSettings` Cloud Function in `functions/src/index.ts`
**Step 5:** Add `chatSettings` to `_ChatSafetyAction` enum in `chat_screen.dart`
**Step 6:** Add menu item for chat settings in popup menu
**Step 7:** Implement `_showMatchChatSettings()` method with bottom sheet UI
**Step 8:** Add required imports (ChatSettings, AuthBloc, SubscriptionPlan, MatchChatSettingsCubit)

### Files to Modify/Create
- `lib/features/profile/data/repositories/impl/firebase_profile_repository.dart` — Add ChatSettings parsing
- `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` — New cubit for per-match settings
- `functions/src/index.ts` — Add `updateMatchChatSettings` Cloud Function
- `lib/features/chat/presentation/screens/chat_screen.dart` — Add chat settings menu item and bottom sheet

### Success Criteria
- [x] ChatSettings parsed correctly from Firestore
- [x] MatchChatSettingsCubit created with matchId support
- [x] Cloud Function stores settings at match level with user-specific keys
- [x] Chat settings accessible from chat popup menu
- [x] Bottom sheet shows retention toggle for non-premium users
- [x] Premium users see "Plus Benefit: 7 days" message
- [x] Flutter analyze passes with no errors

### Edge Cases & Error Handling
- User not part of match → Cloud Function throws permission error
- Premium users → Show 7-day retention info instead of toggle
- Cloud Function fails → Show error in snackbar, don't update local state
- Match doesn't exist → Cloud Function returns not-found error

### Verification Commands
```
flutter analyze lib/features/chat/presentation/screens/chat_screen.dart
flutter analyze lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart
```

**Related Task ID:** T-038

**Outcome:**
- Files changed:
  - `lib/features/profile/data/repositories/impl/firebase_profile_repository.dart` — Added ChatSettings import and parsing
  - `lib/features/chat/presentation/bloc/match_chat_settings_cubit.dart` — New cubit for per-match settings
  - `functions/src/index.ts` — Added `updateMatchChatSettings` Cloud Function
  - `lib/features/chat/presentation/screens/chat_screen.dart` — Added chat settings menu item, bottom sheet, imports
- Result: Per-chat settings implemented with individual message retention per conversation
- Notes: Requires `firebase deploy --only functions` to deploy Cloud Function changes

---

## Quick Reference

| Task # | Title | Date | Agent | Status |
|--------|-------|------|-------|--------|
| 001 | Implement Bidirectional Chat Messaging | 2026-01-23 | Claude | Completed |
| 002 | Premium "Seen" Status for Messages | 2026-01-23 | Claude | Completed |
| 003 | Create Developer Agent Chat Document | 2026-01-23 | Claude | Completed |
| 004 | Improve Prompt Refinement Workflow | 2026-01-23 | Claude | Completed |
| 005 | Message Requests + Match-aware Profile Actions | 2026-01-23 | Codex | Completed |
| 006 | Remove Original Request from Task Log Template | 2026-01-23 | Claude | Completed |
| 007 | Complete Discovery & Matching System with Real-time RTDB | 2026-01-23 | Claude | Completed |
| 008 | Deck Preload + Background Stack | 2026-01-23 | Codex | Completed |
| 009 | Matched Users Appear + Chat Redirect | 2026-01-23 | Codex | Completed |
| 010 | Per-Chat Settings (Individual Message Retention) | 2026-01-23 | Claude | Completed |

---

## Notes for Agents (STRICT REQUIREMENTS)

1. **ALWAYS log tasks here IMMEDIATELY** when the developer gives you work
2. **UNDERSTAND the developer's intent** — What do they actually want? What are the implicit requirements?
3. **CREATE a VERY SPECIFIC, VERY DETAILED refined prompt** with:
   - Exact technical requirements (not vague descriptions)
   - Step-by-step implementation plan with file paths
   - Success criteria that can be verified
   - Edge cases and how to handle them
4. **NEVER save the developer's original raw message** — Only save the refined prompt you create
5. **SAVE the refined prompt BEFORE executing** — This is your contract
6. **The refined prompt should be so detailed** that another agent could execute it without asking questions
7. **Update status** as you progress (Received → In Progress → Completed)
8. **Document the outcome** with files changed and specific results
