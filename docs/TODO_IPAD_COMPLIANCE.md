# TODO: iPad Compliance

- Priority: P0 – Critical
- Estimated Effort: 4-7 days
- Dependencies: `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_ACCESSIBILITY.md`, `docs/TODO_TESTING_MATRIX.md`
- Assigned: AI + Developer

## Tasks

### IPAD-001 - Run screen-by-screen iPad layout audit
- Files: all presentation routes and shared overlays
- Description: Verify every screen for constrained widths, readable layouts, and no stretched phone-only assumptions.
- Acceptance Criteria: each screen is marked pass, fail, or blocked with evidence.
- Testing: manual matrix on iPad Mini, Air, 11-inch Pro, and 13-inch Pro classes.
- Status: open

### IPAD-002 - Audit orientation, Split View, Slide Over, and Stage Manager behavior
- Files: responsive layouts, router/state preservation flows, media capture and chat/call surfaces
- Description: Validate that state survives window changes and that layouts adapt correctly in narrow and wide multitasking widths.
- Acceptance Criteria: supported multitasking modes are tested with blockers linked to owning modules.
- Testing: manual multitasking matrix and route-state validation.
- Status: open

### IPAD-003 - Verify iPad-specific presentations and input methods
- Files: pickers, popovers, share sheets, dialogs, bottom sheets, keyboard/focus handlers
- Description: Confirm iPad popover anchors, share/picker presentations, external keyboard navigation, pointer support, and Pencil-friendly text input behavior.
- Acceptance Criteria: no iPad-specific presentation crashes; input methods behave predictably.
- Testing: manual picker/dialog/share-sheet checks on iPad simulator or device.
- Status: open
