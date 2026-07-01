# Crush — Security Audit & Hardening (2026-06-13)

Scope of this pass: the **client-bypass trust boundary** — the controls that must
hold even when an attacker fully inspects/modifies the web frontend or reverse-
engineers the mobile app. That means Firestore / Storage / RTDB security rules,
payment & entitlement verification, the web API surface, web security headers,
and secrets in shipped client code.

**Threat model assumption (correct, per the brief):** the web/mobile frontend is
fully visible and modifiable. Security is judged only by what the **server and
security rules** enforce. UI-only gates are treated as cosmetic.

---

## Executive summary

The backend is, overall, **already mature and correctly designed** around the
"never trust the client" principle:

- Firestore rules block clients from writing `plan`, `isPremium`,
  `subscriptionTier`, `premiumPlan`, `isIdVerified`, `boost`, `stripeCustomerId`,
  `safetyFlags`, etc. on their own user doc → **no self-granted premium/role/trust**.
  (`firestore.rules:110-124`)
- `matches` are **backend-only** create/update/delete; messages enforce
  `fromUserId == auth.uid` (no sender spoofing), participant + active-match +
  block checks, ID-verification, and premium gating for video.
  (`firestore.rules:157-248`)
- Storage blocks SVG (stored-XSS vector), caps sizes, locks verification docs and
  legacy chat paths server-only, and serves chat media via a participant-checked
  Cloud Function signed URL. (`storage.rules`)
- RTDB makes `premium_users` server-only and gates presence/typing/read-receipts/
  last-seen on premium, with a default-deny `$other`. (`database.rules.json`)
- Payments: Stripe webhook **signature-verified** server-side and entitlement set
  server-side (`crush-web/.../api/stripe/webhook/route.ts:241`,
  `functions/src/index.ts:9639-9730`); checkout maps a `tier_period` enum to
  **server-side** Stripe price IDs (no client price/amount trust)
  (`.../api/stripe/create-checkout-session/route.ts:12-77`); Apple & Google
  receipts verified server-side (`functions/src/index.ts:9229-9460`); admin key
  read from env, **not committed** (`crush-web/.../lib/firebase-admin.ts`).

No unauthenticated account-takeover, trivial premium unlock, or sender-spoofing
hole was found in the reviewed surface. The findings below are the real gaps.

### Findings at a glance

| # | Sev | Area | Status |
|---|-----|------|--------|
| H-1 | High | `likes` readable by any signed-in user (BOLA/scrape + premium "who likes you" partial bypass) | **FIXED + verified** |
| H-2 | High | `users/{uid}` exposes sensitive top-level fields (billing IDs, possibly precise geo/contact) to any signed-in viewer | Phase 1 shipped (private subcollection + rules + backfill + web dual-write + tests); cutover pending — see `docs/h2_user_private_split_runbook_2026-06-12.md` |
| W-1 | Med→Low | Web: HSTS missing; console not stripped in prod | **FIXED + verified** |
| M-1 | Med | `stories` world-readable; "privacy handled in queries" = not enforced server-side | Documented |
| M-2 | Med | RTDB `read_receipts` writable by any authed user (spoof read state) | Documented |
| M-3 | Low | RTDB `chat_settings.$uid` exposes `isPremium`/retention to any authed user | Documented |
| W-2 | Med | Web CSP `script-src` uses `'unsafe-inline'` (tradeoff for static hydration) | Documented (path back to nonce) |

### Coverage gaps (NOT audited this pass — see "Remaining work")
Full line-by-line IDOR/rate-limit/validation review of the 14k-line
`functions/src/index.ts`; OWASP MASVS Android/iOS review; secret rotation &
git-history scrubbing; CI/CD SAST/dependency/secret scanning.

---

## A. Detailed findings

### H-1 — `likes` collection world-readable  **(FIXED, verified)**
- **File:** `firestore.rules` (and duplicate `functions/firestore.rules`), `likes` match.
- **Was:** `allow read: if isSignedIn();` — every signed-in user could read **every**
  like document.
- **Exploit (frontend-independent):** issue a Firestore query
  `likes where targetUserId == <anyUid>` (the exact query `fetchLikesYou` uses,
  `firebase_discovery_repository.dart:109`) for *any* user to learn who likes
  them, or page the whole collection to reconstruct the entire like-graph. Free
  users can read their **own** incoming likes → partial bypass of the premium
  "See who likes you" feature.
- **Fix applied:** reads scoped to the two participants only:
  ```
  allow read: if isSignedIn()
    && (resource.data.fromUserId == request.auth.uid
        || resource.data.toUserId == request.auth.uid
        || (('targetUserId' in resource.data)
            && resource.data.targetUserId == request.auth.uid));
  ```
  Closes cross-user scraping/BOLA with **no functional regression** (legitimate
  self-reads still pass). Verified by emulator rules tests (80/80 passing),
  including a new "third party cannot read a like between two other users".
- **Residual:** the premium gate for "who likes you" is still only enforced in the
  UI for the recipient's own incoming likes. To fully gate it behind payment,
  stop reading `likes` directly and serve incoming likers through a
  premium-checked Cloud Function (see Remaining work).

### H-2 — `users/{uid}` leaks sensitive top-level fields cross-user  **(needs refactor)**
- **Files:** `firestore.rules:87-98` (cross-user read allowed when profile
  visible/matched); clients read full docs directly
  (`firebase_discovery_repository.dart:323`, `firebase_profile_repository.dart:88`).
- **Why risky:** Firestore has **no field-level read rules** — allowing a doc read
  exposes the *entire* document. The update-protection list proves these
  sensitive fields live at the top level of the user doc: `stripeCustomerId`,
  `stripeSubscriptionId`, `kycVerificationStatus`, `safetyFlags`,
  `subscriptionLifecycle`, etc. (`firestore.rules:113-115`). Any signed-in,
  non-blocked user who can view a profile can read those. For a dating app, if
  precise `latitude`/`longitude` or contact fields are also top-level, this is a
  **stalking/PII risk**.
- **Fix (refactor):** split the user doc into a public projection (display fields
  only) and a private doc/subcollection `users/{uid}/private/*` readable only by
  owner + backend; move billing IDs, KYC, safety flags, exact geo, email/phone
  there; store only coarse/rounded location publicly. Migrate reads (discovery,
  profile, likesYou) to the public projection and writes accordingly. Add rules
  tests asserting a non-owner cannot read the private doc. *(Not done blind in
  this pass — it touches Flutter + web + functions + a data migration and must be
  validated against the running app.)*

### W-1 — Web security headers / console  **(FIXED, verified)**
- **File:** `crush-web/apps/web/next.config.js`.
- Added **HSTS** `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
  (verified present via `curl -I` against `next start`).
- Added `compiler.removeConsole` in production (excludes `error`/`warn`) so the
  client bundle doesn't leak tokens/user data/endpoints via the console.
- Build green (54/54 static pages), all pre-existing headers + CSP intact.

### M-1 — `stories` world-readable
- `firestore.rules:321-323` `allow read: if isSignedIn();` with a comment that
  privacy is "handled in queries" — i.e., **client-side only**, not enforced. A
  modified client can read all stories regardless of intended audience. Lower
  impact (stories are broadcast-ish) but should be scoped to non-blocked viewers
  / matches if stories are meant to be private. Not changed (could alter the
  stories feed; needs product intent confirmation).

### M-2 — RTDB `read_receipts` writable by any authed user
- `database.rules.json` `read_receipts.$matchId.$messageId .write: "auth != null"`.
  No participant check (RTDB can't read Firestore match membership), so a user can
  write read-receipt entries for matches they're not in. Read is premium-gated, so
  impact is limited to spoofing "read" state. Consider moving read-receipt writes
  behind a Cloud Function that verifies match participation, or mirror minimal
  match membership into RTDB for a rule check.

### M-3 — RTDB `chat_settings.$uid` exposes premium flag
- `chat_settings.$uid .read: "auth != null"` exposes `isPremium`/retention of any
  user to any authed user. Low sensitivity; scope read to owner if not needed by
  the other participant.

### W-2 — Web CSP allows `'unsafe-inline'` scripts
- `crush-web/apps/web/src/shared/lib/csp.ts`. This was a deliberate tradeoff: the
  prior nonce policy broke hydration on statically-prerendered pages. It weakens
  XSS defense-in-depth (the app is otherwise XSS-resistant via React + no
  `dangerouslySetInnerHTML` on user input). Path back to strict: render the
  affected routes dynamically and restore a per-request nonce + `strict-dynamic`
  (documented inline in `csp.ts`).

---

## B. Architecture notes (current state is largely the secure target)

- **Backend authority:** Firestore/Storage/RTDB rules + Cloud Functions are the
  source of truth. Privileged writes (matches, entitlement, boost, retention) are
  backend-only; clients cannot mutate protected fields. ✔
- **Payment entitlement model:** purchase → provider webhook (signature-verified)
  → server writes canonical entitlement fields → rules read entitlement. Client
  never decides premium. ✔ Keep all premium feature *use* behind a server check
  or a rule that reads server-written entitlement (already true for video msgs,
  calls, typing, presence, read-receipts).
- **Gap to close:** the user-document is doing double duty as both the public
  profile and the private/billing record (H-2). Split it.

---

## C. Implementation patches applied in this pass
1. `firestore.rules` + `functions/firestore.rules` — `likes` read scoped to
   participants (H-1).
2. `firestore-tests/rules.test.mjs` — replaced the "anyone can read likes" test
   with participant-scoping + no-scraping assertions (80/80 pass).
3. `crush-web/apps/web/next.config.js` — HSTS header + production console
   stripping (W-1).

---

## D. Security checklists

**Database/rules (Firebase)** — ✔ done unless noted
- [x] Users cannot write entitlement/role/verification fields
- [x] Matches/messages backend-controlled; no sender spoofing
- [x] Reports/blocks: no client reads; creator-only writes
- [x] Storage: SVG blocked, size caps, verification + chat media locked
- [x] RTDB premium_users server-only; default-deny
- [x] `likes` reads participant-scoped (this pass)
- [ ] Split sensitive fields out of public `users/{uid}` (H-2)
- [ ] Gate "who likes you" via premium-checked Cloud Function
- [ ] Scope `stories` reads; lock `read_receipts` writes; scope `chat_settings`

**Payments** — ✔
- [x] Webhook signatures verified (Stripe/Apple/Google)
- [x] Server-side price mapping (no client price/plan trust)
- [x] Entitlement written server-side; revocation on cancel/refund handled
- [ ] Add explicit automated tests: expired/cancelled/refunded → entitlement lost

**Web** — ✔ unless noted
- [x] No secrets in client bundle; admin key env-based & server-only
- [x] Source maps off in prod; console stripped in prod
- [x] HSTS + X-Frame-Options + nosniff + Referrer-Policy + Permissions-Policy + CSP
- [ ] Restore nonce/`strict-dynamic` CSP after making routes dynamic (W-2)

**Android / iOS (MASVS)** — NOT audited this pass
- [ ] Token storage in Keystore/Keychain; no secrets in APK/IPA
- [ ] Cert pinning; root/jailbreak as risk signal; release log/obfuscation
- [ ] Deep-link params validated server-side; no sensitive data in push payloads
- [ ] Premium/feature use re-checked against backend entitlement

**Deployment / CI** — partially in place
- [x] Branch CI: lint, typecheck, unit, build (green)
- [ ] Add SAST, dependency audit, secret scanning to CI; required review on `main`

---

## E. Abuse-case results (verified this pass)

| Abuse attempt | Result |
|---|---|
| Read another user's likers via `likes where targetUserId==victim` | **Blocked** (rules test: third party read fails) |
| Scrape entire like-graph | **Blocked** (participant-scoped read) |
| Self-grant premium by writing `plan/isPremium/subscriptionTier` on own user doc | **Blocked** (`firestore.rules:110-124`) |
| Self-grant role/verification/boost on own user doc | **Blocked** (same protected-field list) |
| Send message as another user (spoof `fromUserId`) | **Blocked** (`firestore.rules:217`) |
| Join another chat by changing `matchId` | **Blocked** (participant + active-match check) |
| Unlock premium by tampering checkout price/amount | **Blocked** (server-side price-ID mapping) |
| Forge a Stripe webhook to grant premium | **Blocked** (signature verification) |
| Find secrets in web client bundle / shipped Flutter code | **None found** (admin key env-based) |
| SSL-strip / downgrade (no HSTS) | **Now mitigated** (HSTS added) |
| Stalk via cross-user read of billing/precise-geo fields on user doc | **Still possible** → H-2 (refactor required) |

---

## Remaining work (prioritized, NOT done this pass)
1. **H-2 refactor:** public/private split of `users/{uid}`; migrate reads/writes; rules tests.
2. **Premium "who likes you"** → premium-checked Cloud Function; make `likes` read server-only.
3. **Full `functions/src/index.ts` review:** per-callable authZ/ownership, input
   schema validation (reject unexpected fields), and per-user/IP rate limits on
   swipe/like/message/report/OTP/payment; confirm idempotency on payment ops.
4. **MASVS Android/iOS** review (token storage, pinning, deep links, push payloads,
   release hardening, local-state→entitlement re-check).
5. **Secrets:** rotate anything ever committed; scrub git history; add CI secret
   scanning + pre-commit hooks (`.gitignore` already hardened for
   `*-adminsdk-*.json`, `*.p8`, `*.keystore`).
6. **CI/CD:** add SAST + `npm/pnpm audit` + secret scanning; protect `main`.
7. **Tests:** add payment-lifecycle entitlement tests and per-route authZ tests.
