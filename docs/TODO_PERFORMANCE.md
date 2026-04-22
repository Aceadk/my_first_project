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
- Status: open

### PERF-002 - Audit frame pacing on discovery, chat, and profile-heavy screens
- Files: discovery deck, chat screens, profile media/view screens
- Description: Identify jank sources and expensive rebuild paths on the most interactive surfaces.
- Acceptance Criteria: top jank hotspots are measured and prioritized; major rebuild offenders are tracked or fixed.
- Testing: DevTools profiling and targeted interaction smoke tests.
- Status: open

### PERF-003 - Run web bundle analysis and code-splitting pass
- Files: `/Users/ace/crush-web/apps/web/**`, build configuration, route-level imports
- Description: Audit bundle composition and reduce unnecessary app/runtime code on marketing and auth-heavy entry points.
- Acceptance Criteria: bundle report produced; code-splitting actions identified or shipped.
- Testing: production build analysis and Lighthouse comparison.
- Status: open

### PERF-004 - Run image optimization audit across mobile and web
- Files: profile/discovery/chat media pipelines, asset catalogs, web image usage
- Description: Ensure thumbnails, responsive images, and upload processing use appropriate dimensions and formats.
- Acceptance Criteria: oversized image hotpaths are identified and remediation plan exists.
- Testing: network and render-size spot checks on key screens.
- Status: open
