# Performance Module

Priority: P1-P2

This document tracks outstanding remediation and audit actions for the Performance domain.

---

## PERF-001 · P1 · `CrushAvatar` uses uncached `Image.network`

**File:** `lib/design_system/widgets/crush_avatar.dart:75`

`CrushAvatar` uses `Image.network()` instead of the app's `CachedNetworkImage` wrapper. This widget is used on nearly every screen (chat list, matches, profiles, notifications) and will re-download the image every time. Switch to `CachedNetworkImage`.

---

## PERF-002 · P1 · `MatchCelebration` avatars use uncached `Image.network`

**File:** `lib/design_system/widgets/match_celebration.dart:434`

`_buildAvatar` uses `Image.network()` for both user and match avatars. Switch to `CachedNetworkImage`.

---

## PERF-003 · P2 · No image prefetching for discovery deck

**Files:** `lib/features/discovery/presentation/widgets/deck_card_stack.dart`

The deck shows 1 card at a time but doesn't `precacheImage` the next card(s) in the stack. Users waiting for the next image to load creates visible jank. Prefetch the next 1-2 images during the current card view.

---

## PERF-004 · P2 · Several high-item lists use `ListView()` not `ListView.builder`

Multiple screens with potentially long lists use non-lazy `ListView()`:

- `call_history_screen.dart:261` — call history can grow large
- `date_ideas_screen.dart:111, 151` — date ideas lists

Static settings screens (< 15 items) using `ListView()` are acceptable and don't need changes.

---

## PERF-005 · P2 · BlocBuilders in discovery lack `buildWhen`

**Files:** `deck_screen.dart:1502, 1929`, `boost_button.dart:20, 333`

BlocBuilders in the deck screen rebuild on every state change, even when only unrelated fields change. Add `buildWhen` to limit rebuilds to only relevant state changes.

---

## PERF-006 · P2 · Chat `ChatBloc` holds 8+ stream subscriptions

**File:** `lib/features/chat/presentation/bloc/chat_bloc.dart:33-44`

`ChatBloc` maintains 8 `StreamSubscription` fields (`_typingSub`, `_presenceSub`, `_mediaSub`, `_authSubscription`, `_realtimeStateSub`, `_sessionStateSub`, `_messageStateSub`). Verify all are cancelled in `close()`. Consider consolidating related streams.

---

## PERF-007 · P2 · `Timer.periodic` usage without centralized lifecycle management

`Timer.periodic` is used in 20+ locations. Most appear to cancel in `dispose()`/`close()`, but there is no pattern enforcing this. Key locations at risk of leaking:

- `connectivity_cubit.dart:57`
- `http_chat_repository.dart:155, 566` (map-based timer storage)
- `http_subscription_repository.dart:42`
- `performance_monitor.dart:201`

---

## PERF-008 · P1 · Match celebration confetti creates 100 widgets per frame

**File:** `lib/design_system/widgets/match_celebration.dart:167, 449`

`_buildConfetti` generates 100 `_ConfettiParticle` objects and rebuilds all of them via `AnimatedBuilder` on every animation frame. Consider using `CustomPainter` to draw confetti directly on a canvas instead of composing 100 widget trees.

---

## PERF-009 · P2 · No `const` constructors on frequently rebuilt list item widgets

Discovery explore grids and likes-you grids instantiate list items without `const` constructors, preventing Flutter from short-circuiting rebuilds.

---

## PERF-010 · P1 · `BackdropFilter` in match celebration is expensive

**File:** `lib/design_system/widgets/match_celebration.dart:237-241`

`BackdropFilter` with animated blur (`sigmaX/Y`) running on every frame is one of the most expensive Flutter operations. Change to a static blur value or animate only once on entry, then keep the value fixed.
