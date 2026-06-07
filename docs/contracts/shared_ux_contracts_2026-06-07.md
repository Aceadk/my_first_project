# Shared UX Contracts (Phase 8 Step 15)

- Date: 2026-06-07
- Purpose: define equivalent user flows across mobile (Flutter, `lib/features/*`)
  and web (Next.js, `crush-web/apps/web/src/app/*`), the **intentional**
  navigation differences, and one shared taxonomy of UI states so both clients
  behave equivalently against the same backend (`functions/src/index.ts`).
- Source of truth: backend contracts in `shared_backend_contract_matrix_*.md`
  and the route inventory in `route_manifest_2026-06-07.md`.

## 1. Equivalent user flows

Each flow has the same backend steps and the same success/failure outcomes on
both clients; only presentation/navigation differs (see §2).

| Flow | Mobile (Flutter feature) | Web (route) | Shared backend |
|---|---|---|---|
| **Onboarding** | `auth/` → basic info → photos → preferences | `/onboarding` (after `/auth/*`) | `createUserProfile`, canonical `profile.*` writes, `onboardingComplete` gate |
| **Discovery** | `discovery/` deck | `/discover` | `getDiscoveryProfiles` (REST `/v1`), like/pass; daily like limit (streak-aware) |
| **Matching** | `discovery/` match modal + `social/` | `/matches`, `/likes`, `/weekly-picks` | swipe → `matches/{id}` create; `getBlockedUsers` |
| **Chat** | `chat/` | `/messages`, `/messages/[matchId]`, `/messages/requests` | `matches/{id}/messages` (V2, flag-gated); send/read/edit/unsend/react/typing/pin |
| **Safety** | `safety/`, `verification/` | `/date-safety`, `/settings/blocked`, `/(marketing)/safety` | `blockUser`, `reportUser`, `setMatchPinned`, verification |
| **Premium** | `subscription/` | `/premium`, `/premium/success`, `/premium/cancel` | `plan`/`subscriptionExpiresAt`/`subscriptionLifecycle`; `activateBoost`, promo codes |
| **Profile** | `profile/` | `/profile`, `/profile/edit`, `/profile/preview` | canonical `profile.*`; photo upload |
| **Settings** | `settings/` | `/settings`, `/settings/{account,privacy,discovery,notifications,incognito,blocked}` | account lifecycle, notif prefs, discovery prefs |
| **Insights/extras** | `analytics/` | `/insights`, `/compatibility-quiz`, `/date-ideas` | analytics reads, quiz |
| **Calls** | `calls/` (Agora) | — (not on web; product decision) | call signaling — **mobile only** today |

Intentional flow differences:
- **Calls** are mobile-only (no web WebRTC yet) — documented gap, not a bug.
- Web exposes a **marketing** surface (`/(marketing)/*`) with no mobile analog.
- Mobile uses native verification/permission prompts; web uses browser prompts.

## 2. Navigation differences (intentional)

| Aspect | Mobile | Web |
|---|---|---|
| Primary nav | `glass_bottom_nav_bar` (bottom tab bar), gesture back | `app-sidebar` (persistent left rail ≥ lg), top bar |
| Narrow width | n/a (always compact) | sidebar collapses to a menu / bottom affordance < md |
| Deep linking | Universal/App Links (crush.app) | URL routes (canonical) |
| Modality | full-screen routes + bottom sheets | dialogs/drawers (radix) |
| Back affordance | OS back / swipe | browser back + in-app back |

These differences are **deliberate platform idioms**; equivalence is measured by
*reachability of the same flows and outcomes*, not identical chrome.

## 3. Shared UI-state taxonomy

Every list/detail/action surface MUST handle these states identically in meaning
(presentation may differ per platform). Naming is shared so QA can check parity.

| State | When | Required behavior |
|---|---|---|
| **Loading** | request in flight, no cached data | skeletons (web `skeleton.tsx`; mobile `DsColors.skeleton*`), no layout shift |
| **Empty** | request ok, zero results | explicit empty illustration + primary action (e.g. "Adjust filters") |
| **Error** | request failed (non-auth) | inline message + **Retry**; never a blank screen; map to `auth_errors`/typed error |
| **Offline** | no connectivity | offline banner; reads from cache if available; queue writes |
| **Retry** | after error/offline | idempotent re-issue; backoff; no duplicate side effects |
| **Optimistic** | mutating action (like, send, react) | apply locally immediately; reconcile/rollback on failure (no dupes on reconnect) |
| **Blocked** | viewing/contacting a blocked user | hide/disable contact; show "unavailable"; never leak content |
| **Permission-denied** | rules/entitlement/role denies | explain + route to fix (upgrade for entitlement; request permission for OS) — distinct from generic error |

Rules:
- **Optimistic + Retry** must be duplicate-safe (matches the chat cutover
  acceptance: offline send → reconnect → no duplicate messages).
- **Permission-denied** is never collapsed into **Error**: entitlement gates link
  to `/premium`; OS permission gates link to the permission prompt/settings.
- **Blocked** state is enforced server-side (rules) AND reflected in UI.

## Done-when status (Step 15)

- ✅ Equivalent flows defined for onboarding, discovery, matching, chat, safety,
  premium, profile, settings (+ insights); calls documented as mobile-only.
- ✅ Intentional mobile/desktop navigation differences documented.
- ✅ Shared 8-state taxonomy defined with required behavior + parity rules.
- ⏳ Per-screen conformance is verified by the Phase 8 Step 17 automation
  (axe/responsive specs) + the manual device matrix
  (`accessibility_responsive_validation_2026-06-07.md`).
