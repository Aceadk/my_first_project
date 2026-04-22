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
- Status: open

### SEC-FE-002 - Verify secure transport expectations and certificate-handling policy
- Files: HTTP clients, network config, web CSP/session config, mobile transport settings
- Description: Confirm TLS assumptions, certificate policy, and any pinning or trust-store decisions are documented.
- Acceptance Criteria: transport policy is explicit; unsafe exceptions are removed or tracked.
- Testing: client config review and negative-path network tests where available.
- Status: open

### SEC-FE-003 - Audit XSS, CSRF, and CSP posture for the web app
- Files: `/Users/ace/crush-web/**`, web middleware, API routes, headers
- Description: Validate browser security controls and ensure user content cannot execute arbitrary script or bypass state-change protections.
- Acceptance Criteria: CSP, CSRF, and XSS mitigations are documented with any gaps tracked.
- Testing: route/header review and targeted web security checks.
- Status: open
