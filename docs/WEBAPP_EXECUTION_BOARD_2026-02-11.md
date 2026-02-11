# CRUSH Web App Execution Board

Last updated: February 11, 2026  
Environment audited: `https://crush-web-chi.vercel.app`

## Objective

Close production gaps found in live audit and complete the remaining high-value web backlog with measurable acceptance criteria.

## Owner Legend

- `WEB-FE` = Web Frontend Engineer
- `WEB-BE` = Backend/Firebase Engineer
- `DEVOPS` = Deployment/Env/Infra Engineer
- `QA` = Test Automation Engineer
- `PM` = Product/Project Owner

## Priority Board

| ID | Priority | Task | Owner | ETA | Dependencies | Acceptance Criteria | Status |
|---|---|---|---|---|---|---|---|
| WB-001 | P0 | Fix Firebase config newline/whitespace issue causing Firestore request path corruption (`%0A`) | DEVOPS + WEB-BE | Feb 11, 2026 | Vercel env access | 1) Firestore listen/request URLs no longer contain `%0A` in `database=projects/...` 2) Authenticated app routes load data without repeated "client is offline" console errors 3) Post-fix smoke pass completed on `/discover`, `/messages`, `/profile`, `/settings` | Todo |
| WB-002 | P0 | Repair download conversion flow (`/download` redirect target + in-page anchor) | WEB-FE | Feb 11, 2026 | None | 1) `/download` resolves to page section with `id="download"` 2) Scroll lands at correct section 3) No dead internal anchors from homepage/footer | Todo |
| WB-003 | P0 | Replace placeholder store CTAs (`href="#"`) with real App Store/Google Play URLs | WEB-FE + PM | Feb 11, 2026 | Real store URLs from PM | 1) Zero `href="#"` in production markup for store/download CTAs 2) Links open correct destinations 3) Tracking params (if required) included and validated | Todo |
| WB-004 | P0 | Close auth recovery route gaps (`/auth/reset-password`, `/auth/verify`) and align Firebase action URLs | WEB-FE + WEB-BE | Feb 12, 2026 | Firebase Auth template/config access | 1) `200` on required auth action routes 2) Password reset end-to-end flow passes 3) Email verification/deep-link flow lands on supported route 4) No auth template points to `404` route | Todo |
| WB-005 | P1 | Fix metadata/structured-data asset integrity (`/logo.png`, `/favicon.ico`, `/apple-touch-icon.png`) | WEB-FE | Feb 12, 2026 | Design assets | 1) Referenced assets return `200` 2) JSON-LD/logo URL valid 3) Browser favicon and touch icon load correctly | Todo |
| WB-006 | P1 | Canonicalize route naming (`/likes` vs `/likes-you`) and remove route ambiguity | WEB-FE + PM | Feb 13, 2026 | Product route decision | 1) Single canonical route in nav, sitemap, docs, and code 2) Legacy path has explicit redirect (if retained) 3) No route-contract mismatch in tests | Todo |
| WB-007 | P1 | Build CI smoke suite (guest + authenticated core flows) and gate deploys | QA + WEB-FE | Feb 13, 2026 | Test account credentials in CI secrets | 1) CI job executes route/status checks + Playwright smoke 2) Deploy blocked on failures 3) Test report artifact available per run | Todo |
| WB-008 | P1 | Add runtime observability (Sentry + uptime monitor + performance dashboards) | DEVOPS + WEB-BE | Feb 14, 2026 | Vendor accounts/secrets | 1) Frontend exceptions captured with release/version tags 2) Uptime alerts configured for prod domain 3) Core web performance dashboard receiving data | Todo |
| WB-009 | P2 | Run accessibility and performance baseline gates (Lighthouse + Axe) | QA + WEB-FE | Feb 14, 2026 | CI runner/browser deps | 1) Lighthouse mobile/desktop baseline recorded for marketing + auth pages 2) Axe scan added for critical routes 3) Regressions tracked in CI | Todo |
| WB-010 | P2 | Rebaseline docs and backlog to match live state (`TODO_WEBAPP`, tasks board) | PM + WEB-FE | Feb 15, 2026 | Completed P0/P1 changes | 1) Outdated unchecked items removed or reprioritized 2) Only actionable gaps remain 3) Board reflects real production status | Todo |

## Release Gate (Must Pass)

- [ ] All required public routes return expected statuses: `/`, `/features`, `/pricing`, `/about`, `/contact`, `/faq`, `/help`, `/privacy`, `/terms`, `/safety`, `/guidelines`
- [ ] Auth critical routes return expected statuses: `/auth/login`, `/auth/signup`, `/auth/phone`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/verify`, `/finishSignIn`, `/auth/callback`
- [ ] Key metadata assets return `200`: `/manifest.json`, `/favicon.svg`, `/favicon.ico`, `/apple-touch-icon.png`, `/og-image.svg`, `/logo.png`
- [ ] No placeholder CTA links in production HTML
- [ ] Authenticated smoke suite passes for: `/discover`, `/matches`, `/messages`, `/weekly-picks`, `/likes`, `/profile`, `/settings`, `/premium`
- [ ] No Firestore request URL contains `%0A` in project path

## Validation Commands (Operator Runbook)

```bash
# Route and asset status checks
BASE="https://crush-web-chi.vercel.app"
for p in / /features /pricing /about /contact /faq /help /privacy /terms /safety /guidelines \
  /auth/login /auth/signup /auth/phone /auth/forgot-password /auth/reset-password /auth/verify \
  /finishSignIn /auth/callback /manifest.json /favicon.svg /favicon.ico /apple-touch-icon.png /og-image.svg /logo.png
do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE$p")
  echo "$p -> $code"
done
```

```bash
# Firestore request sanity probe (should not contain %0A in database project segment)
# Run in browser automation after auth
# Expected: 0 matches
```

## Daily Plan (Execution Sequence)

1. **Feb 11, 2026**: WB-001, WB-002, WB-003
2. **Feb 12, 2026**: WB-004, WB-005
3. **Feb 13, 2026**: WB-006, WB-007
4. **Feb 14, 2026**: WB-008, WB-009
5. **Feb 15, 2026**: WB-010 + final release gate run

## Notes

- This board is intentionally strict: each task is only complete when acceptance criteria are fully met in production.
- Keep this file as the single source of truth for web remediation until the release gate is green.
