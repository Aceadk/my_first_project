# TODO: Security Hardening Backend

- Priority: P0 – Critical
- Estimated Effort: 4-6 days
- Dependencies: `docs/TODO_API_ARCHITECTURE.md`, `docs/TODO_DATABASE.md`
- Assigned: AI + Developer

## Tasks

### SEC-BE-001 - Run OWASP backend audit on auth, discovery, chat, and file ingress
- Files: Functions, REST routes, validators, storage triggers
- Description: Review injection, authz, broken access control, unsafe deserialization, and upload ingress risks.
- Acceptance Criteria: high-severity backend findings are tracked with owners and fixes.
- Testing: malicious fixture tests and manual endpoint review.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_backend_audit_2026-05-30.md`
- Verification: `npm run build` + `npx mocha --exit test/securityAbuseLanes.test.js test/safetyValidation.test.js test/sanitizationPolicy.test.js` (per-file), `npm run lint` (all in `functions/`)
- Fixes: hardened `stripHtml`; `validateProfileName` now enforces its minimum on the sanitized value.

### SEC-BE-002 - Audit secrets management and dependency vulnerabilities
- Files: environment usage, CI secrets, dependency manifests, ops docs
- Description: Verify no hardcoded secrets remain and dependency vulnerability scan results are triaged.
- Acceptance Criteria: secret inventory exists; high-severity dependency risks are tracked or remediated.
- Testing: dependency scans and secret-pattern review.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_backend_audit_2026-05-30.md`
- Verification: secret-pattern scan (clean), `.env` gitignore review, `npm audit --omit=dev` triage (1 critical / 4 high — all transitive, tracked)

### SEC-BE-003 - Verify content-upload scanning and input sanitization pipeline
- Files: upload handlers, moderation jobs, sanitization helpers
- Description: Ensure user-provided data is sanitized before storage/rendering and uploads are checked before exposure.
- Acceptance Criteria: sanitization policy is documented and enforced on critical inputs.
- Testing: malicious payload tests and upload-fixture checks.
- Status: done 2026-05-30
- Evidence: `docs/reports/security_backend_audit_2026-05-30.md`
- Verification: `npx mocha --exit test/sanitizationPolicy.test.js` (7 passing), upload magic-byte/oversize/spoof cases in `test/profileRestEndpoints.test.js`
- Fixes: hardened `stripHtml` against trailing unterminated tags; added `test/sanitizationPolicy.test.js`.

### SEC-BE-004 - Move web trust and benefit state behind server-owned commands
- Files: `functions/src/**`, `firestore.rules`, `/Users/ace/crush-web/packages/core/src/services/device-security.ts`, `boost.ts`, `promo.ts`, entitlement services/stores
- Description: Remove client authority over device trust, boost activation, promo redemption, and final entitlement-affecting state. Decide whether device trust is a security control or UX-only state; if it is a control, require a verified backend challenge and audited server-owned records.
- Dependencies: `AUTH-SEC-006`, `SUB-001`, `DB-004`
- Acceptance Criteria:
  - A client cannot self-add a trusted device or modify protected trust records.
  - Boost eligibility, cooldown, activation, and counters are backend-enforced.
  - Promo validation/redemption and final entitlement writes are backend-owned.
  - Firestore rules deny direct client mutation of security and benefit fields.
  - Security-sensitive commands produce audit events with actor, target, outcome, and request metadata.
- Testing:
  - Abuse tests for self-grant, replay, cooldown bypass, forged entitlement, and unauthorized revocation.
  - Rules-emulator denial tests for protected fields.
  - Staging smoke tests for legitimate trust, boost, promo, and entitlement flows.
- Status: open — P0 security blocker from `R-066`.
