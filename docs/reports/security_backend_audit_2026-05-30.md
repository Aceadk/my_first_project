# Backend Security Audit — 2026-05-30

Scope: `SEC-BE-001`, `SEC-BE-002`, `SEC-BE-003` from `docs/TODO_SECURITY_BACKEND.md`.
Surface: `functions/src/index.ts` (REST + callables), upload/ingress handlers,
validators/sanitizers, secrets configuration, and dependency manifests.

## Summary

The backend already enforces the major OWASP controls: every REST route sits
behind ID-token auth + App Check, ownership is checked on cross-user actions,
uploads are content-verified by magic bytes, and secrets are param/.env-backed
with no hardcoded values. Two real input-sanitization gaps were found and fixed
in this pass; dependency-scan findings (all transitive) and the per-instance
Express rate limiter are tracked as follow-ups.

---

## SEC-BE-001 — OWASP Backend Audit (auth, discovery, chat, file ingress)

| OWASP area | Control in place | Status |
| --- | --- | --- |
| Authentication | All REST routes use `authMiddleware` (`admin.auth().verifyIdToken` on `Bearer`); callables use `requireAuth`. App Check enforced via `evaluateRestAppCheck`/`evaluateCallableAppCheck`. | OK |
| Broken access control | Cross-user actions verify ownership/membership: unmatch & messages & chat-media check `match.users.includes(req.uid)`; profile reads/writes are scoped to `req.uid`; photo delete checks owning user. | OK |
| Injection | Datastore is Firestore via the Admin SDK (no string-built queries → no SQL/NoSQL injection surface). Inputs pass `requireString`/`parseBoundedIntQueryParam` and allowlists (`normalizeProfileGender`, discovery preference token set). | OK |
| XSS / stored markup | `stripHtml` applied to message content, profile name/bio/text fields, interests, gender before storage. **Hardened this pass** (see SEC-BE-003). | Fixed |
| Unsafe deserialization | Bodies are JSON-only via `express.json()` (default 100 kb cap); no `eval`/dynamic require on user input; multipart handled by `multer` with size/type checks. | OK |
| File ingress | Magic-byte content verification (`file-type`), MIME allowlist, size caps, and private randomized storage paths; spoofed/oversize/empty payloads rejected. | OK |
| Rate limiting | Durable callable limiter (`applyRateLimit`, Firestore) + per-route Express limiter (see `API-002` report). | OK / tracked |
| CORS | `corsOriginValidator` allowlist; **fails closed in production** when unset. | OK |

**Findings / fixes**

1. **`stripHtml` left trailing unterminated tags** (fixed — SEC-BE-003).
2. **`validateProfileName` enforced its 2-char minimum on the raw string**, so
   markup could pad a name that renders as a single character (e.g.
   `<b>a</b>`). Now enforced on the sanitized value, consistent with
   `validateProfileTextField`. (fixed)
3. Express rate limiter is per-instance/in-memory — authoritative abuse control
   is the durable callable limiter. Tracked from `API-002`; not a new risk.

Existing malicious-fixture coverage: `securityAbuseLanes.test.js`,
`safetyValidation.test.js`, and the upload-spoofing/oversize cases in
`profileRestEndpoints.test.js` (magic-byte spoof, oversize, unsupported MIME).

---

## SEC-BE-002 — Secrets & Dependency Vulnerabilities

### Secret inventory

All secrets are Firebase `defineString` params (`.env`-backed), read lazily via
getters — **no hardcoded secrets** in source (pattern scan clean). `.env`,
`.env.local`, `functions/.env` are git-ignored; only `*.env.example` templates
are tracked.

| Param | Default | Notes |
| --- | --- | --- |
| `OTP_SECRET` | **none** | Fails closed (`getOtpSecretChecked` throws if unset). |
| `STRIPE_SECRET`, `STRIPE_WEBHOOK_SECRET` | `""` | Billing/webhook verification. |
| `APPLE_ISSUER_ID/KEY_ID/PRIVATE_KEY/BUNDLE_ID` | `""` | Apple receipt/S2S. |
| `GOOGLE_PLAY_PACKAGE_NAME`, `GOOGLE_RTDN_VERIFICATION_TOKEN` | `""` | Play billing/RTDN. |
| `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` | `""` | Calls token signing. |
| `RESEND_API_KEY`, `EMAIL_FROM` | `""` / default sender | Transactional email. |
| `CORS_ALLOWED_ORIGINS` | `""` | Allowlist (fail-closed in prod). |

Low-severity note: `integration_test/test_credentials.dart` ships a default test
email/password (`String.fromEnvironment` fallback). It is test-only,
overridable via `--dart-define`, and not a production secret; flagged for
awareness.

### Dependency scan (`npm audit --omit=dev`)

Totals: **1 critical, 4 high, 17 moderate, 1 low**. **All are transitive** — the
direct manifest is on current majors (`firebase-admin@^13.6.1`,
`firebase-functions@^7.0.5`, `express@^4.22.1`, `stripe@^16.12.0`).

| Package (sev) | Pulled in by | Issue | Exposure in this app |
| --- | --- | --- | --- |
| `protobufjs@7.5.4` (critical) | `google-gax` ← firebase-admin/firestore, vision | Code injection via bytes-field defaults | Internal gRPC only; no user-supplied `.proto` — low |
| `fast-xml-parser@5.3.6` (high) | `@google-cloud/storage` | Entity-expansion / ReDoS | Parses trusted GCS XML responses — low |
| `node-forge@1.3.3` (high) | firebase-admin | Cert-chain bypass / Ed25519 forgery | Admin-internal cert handling — low |
| `path-to-regexp@0.1.12` (high) | `express@4` | ReDoS via route params | Routes are static patterns — low |
| `minimatch@9.0.5` (high) | google-gax/protobufjs | ReDoS | Build/glob tooling — low |

**Remediation status:** tracked. Fixes require upstream `firebase-admin` /
`@google-cloud/*` / `express` releases that bump the nested versions.
`npm audit fix --force` is **not** applied because it pulls breaking majors
(e.g. Express 5) onto a P0 backend without validation. Real-world exploitability
is low because every finding is an internal transitive dep not fed untrusted
request input. Recommended follow-up: monitor for firebase-admin patch releases
and re-run `npm audit` each dependency bump; consider scoped `overrides` only
after API-compat validation.

---

## SEC-BE-003 — Upload Scanning & Input Sanitization

### Sanitization policy (documented + enforced)

Layered model: **server-side stripping** (defense-in-depth) + **client output
encoding** (primary XSS defense on web). Server enforcement:

- `stripHtml(input)` removes complete tags **and** a trailing unterminated tag
  start, with a letter/`"/"` guard so benign `<` usage (`3 < 5`, the `<3`
  emoticon) is preserved.
- Applied to every stored free-text field: message content
  (`validateMessageContent`), profile name (`validateProfileName`), bio
  (`validateBio`), generic profile text (`validateProfileTextField`), interests,
  and gender; each also enforces length bounds and (where relevant) allowlists.

**Hardening applied this pass:** the previous `stripHtml` was
`/<[^>]*>/g` only, which left a trailing unterminated tag (e.g.
`hi <img src=x onerror=alert(1)`) intact — a browser would parse it once more
markup followed. Now removed. `validateProfileName` also enforces its minimum
length on the sanitized value.

### Upload ingress

`validateBinaryUpload` enforces, in order: non-empty buffer → size cap
(`maxBytes`, `413`) → claimed MIME in allowlist (`415`) → **magic-byte content
detection** (`file-type`) matching the allowlist (`415` on spoof) → known
extension. Uploads land at private, randomized storage paths. This covers the
"checked before exposure" criterion for type/size/spoofing. (Deep content
moderation / AV scanning of pixel content is a separate concern outside this
ingress check.)

### Tests added

`functions/test/sanitizationPolicy.test.js` (7 cases): tag stripping, the
trailing-unterminated-tag bypass, the `"><script>` breakout payload, benign-`<`
preservation, and validator enforcement for message/name/bio.

---

## Verification

- `npm run build` (in `functions/`)
- `npx mocha --exit test/sanitizationPolicy.test.js` (7 passing)
- `npx mocha --exit test/safetyValidation.test.js` (5 passing)
- `FIREBASE_CONFIG=… npx mocha --exit test/profileRestValidation.test.js test/profileCompleteness.test.js` (18 passing)
- `npx mocha --exit test/securityAbuseLanes.test.js` (7 passing)
- `npx mocha --exit test/chatRestPagination.test.js` (12 passing)
- `npx mocha --exit test/callables.test.js` (11 passing)
- `npm run lint` clean
- `npm audit --omit=dev` (findings triaged above)
- Full-suite delta check: `npm test` reports **127 passing / 50 failing both
  with and without this change** — the 50 are pre-existing cross-file
  `admin`-mock contamination in the recursive run (the project verifies
  per-file); this change adds **zero** new failures.

## Tracked Follow-Ups

1. Migrate REST abuse-path rate limiting onto the durable Firestore limiter
   (shared with `API-002`).
2. Monitor and bump transitive dependency vulns on each `firebase-admin` /
   `@google-cloud` release; re-run `npm audit`.
3. (Optional) Add pixel-content moderation/AV scanning for uploaded media beyond
   magic-byte/type/size validation.
4. (Test infra) The per-file `admin`-mock isolation limitation should be
   addressed so the recursive `npm test` run is green.
