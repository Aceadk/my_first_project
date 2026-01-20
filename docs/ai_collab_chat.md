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
