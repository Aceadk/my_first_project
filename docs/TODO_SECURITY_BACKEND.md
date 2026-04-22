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
- Status: open

### SEC-BE-002 - Audit secrets management and dependency vulnerabilities
- Files: environment usage, CI secrets, dependency manifests, ops docs
- Description: Verify no hardcoded secrets remain and dependency vulnerability scan results are triaged.
- Acceptance Criteria: secret inventory exists; high-severity dependency risks are tracked or remediated.
- Testing: dependency scans and secret-pattern review.
- Status: open

### SEC-BE-003 - Verify content-upload scanning and input sanitization pipeline
- Files: upload handlers, moderation jobs, sanitization helpers
- Description: Ensure user-provided data is sanitized before storage/rendering and uploads are checked before exposure.
- Acceptance Criteria: sanitization policy is documented and enforced on critical inputs.
- Testing: malicious payload tests and upload-fixture checks.
- Status: open
