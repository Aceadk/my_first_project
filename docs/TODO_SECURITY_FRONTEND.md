# TODO: Security Hardening Frontend

- Priority: P0 – Critical
- Estimated Effort: 3-5 days
- Dependencies: `docs/TODO_SECURITY_BACKEND.md`, `docs/TODO_AUTH_SECURITY.md`
- Assigned: AI + Developer

## Tasks

### SEC-FE-001 - Audit mobile and web clients against OWASP client risks
- Files: mobile app shell, web app shell, auth/session flows, storage helpers
- Description: Review insecure local storage, unsafe web rendering, deep-link abuse, and client-side trust assumptions.
- Acceptance Criteria: major client-side security risks are documented and prioritized.
- Testing: manual security review plus targeted automated checks where possible.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_frontend_audit_2026-05-30.md`
- Verification: `flutter analyze` + `flutter test test/input_sanitizer_hotspot_test.dart` (sanitizer + deep-link allowlist + storage reviewed; storage cross-ref `AUTH-SEC-001`)
- Fix: hardened `InputSanitizer._stripHtmlTags` against trailing unterminated tags.

### SEC-FE-002 - Verify secure transport expectations and certificate-handling policy
- Files: HTTP clients, network config, web CSP/session config, mobile transport settings
- Description: Confirm TLS assumptions, certificate policy, and any pinning or trust-store decisions are documented.
- Acceptance Criteria: transport policy is explicit; unsafe exceptions are removed or tracked.
- Testing: client config review and negative-path network tests where available.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_frontend_audit_2026-05-30.md`
- Verification: `flutter test test/core/network/certificate_pinning_test.dart`; Android `network_security_config.xml` (cleartext disabled) + iOS ATS (no exceptions) reviewed.
- Fix: `CertificatePinning._validateCertificate` now rejects (was accept) certs on non-pinned hosts that already failed OS validation.

### SEC-FE-003 - Audit XSS, CSRF, and CSP posture for the web app
- Files: `/Users/ace/crush-web/**`, web middleware, API routes, headers
- Description: Validate browser security controls and ensure user content cannot execute arbitrary script or bypass state-change protections.
- Acceptance Criteria: CSP, CSRF, and XSS mitigations are documented with any gaps tracked.
- Testing: route/header review and targeted web security checks.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_frontend_audit_2026-05-30.md`
- Verification: reviewed `crush-web` `next.config.js` headers, nonce-CSP `middleware.ts`, and `api/auth/**` SameSite cookie options.
- Gaps tracked: explicit web HSTS header (P2); optional CSP `frame-ancestors` (P3).

### SEC-FE-004 - Make protected web backend access production-operational
- Files: `/Users/ace/crush-web/packages/core/src/firebase/config.ts`, `/Users/ace/crush-web/apps/web/src/middleware.ts`, web environment validation, protected web service tests
- Description: Initialize Firebase App Check for the web app and align CSP `connect-src` with the approved callable/REST origins. Current production backend paths enforce App Check while the web bootstrap does not initialize it, and CSP excludes the Cloud Functions origin.
- Dependencies: `API-008`, `TEST-007`
- Acceptance Criteria:
  - Web App Check uses an approved production provider with automatic token refresh.
  - Local/emulator debug behavior is explicit and cannot weaken production enforcement.
  - CSP permits only the required Firebase/Cloud Functions/API origins per environment.
  - Discovery REST, Firebase callables, Storage, Stripe, and push registration work without CSP violations.
  - Missing or invalid App Check tokens fail predictably and surface actionable diagnostics.
- Testing:
  - Unit tests for environment/provider selection and CSP construction.
  - Staging integration tests proving protected REST and callable success with App Check and denial without it.
  - Browser console/header smoke checks for CSP violations.
- Status: open — P0 release blocker from `R-065`.
