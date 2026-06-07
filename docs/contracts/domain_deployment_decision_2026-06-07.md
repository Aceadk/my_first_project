# Domain & Deployment Decision (2026-06-07)

Phase 6 Step 10 — establish the environment source of truth. Decides the
canonical domains + deployment platform and sequences the migration (code vs
infrastructure), because several "domains" are live infra facts (mobile deep
links, certificate pinning, email sender) that must migrate before the code flips.

## Decisions

| Concern | Canonical | Notes |
|---|---|---|
| Production web domain | **`crush.app`** | App + marketing. Web metadata/CSP already use it. |
| Staging web domain | `staging.crush.app` | target |
| API origin | `api.crush.app` (target) → today `us-central1-crush-265f7.cloudfunctions.net` | set `NEXT_PUBLIC_API_ORIGIN=https://api.crush.app` once the custom domain is mapped (CSP already allows `*.cloudfunctions.net` + the configured apiOrigin) |
| App deep-link domain | `crush.app` (target) | **currently `crushhour.app`** in mobile — infra-gated migration (below) |
| Support email | `support@crush.app` | |
| Transactional email | `Crush <no-reply@crush.app>` | **currently `crushhour.app`** — infra-gated (verify sender first) |
| Deployment platform | **Vercel** (Next.js web app) | the Firebase Hosting `crushapp` web config is removed as conflicting |

Deprecated (→ redirect to crush.app, reject in new code): `crushhour.app`,
`crushapp.com`, `app.crush.dating`, `crush.dating`.

## Migration sequencing — INFRA FIRST, then code

Several references are **live infrastructure** and must NOT be flipped in code
before the infra is migrated, or production breaks:

1. **DNS + SSL** for `crush.app` / `api.crush.app` / `staging.crush.app`.
2. **Firebase Auth authorized domains** — add `crush.app` (console).
3. **Apple Universal Links** — host `apple-app-site-association` at
   `https://crush.app/.well-known/...`; update the iOS associated-domains.
4. **Android App Links** — host `assetlinks.json` at `https://crush.app/...`.
5. **Certificate pinning** — mobile pins `crushhour.app` (see
   `test/core/network/certificate_pinning_test.dart`). Rotate to pin `crush.app`
   only after its cert chain is live; ship a mobile release that pins BOTH during
   transition.
6. **Email sender verification** — verify `crush.app` (or `no-reply@crush.app`)
   in the email provider BEFORE changing `EMAIL_FROM`.
7. **Stripe dashboard** — add `crush.app` redirect/return URLs.

Only after the above: flip the code defaults (mobile deep-link host, cert pins,
`EMAIL_FROM`, Stripe success/cancel defaults) and retire `crushhour.app`.

## Done in code now (safe; web-side, no infra dependency)

- Web metadata/`appUrl` default already `https://crush.app`.
- Web content domains `crushapp.com` → `crush.app` (support/help/contact/schema).
- Web billing success/cancel URLs `crushhour.app` → `crush.app`.
- Notification route resolver keeps `crushhour.app`/`www.crushhour.app` as
  accepted **legacy-redirect** hosts (mobile still emits them) with `crush.app`
  canonical.
- Removed the conflicting `crush-web/firebase.json` Hosting (`crushapp`) config
  and the `firebase deploy --only hosting:crushapp` script — Vercel is canonical.
- Added a deprecated-domain CI guard for the web app (rejects `crushapp.com` /
  `app.crush.dating` / `crush.dating`, and `crushhour.app` outside the
  documented legacy-redirect allowlist).

## Deferred to the infra-sequenced migration (NOT flipped in code yet)

- Mobile deep-link host + universal/app links + certificate pinning
  (`crushhour.app` → `crush.app`).
- Backend `EMAIL_FROM` default + Stripe success/cancel default URLs
  (`crushhour.app` → `crush.app`) — gated on sender verification + Stripe config.
- These keep `crushhour.app` until infra is ready; the web deprecated-domain
  guard does not scan the mobile codebase, so it does not force a premature flip.
