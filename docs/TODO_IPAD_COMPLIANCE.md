# TODO: iPad Compliance and Store-Rejection Prevention

- Module: iPad UX, orientation, multitasking, input methods
- Priority: P0
- Estimated Effort: 5-8 days
- Dependencies: responsive/accessibility/chat/settings/onboarding modules

## Tasks

### IPAD-001 - Screen-by-Screen Layout Audit
- Files: all iOS presentation screens
- Description: Validate every screen at iPad widths in portrait/landscape with max-width constraints.
- Acceptance Criteria: No clipped or stretched critical content on iPad Air/Pro sizes.
- Testing: screenshot evidence matrix for key routes.
- Status: todo

### IPAD-002 - Split View and Slide Over Validation
- Files: `lib/app.dart`, affected screens
- Description: Ensure behavior in 1/3, 1/2, 2/3 Split View and Slide Over widths.
- Acceptance Criteria: App remains functional and readable in all multitasking widths.
- Testing: manual and integration resize test scripts.
- Status: todo

### IPAD-003 - Orientation State Preservation
- Files: onboarding, discovery, chat, settings screens
- Description: Preserve in-progress user state during orientation changes.
- Acceptance Criteria: no form/composer/scroll state loss on rotation.
- Testing: integration tests with rotate events.
- Status: todo

### IPAD-004 - iPad Native Presentation Rules
- Files: `ios/Runner/Info.plist`, Flutter dialog/sheet call sites
- Description: Ensure action sheets/popovers/file pickers are anchored and iPad-safe.
- Acceptance Criteria: no iPad-only presentation crashes.
- Testing: device test on iPad simulator/hardware.
- Status: todo

### IPAD-005 - External Input Method Readiness
- Files: chat/settings/profile form widgets
- Description: Validate hardware keyboard navigation and pointer interactions.
- Acceptance Criteria: Tab traversal and submit/dismiss shortcuts are usable.
- Testing: manual QA checklist + focused widget tests.
- Status: todo
