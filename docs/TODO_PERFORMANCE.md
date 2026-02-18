# TODO: Performance Optimization Module
**Priority:** P1 – High
**Estimated Effort:** 35-50 hours
**Dependencies:** Flutter DevTools, Firebase Performance, design system
**Assigned:** AI + Developer

---

## PERF-001: Optimize App Startup Time (Target: <2s)
**Files:** `lib/main.dart`, `lib/app.dart`, `lib/core/di.dart`
**Description:** Measure and optimize cold start time. Defer non-critical initialization, lazy-load feature modules, reduce synchronous work on main thread.
**Acceptance Criteria:**
- [ ] Cold start baseline measured on iPhone 12 and Pixel 6
- [ ] Non-critical services initialized after first frame (analytics, remote config, performance)
- [ ] DI registration uses lazy singletons for feature-specific services
- [ ] Splash screen shows while critical init completes
- [ ] Target: <2s from tap to interactive on mid-range device
**Testing:** Profile with Flutter DevTools timeline; measure with Stopwatch in release mode.

---

## PERF-002: Implement Image Optimization Pipeline
**Files:** `lib/features/profile/data/services/profile_media_service.dart`, `lib/core/services/image_cache_service.dart`
**Description:** Profile photos uploaded without optimization. Implement: resize to max 2048px, compress to 85% JPEG, strip EXIF, generate thumbnails, use WebP where supported.
**Acceptance Criteria:**
- [ ] Upload: resize >4096px to 4096px, compress to 85% JPEG quality
- [ ] Thumbnail: generate 200px preview for list views
- [ ] EXIF stripped before upload (critical privacy — see PROF-FE-004)
- [ ] HEIC/HEIF converted to JPEG before upload
- [ ] Display: use `cached_network_image` with memory + disk cache
- [ ] Placeholder: skeleton loader or blurhash during load
**Testing:** Upload 12MP photo; verify file size reduction; verify load speed improvement.

---

## PERF-003: Add List Virtualization for Chat Messages
**Files:** `lib/features/chat/presentation/screens/chat_screen.dart`
**Description:** Chat uses reversed ListView loading all messages. For 1000+ message conversations, performance degrades. Limit in-memory messages and paginate.
**Acceptance Criteria:**
- [ ] Maximum 100 messages in memory at a time
- [ ] Scroll up triggers pagination (load 50 more)
- [ ] No jank when scrolling long histories
- [ ] Scroll position maintained during pagination loads
- [ ] Smooth 60fps scrolling measured with DevTools
**Testing:** Test with 500+ messages; profile frame times with DevTools.

---

## PERF-004: Reduce Widget Rebuild Frequency
**Files:** Various BLoCs, screens using `BlocBuilder`
**Description:** Audit screens for unnecessary rebuilds caused by BLoC state changes that don't affect visible UI. Use `buildWhen`, `listenWhen`, and `Selector` patterns.
**Acceptance Criteria:**
- [ ] All `BlocBuilder` usages reviewed for `buildWhen` optimization
- [ ] Chat screen: typing indicator changes don't rebuild message list
- [ ] Discovery: deck state changes don't rebuild action buttons unnecessarily
- [ ] Profile: form field changes only rebuild affected field
- [ ] Rebuild count measured before/after with `debugPrintRebuildDirtyWidgets`
**Testing:** Enable rebuild tracking; measure reduction in rebuild count.

---

## PERF-005: Optimize Discovery Deck Card Rendering
**Files:** `lib/features/discovery/presentation/widgets/swipe_card.dart`, `deck_card_stack.dart`
**Description:** Deck pre-renders multiple cards with images. Optimize by: lazy-loading off-screen card images, using `RepaintBoundary`, caching rendered cards.
**Acceptance Criteria:**
- [ ] Only top 2 cards fully rendered; remaining show skeleton
- [ ] Card images lazy-loaded as they approach the top
- [ ] `RepaintBoundary` on each card to prevent sibling repaints
- [ ] Video auto-play only on top card
- [ ] 60fps maintained during swipe animation
**Testing:** Profile swipe animation with DevTools; measure frame times.

---

## PERF-006: Implement Bundle Size Optimization
**Files:** `pubspec.yaml`, build configuration
**Description:** Measure and optimize app bundle size. Target: <30MB download size on both platforms.
**Acceptance Criteria:**
- [ ] Baseline bundle size measured (AAB and IPA)
- [ ] Unused packages identified and removed
- [ ] Tree shaking verified for all packages
- [ ] Font subsetting for unused glyphs
- [ ] Deferred loading for large feature modules
- [ ] Image assets optimized (PNG → WebP where possible)
**Testing:** Build release AAB/IPA; measure download size in store console.

---

## PERF-007: Add Performance Monitoring Dashboard
**Files:** `lib/core/performance/performance_monitor.dart`, `lib/core/performance/performance_observer.dart`
**Description:** Performance monitoring infrastructure exists but needs real-time dashboards. Track: startup time, screen load times, API latency p95, frame rate, and image load times.
**Acceptance Criteria:**
- [ ] Firebase Performance traces for each screen transition
- [ ] Custom traces for: image upload, message send latency, deck fetch
- [ ] API latency tracking with p50/p95/p99 aggregation
- [ ] Frame rate monitoring for animations (swipe, scroll)
- [ ] Dashboard accessible in Firebase Console
**Testing:** Verify traces appear in Firebase Console; validate latency measurements.

---

## PERF-008: Optimize Firestore Query Performance
**Files:** Various repository implementations
**Description:** Audit Firestore queries for: missing indexes, over-fetching (reading full documents when only one field needed), lack of pagination, and no caching of frequently-accessed data.
**Acceptance Criteria:**
- [ ] All Firestore queries have required composite indexes
- [ ] Queries use `select()` to fetch only needed fields where possible
- [ ] All list queries use cursor-based pagination (not offset)
- [ ] Frequently-accessed data cached locally with TTL
- [ ] No full-collection reads (all queries filtered)
**Testing:** Monitor Firestore console for slow queries; verify index usage.
