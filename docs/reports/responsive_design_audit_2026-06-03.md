# Responsive & Adaptive Design Audit - 2026-06-03

Scope: `RESP-001`–`RESP-003` from [`docs/TODO_RESPONSIVE_DESIGN.md`](../TODO_RESPONSIVE_DESIGN.md).

Surfaces reviewed: shared design tokens
([`breakpoints.dart`](../../lib/design_system/tokens/breakpoints.dart)),
adaptive scaffolds/layouts
([`responsive_scaffold.dart`](../../lib/design_system/widgets/responsive_scaffold.dart),
[`adaptive_layout.dart`](../../lib/design_system/widgets/adaptive_layout.dart)),
the primary navigation shell
([`home_screen.dart`](../../lib/presentation/screens/home_screen.dart)), and the
discovery, profile, chat, settings, and support grid/list/media surfaces.

## Result

The app already has a mature, broadly-applied responsive system, so this was a
**verification** pass with one concrete fix. The standardized breakpoint tokens
are in place and the primary navigation shell adapts correctly
(bottom nav → navigation rail). Grids use adaptive column counts and media is
constrained to fixed aspect ratios with `BoxFit.cover` (no stretching). One real
gap was **fixed**: there was no app-wide `ScrollBehavior`, so click-and-drag
scrolling did not work for mouse/stylus users on web, desktop, and
pointer-equipped tablets.

Legend: ✅ verified · 🔧 fixed · ⚠️ manual/tracked.

---

## RESP-001 - Breakpoints, max widths, adaptive navigation

Status: ✅ verified

- **Shared breakpoint tokens** live in
  [`DsBreakpoints`](../../lib/design_system/tokens/breakpoints.dart):
  compact `<360`, mobile `<600`, tablet `<1024`, desktop `<1440`, large desktop
  `≥1440`, plus helpers (`isMobile/isTablet/isDesktop`, `responsiveValue`,
  `gridColumns`, `contentMaxWidth`). The `ResponsiveContext` extension exposes
  `context.isMobile/isTablet/isDesktop` and `context.responsive(...)`.
- **Content max widths** are tokenized: tablet 720, desktop 960, large desktop
  1200, and applied via `ResponsiveScaffold` / `AdaptiveLayout` / the
  `_CenteredContent` helper.
- **Adaptive navigation** in the primary shell
  ([`home_screen.dart`](../../lib/presentation/screens/home_screen.dart)) switches
  on `DsBreakpoints`: `GlassBottomNavBar` below the mobile breakpoint, and a
  `NavigationRail` (extended on desktop) at tablet+ — verified consistent with
  the design-system `AdaptiveScaffold` pattern.
- ⚠️ **Content-density breakpoints** in
  [`profile_media_screen.dart`](../../lib/features/profile/presentation/screens/profile_media_screen.dart),
  [`profile_adaptive_layout.dart`](../../lib/features/profile/presentation/widgets/profile_adaptive_layout.dart),
  and [`support_screen.dart`](../../lib/features/settings/presentation/screens/support_screen.dart)
  use a few local pixel thresholds (e.g. `≥760`, `≥900`, `≥1100`) to tune grid
  column counts for media-dense content. These are intentional, item-sized
  density tuning distinct from the global layout breakpoints, not a
  navigation-layout inconsistency — left as-is.

## RESP-002 - Grid, list, and media aspect-ratio behavior

Status: ✅ verified

- **Adaptive column counts.** Discovery
  ([`explore_grid_view.dart`](../../lib/features/discovery/presentation/widgets/explore_grid_view.dart)
  → `gridColumnsOf().clamp(2, 3)`), likes-you and profile galleries
  (`gridColumnsOf().clamp(2, 4)`) increase columns intentionally with width
  rather than stretching a fixed count.
- **Aspect-ratio integrity.** Grid tiles use fixed `childAspectRatio`
  (0.7–0.8) and media is wrapped in `AspectRatio` containers; images render with
  `BoxFit.cover` (the
  [`CachedNetworkImage`](../../lib/shared/widgets/cached_network_image.dart)
  default). A repo-wide search found **no `BoxFit.fill`**, so media is never
  stretched out of ratio on large screens.
- **Content centering.** Wide grids are wrapped in a `ConstrainedBox` keyed to
  `DsBreakpoints.contentMaxWidth(...)` so content doesn't run edge-to-edge on
  desktop.

## RESP-003 - Scroll, hover, and pointer behavior on tablet/web

Status: 🔧 mouse-drag scrolling fixed; ✅ hover/focus verified

- 🔧 **Click-and-drag scrolling fix.** Flutter's default `MaterialScrollBehavior`
  omits `PointerDeviceKind.mouse` from `dragDevices`, so on web/desktop a
  click-drag gesture did **not** scroll lists or grids (only the wheel/trackpad
  did). Added [`AppScrollBehavior`](../../lib/core/ui/app_scroll_behavior.dart)
  (mouse + touch + trackpad + stylus drag) and wired it into
  `MaterialApp.router` ([`app.dart`](../../lib/app.dart)). Covered by
  [`test/core/ui/app_scroll_behavior_test.dart`](../../test/core/ui/app_scroll_behavior_test.dart),
  including a widget test that drives a mouse drag and asserts the list scrolls.
- ✅ **Hover/focus.** Interactive elements are built on Material
  `InkWell`/button widgets and `NavigationRail`/`NavigationBar`, which expose
  built-in hover and focus highlights on platforms that support a pointer — no
  custom `MouseCursor`/`onHover` wiring is required for native-feeling
  affordances.
- ✅ **Scroll physics.** `MaterialScrollBehavior` continues to provide
  platform-appropriate physics and scrollbars; only the drag-device set was
  widened.

---

## Existing test coverage

The responsive system is regression-guarded by
[`design_system_breakpoints_test.dart`](../../test/design_system_breakpoints_test.dart)
and 7 per-screen `*_responsive_test.dart` suites (chat list/screen, calls,
discovery filters, date ideas, terms, PIN fallback), now joined by the new
`app_scroll_behavior_test.dart`.

## Changed files

- `lib/core/ui/app_scroll_behavior.dart` (new)
- `lib/app.dart` (wire `scrollBehavior`)
- `test/core/ui/app_scroll_behavior_test.dart` (new)
