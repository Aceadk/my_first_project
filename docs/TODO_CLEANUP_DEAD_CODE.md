# TODO: Codebase Cleanup & Dead Code Removal
**Priority:** P2
**Estimated Effort:** 15-25 hours
**Dependencies:** Clean architecture domain interfaces resolved, ChatBloc split completed
**Assigned:** AI + Developer

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

## CLEAN-002: Fix R-126: Migrate BLoC Presentation→Data Imports (Phase 1)
**Files:** All BLoC/Cubit files under `lib/features/*/presentation/bloc/`
**Description:** ~20 BLoC files still import data-layer models directly. Phase 1 focuses on BLoC/Cubit files.
**Acceptance Criteria:**
- [ ] All BLoCs import only from domain layer or shared DTOs
- [ ] No BLoC imports from `*/data/repositories/impl/`, `*/data/services/`
- [ ] Shared models via `package:crushhour/shared/dto/dto.dart`
- [ ] `flutter analyze` passes
**Testing:** Grep for data imports in BLoC directories; all tests pass.

---

## CLEAN-003: Fix R-126: Migrate Screen/Widget Imports (Phase 2)
**Files:** All screens/widgets under `lib/features/*/presentation/`
**Description:** ~50+ presentation files import data layer. After BLoCs clean (CLEAN-002), migrate screens and widgets.
**Acceptance Criteria:**
- [ ] Zero imports from data layer in presentation files
- [ ] R-126 in risk_notes.md marked RESOLVED
- [ ] Violating file count: 73 → 0
**Testing:** Grep verification; analyze; manual smoke test.

---

## CLEAN-004: Remove All Raw print() Calls
**Files:** `lib/core/security/secure_logger.dart`, full codebase scan
**Description:** `secure_logger.dart` has 10+ raw `print()` calls. Sweep for any new `print()` since migration.
**Acceptance Criteria:**
- [ ] Zero `print()` in `lib/` except `app_logger.dart`
- [ ] `secure_logger.dart` uses `AppLogger` methods
- [ ] Release build produces zero application console output
**Testing:** Grep for print(); release mode console check.

---

## CLEAN-005: Extract ChatScreen Inline Styles to Design System Tokens
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`, `lib/design_system/tokens/`
**Description:** ChatScreen has hardcoded colors, padding, font sizes, border radii instead of design system tokens.
**Acceptance Criteria:**
- [ ] Zero hardcoded `Color(0x...)` — all use `CrushColors` or theme
- [ ] Zero hardcoded `EdgeInsets` — all use `CrushSpacing`
- [ ] Zero hardcoded `fontSize` — all use `CrushTypography`
- [ ] Visual appearance unchanged (screenshot comparison)
**Testing:** Visual regression; dark mode verification; analyze clean.

---

## CLEAN-006: Consolidate Duplicate Widget Implementations
**Files:** `lib/design_system/widgets/`, `lib/features/*/presentation/widgets/`
**Description:** Audit for duplicate widgets: empty states, loading indicators, avatars, cards.
**Acceptance Criteria:**
- [ ] Widget inventory completed
- [ ] Duplicates identified and documented
- [ ] Canonical version kept in design system, others replaced
- [ ] All import references updated
**Testing:** Analyze passes; tests pass; manual smoke test.

---

## CLEAN-007: Add Barrel Files for Feature Modules
**Files:** `lib/features/*/` directories
**Description:** Some features have barrel files, others don't. Create barrel files exporting public API only.
**Acceptance Criteria:**
- [ ] Every feature has `lib/features/{feature}/{feature}.dart`
- [ ] Exports: domain entities, repository interfaces, BLoC classes
- [ ] Does NOT export data internals
- [ ] No circular dependency warnings
**Testing:** Analyze; verify barrel imports work.

---

## CLEAN-008: Audit and Remove Unused Assets
**Files:** `assets/`, `pubspec.yaml`
**Description:** Unused images/animations/fonts increase bundle size (60.3MB AAB).
**Acceptance Criteria:**
- [ ] All assets cross-referenced against source usage
- [ ] Unused assets removed from filesystem and pubspec
- [ ] Bundle size reduced (measure before/after)
**Testing:** Build AAB before/after; navigate all screens; tests pass.
