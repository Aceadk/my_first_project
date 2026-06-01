# API Pagination, Rate-Limit & Retry Audit — 2026-05-30

Scope: `API-002` from `docs/TODO_API_ARCHITECTURE.md`.

## Summary

Audited every list (GET-collection) endpoint for pagination semantics, mapped
the two rate-limiting systems to the routes they protect, and defined the
client/server retry-safety contract. List endpoints are consistent on a
cursor-first strategy except `likes-you`, which intentionally uses offset
pagination because it merges two collections in memory. One duplicated cursor
parse/validate block was extracted into a shared helper as part of the audit.

## Pagination Matrix (list endpoints)

| Endpoint | Strategy | Page params (bounds) | Response keys | `has_more` detection |
| --- | --- | --- | --- | --- |
| `GET /v1/discovery/deck` | Opaque cursor | `limit`, `cursor` | `candidates`/`profiles`, `total`/`total_count`, `has_more`/`hasMore`, `next_cursor`/`nextCursor` | via `buildDiscoveryDeckPayload` |
| `GET /v1/discovery/likes-you` | **Offset** (in-memory merge) | `offset` (0–5000, def 0), `limit` (1–100, optional) | `candidates`/`profiles`, `total_count`, `has_more`, `next_offset` | `offset + page < total` |
| `GET /v1/matches` | Cursor on `lastMessageAt` (+ `offset` fallback) | `limit` (1–50, def 20), `before` (ISO), `offset` (0–5000) | `matches`, `total_count`, `has_more`, `next_cursor` | `limit + 1` probe |
| `GET /v1/chat/conversations` | Cursor on `lastMessageAt` | `limit` (1–100, def 50), `before` (ISO) | `conversations`, `total_count`, `has_more`, `next_cursor` | `limit + 1` probe |
| `GET /v1/chat/:conversationId/messages` | Cursor on `createdAt` (ISO **or** message id via `startAfter`) | `limit` (1–100, def 50), `before` (ISO\|msgId) | `messages`, `has_more`, `next_cursor` (no `total_count`) | `limit + 1` probe |

Non-list GETs (`/v1/profile/me`, `/v1/profile/:userId`, `/v1/subscription/current`,
`/v1/subscription/plans`, `/v1/chat/settings`) return a single resource and do
not paginate.

Shared helpers: `parseBoundedIntQueryParam` clamps `limit`/`offset` to their
documented bounds; `parseChatMessagesBeforeCursor` and the newly extracted
`parseBeforeTimestampCursor` parse/validate the `before` cursor (present-but-
unparseable → `400 Invalid before cursor`; absent → unfiltered first page).

## Rate-Limit Matrix

Two complementary systems:

**A. Callable (`applyRateLimit`) — Firestore-backed, durable.** Persists
attempts/window/block in `auth_rate_limits`, survives instance restarts, and
applies blocking windows. Authoritative for abuse-sensitive auth/safety flows
(login, signup, email-OTP request/verify, password reset, block/report/unblock
callables). Exceeds limit → `resource-exhausted` HttpsError with `retryAfterMs`.

**B. Express (`createRateLimiter`) — in-memory per-instance, best-effort.**
Keyed by `${path}:${uid|ip}`. Exceeds limit → `429` with a `Retry-After`
header.

| Express limiter | Limit / window | Routes |
| --- | --- | --- |
| `rateLimitAuth` | 20 / 10 min | `POST /v1/auth/otp/send`, `POST /v1/auth/otp/verify` |
| `rateLimitDiscovery` | 30 / hour | `GET /v1/discovery/deck`, `GET /v1/discovery/likes-you` |
| `rateLimitSwipe` | 100 / hour | `POST /v1/discovery/swipe`, `POST /v1/discovery/boost` |
| `rateLimitMessage` | 60 / min | `POST /v1/chat/:id/send`, `POST /v1/chat/:id/media` |
| `rateLimitBlock` | 20 / hour | `POST /v1/users/block` |
| `rateLimitReport` | 10 / hour | `POST /v1/users/report` |
| `rateLimitDefault` | 60 / min | `GET /v1/matches`, `GET /v1/chat/conversations`, `GET /v1/chat/:id/messages` |

Limits scale with endpoint risk/cost: highest-abuse auth and safety paths use
the durable callable limiter with the tightest windows; read-list endpoints use
the looser shared `rateLimitDefault`.

## Retry Safety

Client (`lib/core/network/api_client.dart`):

- **Transport failures** (`SocketException`/`TimeoutException`): only **GET** is
  replayed (up to `retryCount`); `POST/PUT/PATCH/DELETE` are **not** retried,
  because the server may have processed a non-idempotent write before the
  response was lost. (`_shouldRetryTransportFailure`.)
- **401**: a single silent token refresh + one retry, with concurrent refreshes
  coalesced and re-auth routed once per expiry (see `AUTH-SEC-002` /
  `docs/reports/auth_silent_refresh_2026-05-30.md`). No request retries twice.
- **429**: surfaced as `ApiErrorType.rateLimited`, **not** auto-retried; callers
  honor the server `Retry-After`/`retryAfterMs` rather than hammering.

Server: both limiters return retry timing (`Retry-After` header / `retryAfterMs`
field) so clients can back off deterministically.

## Findings

1. **Mixed pagination styles are intentional, not drift.** Every list endpoint
   is cursor-first except `likes-you`, which merges the `likes` and `swipes`
   collections in memory and dedups likers — there is no single Firestore order
   key to cursor on, so offset over the materialized list is the correct fit.
   Documented as an accepted exception.
2. **`messages` omits `total_count` by design.** Per-conversation message counts
   are unbounded and would require a full count read per page; `has_more` +
   `next_cursor` are sufficient for infinite-scroll history.
3. **Express limiter is per-instance.** `rateLimitStore` is an in-process `Map`,
   so limits are not shared across Cloud Functions instances and reset on cold
   start. The durable callable `applyRateLimit` is the authoritative control for
   abuse-sensitive flows; the Express limiter is a best-effort per-instance
   guard. Migrating the REST abuse paths to Firestore-backed limiting is a
   reasonable future hardening item but is not required by this audit.
4. **Refactor applied (this change):** the identical `before`-cursor
   parse/validate block in `/v1/matches` and `/v1/chat/conversations` was
   extracted into `parseBeforeTimestampCursor`, removing the duplication and
   standardizing the `400` response. Behavior is unchanged and verified by the
   existing invalid-/valid-cursor pagination tests.

## Verification

- `npm run build` (in `functions/`)
- `npx mocha --exit test/chatRestPagination.test.js` (12 passing — pagination
  contract for messages, conversations, matches, likes-you incl. valid/invalid
  cursors)
- `npx mocha --exit test/callRestRateLimit.test.js` (rate-limit contract)
- `npx mocha --exit test/securityAbuseLanes.test.js` (abuse lanes)
- `npx mocha --exit test/callables.test.js` (auth callable regression)

Note: `test/profileRestEndpoints.test.js` has 2 pre-existing failures in
`PATCH /v1/profile/preferences` merge logic, unrelated to pagination/rate-limit
and present without this change (verified by stash); they are outside `API-002`
scope and tracked separately. The cross-suite `admin` mock isolation issue
(tests must run per-file) is also pre-existing.

## Manual Follow-Up

- None required for the documented scope. Optional future hardening: move REST
  abuse-path rate limiting onto the durable Firestore-backed limiter so limits
  survive instance churn.
