# TODO: Profile Frontend Module

- Priority: P1 – High
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_PROFILE_BACKEND.md`, `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_ACCESSIBILITY.md`
- Assigned: AI + Developer

## Tasks

### PROF-FE-001 - Make profile create/edit flows intentional on phone, iPad, tablet, and web
- Files: `lib/features/profile/presentation/**`, `/Users/ace/crush-web/**/profile/**`
- Description: Audit profile creation, edit, and view flows for readable widths, adaptive grids, and tablet/web layout quality.
- Acceptance Criteria: profile UI respects breakpoints and max content widths; no stretched single-column layouts on large screens.
- Testing: widget screenshots or manual checks on phone, iPad portrait, iPad landscape, and desktop web.
- Status: completed
- Evidence: Added shared Flutter `ProfileAdaptiveLayoutMetrics`, applied phone/tablet/desktop content widths to setup/edit/view, split setup/edit into adaptive columns where width and text scale allow, and widened web profile edit/view/preview surfaces into responsive side-rail layouts. See `docs/reports/profile_frontend_audit_2026-05-30.md`.

### PROF-FE-002 - Harden photo upload, crop, reorder, and picker UX
- Files: profile media widgets, picker/crop flows, camera/gallery integrations
- Description: Verify photo flows behave correctly across iPad popovers, Android pickers, web uploads, and drag/reorder interactions.
- Acceptance Criteria: upload, crop, reorder, and delete flows behave consistently; iPad presentations do not crash or stretch.
- Testing: widget tests where possible plus manual picker/crop smoke runs.
- Status: completed
- Evidence: Flutter media picker now has explicit empty-state guidance, horizontal reorder, keyboard/tap move controls, primary-photo retention, and adaptive tile sizes. Web media picker validates JPG/PNG/WebP and 10 MB limits, supports crop error handling, stable drag IDs, visible move/remove controls, and accessible labels. iPad popover and Android bottom-sheet tests pass; remaining live picker/crop device smoke checks are release-gate manual items.

### PROF-FE-003 - Audit profile completion guidance and validation copy
- Files: profile setup screens, validation helpers, empty/error states
- Description: Ensure partial profiles have clear next actions, validation is understandable, and large-text / screen-reader behavior remains intact.
- Acceptance Criteria: incomplete states guide users cleanly; validation copy is specific and accessible.
- Testing: widget tests for validation states and manual accessibility spot checks.
- Status: completed
- Evidence: Added reusable Flutter and web completion-guidance helpers, specific required/recommended action copy, save blocking for incomplete visible web profiles, visible bio/interests validation hints, and completion cards that list next actions instead of only showing a percent.
