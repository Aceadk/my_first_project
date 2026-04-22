# Discovery Query And Index Audit

Date: 2026-04-19
Owner: Codex
Related TODO: `DISC-BE-001`

## Scope

This audit covers the discovery deck backend query path in `functions/src/index.ts`
and the Firestore composite indexes required to support that path.

## Eligibility Pipeline

Discovery candidate eligibility is determined in two stages:

1. Mirror-and-normalize stage:
   - `buildDiscoveryUserSnapshot(...)` normalizes canonical nested profiles and
     legacy flat web/mobile user documents into one discovery snapshot model.
   - `buildLegacyDiscoveryMirrorPatch(...)` keeps root discovery fields aligned
     for cross-platform compatibility.

2. Inclusion stage:
   - `evaluateDiscoveryEligibility(...)` blocks candidates missing required
     discovery prerequisites such as name, adult age, gender, photo, discovery
     preferences, active account state, or moderation clearance.
   - `evaluateDiscoveryCandidateForRequester(...)` applies requester-specific
     exclusions and filters: self-exclusion, blocks, reports, prior swipes,
     likes, matches, age window, distance, optional verified-only mode, and
     optional interest overlap.

## Previous Query Risk

Before this remediation slice, the deck builder queried a bounded window of
recent user documents and then performed almost all filtering in memory. That
left two problems:

- Query efficiency depended on how many irrelevant users happened to be in the
  most recent write window.
- Firestore indexes were not aligned with the actual discovery query shapes.

## Current Query Strategy

The deck builder now issues an indexed prefilter query before scoring:

- Base filters:
  - `onboardingComplete == true`
  - `profileComplete == true`
- Optional filters:
  - gender equality or gender `in [...]` when the requester is not open to all
    canonical genders
  - `isVerified == true` when verified-only discovery is requested
- Ordering:
  - `updatedAt desc`

These fields are already mirrored on root user documents by the existing
compatibility sync path, so the query improvement does not require a new user
document backfill to become safe.

## Added Index Coverage

`firestore.indexes.json` now includes discovery-specific composites for:

- ready-only discovery deck queries
- ready-only + verified-only queries
- ready-only + gender-targeted queries
- ready-only + gender-targeted + verified-only queries

## Fallback Behavior

If the indexed query fails, the backend logs the failure and falls back to the
legacy recent-users scan. This keeps discovery available during local emulation
or before the new indexes are deployed.

## Residual Limits

- Age range, distance, prior relationship exclusions, and interest matching are
  still evaluated in memory after the indexed prefilter query.
- This is intentional in the current slice because those filters either depend
  on requester-specific relation sets or would force query ordering that is not
  compatible with a general recency-prefilter strategy.
- Future deeper optimization, if needed, should evaluate whether a dedicated
  discovery candidate materialization or geospatial index is justified.

## Verification

- `npm run build` in `functions/`
- `npx mocha --exit test/discoveryEligibility.test.js` in `functions/`
- `npm run lint` in `functions/`
