# State Management Audit - 2026-06-03

Scope: `STATE-001`–`STATE-003` from [`docs/TODO_STATE_MANAGEMENT.md`](../TODO_STATE_MANAGEMENT.md).

Surfaces reviewed: all 31 blocs/cubits, long-lived services/repositories, and
StatefulWidget controllers across `lib/`; the app-root lifecycle handler
([`app.dart`](../../lib/app.dart)); and the optimistic-update flows in discovery
([`discovery_bloc.dart`](../../lib/features/discovery/presentation/bloc/discovery_bloc.dart))
and chat
([`message_handling_bloc.dart`](../../lib/features/chat/presentation/bloc/message_handling_bloc.dart)).

## Result

The state layer is broadly disciplined. The audit found **one real disposal bug
(fixed)**; stale-state invalidation and optimistic-rollback semantics are
already consistent and are documented here as the standing policy.

Legend: ✅ verified · 🔧 fixed · ⚠️ tracked.

---

## STATE-001 - Stale-state on navigation, refresh, and resume

Status: ✅ verified; invalidation paths documented

Owning invalidation paths (the answer to "what refreshes this surface"):

- **App resume (global).** [`app.dart`](../../lib/app.dart) `_RouterHostState`
  observes `AppLifecycleState`. On `resumed` it: clears the preserved route,
  triggers biometric re-auth, runs `_refreshOnResume()` — **debounced to 30s**
  (`SubscriptionRestoreRequested` + `ProfileLoadRequested`) — and refreshes
  location via `_updateUserLocationOnResume()` (feeds discovery). On
  `paused/inactive` it persists the current route through `AppStatePreserver`.
- **Chat.** Realtime by construction (stream-backed). `ChatBloc` also observes
  lifecycle (`ChatAppLifecycleChanged`, CHAT-RT-002) to clear own-typing / set
  presence offline on background and restore on resume;
  `HttpChatRepository` re-syncs on `resumed`.
- **Auth.** `email_verification_screen` re-checks verification on `resumed`;
  `sign_up_screen` re-evaluates on resume.
- **Discovery.** Deck refreshes from the resume location update and paginates via
  `_maybeLoadMore`; swipe results update counters in place.

Conclusion: every primary surface has an explicit owner for re-fetching after
navigation/resume; no "load-once-in-initState-and-never-refresh" hotspot was
found on the core journeys. ⚠️ Manual resume/navigation spot-checks on device
remain a release-gate item (no automated lifecycle harness for full journeys).

## STATE-002 - Stream/controller/timer disposal and leaks

Status: 🔧 one real leak fixed; rest ✅ verified

- 🔧 **Fixed — `FirebaseFeatureFlagRepository`.** Its `onConfigUpdated.listen(...)`
  subscription was never stored or cancelled, and `dispose()` closed
  `_flagsController` without stopping it. A config update arriving after
  `dispose()` would re-enter `_updateFlags()` and call `add()` on a **closed**
  controller → uncaught `StateError`. (The repo is an app-lifetime
  `RepositoryProvider.value`, so today this is latent — but unsafe under
  hot-restart, tests, or any future re-provisioning.) Fix: store the
  subscription, cancel it in `dispose()`, and guard the publish with
  `if (!_flagsController.isClosed)`. Covered by
  [`firebase_feature_flag_repository_disposal_test.dart`](../../test/features/feature_flags/firebase_feature_flag_repository_disposal_test.dart).
- ✅ **Blocs/Cubits (31).** Subscriptions are stored and cancelled in `close()`;
  the listen-vs-cancel sweep flagged no bloc/cubit.
- ✅ **StatefulWidgets.** Every State that declares an Animation/Text/Scroll/
  Page/Tab controller, `FocusNode`, `Timer`, or `StreamSubscription` has a
  `dispose()` that tears it down (e.g. `call_screen` cancels its quality
  subscription and calls `stopMonitoring()`).
- ✅ **Owned services.** `LocationService`, `RealtimeMatchService`,
  `DailyLikesService`, and `StubChatRepository` cancel timers/subscriptions and
  close their controllers in `dispose()`.

⚠️ **Tracked (acceptable, not fixed):** app-lifetime singletons
`AppCheckService` (token-change listener) and `CallQualityService` (two
broadcast controllers) intentionally keep their broadcast streams open for the
process lifetime — released at exit, with no listener accumulation; their
per-use resources (e.g. the sampling `Timer`) *are* cancelled.
`AppCheckService.setTokenRefreshListener` discards its subscription but is
currently dead code (no call sites).

### Disposal policy (standing convention)

1. **Bloc/Cubit:** keep each `StreamSubscription` in a field; cancel all in
   `close()`. No bare `stream.listen(...)`.
2. **StatefulWidget:** keep controllers/subscriptions/timers in fields; dispose
   or cancel each in `dispose()` before `super.dispose()`.
3. **Owned `StreamController`:** `close()` it in the owner's `dispose()`; guard
   any post-`await` publish with `if (!controller.isClosed)`.
4. **Stream consumers of shared/broadcast streams:** the consumer owns its
   subscription's cancellation.
5. **App-lifetime singletons:** broadcast controllers may stay open for the
   process; per-call resources (timers, subscriptions) must still be released.

## STATE-003 - Optimistic update and rollback semantics

Status: ✅ verified consistent; semantics documented

Standard pattern (applied identically in all three discovery swipe handlers —
`_onSwipedRight`/`_onSwipedLeft`/`_onSuperLiked`):

1. **Capture** the pre-action state (`currentIndex`).
2. **Optimistically** advance the UI (`emit(currentIndex: nextIndex)`).
3. On backend failure **roll back** to the captured state
   (`emit(currentIndex: currentIndex)`) and surface feedback — an
   `errorMessage` and, for limit/gate cases, a `premiumGateSource`/paywall.

Chat uses the same shape with a queue twist: an optimistic message (temp id) is
held in `failedMessages` on failure and surfaced through
`ChatFailedMessageActions` (Retry → `MsgRetryRequested`, Discard →
`MsgDiscardFailedRequested`); optimistic↔server convergence is handled by
`MessageReconciler` within a 30s window (CHAT-RT-001).

Settings, profile, and subscription flows are **load-then-confirm** (await the
backend, then emit) rather than optimistic, so they need no rollback path — this
is intentional and consistent. No optimistic-without-rollback path was found.

---

## Changed files

- `lib/features/feature_flags/data/repositories/impl/firebase_feature_flag_repository.dart` (fix)
- `test/features/feature_flags/firebase_feature_flag_repository_disposal_test.dart` (new)

## Verification

- `flutter analyze` on changed files — clean.
- `flutter test test/features/feature_flags/firebase_feature_flag_repository_disposal_test.dart test/feature_flags_test.dart` — 32 passing (3 new + 29 existing).
