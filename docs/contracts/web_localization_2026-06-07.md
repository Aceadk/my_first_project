# Web Localization (Phase 8 Step 18)

- Date: 2026-06-07
- Repo: crush-web (`apps/web/src/i18n/*`, `packages/core/src/services/auth_errors.ts`).
- Foundation: the non-routing dictionary i18n built in P2 #11 (dot-notation keys,
  `{placeholder}` interpolation, `_one/_other` plurals, English fallback). This
  step makes it globally active and adds switching, persistence, formatting, and
  shipped non-English catalogs.

## What shipped

### 1. Provider mounted globally
- `<I18nProvider>` wraps the whole app in `app-providers.tsx` (inside `Providers`).
- Locale is resolved **client-first** from the `crush-locale` cookie → browser
  language → `en`, mirroring the theme strategy so static marketing pages are
  **not** deopted to dynamic rendering.
- A pre-hydration `localeInitScript` (in `layout.tsx <head>`) sets
  `<html lang>` + `<html dir>` before paint, so RTL/locale is correct on the
  first frame (no flash). `<html>` keeps `suppressHydrationWarning`.

### 2. Locale switching + persistence
- `LocaleSwitcher` (accessible radio dropdown) in the sidebar footer.
- `setLocale` writes the `crush-locale` cookie (+ localStorage backup) and updates
  state + `<html lang/dir>` **instantly** (no full reload).
- 21 locales offered (mirrors mobile ARB roadmap); each shown by endonym.

### 3. Locale-aware formatting (`i18n/format.ts`, `useFormatters`)
- `date`, `dateTime`, `number`, `currency` (ISO 4217), `relativeTime` via `Intl`,
  bound to the active locale. Unit-tested (en/de/Intl behaviors).

### 4. Externalized copy + catalogs
- New namespaces in the catalog: `validation`, `authErrors` (mirrors the
  backend/Firebase codes), `notifications` (category labels), `meta`; expanded
  `errors`, `settings` (language/theme), `auth` (login flow).
- **Backend/validation/auth errors:** `getAuthErrorKey(error)` (in
  `@crush/core`) maps an error code to an `authErrors.<code>` i18n key so call
  sites render localized messages; `getAuthErrorMessage` remains for the English
  default. Keys kept in sync via a guarded set + a parity test.
- **Shipped catalogs:** `es` (Spanish, LTR) and `ar` (Arabic, RTL), both typed
  as `Messages` so TypeScript enforces structural completeness against English.
- **Representative copy replacement:** the global app chrome (`app-sidebar`: nav,
  upgrade, plan label, theme/language labels, sign-out) and the login form are
  fully localized through the catalog.

### 5. Tests
- Unit (vitest): translation engine; **catalog parity** (es/ar have the exact
  English key set, no blanks, no unknown placeholders); **formatters**;
  `getAuthErrorKey` ↔ catalog. 251 web unit tests green; lint + typecheck clean.
- E2E (`e2e/i18n.spec.ts`, prioritized locales): default→en, `es` cookie→lang=es
  (LTR), `ar` cookie→dir=rtl + Arabic copy, and switcher persistence across
  reload. Runs in the Playwright lane.

## Metadata note (intentional scope boundary)
The default `metadata` export stays English (static, SEO-stable); localized
`meta.title/description` keys exist in every catalog for client title sync and a
future migration. **Fully localized SSR metadata + per-locale routing/hreflang
require routed locales** (a next-intl-style migration) — deliberately out of
scope for this non-routing foundation; tracked as follow-up.

## Remaining incremental work (tracked, not blocking)
- **String sweep:** externalize the remaining page/component copy (discovery,
  chat, settings sub-pages, premium, profile, marketing) into the existing
  namespaces. The mechanism, catalogs, and fallback are in place; this is
  mechanical. A `t()`-coverage lint rule could enforce no new hardcoded copy.
- **More catalogs:** translate the other roadmap locales (currently fall back to
  English at lookup).
- **Routed locales + localized SSR metadata** (next-intl migration) if SEO per
  locale becomes a priority.

## Done-when status (Step 18)
- ✅ i18n provider mounted globally (SSR-safe, html lang/dir, no-flash script).
- ✅ Hardcoded copy replaced in the global chrome + login (representative);
  remaining sweep tracked.
- ✅ Validation, backend/auth errors, notifications labels, dates, and currencies
  localized (catalogs + `getAuthErrorKey` + `Intl` formatters). Metadata: catalog
  keys + boundary documented.
- ✅ Locale switching + cookie persistence.
- ✅ Prioritized locale E2E (es LTR, ar RTL, switcher persistence).
