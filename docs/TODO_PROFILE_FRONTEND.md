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
- Status: open

### PROF-FE-002 - Harden photo upload, crop, reorder, and picker UX
- Files: profile media widgets, picker/crop flows, camera/gallery integrations
- Description: Verify photo flows behave correctly across iPad popovers, Android pickers, web uploads, and drag/reorder interactions.
- Acceptance Criteria: upload, crop, reorder, and delete flows behave consistently; iPad presentations do not crash or stretch.
- Testing: widget tests where possible plus manual picker/crop smoke runs.
- Status: open

### PROF-FE-003 - Audit profile completion guidance and validation copy
- Files: profile setup screens, validation helpers, empty/error states
- Description: Ensure partial profiles have clear next actions, validation is understandable, and large-text / screen-reader behavior remains intact.
- Acceptance Criteria: incomplete states guide users cleanly; validation copy is specific and accessible.
- Testing: widget tests for validation states and manual accessibility spot checks.
- Status: open
