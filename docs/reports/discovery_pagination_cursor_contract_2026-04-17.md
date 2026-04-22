# Discovery Deck Cursor Contract

Date: 2026-04-17
Owner: Codex
Related TODO: `DISC-BE-003`

## Scope

This report documents the server and client contract for discovery deck
pagination after the `DISC-BE-003` remediation slice.

## Cursor Semantics

- Discovery deck ordering is deterministic:
  - primary sort: `score` descending
  - secondary sort: `updatedAtMs` / `lastActiveMs` descending
  - final tie-break: `user.id` ascending
- The server now emits real pagination metadata instead of deriving `has_more`
  from page length alone.
- Callable response fields:
  - `hasMore`
  - `nextCursor`
- REST response fields:
  - `has_more`
  - `next_cursor`
  - compatibility mirrors: `hasMore`, `nextCursor`
- The cursor is an opaque base64url JSON payload that includes:
  - cursor version
  - requester UID
  - normalized request scope hash
  - last seen score
  - last seen activity timestamp
  - last seen user ID

## Request Scope Locking

The server binds each cursor to the effective discovery request. A cursor is
invalid if any of these change between pages:

- requester UID
- min/max age
- max distance
- show-me genders
- required interests
- `requirePhotos`
- `requireVerified`
- latitude / longitude input

Invalid or mismatched cursors now fail fast:

- callable: `invalid-argument`
- REST: HTTP `400` with the same error code payload

## Retry And Reconnect Behavior

- Repeating the same cursor request returns the same page ordering.
- Client-side deduplication can safely ignore already-appended profiles while
  still advancing to the server-provided `nextCursor`.
- The backend uses keyset-style comparison instead of offset-based pagination,
  so retries do not depend on the anchor profile still being present.
- If higher-ranked candidates appear before the anchor between requests, they do
  not cause already-served candidates to replay.
- If the anchor profile disappears between requests, the next page still
  advances correctly from the last served sort boundary.

## Verification

- `npm run build` in `functions/`
- `npx mocha --exit test/discoveryEligibility.test.js` in `functions/`
- `npm run lint` in `functions/`
- `flutter analyze lib/features/discovery/domain/repositories/discovery_repository.dart lib/features/discovery/presentation/bloc/discovery_state.dart lib/features/discovery/presentation/bloc/discovery_bloc.dart lib/core/network/dto/discovery_dto.dart lib/features/discovery/data/repositories/impl/firebase_discovery_repository.dart lib/features/discovery/data/repositories/impl/http_discovery_repository.dart lib/features/discovery/data/repositories/impl/hybrid_discovery_repository.dart lib/features/discovery/data/repositories/impl/stub_discovery_repository.dart test/discovery_bloc_test.dart test/deck_gating_test.dart test/message_requests_cubit_test.dart test/router_create_router_test.dart test/safety_cubit_test.dart lib/data/repositories/fake_repositories.dart`
- `flutter test test/discovery_bloc_test.dart`

## Residual Scope

This closes cursor and retry correctness for the current bounded candidate scan.
The broader discovery query/index audit remains open in `DISC-BE-001`.
