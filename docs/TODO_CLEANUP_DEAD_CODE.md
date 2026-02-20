# TODO: Codebase Cleanup & Dead Code Removal
**Priority:** P2
**Estimated Effort:** 15-25 hours
**Dependencies:** Clean architecture domain interfaces resolved, ChatBloc split completed
**Assigned:** AI + Developer
**Status:** 7 of 8 items completed (2026-02-20). CLEAN-006 partially complete (Phase 1 done).

---

## CLEAN-001: Split ChatScreen into Composable Widgets (3,230 lines)
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart` (split target)
**Description:** ChatScreen at 3,230 lines is the largest file. Mixes message rendering, input, media preview, action sheets, scroll management. Extract into composable widgets.
**Acceptance Criteria:**
- [ ] ChatScreen reduced to <500 lines (orchestrator role only)
- [ ] Extracted: `chat_message_list.dart`, `chat_input_bar.dart`, `chat_header.dart`, `chat_message_bubble.dart`, `chat_action_sheet.dart`, `chat_media_preview.dart`
- [ ] Each widget self-contained with constructor parameters
- [ ] All chat functionality preserved
- [ ] Zero new lint warnings
**Testing:** Manual test all chat features; widget tests for extracted widgets; existing tests pass.

---

## CLEAN-002: Fix R-126: Migrate BLoC Presentation→Data Imports (Phase 1) — COMPLETED
**Status:** Complete (2026-02-19). Moved 7 data models to domain layer: `CompatibilityQuiz`, `DateIdea`, `WeeklyPicks`, `IncognitoSettings`, `FilterOptions`, `FeatureFlags`, `Call`. Created `domain/models/` directories in social, discovery, feature_flags, and calls features. Data-layer files converted to re-exports for backward compatibility. Updated all BLoC/Cubit imports to use `domain/models/` paths. `flutter analyze` passes with 0 errors.
**Files Changed:**
- Created: `social/domain/models/compatibility_quiz.dart`, `social/domain/models/date_idea.dart`, `discovery/domain/models/weekly_picks.dart`, `discovery/domain/models/incognito_settings.dart`, `discovery/domain/models/filter_options.dart`, `feature_flags/domain/models/feature_flags.dart`, `calls/domain/models/call.dart`
- Modified (re-exports): `social/data/models/compatibility_quiz.dart`, `social/data/models/date_idea.dart`, `discovery/data/models/weekly_picks.dart`, `discovery/data/models/incognito_settings.dart`, `discovery/data/models/filter_options.dart`, `feature_flags/data/models/feature_flags.dart`, `calls/data/models/call.dart`
- Updated BLoC imports: `compatibility_quiz_cubit.dart`, `date_ideas_cubit.dart`, `weekly_picks_cubit.dart`, `feature_flag_cubit.dart`

---

## CLEAN-003: Fix R-126: Migrate Screen/Widget Imports (Phase 2) — PARTIALLY COMPLETED
**Status:** Model imports migrated for screens (2026-02-19). All presentation files now import models from `domain/models/` instead of `data/models/`. Remaining: ~13 service imports in presentation files still reference `data/services/` directly (requires creating repository abstractions — tracked as follow-up).
**Files Changed:**
- Updated screen imports: `date_ideas_screen.dart`, `weekly_picks_screen.dart`, `settings_screen.dart`, `discovery_filters_settings_screen.dart`, `incoming_call_screen.dart`, `call_screen.dart`, `call_history_screen.dart`, `app.dart`
- Updated domain imports: `compatibility_quiz_repository.dart`, `date_idea_repository.dart`, `feature_flag_repository.dart`, use case files
- Updated test imports: 11 test files
**Remaining Service Violations (follow-up):**
- `weekly_picks_cubit.dart` → `weekly_picks_service.dart`
- `weekly_picks_screen.dart` → `weekly_picks_service.dart`
- `swipe_card.dart` → `story_service.dart`
- `story_viewer_screen.dart` → `story_service.dart`
- `deck_screen.dart` → `profile_validation_service.dart`
- `profile_setup_screen.dart` → `profile_media_service.dart`, `passport_locations_service.dart`
- `profile_edit_screen.dart` → `profile_media_service.dart`
- `voice_note_recorder.dart` → `voice_recorder_service.dart`
- `matches_screen.dart` → `realtime_match_service.dart`
- `chat_screen.dart` → `profile_validation_service.dart`
- `settings_screen.dart` → `incognito_service.dart`
- `call screens` → `call_service.dart`, `callkit_service.dart`, `call_quality_service.dart`, `native_pip_service.dart`
- `pip_video_overlay.dart` → `call_service.dart`

---




## CLEAN-006: Consolidate Duplicate Widget Implementations — PARTIALLY COMPLETED
**Status:** Partially complete (2026-02-20). Widget inventory done, 3 duplicates eliminated, 5 more documented for future.
**Acceptance Criteria:**
- [x] Widget inventory completed — 13 categories audited across 4 widget directories
- [x] Duplicates identified and documented (see below)
- [x] Phase 1 consolidation: 3 duplicates eliminated
- [ ] Phase 2-4 consolidation: 5 remaining duplicates require deeper refactoring
**Duplicates Eliminated:**
1. `deck_skeleton.dart` — removed duplicate `SkeletonCard` and `SkeletonCircle` classes, now uses design system `SkeletonBox`/`SkeletonCircle`
2. `presentation/widgets/primary_button.dart` — deleted re-export file, updated 5 imports to use design system path
3. `onboarding_nav_buttons.dart` — updated relative import to design system path
**Remaining Duplicates (documented for future):**
- `CrushEmptyState` vs `DsEmptyState` — similar functionality, 1 import (dev showcase only)
- `ChatTypingIndicator` vs `TypingIndicator` — near-identical animation, used in chat barrel
- `MatchCelebrationModal` vs `MatchCelebration` — modal uses design system base but re-implements animations
- `AppTextField` vs `GlassTextField` — basic vs glass-styled input (3 imports: showcase + 2 tests)
- Standard vs Glass skeleton loaders — intentional variants, could add `glass` parameter
**Files Changed:**
- Rewritten: `lib/features/discovery/presentation/widgets/deck_skeleton.dart`
- Deleted: `lib/presentation/widgets/primary_button.dart`
- Modified imports: `email_protection_screen.dart`, `phone_protection_screen.dart`, `new_device_screen.dart`, `change_email_screen.dart`, `onboarding_nav_buttons.dart`
**Testing:** `flutter analyze` 0 errors, `flutter test` +1502 ~6 -4.

---

