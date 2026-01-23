# AI Collaboration Chat Log

This file records short AI-to-AI discussion logs for all tasks.

---

## Template

```
T-XXX - <title> - YYYY-MM-DD
Planner AI:
Summary of repo context:
Proposed approach:
File impact list:
Risks + mitigations:
Critic AI:
Concerns / edge cases:
Better alternatives:
Required tests:
UX notes:
Resolution:
Final agreed plan:
What changed from the original plan:
```

---

## Logs

T-031 - Implement Bidirectional Chat Messaging - 2026-01-23
Planner AI:
Summary of repo context:
- Flutter client calls `sendMessage` Cloud Function but it doesn't exist
- `markMessagesRead` Cloud Function also missing
- Real-time listening already works via Firestore snapshots in `watchMessages`
- `onMessageCreated` trigger exists for push notifications
- Message format expected by Flutter: matchId, fromUserId, toUserId, content, type, sentAt, isRead, reactions (Map)

Proposed approach:
- Add three callable Cloud Functions: sendMessage, markMessagesRead, editMessage
- sendMessage validates match membership, creates message document, updates match lastMessage
- markMessagesRead batch updates all unread messages from other user
- editMessage allows sender to modify their own message (Plus plan only)
- No changes needed in Flutter - ChatBloc already uses watchMessages for real-time updates

File impact list:
- functions/src/index.ts (add interfaces + 3 callable functions)

Risks + mitigations:
- Risk: Functions need deployment to Firebase
  - Mitigation: Document deployment command in verification steps
- Risk: Message format mismatch with Flutter
  - Mitigation: Verified _messageFromFirestore expectations; included matchId, reactions as Map

Critic AI:
Concerns / edge cases:
- Reactions should be {} not [] since Flutter expects Map<String, String>
- matchId should be included in message document for consistency
Better alternatives:
- Could use direct Firestore writes instead of Cloud Functions for lower latency
  - Rejected: Cloud Functions provide better security/validation
Required tests:
- Two-device test: User A sends, User B receives
- Verify markMessagesRead updates isRead flag
UX notes:
- Real-time updates should work seamlessly

Resolution:
Final agreed plan:
- Added SendMessageRequest, MarkMessagesReadRequest, EditMessageRequest interfaces
- Added sendMessage callable with match validation, blocked user check
- Added markMessagesRead callable with batch update
- Added editMessage callable with ownership check
- Changed reactions from [] to {} in message document
- Added matchId field to message document

What changed from the original plan:
- Added matchId field to message (discovered via _messageFromFirestore)
- Changed reactions from array to object

---

T-034 - Message Requests for non-matched users - 2026-01-23
Planner AI:
Summary of repo context:
- ChatRepository handles matched conversations only; no message request model exists.
- OtherUserProfileScreen already has Pass/Like actions and match-aware routing.
- MatchesBloc loads matches and is a natural place to trigger request migration.
Proposed approach:
- Add MessageRequest model + repository methods for send/fetch/expire/migrate.
- Add MessageRequestsCubit + MessageRequestsScreen; add a Chats entry and route.
- Update OtherUserProfileScreen: show Send Message between Pass/Like; matched shows only Send Message.
- Migrate eligible requests into chats when matches load.
File impact list:
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
- lib/core/router.dart
Risks + mitigations:
- Risk: Migration may only succeed on sender device due to auth constraints.
  - Mitigation: Attempt migration only when current user is sender; document limitation.
Critic AI:
Concerns / edge cases:
- Recipient device may still see request after match if sender hasn't synced.
- Single-request-per-pair vs per-user needs a clear rule.
Better alternatives:
- Backend-driven migration via Cloud Functions or Firestore trigger.
Required tests:
- Manual: send request, prevent duplicate, match migration, expiration cleanup.
UX notes:
- Clearly label requests as “Message Request” and show expiration countdown.
Resolution:
Final agreed plan:
- Implement client-side request storage + migration (best-effort), with expiration cleanup on fetch.
What changed from the original plan:
- Added explicit migration limitation note and guard for sender-only migration.
- Added Firestore rules + docs updates; corrected task ID to avoid duplicate T-032.
Execution notes:
- Implemented message request model, repositories, cubit, screen, chat list entry, profile send flow, and match migration hook.
- Added Firestore `message_requests` rules and updated flow/DFD/ER docs.

---

T-036 - Deck preload + background stack in swipe deck - 2026-01-23
Planner AI:
Summary of repo context:
- DeckScreen renders only the active SwipeableCard; a DeckPreviewStack widget exists but is unused.
- DeckScreen preloads only the next 2 profile images via NetworkImageCache.
Proposed approach:
- Wrap SwipeableCard with DeckPreviewStack to show upcoming profiles behind the current card.
- Increase prefetch count to 4 and align DeckPreviewStack to render up to 4 background cards.
- Keep match celebration listener unchanged.
File impact list:
- lib/features/discovery/presentation/screens/deck_screen.dart
- lib/features/discovery/presentation/widgets/deck_card_stack.dart
Risks + mitigations:
- Risk: Extra prefetching increases memory/network usage.
  - Mitigation: Preload only the first photo and cap background cards to 4.
Critic AI:
Concerns / edge cases:
- Deck length < 2 should not crash; background stack should handle empty states.
- Too-low opacity for deeper cards could make them invisible.
Better alternatives:
- Use PageView with cacheExtent; rejected to avoid architecture change.
Required tests:
- Manual: drag card to see background, swipe quickly to confirm no delay, verify match celebration still triggers.
UX notes:
- Keep background cards subtle but visible to imply depth.
Resolution:
Final agreed plan:
- Use DeckPreviewStack behind SwipeableCard and bump prefetch count to 4 with safer opacity scaling.
What changed from the original plan:
- Add opacity adjustment so 4th card remains faintly visible.
Execution notes:
- Wrapped SwipeableCard with DeckPreviewStack and passed filtered upcoming profiles.
- Increased prefetch and preview counts to 4 and adjusted opacity scaling.

---

T-037 - Matched users appear + chat redirect - 2026-01-23
Planner AI:
Summary of repo context:
- MatchesScreen uses MatchesBloc with caching; new matches may not appear immediately if no refresh is triggered.
- Match tiles already navigate to chat via matchId.
Proposed approach:
- Listen to RealtimeMatchService notifications and refresh MatchesBloc.
- Keep existing match tile routing intact.
File impact list:
- lib/features/chat/presentation/screens/matches_screen.dart
Risks + mitigations:
- Risk: Additional refresh calls increase network usage.
  - Mitigation: Refresh only on match notifications.
Critic AI:
Concerns / edge cases:
- Ensure subscription is disposed to avoid leaks.
Better alternatives:
- Invalidate cache from a global event bus; skipped to keep scope small.
Required tests:
- Manual: create match → matches screen updates; tap match → chat opens.
UX notes:
- No UI change needed; just keep list current.
Resolution:
Final agreed plan:
- Subscribe to RealtimeMatchService in MatchesScreen and trigger MatchesRefreshRequested.
What changed from the original plan:
- Added listener in MatchesScreen instead of global refresh.
Execution notes:
- Added match notification subscription and refresh in MatchesScreen state.

---

T-039 - Fix Flutter SDK path for VS Code - 2026-01-23
Planner AI:
Summary of repo context:
- IDE error indicates `dart.flutterSdkPath` points to `/Users/ace/Developmentflutter` (missing slash).
Proposed approach:
- Add workspace `.vscode/settings.json` with `dart.flutterSdkPath` set to `/Users/ace/Development/flutter`.
File impact list:
- .vscode/settings.json
Risks + mitigations:
- Risk: Path is machine-specific.
  - Mitigation: Document in task log; update if SDK moves.
Critic AI:
Concerns / edge cases:
- If user uses a different SDK location, this will need adjustment.
Better alternatives:
- Set via user settings; skipped to keep fix in repo.
Required tests:
- Reload VS Code and confirm SDK detected.
UX notes:
- None.
Resolution:
Final agreed plan:
- Commit workspace settings with correct path.
What changed from the original plan:
- None.
Execution notes:
- Added `.vscode/settings.json` with corrected Flutter SDK path.
T-027 - Hide pass/like for matched profiles + wire profile actions - 2026-01-23
Planner AI:
Summary of repo context:
- OtherUserProfileScreen always shows Pass/Like buttons and only uses isMatch for contact info.
- DiscoveryBloc owns deck state and swipe actions; DiscoveryRepository can swipe directly when deck context is unknown.
Proposed approach:
- Hide the bottom Pass/Like bar when args.isMatch is true.
- Wire pass/like buttons to swipe: use DiscoveryBloc when the viewed profile matches the current deck card; otherwise call DiscoveryRepository directly.
- After a pass/like, return to the deck (pop when coming from deck; go to Home when not).
File impact list:
- lib/features/profile/presentation/screens/other_user_profile_screen.dart
Risks + mitigations:
- Risk: DiscoveryBloc swipe could act on the wrong card if the viewed profile isn't current.
  - Mitigation: guard by checking current deck card ID; fallback to repository and refresh deck.
Critic AI:
Concerns / edge cases:
- If navigation replaces Home, deck match celebration might be missed.
Better alternatives:
- Prefer pop to keep deck state/celebration when possible; only go Home when needed.
Required tests:
- Manual: open profile from deck and from chat; verify actions and button visibility.
UX notes:
- Keep feedback via snack bars for likes and matches.
Resolution:
Final agreed plan:
- Implement match-aware bottom bar and swipe handlers with deck-aware dispatch + repo fallback + deck navigation.
What changed from the original plan:
- Added deck/profile identity guard before dispatching DiscoveryBloc swipe events.
Execution notes:
- Implemented in other_user_profile_screen.dart; no additional risks observed.

T-026 - Fix ID verification notification in chat screen - 2026-01-23
Planner AI:
Summary of repo context:
- Chat screen has an ID verification notification banner at the top.
- Clicking "Verify" navigates to Safety & Blocking instead of ID verification screen.
- Banner shows permanently when user is not verified.
Proposed approach:
- Change navigation from `CrushRoutes.safety` to `CrushRoutes.idVerification`.
- Add 10-second auto-dismiss timer using Timer.
- Add 3-hour cooldown using SharedPreferences timestamp.
- Only show banner when `!selfVerified && _showVerificationBanner`.
File impact list:
- lib/features/chat/presentation/screens/chat_screen.dart
Risks + mitigations:
- SharedPreferences key may persist across accounts -> minor UX impact, consider adding to clearance service.
Critic AI:
Concerns / edge cases:
- No external critic available; self-critique applied.
- Cooldown resets on banner dismiss, not on chat open.
Better alternatives:
- Could track "ID submitted" status from PhotoVerification model to hide banner after submission.
Required tests:
- Manual: Open chat, verify banner shows and auto-dismisses.
UX notes:
- 10 seconds may feel short; 3 hours is reasonable cooldown.
Resolution:
Final agreed plan:
- Implement timer-based auto-dismiss and SharedPreferences cooldown.
What changed from the original plan:
- None.

---

T-025 - Enforce before/after AI doc sync - 2026-01-23
Planner AI:
Summary of repo context:
- Collaboration docs already required before changes, but no explicit after-edit re-read and suggestion loop.
Proposed approach:
- Strengthen CLAUDE.md rules to require reading the four docs before and after edits and to log suggestions in ai_collab_chat.
File impact list:
- CLAUDE.md
Risks + mitigations:
- None (documentation-only change).
Critic AI:
Concerns / edge cases:
- Ensure after-edit requirement is unambiguous and applies to all agents.
Better alternatives:
- Add a pre-commit hook to enforce doc reads (out of scope).
Required tests:
- None.
UX notes:
- N/A.
Resolution:
Final agreed plan:
- Update CLAUDE.md rule wording; log change in AI docs.
What changed from the original plan:
- None.

T-024 - Move auth screens into auth feature folder - 2026-01-23
Planner AI:
Summary of repo context:
- Auth/onboarding screens are split between `lib/features/auth` and legacy `lib/presentation/screens`.
- GoRouter imports those legacy paths for onboarding/security flows.
Proposed approach:
- Move auth/onboarding/security screens into `lib/features/auth/presentation/screens`.
- Update router imports and profile barrel exports.
- Refresh auth system doc paths to prevent drift.
File impact list:
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
Risks + mitigations:
- Risk: missed import updates -> build failures.
  - Mitigation: search for old paths and update imports; run `flutter analyze` if requested.
Critic AI:
Concerns / edge cases:
- Ensure non-auth screens (home/safety/legal) remain in place.
- Confirm no residual references to `lib/presentation/screens` for moved files.
Better alternatives:
- Create a dedicated onboarding feature folder, but this is out of scope.
Required tests:
- `flutter analyze` if time allows.
- Manual: splash -> auth gateway; onboarding/security screens load.
UX notes:
- No UI changes required.
Resolution:
Final agreed plan:
- Move auth screens to `features/auth`, update imports, update docs.
What changed from the original plan:
- Added `docs/auth_system.md` path updates to prevent documentation drift.

T-020 - Project-wide audit + repo hygiene scan - 2026-01-22
Planner AI:
Summary of repo context:
- Multi-backend (Firebase/HTTP/Stub) Flutter app with GoRouter + BLoC.
- Firebase Functions and storage rules drive discovery, chat, and media upload.
Proposed approach:
- Perform static audit of routing, discovery, chat, profile completeness, and Firebase rules.
- Review platform manifests for permission parity and deep link alignment.
- Document findings and defer fixes/deletions pending approval.
File impact list:
- AUDIT_REPORT.md
- docs/ai_change_log.md
- docs/ai_tasks_board.md
- docs/risk_notes.md
Risks + mitigations:
- Static-only review -> mark limitations and verification gaps in report.
Critic AI:
Concerns / edge cases:
- No external critic available; ensure report notes limitations and avoids false certainty.
Better alternatives:
- Run `flutter analyze`/`flutter test` and device builds for stronger confidence.
Required tests:
- None (report only).
UX notes:
- Highlight mismatches that block discovery/messaging first.
Resolution:
Final agreed plan:
- Ship an audit addendum with severity-ranked findings and next steps.
What changed from the original plan:
- No code changes; report-only update.

---

T-005 - Weekly Picks during onboarding + remove Deck safety icon - 2026-01-20
Planner AI:
Summary of repo context:
- GoRouter enforces onboarding redirects and currently blocks Weekly Picks during Basic Info/Profile Setup.
- Deck app bar shows Boost, Weekly Picks, and a Safety shield icon.
Proposed approach:
- Allow Weekly Picks in onboarding allowlists (needsBasicInfo/needsProfileSetup).
- Remove the safety shield icon from the Deck app bar.
File impact list:
- lib/core/router.dart
- lib/features/discovery/presentation/screens/deck_screen.dart
Risks + mitigations:
- Onboarding gating loosened for Weekly Picks only -> still blocked if terms not accepted or not logged in.
Critic AI:
Concerns / edge cases:
- No external critic available; developer approved proceeding.
Better alternatives:
- Hide Weekly Picks until onboarding completes.
Required tests:
- Manual: tap Weekly Picks during onboarding, confirm navigation.
UX notes:
- Keep Safety & Blocking in Settings; keep in-card safety menu.
Resolution:
Final agreed plan:
- Option A: allow Weekly Picks during onboarding; remove Deck safety icon.
What changed from the original plan:
- None

---

T-006 - Prevent onboarding reroute to profile setup on restart - 2026-01-20
Planner AI:
Summary of repo context:
- Onboarding redirects rely on `CrushUser.hasCompletedProfileSetup`, which only checks photos.
- Auth state may be stale on restart; a single refresh after login helps sync profile data.
Proposed approach:
- Treat video-only profiles as completed setup.
- Trigger a one-time auth refresh after the first authenticated user event.
File impact list:
- lib/data/models/user.dart
- lib/features/auth/presentation/bloc/auth_bloc.dart
Risks + mitigations:
- Extra refresh call after login -> guard with one-time flag to avoid loops.
Critic AI:
Concerns / edge cases:
- No external critic available; developer approved proceeding.
Better alternatives:
- Add explicit completion flags in Firestore for onboarding steps.
Required tests:
- Manual: sign in, add video-only profile, restart app.
UX notes:
- Avoid forcing users back into onboarding after completing it with video media.
Resolution:
Final agreed plan:
- Update completion logic to accept videos; add one-time auth refresh after login.
What changed from the original plan:
- None

---

T-007 - Prevent onboarding reroute to Basic Info on restart - 2026-01-20
Planner AI:
Summary of repo context:
- Basic Info completion check required a non-empty name, but UI does not enforce name.
Proposed approach:
- Align completion logic with required fields by removing the name requirement.
File impact list:
- lib/data/models/user.dart
Risks + mitigations:
- Users may proceed without a display name -> follow up to add validation if desired.
Critic AI:
Concerns / edge cases:
- No external critic available; developer approved proceeding.
Better alternatives:
- Enforce name validation in Basic Info screen instead.
Required tests:
- Manual: complete Basic Info, restart app.
UX notes:
- Avoid sending users back to a step they already completed.
Resolution:
Final agreed plan:
- Remove name requirement from `hasCompletedBasicInfo`.
What changed from the original plan:
- None

---

T-008 - Create project flowchart documentation - 2026-01-20
Planner AI:
Summary of repo context:
- Project understanding doc outlines architecture, routing, and core flows.
Proposed approach:
- Create a docs flowchart using Mermaid for navigation and architecture/data flow.
File impact list:
- docs/project_flowchart.md
Risks + mitigations:
- Docs may drift -> keep update note in change log.
Critic AI:
Concerns / edge cases:
- No external critic available; developer approved proceeding.
Better alternatives:
- Maintain only a navigation flowchart to reduce drift.
Required tests:
- None (documentation only).
UX notes:
- Keep diagrams readable and high-level.
Resolution:
Final agreed plan:
- Add a single doc with multiple Mermaid diagrams.
What changed from the original plan:
- None

---

T-009 - Route T&C acceptance into onboarding steps - 2026-01-20
Planner AI:
Summary of repo context:
- Terms acceptance handler navigated directly to Home, bypassing onboarding.
Proposed approach:
- After accept, refresh user and route using the same order as router.
File impact list:
- lib/features/auth/presentation/screens/terms_conditions_screen.dart
Risks + mitigations:
- None identified.
Critic AI:
Concerns / edge cases:
- No external critic available; developer approved proceeding.
Better alternatives:
- Redirect to splash and let router handle it.
Required tests:
- Manual: create new account -> accept terms -> verify Basic Info.
UX notes:
- Keep onboarding flow consistent for new accounts.
Resolution:
Final agreed plan:
- Route to Basic Info/Profile Setup/Email Verification as needed after terms.
What changed from the original plan:
- None

---

T-023 - UI/UX polish for auth flow - 2026-01-23
Planner AI:
Summary of repo context:
- Auth screens still used Material buttons and some hard-coded Colors.*.
Proposed approach:
- Replace Material buttons with Glass variants.
- Swap hard-coded colors to DsColors/DsGlassColors.
- Add Semantics labels for key actions.
File impact list:
- lib/features/auth/presentation/screens/auth_gateway_screen.dart
- lib/features/auth/presentation/screens/login_screen.dart
- lib/features/auth/presentation/screens/sign_up_screen.dart
- lib/features/auth/presentation/screens/email_auth_screen.dart
- lib/features/auth/presentation/screens/phone_auth_screen.dart
- lib/features/auth/presentation/screens/otp_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/screens/email_verification_screen.dart
- lib/features/auth/presentation/screens/terms_conditions_screen.dart
Risks + mitigations:
- Glass buttons could reduce link affordance -> keep labels concise and add Semantics.
Critic AI:
Concerns / edge cases:
- No external critic available; ensure only auth flow is touched in this pass.
Better alternatives:
- Phase the changes by screen to reduce UI drift risk.
Required tests:
- Manual: auth gateway, login, sign up, email/phone auth, OTP, verification, forgot password.
UX notes:
- Use GlassSmallButton for link-style actions to keep layout compact.
Resolution:
Final agreed plan:
- Ship auth flow polish now; defer discovery/chat/profile/settings to follow-up.
What changed from the original plan:
- Scoped work to auth screens only for this pass.

---

T-022 - Add missing routes for call/video/media/story screens - 2026-01-23
Planner AI:
Summary of repo context:
- Call, video call, profile media, and story viewer screens existed but were not in GoRouter.
- Video call/profile media used Navigator pushes; story viewer had no entry point.
Proposed approach:
- Add route constants and GoRoute entries with typed args.
- Update chat and swipe card navigation to use GoRouter.
- Add a small story badge entry point on discovery cards.
File impact list:
- lib/core/router.dart
- lib/features/calls/presentation/screens/call_screen.dart
- lib/features/calls/presentation/screens/video_call_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
- lib/features/discovery/presentation/screens/story_viewer_screen.dart
- lib/features/profile/presentation/screens/profile_media_screen.dart
- docs/project_flowchart.md
Risks + mitigations:
- Call screen uses stub caller ID -> document in risk notes.
Critic AI:
Concerns / edge cases:
- No external critic available; guard routes against missing extras.
Better alternatives:
- Defer story wiring until a stories list UI exists.
Required tests:
- Manual: open chat video call route and profile media route.
- Manual: open story viewer from story badge if stories exist.
UX notes:
- Keep story badge small to avoid blocking swipe.
Resolution:
Final agreed plan:
- Add routes, swap navigation to GoRouter, and wire story badge entry.
What changed from the original plan:
- Added a story badge entry on discovery cards for story viewer access.

---

T-021 - Fix Boost timer + auth cleanup for feature cubits - 2026-01-23
Planner AI:
Summary of repo context:
- BoostCubit uses a periodic timer and calls initialize inside the timer.
- WeeklyPicks/DateIdeas/CompatibilityQuiz/ProfileInsights cubits lack auth cleanup.
Proposed approach:
- Guard refresh to prevent recursive timers and only tick during active boost/cooldown.
- Add authStateChanges listeners to reset cubits and clear cached service data on logout.
File impact list:
- lib/features/discovery/presentation/bloc/boost_cubit.dart
- lib/features/discovery/presentation/bloc/weekly_picks_cubit.dart
- lib/features/discovery/data/services/weekly_picks_service.dart
- lib/features/social/presentation/bloc/date_ideas_cubit.dart
- lib/features/social/data/services/date_idea_service.dart
- lib/features/social/presentation/bloc/compatibility_quiz_cubit.dart
- lib/features/social/data/services/compatibility_quiz_service.dart
- lib/features/analytics/presentation/bloc/profile_insights_cubit.dart
- lib/features/analytics/data/services/profile_insights_service.dart
Risks + mitigations:
- Resetting state could clear visible UI -> only trigger on logout.
Critic AI:
Concerns / edge cases:
- No external critic available; ensure refresh guards don't block legitimate updates.
Better alternatives:
- Track user IDs to ignore in-flight loads after logout (not implemented).
Required tests:
- Manual: activate boost, wait for expiry, confirm single refresh.
- Manual: logout, confirm feature cubits reset.
UX notes:
- None.
Resolution:
Final agreed plan:
- Implement guarded refresh + timer gating in BoostCubit.
- Add auth cleanup listeners and clear service caches on logout.
What changed from the original plan:
- Added service-level clearUserData helpers to remove cached lists.

---

T-010 - Enforce onboarding redirect away from Home - 2026-01-20
Planner AI:
Summary of repo context:
- GoRouter allows Home during needsBasicInfo/needsProfileSetup, enabling onboarding bypass.
Proposed approach:
- Remove Home from the allowlist when onboarding is incomplete.
File impact list:
- lib/core/router.dart
Risks + mitigations:
- Possible redirect loop if AuthBloc is stale -> rely on refresh after profile save and router redirect away from onboarding once updated.
Critic AI:
Concerns / edge cases:
- No external critic available; proceeding with self-critique per developer approval.
Better alternatives:
- Route all auth screens through a shared onboarding-aware helper and keep Home allowlist.
Required tests:
- Manual: new account -> terms -> verify Basic Info; post-onboarding -> Home accessible.
UX notes:
- Keep weekly picks/legal routes accessible via public routes.
Resolution:
Final agreed plan:
- Tighten router allowlist by removing Home while onboarding is incomplete.
What changed from the original plan:
- None

---

T-011 - Date plan email notification - 2026-01-20
Planner AI:
Summary of repo context:
- Date plan creation is in Safety screen; DatePlanService stores plans in memory only.
- Email sending is already implemented in Cloud Functions via Resend for auth flows.
Proposed approach:
- Add a callable `notifyDatePlanContact` using Resend with rate limiting.
- Call the function from DatePlanService on successful plan creation.
File impact list:
- functions/src/index.ts
- lib/features/safety/data/services/date_plan_service.dart
- lib/presentation/screens/safety_screen.dart
Risks + mitigations:
- Missing Resend configuration -> return failed-precondition error and show UI message.
- Spam risk -> rate limit per user/contact.
Critic AI:
Concerns / edge cases:
- No external critic available; proceeding with self-critique per developer approval.
Better alternatives:
- Persist plans in Firestore and trigger notification via Firestore trigger.
Required tests:
- Manual: create plan and verify contact email.
UX notes:
- Surface validation errors for invalid emails.
Resolution:
Final agreed plan:
- Implement callable + client call with validation and rate limiting.
What changed from the original plan:
- None

---

T-019 - Match celebration heart animation polish - 2026-01-21
Planner AI:
Summary of repo context:
- Match celebration modal renders two photos with a centered heart animation.
Proposed approach:
- Move the heart above the photos and add pulsing rings around each avatar.
File impact list:
- lib/features/discovery/presentation/widgets/match_celebration_modal.dart
Risks + mitigations:
- Animation layering might add GPU load -> keep pulse count and shadows modest.
Critic AI:
Concerns / edge cases:
- Ensure the heart no longer overlaps faces and the photos stay centered on smaller screens.
Better alternatives:
- Use a lightweight Lottie for the heart, but avoid new assets for now.
Required tests:
- Manual: trigger match and verify animation timing and layout on small screens.
UX notes:
- Keep the pulse smooth and slow; avoid rapid beats that feel jittery.
Resolution:
Final agreed plan:
- Replace center heart with a top heart pulse; add subtle ring pulses around photos.
What changed from the original plan:
- Use existing controllers instead of adding new ones.

---

T-018 - Skeleton loaders across core screens - 2026-01-20
Planner AI:
Summary of repo context:
- Deck screen already shows DeckSkeletonList when loading with empty deck.
- Matches screen uses spinners and minimal skeletons for Likes You only.
- Chat screen has isInitialLoading state but no skeleton UI.
- Profile view uses a centered progress indicator while loading.
Proposed approach:
- Enhance DeckSkeletonList with shimmer styling.
- Show skeleton lists for matches (vertical) and likes (horizontal) on Matches screen.
- Use GlassSkeletonMessage list while chat messages are initially loading.
- Replace profile view spinner with GlassSkeletonProfile.
File impact list:
- lib/features/discovery/presentation/screens/deck_screen.dart
- lib/features/discovery/presentation/widgets/deck_skeleton.dart
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/chat/presentation/screens/chat_screen.dart
- lib/features/profile/presentation/screens/profile_view_screen.dart
Risks + mitigations:
- Shimmer performance on low-end devices -> keep item count modest.
Critic AI:
Concerns / edge cases:
- Avoid nested scroll conflicts when inserting skeleton lists inside CustomScrollView.
Better alternatives:
- Use SliverList with SkeletonMatchCard to avoid ListView inside slivers.
Required tests:
- Manual: load each screen and verify skeletons appear briefly without layout jumps.
UX notes:
- Match skeletons should visually match real tile sizes to prevent jarring transitions.
Resolution:
Final agreed plan:
- Implement skeletons using existing design_system loaders, scoped to existing loading flags.
What changed from the original plan:
- Prefer sliver-based skeletons for Matches to avoid nested scroll issues.

---

T-013 - Name privacy + last name onboarding - 2026-01-20
Planner AI:
Summary of repo context:
- Basic Info saves name/age/gender via ProfileBloc -> ProfileRepository.saveBasicInfo -> Firestore profile.
- Profile model only stores `name`; privacy settings exist but no name-visibility flags.
- Discovery/matches/other-user screens render `profile.name` directly.
Proposed approach:
- Add `lastName` to Profile + Firestore/DTO mappings; keep `name` as first name.
- Add privacy flags `showFirstName` and `showLastName` (default false).
- Update Basic Info + Profile Edit to capture last name and name visibility toggle, saving to Firestore.
- Add `publicDisplayName` helper and use it across public-facing UI.
File impact list:
- lib/data/models/profile.dart
- lib/data/models/privacy_settings.dart
- lib/presentation/screens/basic_info_screen.dart
- lib/features/profile/presentation/screens/profile_edit_screen.dart
- lib/features/profile/data/repositories/impl/firebase_profile_repository.dart
- lib/features/auth/data/repositories/impl/firebase_auth_repository.dart
- lib/features/discovery/presentation/widgets/swipe_card.dart
Risks + mitigations:
- Names hidden by default -> use placeholder and prompt users during onboarding.
- Legacy profiles missing lastName -> fallback to first name only.
Critic AI:
Concerns / edge cases:
- PrivacySettingsCubit persists locally only; name visibility should be saved in profile.
Better alternatives:
- Use Profile Edit (not privacy settings screen) to persist name visibility without DI changes.
Required tests:
- Manual: new account Basic Info save; name privacy default private
- Manual: toggle name visibility in Profile Edit and verify public views
UX notes:
- Add clear copy: "Your name is private by default" with an explicit toggle.
Resolution:
Final agreed plan:
- Implement lastName + name privacy in profile model/repo, update onboarding + profile edit, and gate public UI with `publicDisplayName`.
What changed from the original plan:
- Keep privacy toggles in Profile Edit instead of privacy settings screen to avoid DI changes.

---

T-012 - Matches screen likes-you section - 2026-01-20
Planner AI:
Summary of repo context:
- Matches screen shows only mutual matches from MatchesBloc.
- Likes You exists as a separate Discovery screen backed by DiscoveryRepository.
Proposed approach:
- Add Likes You section to Matches screen using DiscoveryRepository.
- Show blurred cards with DOB/distance and an upgrade prompt on tap.
- Ensure stub mode supplies 2-3 dummy likes.
File impact list:
- lib/features/chat/presentation/screens/matches_screen.dart
- lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart
Risks + mitigations:
- Privacy exposure of DOB/distance before match -> add risk note and consider hiding later.
Critic AI:
Concerns / edge cases:
- No external critic available; proceeding with self-critique per developer approval.
Better alternatives:
- Keep Likes You in its own screen and link from Matches.
Required tests:
- Manual: match creation -> matches list
- Manual: likes-you blur + upgrade prompt
UX notes:
- Keep blurred cards visually consistent with Likes You screen.
Resolution:
Final agreed plan:
- Embed Likes You section at top of Matches with blur and upgrade prompt.
What changed from the original plan:
- None
