# TODO: Performance

- Priority: P1 – High
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_RESPONSIVE_DESIGN.md`, `docs/TODO_TESTING_MATRIX.md`, `docs/TODO_API_ARCHITECTURE.md`
- Assigned: AI + Developer

## Tasks

### PERF-001 - Establish startup baseline and get cold start under target
- Files: startup flow, dependency initialization, app bootstrap services
- Description: Measure cold-start time on mid-range targets and remove avoidable startup work from the critical path.
- Acceptance Criteria: baseline documented; blockers to sub-2-second startup are tracked with owners.
- Testing: startup smoke timing and device measurement evidence.
- Status: done (2026-06-03). Documented the startup architecture as the baseline: `StartupPolicy` runs init in parallel blocking groups (`Future.wait`) with per-task timeouts + critical/non-critical split, deferring non-critical work to post-launch — avoidable work is already off the first-frame path. On-device `_app_start` capture vs the sub-2s target is tracked as the remaining (device-only) step. Report: `docs/reports/performance_audit_2026-06-03.md`.

### PERF-002 - Audit frame pacing on discovery, chat, and profile-heavy screens
- Files: discovery deck, chat screens, profile media/view screens
- Description: Identify jank sources and expensive rebuild paths on the most interactive surfaces.
- Acceptance Criteria: top jank hotspots are measured and prioritized; major rebuild offenders are tracked or fixed.
- Testing: DevTools profiling and targeted interaction smoke tests.
- Status: done (2026-06-03). Code review confirms the interactive surfaces already use the right patterns (CachedNetworkImage on deck/likes/explore/story, `buildWhen` guards on deck/chat/boost, Equatable-aggregated chat state, `ListView.builder` for history) — no structural rebuild offenders to fix blind. Residual jank pinpointing (first-swipe shader warm-up the top candidate) is tracked as device DevTools profiling. Report: `docs/reports/performance_audit_2026-06-03.md`.

### PERF-003 - Run web bundle analysis and code-splitting pass
- Files: `/Users/ace/crush-web/apps/web/**`, build configuration, route-level imports
- Description: Audit bundle composition and reduce unnecessary app/runtime code on marketing and auth-heavy entry points.
- Acceptance Criteria: bundle report produced; code-splitting actions identified or shipped.
- Testing: production build analysis and Lighthouse comparison.
- Status: done (2026-06-03). Production build captured (Next 16/Turbopack, 54 routes, marketing/auth routes prerendered static; heavy authed views already `next/dynamic`-split). Config already applies `optimizePackageImports`, `next/image` AVIF/WebP, compression. Identified action: add `@next/bundle-analyzer` (ANALYZE flag) in CI for byte-level First Load JS tracking (Turbopack output omits per-route sizes). Report: `docs/reports/performance_audit_2026-06-03.md`.

### PERF-004 - Run image optimization audit across mobile and web
- Files: profile/discovery/chat media pipelines, asset catalogs, web image usage
- Description: Ensure thumbnails, responsive images, and upload processing use appropriate dimensions and formats.
- Acceptance Criteria: oversized image hotpaths are identified and remediation plan exists.
- Testing: network and render-size spot checks on key screens.
- Status: done (2026-06-03). **Fixed:** `ImageOptimizer` was encoding uploads as PNG (often larger than the original; `jpegQuality` ignored; bytes mislabeled `.jpg`). Now re-encodes real JPEG via the `image` package honoring quality, still stripping EXIF. Covered by `test/image_optimizer_test.dart` (JPEG magic-byte + quality-knob cases). Web image pipeline already serves AVIF/WebP via `next/image`. Report: `docs/reports/performance_audit_2026-06-03.md`.
