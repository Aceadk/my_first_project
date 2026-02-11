# CRUSH Web App Execution Board

Last updated: February 11, 2026  
Environment audited: `https://crush-web-chi.vercel.app`  
Code patch prepared in repo: `/Users/ace/crush-web`

## Objective

Close production gaps found in live audit, fix the settings theme bug, and finish release-readiness checks with clear pass/fail criteria.

## Owner Legend

- `WEB-FE` = Web Frontend Engineer
- `WEB-BE` = Backend/Firebase Engineer
- `DEVOPS` = Deployment/Env/Infra Engineer
- `QA` = Test Automation Engineer
- `PM` = Product/Project Owner

## Audit Snapshot (Current Truth)

- Route scan (43 routes): `0` hard errors (`4xx/5xx`) and expected auth redirects for protected pages.
- Public route baseline is healthy: marketing and auth-entry pages return `200`.
- Protected app routes redirect unauthenticated users to `/auth/login?redirect=...` as expected.
- `/download` flow works: `/download -> 307 -> /#download`, and homepage contains `id="download"`.
- Canonical route is active: `/likes-you -> 308 -> /likes`.
- Placeholder anchor audit: no `href="#"` and no `javascript:void(0)` on sampled public pages.
- Asset integrity still failing: `/favicon.ico`, `/apple-touch-icon.png`, `/logo.png` return `404`.
- Theme root cause found in code: settings page used `next-themes` hook while app uses custom `ThemeProvider`.

## Theme Bug Fix (Prepared)

- **Issue**: Settings theme chooser did not use the app's theme context.
- **Root cause**: `apps/web/src/app/(app)/settings/settings-view.tsx` imported `useTheme` from `next-themes` instead of `@/shared/components/theme`.
- **Patch done**:
  - Switched hook import to custom provider.
  - Added typed theme option list (`Theme` union).
  - Kept UI behavior unchanged, only corrected provider wiring.
- **Verification**:
  - `pnpm --filter @crush/web build` passed successfully after patch.
  - Production `/settings` remains auth-protected, so final runtime verification requires authenticated session after deploy.

## Priority Board

| ID | Priority | Task | Owner | ETA | Dependencies | Acceptance Criteria | Status |
|---|---|---|---|---|---|---|---|
| WB-011 | P0 | Fix settings theme switcher provider mismatch and deploy | WEB-FE | Feb 11, 2026 | Deploy access + authenticated QA user | 1) `/settings` theme button updates app theme 2) `crush-theme` cookie/localStorage update 3) persists after reload | In Progress (Code Fixed, Deploy Pending) |
| WB-001 | P0 | Validate and fix Firebase config newline/whitespace issue causing Firestore request path corruption (`%0A`) | DEVOPS + WEB-BE | Feb 11, 2026 | Vercel env access + authenticated smoke run | 1) No `%0A` in Firestore request project path 2) No "client is offline" loop on app pages 3) Post-fix authenticated smoke is clean | Todo |
| WB-002 | P0 | Repair download conversion flow (`/download` redirect + in-page anchor) | WEB-FE | Feb 11, 2026 | None | 1) `/download` resolves to section `id="download"` 2) Anchor lands correctly 3) No dead internal download links | Done |
| WB-003 | P0 | Finalize mobile-store CTAs for launch readiness | WEB-FE + PM | Feb 12, 2026 | Real App Store/Play URLs from PM | 1) Production decision documented: real links or explicit "coming soon" non-click policy 2) Tracking params (if needed) verified | In Progress |
| WB-004 | P0 | Close auth recovery flow gaps and align Firebase action URLs | WEB-FE + WEB-BE | Feb 12, 2026 | Firebase Auth template/config access | 1) `/auth/reset-password` behavior intentionally defined 2) `/auth/verify` deep-link flow validated 3) Firebase email templates point to supported routes | In Progress |
| WB-005 | P1 | Fix metadata/structured-data asset integrity (`/logo.png`, `/favicon.ico`, `/apple-touch-icon.png`) | WEB-FE | Feb 12, 2026 | Design assets | 1) Assets return `200` 2) JSON-LD logo URL points to valid asset 3) Browser favicon/touch icon load correctly | Todo |
| WB-006 | P1 | Canonicalize route naming (`/likes` vs `/likes-you`) across docs/tests | WEB-FE + PM | Feb 13, 2026 | Product naming confirmation | 1) Single canonical route in nav/sitemap/tests 2) legacy path redirects cleanly | Done (Redirect Active) |
| WB-007 | P1 | Build CI smoke suite (guest + authenticated) and gate deploys | QA + WEB-FE | Feb 13, 2026 | Test credentials in CI secrets | 1) CI route/status + Playwright smoke 2) deploy blocked on failures 3) artifact report uploaded | Todo |
| WB-008 | P1 | Add runtime observability (Sentry + uptime + performance dashboards) | DEVOPS + WEB-BE | Feb 14, 2026 | Vendor accounts/secrets | 1) FE exceptions captured with release tags 2) uptime alerts for prod 3) perf dashboard receiving data | Todo |
| WB-009 | P2 | Add accessibility and performance baseline gates (Lighthouse + Axe) | QA + WEB-FE | Feb 14, 2026 | CI browser runtime | 1) baseline scores for marketing/auth pages 2) Axe scan on critical routes 3) regression budget tracked | Todo |
| WB-010 | P2 | Rebaseline docs and backlog (`TODO_WEBAPP`, task board) to live state | PM + WEB-FE | Feb 15, 2026 | Completion of P0/P1 | 1) remove stale tasks 2) only actionable gaps remain 3) board matches production | In Progress |

## Release Gate (Must Pass)

- [x] Public routes return expected statuses (`/`, `/features`, `/pricing`, `/about`, `/contact`, `/faq`, `/help`, `/privacy`, `/terms`, `/safety`, `/guidelines`)
- [ ] Auth critical routes fully validated as product-intended (`/auth/reset-password` currently `308` to `/auth/forgot-password`; confirm this is intended)
- [ ] Metadata assets all return `200` (`/favicon.ico`, `/apple-touch-icon.png`, `/logo.png` currently failing)
- [x] No placeholder dead links (`href="#"` / `javascript:void(0)`) in sampled production HTML
- [ ] Authenticated smoke suite passes for `/discover`, `/matches`, `/messages`, `/weekly-picks`, `/likes`, `/profile`, `/settings`, `/premium`
- [ ] Settings page theme toggle validated after deployment of WB-011
- [ ] Firestore URL `%0A` issue validated as resolved in authenticated run

## Validation Commands (Operator Runbook)

```bash
# Route status + redirect audit
BASE="https://crush-web-chi.vercel.app"
for p in / /features /pricing /about /contact /faq /help /privacy /terms /safety /guidelines \
  /auth/login /auth/signup /auth/phone /auth/forgot-password /auth/reset-password /auth/verify \
  /finishSignIn /auth/callback /discover /likes /matches /messages /weekly-picks /profile /settings /premium
do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$p")
  redir=$(curl -s -o /dev/null -w '%{redirect_url}' "$BASE$p")
  echo "$p -> $code $redir"
done
```

```bash
# Asset integrity audit
BASE="https://crush-web-chi.vercel.app"
for p in /manifest.json /favicon.svg /favicon.ico /apple-touch-icon.png /og-image.svg /logo.png /robots.txt /sitemap.xml
do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$p")
  echo "$p -> $code"
done
```

```bash
# Local compile validation of settings theme patch
cd /Users/ace/crush-web
pnpm --filter @crush/web build
```

## Execution Sequence (Remaining)

1. Deploy WB-011 (settings theme fix), then run authenticated `/settings` theme persistence check.
2. Fix missing metadata assets (WB-005), then rerun asset gate.
3. Confirm auth recovery product contract (WB-004) and Firebase template links.
4. Run authenticated smoke + Firestore `%0A` validation (WB-001, WB-007).
5. Final gate rerun and backlog cleanup (WB-010).

## Notes

- This board is strict by design: a task is complete only when production behavior matches acceptance criteria.
- Current highest-risk unverified area is authenticated flow validation; guest/public flow baseline is stable.
