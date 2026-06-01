# Frontend Security Audit — 2026-05-30

Scope: `SEC-FE-001`, `SEC-FE-002`, `SEC-FE-003` from
`docs/TODO_SECURITY_FRONTEND.md`. Surfaces: the Flutter mobile client
(`lib/**`), platform transport config (`android/`, `ios/`), and the web app
(`/Users/ace/crush-web/**`).

## Summary

Both clients are in good shape: mobile traffic is HTTPS-only with no ATS/cleartext
exceptions, deep links are allowlisted, and the web app ships a per-request
nonce CSP with `object-src 'none'` and SameSite session cookies. Two real mobile
issues were fixed in this pass — a latent certificate-pinning MITM hole and the
same naive HTML-strip weakness corrected on the backend. Web HSTS is the one
tracked gap.

## SEC-FE-001 — OWASP Client Risks (mobile + web)

| Risk | Finding | Status |
| --- | --- | --- |
| Insecure local storage | Mobile: ID/refresh tokens via Firebase SDK + `flutter_secure_storage` (`AuthSecureStorage`); only non-sensitive prefs in `SharedPreferences`; all cleared on logout/delete. Web: HttpOnly session cookies; `localStorage` holds only non-token prefs. | OK (see `AUTH-SEC-001`) |
| Unsafe rendering / XSS | Mobile renders chat/profile in Flutter `Text` (no HTML execution); `InputSanitizer` strips tags + escapes bios. Web: nonce CSP + React auto-escaping + server `stripHtml`. | OK + hardened |
| Deep-link abuse | `DeepLinkConfig._isValidDeepLink` allowlists scheme/host: `crushhour://` or HTTPS on `crushhour.app`/`www.crushhour.app` only (`http://localhost` debug-only); sensitive routes carry `requiresAuth`. | OK |
| Client-side trust assumptions | The backend is authoritative for authz/validation/sanitization (`SEC-BE-*`); client `InputSanitizer` is defense-in-depth, not the security boundary. | OK |

Fix: `InputSanitizer._stripHtmlTags` now also removes a trailing unterminated
tag start (e.g. `hi <img src=x onerror=...`) — the same gap fixed server-side in
`SEC-BE-003` — while preserving benign `<` (`3 < 5`, `<3`). This matters most for
`sanitizeMessage`, which neither allowlists nor entity-escapes.

## SEC-FE-002 — Transport & Certificate Policy

**Policy: HTTPS-only on every platform, OS trust store, no pinning (by design).**

| Surface | Setting |
| --- | --- |
| Android | `network_security_config.xml`: `cleartextTrafficPermitted="false"`, system trust anchors; user-installed CAs only under `debug-overrides`. |
| iOS | No `NSAppTransportSecurity` exceptions in `Info.plist` → ATS defaults (TLS, no arbitrary loads). |
| Certificate pinning | `CertificatePinning` infra exists but is intentionally **unconfigured** — the backend is Google-hosted (`cloudfunctions.net`, `googleapis.com`, `firebasestorage`) which rotates certs; pinning those would break on rotation. Documented decision. |

Fix (latent MITM): `CertificatePinning._validateCertificate` returned `true` for
non-pinned hosts. `badCertificateCallback` only fires after the OS trust store
already rejected the cert, so blanket-accepting non-pinned hosts would defeat TLS
for them whenever the pinned client is active. Now returns `false` (honors the
rejection). No runtime change today because pinning is unconfigured (the callback
isn't installed), but the secure default is now in place and covered by a test.

## SEC-FE-003 — Web XSS / CSRF / CSP

| Control | Implementation | Status |
| --- | --- | --- |
| CSP | Per-request nonce in `middleware.ts`: `default-src 'self'`, `script-src 'self' 'nonce-…'` (no `unsafe-inline` in prod; `unsafe-eval/inline` dev-only), `object-src 'none'`, `base-uri 'self'`, `form-action 'self'`, `upgrade-insecure-requests`, explicit img/font/connect/frame allowlists. | Strong |
| Clickjacking | `X-Frame-Options: SAMEORIGIN` (next.config headers). | OK |
| MIME sniffing | `X-Content-Type-Options: nosniff`. | OK |
| Referrer / Permissions | `Referrer-Policy: strict-origin-when-cross-origin`; `Permissions-Policy: camera=(), microphone=(), geolocation=(self)`. | OK |
| CSRF | Session cookies `HttpOnly` + `Secure` (prod) + `SameSite=Lax`; the backend API authenticates with Bearer Firebase ID tokens (not ambient cookies), so the cross-site state-change surface is minimal. | OK |
| XSS | Nonce CSP + React auto-escaping + server `stripHtml` (`SEC-BE-003`) + client `InputSanitizer`. | OK |

## Gaps Tracked

1. **HSTS** — no explicit `Strict-Transport-Security` header in `next.config.js`
   or `middleware.ts`. Vercel injects HSTS for custom domains by default; verify
   in the deployed environment and add it explicitly if absent. (P2)
2. **CSP `frame-ancestors`** — clickjacking is covered by `X-Frame-Options:
   SAMEORIGIN`; adding `frame-ancestors 'self'` would modernize the control. (P3)
3. **`style-src 'unsafe-inline'`** — retained for Tailwind/Google Fonts; accepted
   low-risk tradeoff (style injection, not script). (Accepted)

## Verification

- `flutter analyze` (cert pinning + input sanitizer + their tests) — clean
- `flutter test test/core/network/certificate_pinning_test.dart test/input_sanitizer_hotspot_test.dart` — passing (incl. new non-pinned-host reject + trailing-tag strip cases)
- Web posture reviewed in `apps/web/next.config.js`, `apps/web/src/middleware.ts`, and `apps/web/src/app/api/auth/**` cookie options.

## Manual Follow-Up

- Confirm HSTS is present on the deployed web domain (gap #1).
- On-device verification that deep links from untrusted hosts are ignored and
  that release builds reject proxied/MITM TLS (pinning bypass is debug-only).
