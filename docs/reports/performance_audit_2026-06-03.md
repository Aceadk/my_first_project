# Performance Audit - 2026-06-03

Scope: `PERF-001`–`PERF-004` from [`docs/TODO_PERFORMANCE.md`](../TODO_PERFORMANCE.md).

Surface reviewed: mobile startup (`lib/main.dart`, `StartupPolicy`), the most
interactive screens (discovery deck, chat, profile media), the image pipeline
(`lib/core/media/image_optimizer.dart`, `profile_media_service.dart`), and the
web app build config (`/Users/ace/crush-web/apps/web`).

## Result

PERF-004 found and **fixed** a concrete image-pipeline bug (uploads were encoded
as PNG, not JPEG — often larger than the original, with the quality knob dead).
PERF-001/002 are architecturally sound from code review; the remaining work is
on-device measurement, documented with baselines + capture method. PERF-003: the
web app already follows bundle best practices (Turbopack, package-import
optimization, `next/image`, existing `next/dynamic` splitting); a build-size
snapshot is included.

Legend: ✅ verified · ⚠️ tracked (needs device/CI) · 🔧 fixed this pass.

---

## PERF-004 - Image optimization (mobile + web) — 🔧 fixed

### The bug
`ImageOptimizer._encodeAsJpeg` (despite its name) encoded output with
`ui.ImageByteFormat.png`. dart:ui's `toByteData` only emits PNG or raw RGBA, so
every "optimized" profile/chat image was a **lossless PNG**:
- For photographic content PNG is typically **3–5× larger** than an equivalent
  JPEG, so an "optimized" upload could be *bigger* than the original — inflating
  upload bandwidth, Storage cost, and download/render size on every view.
- The `jpegQuality` config was **silently ignored** (PNG ignores it).
- Files were named `.jpg` and uploaded with `image/jpeg` content-type while
  containing PNG bytes (mislabeling).

### The fix
`_encodeAsJpeg` now pulls raw RGBA from the resized `ui.Image` and re-encodes to
real JPEG via the `image` package (`img.encodeJpg(decoded, quality: quality)`).
The full re-encode still strips EXIF/metadata (preserving the PROF-BE-002 privacy
property), now honours the quality setting, and produces correctly-typed JPEG
bytes. `image` was moved from `dev_dependencies` to `dependencies` for runtime use.

Covered by `test/image_optimizer_test.dart`: asserts JPEG SOI magic bytes
(`0xFFD8`) on both full-size and thumbnail output, and that lower quality yields a
smaller file (the knob is wired). Measured in-test: quality 95 → 122 KB vs
quality 30 → 27 KB on a 256×256 high-frequency image.

### Web image pipeline ✅
`next.config.js` already serves AVIF/WebP via `next/image` with tuned
`deviceSizes`/`imageSizes` and a 30-day `minimumCacheTTL`. No change needed.

---

## PERF-001 - Startup baseline and cold start

Status: ✅ architecture sound; ⚠️ device baseline capture tracked

- Startup is driven by a `StartupPolicy` (`lib/main.dart`): tasks run in
  **parallel blocking groups** (`Future.wait`) with per-task timeouts and a
  critical/non-critical split; non-critical work is deferred to
  `_schedulePostLaunchTasks`. Firebase init, App Check, crash reporting,
  performance, consent, and platform services are grouped; push/tracking-consent
  are post-launch. This already keeps avoidable work off the first-frame path.
- `PerformanceMonitor` (Firebase Performance) is initialized during startup and
  exposes screen/custom traces; memory monitoring starts post-launch in release.
- ⚠️ The sub-2-second target needs an on-device number (Firebase Performance
  `_app_start` trace on a mid-range device) — not capturable in this environment.
  *Tracked:* record `_app_start` p50/p90 from a mid-range Android device and, if
  over target, profile the blocking group for the slowest task via the per-task
  trace timings the policy already produces.

---

## PERF-002 - Frame pacing on discovery, chat, and profile screens

Status: ✅ fundamentals in place; ⚠️ device DevTools profiling tracked

Code review of the most interactive surfaces shows the right patterns are already
used, so there are no obvious structural jank sources to fix blind:
- **Images:** discovery deck (`deck_card_stack.dart`, `swipe_card.dart`),
  Likes-You, explore grid, and story viewer all use `CachedNetworkImage`
  (mem+disk cache) rather than raw `Image.network`.
- **Rebuild scoping:** deck, chat, and boost surfaces use `BlocBuilder.buildWhen`
  guards to limit rebuilds; the chat facade aggregates sub-BLoC state through an
  Equatable state so high-frequency typing/presence updates don't rebuild the
  tree (see realtime audit).
- **Lists:** chat history uses `ListView.builder` (lazy), not eager `ListView(...)`.
- ⚠️ Pinpointing residual jank (e.g., shader compilation on first swipe, image
  decode on large hero photos) requires DevTools timeline capture on device.
  *Tracked:* run a profile-mode timeline on deck swipe + chat scroll on a
  mid-range device; the candidate to watch first is first-swipe shader jank
  (mitigate with SkSL war-up if confirmed).

---

## PERF-003 - Web bundle analysis and code-splitting

Status: ✅ best practices already applied; build snapshot below

- `next.config.js` already applies: Turbopack (Next 16), `compress: true`,
  `experimental.optimizePackageImports` for `lucide-react`, `framer-motion`,
  `date-fns`, `@crush/ui` (tree-shaking the heaviest UI deps), `next/image`
  AVIF/WebP, and no production browser source maps.
- Route-level code-splitting via `next/dynamic` is already used for the heaviest
  authenticated views: settings, chat room, discover's match modal + filter
  dialog, and profile edit — keeping them out of the initial/marketing bundle.
- Heaviest dependencies are `firebase` (required SDK), `@sentry/nextjs`
  (error tracking), and `framer-motion` (already in `optimizePackageImports`).

### Build snapshot (`npm run build`, 2026-06-03)
- ✅ Production build succeeds: Next.js 16.1.4 (Turbopack), compiled in ~29s,
  TypeScript clean, **54 routes** generated.
- Route composition is favorable: nearly all marketing/auth/content routes
  (`/`, `/about`, `/auth/*`, `/features`, `/pricing`, `/faq`, content pages) are
  **prerendered static (○)**; only genuinely dynamic endpoints are server-rendered
  (`ƒ`): `/api/*`, `/messages/[matchId]`, dynamic icons, plus proxy middleware. So
  the heaviest authenticated views are both code-split *and* off the static entry
  bundles.
- ⚠️ The Turbopack build output does **not** print per-route First Load JS byte
  sizes, so an exact byte budget could not be captured from the build alone. This
  is the gap `@next/bundle-analyzer` closes (recommendation below).

*Recommended next step:* wire `@next/bundle-analyzer` behind an `ANALYZE=true`
flag in CI so per-route First Load JS is tracked over time and regressions are
caught; the current config and dynamic-import usage need no immediate change.

---

## Verification

- `flutter analyze lib/core/media/image_optimizer.dart` — no issues; `flutter pub get` clean after moving `image` to `dependencies`.
- `flutter test test/image_optimizer_test.dart` — **9 passing** (incl. the new JPEG-format + quality-knob cases).
- PERF-001/002 verified by source review of `lib/main.dart` and the interactive screens; on-device measurement tracked above.
- PERF-003 build snapshot captured via `npm run build` in `apps/web` (below).

## Tracked follow-ups
- Capture on-device cold-start (`_app_start`) baseline vs the sub-2s target (PERF-001).
- DevTools timeline profiling of deck swipe + chat scroll on a mid-range device (PERF-002).
- Add `@next/bundle-analyzer` (ANALYZE flag) to CI for ongoing First Load JS tracking (PERF-003).
- Optional: offload `img.encodeJpg` to an isolate (`compute`) if encoding large images on the main isolate shows up in profiling (PERF-004).
