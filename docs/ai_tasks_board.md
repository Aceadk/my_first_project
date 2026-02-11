# AI Tasks Board

Tracking active and completed AI tasks for the CRUSH app.

| Task ID | Date | Title | Status | Notes |
| --- | --- | --- | --- | --- |
| T-2026-02-01-01 | 2026-02-01 | Phase 5 dependency updates (major versions) | Completed | Updated toolchain minimums; verified analyze output |
| T-2026-02-01-02 | 2026-02-01 | Lint cleanup + toolchain pinning | Completed | Fixed new lints; pinned CI Flutter 3.35.0; analyze clean |
| T-2026-02-01-03 | 2026-02-01 | Integration test failures (localization + auth UI) | In progress | Switched l10n lookup to lookupAppLocalizations; integration test rerun still timing out after build/install |
| T-2026-02-01-03 | 2026-02-01 | Phase 7.1 Audit high-traffic screens | Completed | Identified 46 issues across auth, discovery, chat, profile screens |
| T-2026-02-01-04 | 2026-02-01 | Phase 7.2 Design tokens enhancement | Completed | Added sizes.dart, enhanced breakpoints, spacing widgets |
| T-2026-02-01-05 | 2026-02-01 | Phase 7.3 Accessibility pass | Completed | Contrast checking, semantic wrappers, tap target enforcement |
| T-2026-02-01-06 | 2026-02-01 | Phase 7.4 Responsive tablet/desktop layouts | Completed | AdaptiveLayout, AdaptiveScaffold, AdaptiveGrid components |
| T-2026-02-01-07 | 2026-02-01 | Phase 7.5 Content moderation system | Completed | Profanity filter, text analysis, image moderation API |
| T-2026-02-01-08 | 2026-02-01 | Phase 7.6 Photo verification enhancement | Completed | Verification levels, selfie poses, ID document verification |
| T-2026-02-01-09 | 2026-02-01 | Phase 8.3 Configure production environment | Completed | AppConfig, env templates, dart-define support |
| T-2026-02-01-10 | 2026-02-01 | Phase 8.4 Generate Android AAB | Completed | Built app-release.aab (60.3MB); fixed Play Core conflicts |
| T-2026-02-01-11 | 2026-02-01 | Phase 8.5 iOS Archive configuration | Completed | Build config ready; documented Xcode archive process |
| T-2026-02-01-12 | 2026-02-01 | Phase 8.6 Prepare store assets | Completed | STORE_ASSETS.md with descriptions, screenshots, keywords |
| T-2026-02-01-13 | 2026-02-01 | Phase 8.9 Set up customer support | Completed | SupportConfig, SupportScreen, FAQ, contact integration |
| T-2026-02-06-01 | 2026-02-06 | Post‑Blaze Firebase setup | In progress | Functions redeployed with params; rules/indexes/hosting OK; Storage not initialized in console |
| T-2026-02-06-02 | 2026-02-06 | Connect Resend API | Completed | Resend env config verified; functions already wired via params |
| T-2026-02-06-03 | 2026-02-06 | Resend API key/domain setup | Completed | API key set, sender domain configured |
| T-2026-02-11-01 | 2026-02-11 | Fix web app bugs (crush-web) | Completed | Added redirects, safety page, guidelines page, fixed dead links, deployed to Vercel |
| T-2026-02-11-02 | 2026-02-11 | Create web app public assets (favicon, manifest, OG image) | Completed | Created favicon.svg, manifest.json, og-image.svg in crush-web/apps/web/public/ |
| T-2026-02-11-03 | 2026-02-11 | Fix placeholder social media links (crush-web) | Completed | Updated href="#" to real URLs (Twitter, Instagram, YouTube, TikTok) with target="_blank" and aria-label |
| T-2026-02-11-04 | 2026-02-11 | Web app SEO, auth routes, assets & smoke test | Completed | Fixed JSON-LD newline, added /finishSignIn + /auth/callback, updated sitemap, created smoke test — 24/24 pass |
| T-2026-02-11-05 | 2026-02-11 | Senior frontend/UX audit of crush-web homepage | Completed | 14 issues found: logo.png 404, missing #download anchor, SVG OG image, fabricated ratings, placeholder store links, viewport a11y, etc. |
| T-2026-02-11-06 | 2026-02-11 | Comprehensive web app audit (routes, code, content) | Completed | 3-part audit: 48/55 route checks pass, 28 code issues, 14 content issues identified |
| T-2026-02-11-07 | 2026-02-11 | Critical audit remediation (JSON-LD, security, SEO, a11y) | Completed | Fixed JSON-LD (fake ratings, SearchAction, logo 404), CSP headers, viewport a11y, PNG OG images, Stripe auth check, download anchor, store buttons, ReactQueryDevtools — 24/24 smoke tests pass |
| T-2026-02-11-08 | 2026-02-11 | GDPR, CSRF, rate limiting, HttpOnly auth cookie | Completed | Cookie consent banner, Origin-based CSRF, in-memory rate limiter, server-side HttpOnly auth cookie via /api/auth/session — 24/24 smoke tests pass, CSRF blocks verified |
| T-2026-02-11-09 | 2026-02-11 | P0: Fix Firestore env var contamination | Completed | Added .trim() to all Firebase config reads, re-set all Vercel env vars cleanly, fixed tab in .env file |
| T-2026-02-11-10 | 2026-02-11 | P1: Add /auth/verify + route redirects | Completed | Created email verification page, added redirects for /likes-you, /reset-password, /auth/reset-password, /verify — 48 pages, all routes verified |
| T-2026-02-11-11 | 2026-02-11 | P2: Re-baseline TODO_WEBAPP.md | Completed | Updated all phase statuses, removed 652-item parity backlog noise, 1307→~350 lines, added change log entries |
| T-2026-02-11-12 | 2026-02-11 | Fix location service errors | Completed | CSP blocked Nominatim API (added to connect-src), geolocation timeout too short for desktops (30s + retry), deployed |
| T-2026-02-11-13 | 2026-02-11 | Fix discovery visibility (Firestore rules + web profiles) | Completed | Firestore read rule was null-unsafe for flat web docs — made null-safe for both web (flat) and mobile (nested) structures; fixed isFemale() |
| T-2026-02-11-14 | 2026-02-11 | Fix age display showing "0 years old" | Completed | Added calculateAge() utility to compute age from birthDate dynamically; updated profile-view and swipe-card; added birthDate to DiscoveryProfile; fixed discover page error display |
