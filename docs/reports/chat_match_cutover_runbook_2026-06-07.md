# Chat & Match Canonical Cutover Runbook (Phase 5, Steps 8–9)

- Date: 2026-06-07
- Owner: (assign before execution)
- Repos: crush-web `codex/auth-storage-cleanup`, my_first_project (rules/functions)
- Goal (Done when): **No production web behavior uses legacy `conversations`,
  `typing_indicators`, directional matches, or direct `swipes`.**

> This is an OPERATIONAL runbook. It requires staging + production Firebase
> service accounts, a deployed staging web app, and multiple browsers/devices —
> things the implementation work cannot do for you. All code/tooling it
> references is built and committed; execution is manual.

## Tooling (already committed)

| Command (run in `crush-web/apps/web`) | Purpose |
|---|---|
| `pnpm inventory:chat --project <id>` | Read-only counts of all legacy + canonical entities |
| `pnpm migrate:conversations --project <id>` | Migration dry-run (no writes) |
| `pnpm migrate:conversations:execute --project <id>` | Execute conversations→matches/messages migration |
| `pnpm inventory:chat:verify --project <id>` | Compare source vs destination after migration |

Auth: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json` (or
`FIREBASE_SERVICE_ACCOUNT='<json>'`).

## Field mapping (canonical target)

| Legacy | Canonical | Notes |
|--------|-----------|-------|
| `conversations/{id}` | `matches/{matchId}` (reused or created) | conversation archived (`migratedToMatchId`) |
| `conversations/{id}/messages/{m}.senderId` | `matches/{matchId}/messages/{m}.fromUserId` | |
| (derived: other participant) | `…messages.toUserId` | from conversation `participants` |
| `…messages.timestamp` | `…messages.sentAt` | |
| `…messages.status === 'read'` | `…messages.isRead` (+ `readAt`) | |
| `…messages.metadata.*Url` | `…messages.mediaUrl` | |
| `…messages.reactions[]` | `…messages.reactions { [uid]: emoji }` | |
| legacy directional `matches/{uid_otherid}` (`userId`/`otherUserId`/`status:'mutual'`) | canonical `matches/{autoId}` (`userIds[]`/`status:'active'`) | reconciled — reuse existing canonical match for the pair |
| `matches/*.pinnedForUser` (bool) | `matches/*.pinnedForUser { [uid]: bool }` | per-user pin map; set via `setMatchPinned` callable |
| `conversations.unreadCount` | (backend-computed; not persisted on doc) | unread derives from `isRead`/`readBy`; no migration needed |
| `typing_indicators/*` | (none) | **transient — drop**; V2 uses `matches/*.typing` map via `setTyping` |
| `swipes/{a_b}` | (none) | **transient — drop**; canonical likes live in `likes/` and matches already exist |

## Rollback criteria

Roll back (disable V2) immediately if, during the staging or production
observation window, ANY of these occur:
- Permission-denied rate on chat/match callables or reads > 0.5% of attempts.
- Message send success rate < 99% (excluding user network failures).
- Any data-loss signal: `inventory:chat:verify` reports message-count mismatches,
  or users report missing matches/messages.
- p95 chat-load or send latency regresses > 2× the legacy baseline.
- Duplicate-message or cross-match message leakage observed.

Rollback action: set `NEXT_PUBLIC_USE_V2_CHAT=false` and redeploy (the legacy
services remain until the flag is removed). Migrated data is non-destructive
(legacy conversations are archived, not deleted), so rollback loses nothing.

## Backup process

Before `migrate:conversations:execute` in any environment:
1. Trigger a Firestore export:
   `gcloud firestore export gs://<project>-firestore-backups/pre-chat-cutover-$(date +%F) \
      --collection-ids=conversations,matches,swipes,typing_indicators`
2. Record the export operation id + path in the cutover ticket.
3. Confirm the scheduled daily backup (`scheduledFirestoreBackup`) ran in the
   last 24h as a secondary safety net.

## Step 8 — Prepare migration (staging)

1. `pnpm inventory:chat --project crush-265f7-staging` — record all counts.
2. Define/confirm field mapping (table above).
3. Confirm rollback criteria + take the backup (above).
4. `pnpm migrate:conversations --project crush-265f7-staging` (dry-run) — review
   the summary (conversations, matches created/reused, messages, errors).
5. `pnpm migrate:conversations:execute --project crush-265f7-staging`.
6. `pnpm inventory:chat:verify --project crush-265f7-staging` — must report
   0 unmigrated, 0 mismatches.
7. Manually validate 3–5 representative conversations in the Firebase console:
   participants, message order, read state, media URLs resolve.

Exit: verify passes + manual spot-check clean.

## Step 9 — Enable V2 (staging → production)

### Staging enablement
1. Set `NEXT_PUBLIC_USE_V2_CHAT=true` (+ the App Check reCAPTCHA key, see
   Phase 2) in the staging environment; redeploy.
2. Run the **test matrix** (below) with at least two accounts.

### Test matrix (must all pass)
- Match: creation (swipe→match), list loads, ordering by lastMessageAt.
- Chat: load history + pagination; send (text/image/video/audio); read receipts;
  edit; unsend (Plus); reactions add/remove; typing indicator.
- Pin: pin/unpin a match (persists via `setMatchPinned`).
- Safety: block (chat disappears / writes denied), report.
- Multi: two browsers + two devices on the same match (realtime sync).
- Resilience: offline send → reconnect; verify no duplicate messages.

### Monitor (staging, ≥ 24h)
- Sentry: callable/permission errors, exceptions.
- Latency: chat-load + send p50/p95.
- `inventory:chat:verify`: re-run; counts stable.

### Production rollout
1. Backup (above) on production.
2. `pnpm migrate:conversations --project crush-265f7` (dry-run) → execute →
   `inventory:chat:verify`.
3. Enable `NEXT_PUBLIC_USE_V2_CHAT=true` in production. Prefer a staged rollout
   (e.g., 10% via env/edge config if available, else full with close monitoring).
4. Observe rollback criteria for the observation window (≥ 48h).

### Decommission (after the observation window, clean)
- Remove the `NEXT_PUBLIC_USE_V2_CHAT` flag (make V2 the only path).
- Delete the legacy services per `docs/reports/legacy_chat_match_removal_manifest_2026-06-07.md`.
- Delete archived `conversations` + `typing_indicators` + `swipes` collections
  (after a final backup).

## Done-when checklist
- [ ] Staging migrated + verified + test matrix green.
- [ ] Production migrated + verified.
- [ ] `NEXT_PUBLIC_USE_V2_CHAT=true` in production through the observation window.
- [ ] Flag removed; legacy services deleted; legacy collections dropped.
- [ ] No production read/write touches `conversations`, `typing_indicators`,
      directional matches, or `swipes`.
