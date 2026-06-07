# Legacy Chat/Match Removal Manifest (Phase 5 decommission)

Run ONLY after the V2 cutover observation window passes (see
`chat_match_cutover_runbook_2026-06-07.md`). This lists exactly what to delete so
the removal is mechanical and low-risk. All paths are in `crush-web`.

## 1. Remove the feature flag (make V2 the only path)

- `packages/core/src/config/features.ts` — delete `isV2ChatEnabled` (and the
  file if nothing else lives there).
- `packages/core/src/stores/message.ts` — drop the `isV2ChatEnabled()` branch and
  the `legacyMessageService` import; bind `messageService = messageServiceV2Adapter`
  directly (or inline the adapter).
- `packages/core/src/stores/match.ts` — same: drop the flag branch + the
  `legacyMatchService` import for the cut-over methods.
- `packages/core/src/index.ts` — remove the `isV2ChatEnabled` export.
- `.env.example` / deploy envs — remove `NEXT_PUBLIC_USE_V2_CHAT`.
- Tests: `apps/web/src/lib/__tests__/v2-adapters-contract.test.ts` stays (adapters
  remain the path). Remove any test asserting the legacy branch.

## 2. Delete legacy services

- `packages/core/src/services/message.ts` — the entire legacy conversations-based
  `MessageService` (replaced by `message_v2.ts` + `message_v2_adapter.ts`).
  Remove its `messageService` export from `index.ts`.
- `packages/core/src/services/match.ts` — **partial**. Delete the legacy
  match-mutation methods now served by V2 / backend callables:
  `swipe`, `createMatch` (private), `getMatches`, `subscribeToMatches`,
  `unmatch`, `togglePinMatch`, and the `swipes`/`conversations` references.
  **KEEP** the discovery + request/picks read methods still used by the V2
  adapter and pages: `getDiscoveryProfiles`, `getDiscoveryBlockedUserIds`,
  `getLikesReceived`, `getMessageRequests`, `acceptMessageRequest`,
  `declineMessageRequest`, `getWeeklyPicks`. (The V2 `matchServiceV2Adapter`
  delegates `getDiscoveryProfiles` to this service.)
  - NOTE: `acceptMessageRequest`/`declineMessageRequest` may themselves create
    matches directly — re-verify they route through callables before keeping;
    if they do direct match writes, migrate them to `swipeRight`/a callable
    first (they are rules-rejected otherwise).
- `packages/core/src/services/discovery_rest.ts` — KEEP (discovery REST helper).

## 3. Drop legacy data (after a final backup)

```
gcloud firestore export gs://<project>-firestore-backups/pre-legacy-drop-$(date +%F) \
  --collection-ids=conversations,typing_indicators,swipes
# then delete the collections (e.g., via a one-off admin script or console)
```

- `conversations` (archived during migration), `conversations/*/messages`
- `typing_indicators`
- `swipes`
- Legacy directional `matches/{uid_otherid}` docs that were reconciled — confirm
  they carry a `migratedToMatchId`/are superseded before deleting; the canonical
  `matches/{autoId}` docs are the keepers.

## 4. Post-removal verification

- `pnpm typecheck && pnpm lint && pnpm test && pnpm build` green.
- `pnpm inventory:chat --project <prod>` shows 0 conversations / 0
  typing_indicators / 0 swipes / 0 legacy directional matches.
- Rules-emulator suite still green.
- Grep guard (add to CI): no source references to `conversations`,
  `typing_indicators`, or the `swipes` collection outside archived migration
  scripts.
