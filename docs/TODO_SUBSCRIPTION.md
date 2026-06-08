# TODO: Subscription & Billing Module

- Status: Clear as of 2026-04-16
- Purpose: Preserve the historical module path without keeping completed backlog items in the active queue.

## Open Items

### SUB-001 - Unify server-owned entitlement and benefit lifecycle
- Files: backend subscription/promo/boost commands, Stripe routes/webhook, native purchase validation, entitlement documents, web/mobile entitlement readers
- Description: Define one canonical entitlement model and ensure Stripe, Apple, Google, promos, boosts, renewals, expirations, cancellations, and restores reconcile through server-owned state transitions.
- Dependencies: `SEC-BE-004`, `API-007`, provider configuration
- Acceptance Criteria:
  - One documented entitlement schema defines plan, status, provider, period, expiry, renewal, and benefit state.
  - Final entitlement writes are server-owned; clients cannot self-grant premium or benefits.
  - Stripe/native provider events are idempotent and reconcile out-of-order or missed events.
  - Promo and boost behavior has explicit ownership, cooldown/limit rules, and audit history.
  - Web and mobile render equivalent entitlement state from the canonical model.
- Testing:
  - Provider webhook/receipt lifecycle tests for purchase, renew, cancel, expire, restore, refund, and duplicate/out-of-order events.
  - Abuse tests for forged premium, promo replay, and boost cooldown bypass.
  - Staging reconciliation and account-state smoke tests.
- Status: open — P0 reopened from `R-066`.

## Historical Trace

- Completed subscription implementation history is preserved in:
  - `docs/ai_workboard.md`
  - `docs/Developer_agent_chat.md`

## Reopen Rule

- If new billing, restore, entitlement, or store-lifecycle work is discovered, create fresh `SUB-###` items here instead of embedding them in generic backlog files.
