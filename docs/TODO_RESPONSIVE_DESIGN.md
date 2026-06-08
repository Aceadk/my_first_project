# TODO: Responsive & Adaptive Design

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_IPAD_COMPLIANCE.md`, `docs/TODO_ACCESSIBILITY.md`
- Assigned: AI + Developer

## Tasks

### RESP-001 - Standardize breakpoints, max widths, and adaptive navigation rules
- Files: design tokens, shared scaffolds, routing/navigation containers
- Description: Define and apply the compact/medium/expanded breakpoint strategy across mobile, tablet, and web.
- Acceptance Criteria: shared breakpoint rules exist and are applied consistently in primary navigation surfaces.
- Testing: widget/manual checks across representative widths.
- Status: done (2026-06-03). Verified shared `DsBreakpoints` tokens (compact/mobile/tablet/desktop/large-desktop + content max widths) and the primary shell (`home_screen.dart`) switching `GlassBottomNavBar` → `NavigationRail` on `DsBreakpoints`. A few local content-density thresholds in profile/support grids are intentional item-sizing, not layout inconsistencies. Report: `docs/reports/responsive_design_audit_2026-06-03.md`.

### RESP-002 - Audit grid, list, and media aspect-ratio behavior on large screens
- Files: discovery, profile, chat, settings, and support UI surfaces
- Description: Ensure grids increase columns intentionally and media keeps correct aspect ratio without stretching.
- Acceptance Criteria: adaptive column counts and aspect-ratio containers are consistent.
- Testing: screenshot or widget checks across width classes.
- Status: done (2026-06-03). Verified discovery/likes/profile grids use adaptive `gridColumnsOf().clamp(...)` column counts, fixed `childAspectRatio` tiles, `AspectRatio` media containers, and `BoxFit.cover` (no `BoxFit.fill` anywhere → no stretching). Wide grids constrained to `DsBreakpoints.contentMaxWidth`. Report: `docs/reports/responsive_design_audit_2026-06-03.md`.

### RESP-003 - Validate scroll, hover, and pointer behavior on tablet and web
- Files: scrollables, hoverable widgets, desktop/tablet affordances
- Description: Confirm scroll physics, hover states, and pointer interactions feel native on larger input surfaces.
- Acceptance Criteria: interactive elements expose appropriate hover/focus behavior where supported.
- Testing: manual tablet/web interaction review.
- Status: done (2026-06-03). **Fixed:** added `AppScrollBehavior` (mouse+touch+trackpad+stylus `dragDevices`) wired into `MaterialApp.router` so click-and-drag scrolling works on web/desktop/pointer tablets — Flutter's default omits mouse drag. Hover/focus verified via Material `InkWell`/button/`NavigationRail` built-ins. Test: `test/core/ui/app_scroll_behavior_test.dart`. Report: `docs/reports/responsive_design_audit_2026-06-03.md`.

### RESP-004 - Publish shared web/mobile semantic design and navigation contracts
- Files: `docs/design_tokens.json`, web Tailwind/theme tokens, mobile design system, app shells/navigation, shared UX documentation
- Description: Align brand and interaction semantics without forcing identical platform rendering. Define shared semantic tokens and document intentional desktop/mobile information-architecture differences.
- Dependencies: product/design decision; execute after P0 operational gates
- Acceptance Criteria:
  - Shared semantic contract covers color roles, typography roles, spacing, radii, elevation, motion, focus, and component states.
  - Web/mobile typography, radii, and breakpoint differences are explicitly approved or aligned.
  - Primary user goals and equivalent destinations are documented across mobile and desktop navigation.
  - Loading, empty, error, offline, retry, optimistic, blocked, and permission-denied states use consistent behavior.
  - Critical screens have responsive/visual acceptance references.
- Testing:
  - Visual regression coverage for critical web widths and mobile/tablet states.
  - Token validation and contrast checks.
  - Manual cross-platform journey review.
- Status: open — P1 UX alignment task.
