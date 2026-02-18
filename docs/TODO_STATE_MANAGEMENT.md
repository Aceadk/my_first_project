# TODO: State Management Module
**Priority:** P1 – High
**Estimated Effort:** 35-50 hours
**Dependencies:** BLoC architecture, Result pattern (`lib/core/utils/result.dart`)
**Assigned:** AI + Developer

---

## STATE-001: Fix Stream Subscription Leak Risks in ChatBloc Sub-BLoCs
**Files:** `lib/features/chat/presentation/bloc/chat_bloc.dart`, `realtime_state_cubit.dart`, `chat_session_cubit.dart`, `message_handling_bloc.dart`
**Description:** ChatBloc facade pattern with 3 sub-BLoCs has stream leak risks if subscriptions aren't cancelled in `close()` or sub-BLoCs aren't properly disposed.
**Acceptance Criteria:**
- [ ] `ChatBloc.close()` cancels all sub-BLoC stream subscriptions
- [ ] `ChatBloc.close()` calls `.close()` on all 3 sub-BLoCs
- [ ] Each sub-BLoC cancels its own Firestore/RTDB streams in `close()`
- [ ] Unit test: after close, no sub-BLoc emits further states
- [ ] Unit test: re-creating ChatBloc doesn't leave orphan subscriptions
**Testing:** Unit tests with mock streams; memory profiling via DevTools.

---

## STATE-002: Add Diff Check to _buildAggregatedState in ChatBloc
**Files:** `lib/features/chat/presentation/bloc/chat_bloc.dart`
**Description:** `_buildAggregatedState` emits on every sub-BLoC change without equality check, causing unnecessary widget rebuilds from typing/presence updates.
**Acceptance Criteria:**
- [ ] `ChatState` implements `Equatable` with all fields in `props`
- [ ] New aggregated state compared with current before emitting
- [ ] Widget rebuild count measurably reduced
- [ ] Unit test: emit same sub-BLoC state twice → ChatBloc emits only once
**Testing:** Unit test counting emissions; performance profiling of chat rebuild frequency.

---

## STATE-003: Audit All BLoC/Cubit Stream Subscription Disposal
**Files:** All 27 BLoCs/Cubits across the app
**Description:** Systematic audit to verify every `StreamSubscription` is cancelled in `.close()`. High-risk: CallBloc, DiscoveryBloc, MatchesBloc, SessionBloc, SubscriptionBloc.
**Acceptance Criteria:**
- [ ] Every `.listen()` has corresponding `StreamSubscription` field
- [ ] Every subscription cancelled in `close()` override
- [ ] No fire-and-forget listeners
- [ ] Audit report listing each BLoC, subscriptions, and disposal status
**Testing:** Unit test per BLoC verifying close() behavior; static analysis script.

---

## STATE-004: Implement Optimistic Updates for Chat Message Sending
**Files:** `lib/features/chat/presentation/bloc/message_handling_bloc.dart`, `chat_screen.dart`
**Description:** Messages wait for server confirmation before appearing. Implement optimistic update with sending/sent/failed indicators.
**Acceptance Criteria:**
- [ ] Message appears immediately with "sending" indicator
- [ ] Status updates: "sent" → "delivered" → "read"
- [ ] Failed messages show retry option
- [ ] Temporary ID replaced with server ID
- [ ] Multiple rapid sends maintain correct order
**Testing:** Unit tests for state transitions; widget test for immediate appearance; network failure test.

---

## STATE-005: Prevent Stale State on Background/Foreground Transitions
**Files:** `lib/app.dart`, various BLoCs
**Description:** BLoC states become stale when app is backgrounded (unread counts, online status, expired timers). Need systematic "refresh on resume."
**Acceptance Criteria:**
- [ ] `didChangeAppLifecycleState.resumed` triggers refresh on active BLoCs
- [ ] Chat fetches messages since last timestamp
- [ ] Discovery checks for invalidated cards (doesn't reset deck)
- [ ] Realtime connection reconnects and replays missed events
- [ ] Refresh operations debounced
**Testing:** Integration test simulating pause→resume; manual 5-minute background test.

---

## STATE-006: Add BLoC-Level Error Recovery Patterns
**Files:** All BLoCs, `lib/core/utils/result.dart`
**Description:** Error recovery is inconsistent. Standardize: transient errors auto-retry, persistent errors show retry button, auth errors redirect to login.
**Acceptance Criteria:**
- [ ] All BLoCs use `Result<T>` for repository calls
- [ ] Transient errors: auto-retry (max 3) with exponential backoff
- [ ] Persistent errors: error state with manual retry and preserved last data
- [ ] Auth errors: dedicated `AuthExpired` state handled globally
- [ ] All errors logged via `AppLogger` with context
**Testing:** Unit tests per BLoC for each error scenario.

---

## STATE-007: Implement Global State Reset on Logout
**Files:** `lib/features/auth/presentation/bloc/session_bloc.dart`, all feature BLoCs
**Description:** All user-specific state must be cleared on logout to prevent data leakage between accounts.
**Acceptance Criteria:**
- [ ] Logout triggers global state reset signal
- [ ] All BLoCs reset to initial state: Chat, Profile, Subscription, Insights, Matches
- [ ] Local caches and secure storage cleared
- [ ] No user-specific data persists in memory
- [ ] Login with different account shows fresh state
**Testing:** Integration test: login A → populate → logout → login B → verify clean state.
