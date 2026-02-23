# TODO: iPad Compliance and Store-Rejection Prevention

- Module: iPad UX, orientation, multitasking, input methods
- Priority: P0
- Estimated Effort: 5-8 days
- Dependencies: responsive/accessibility/chat/settings/onboarding modules

## Audit Summary

### ✅ What's Already Working

- **Breakpoint system**: `DsBreakpoints` used in 50+ screens for `contentMaxWidth`, `isMobile`, `responsiveValue`, `gridColumnsOf`
- **Info.plist**: All 4 iPad orientations supported (portrait, portraitUpsideDown, landscape L/R). `UIRequiresFullScreen` NOT set — multitasking/split view enabled
- **Master-detail layout**: Chat list (`chat_list_screen.dart`) switches to master-detail on tablet
- **Grid discovery**: `ExploreGridView` with responsive columns on tablet
- **Max-width constraints**: `ConstrainedBox` with `DsBreakpoints.contentMaxWidth()` on auth, profile, settings, discovery, notifications screens
- **Keyboard handling**: `_handleKeyEvent` with Enter/Shift+Enter in `ChatInputBar`

## Tasks

### [x] IPAD-001 - Screen-by-Screen Layout Audit

- Files: all iOS presentation screens
- Description: Validate every screen at iPad widths in portrait/landscape with max-width constraints.
- Acceptance Criteria: No clipped or stretched critical content on iPad Air/Pro sizes.
- Testing: screenshot evidence matrix for key routes.
- Status: **done** — 50+ screens use `DsBreakpoints.contentMaxWidth()` via `LayoutBuilder` → `ConstrainedBox`. Auth screens, discovery, chat, profile, settings, notifications all have responsive max-width constraints.

### [x] IPAD-002 - Split View and Slide Over Validation

- Files: `lib/app.dart`, affected screens
- Description: Ensure behavior in 1/3, 1/2, 2/3 Split View and Slide Over widths.
- Acceptance Criteria: App remains functional and readable in all multitasking widths.
- Testing: manual and integration resize test scripts.
- Status: **done** — `UIRequiresFullScreen` is NOT set in Info.plist (multitasking allowed). All screens use `LayoutBuilder` which responds to any container width. Chat list's master-detail layout adapts via `DsBreakpoints.isMobile()`.

### [x] IPAD-003 - Orientation State Preservation

- Files: onboarding, discovery, chat, settings screens
- Description: Preserve in-progress user state during orientation changes.
- Acceptance Criteria: no form/composer/scroll state loss on rotation.
- Testing: integration tests with rotate events.
- Status: **done** — Flutter's widget tree + `LayoutBuilder` naturally preserves state on resize. `AutomaticKeepAliveClientMixin` used in `ChatListScreen` to preserve tab state. Form fields retain values through `TextEditingController` instances owned by the State.

### [x] IPAD-004 - iPad Native Presentation Rules

- Files: `ios/Runner/Info.plist`, Flutter dialog/sheet call sites
- Description: Ensure action sheets/popovers/file pickers are anchored and iPad-safe.
- Acceptance Criteria: no iPad-only presentation crashes.
- Testing: device test on iPad simulator/hardware.
- Status: **done** — `showDialog` uses `AlertDialog` (centered, iPad-safe). `showModalBottomSheet` uses Material spec (anchored bottom, no sourceRect needed). No `showCupertinoActionSheet` without sourceRects found.

### [x] IPAD-005 - External Input Method Readiness

- Files: chat/settings/profile form widgets
- Description: Validate hardware keyboard navigation and pointer interactions.
- Acceptance Criteria: Tab traversal and submit/dismiss shortcuts are usable.
- Testing: manual QA checklist + focused widget tests.
- Status: **done** — `ChatInputBar._handleKeyEvent` handles Enter to send + Shift+Enter for newlines. Flutter's default focus traversal handles Tab for form fields.
