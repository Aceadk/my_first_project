# Streak → Like-Limit Decision (2026-06-07)

Phase 4 Step 6 flagged a divergence: the backend enforced a FLAT daily like
limit (`DAILY_LIKE_LIMIT_FREE = 30` in `rateLimits/{uid}`), while the web streak
feature advertised a streak bonus (hardcoded base 50 / max 69). This decided and
implemented the reconciliation.

## Decision

1. **Streaks are server-owned.** `user_streaks/{uid}` is written only by Cloud
   Functions (deny-by-default for clients, verified by the rules-emulator suite).
2. **The streak bonus DOES raise the daily like limit** (the feature's intent),
   enforced by the backend — not the client.
3. **Keep the backend base (30) as authoritative.** The free base daily limit is
   unchanged (no unilateral monetization change). The streak bonus is added on
   top, capped at `base + maxMilestoneBonus` (30 + 19 = 49).
4. **The backend is the single source of truth for all the numbers.** The web no
   longer hardcodes 50/69; it reads `getStreakStatus` and displays whatever the
   backend enforces. This permanently eliminates the divergence.

## Implementation

Backend (`functions/src/index.ts`):
- `STREAK_MILESTONES` + `streakBonusLikes()` (mirrors the web milestone curve:
  2d→+2 … 30d→+19).
- `recordDailyStreakActivity(uid)` — transactional, server-owned `user_streaks`
  update (init / increment on consecutive day / reset on gap); idempotent per
  day; returns currentStreak/longestStreak/bonus/incremented/isNewRecord.
- `enforceDailyLikeLimit` — for free users, computes the bonus via
  `recordDailyStreakActivity` (wrapped in try/catch so a streak error NEVER
  blocks a swipe) and uses `DAILY_LIKE_LIMIT_FREE + bonus` as the daily limit.
- `getStreakStatus` callable — server-authoritative streak + like-limit status
  for display (base, bonus, totalAllowed, used, remaining, milestones,
  maintainedToday).
- `recordStreakActivity` callable — records a day of activity (e.g. on app open).

Web (`crush-web/packages/core/src/services/streak.ts`):
- All reads (`getStreakData`/`getLikeLimitInfo`/`getStreakInfo`) derive from the
  `getStreakStatus` callable. No hardcoded limit numbers remain.
- `recordActivity` → `recordStreakActivity` callable.
- `useLike` → non-blocking display gate (returns current limit info); the
  authoritative consume + enforcement is the backend swipe (`swipeRight` →
  `enforceDailyLikeLimit`).

## Tests

- Backend: `callables.test.js` — auth tests for `getStreakStatus` +
  `recordStreakActivity` (20 passing). The 59 pre-existing emulator-integration
  failures are unchanged (no regression from the swipe-path change; no test
  asserted the flat limit number).
- Web: `streak-server-owned.test.ts` (6) — limit derives from backend (base +
  bonus), premium→Infinity mapping, streak-info mapping, recordActivity
  routing/increment, useLike non-blocking.
- Rules emulator already proves `user_streaks` is client-deny.

## Notes / follow-ups

- If product wants the free base to be 50 (the old web number), change
  `DAILY_LIKE_LIMIT_FREE` in one place — the web display follows automatically.
- The streak advances on swipe activity and on `recordStreakActivity` (app
  open). If a different activity definition is desired, adjust where
  `recordStreakActivity` / `recordDailyStreakActivity` are called.
