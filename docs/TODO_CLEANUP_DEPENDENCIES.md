# TODO: Dependency Audit

- Priority: P1 – High
- Estimated Effort: 2-4 days
- Dependencies: `docs/TODO_SECURITY_BACKEND.md`, `docs/TODO_SECURITY_FRONTEND.md`
- Assigned: AI + Developer

## Tasks

### CLEAN-DEP-001 - Build dependency inventory with purpose, owner, and risk
- Files: `pubspec.yaml`, `functions/package.json`, `/Users/ace/crush-web/**/package.json`
- Description: Document why each dependency exists and flag anything obsolete, duplicated, or risky.
- Acceptance Criteria: dependency inventory includes purpose and follow-up action per package group.
- Testing: dependency listing and version scan.
- Status: open

### CLEAN-DEP-002 - Update stale packages and replace deprecated libraries
- Files: dependency manifests and impacted integration points
- Description: Identify outdated or deprecated packages, then plan upgrades or replacements with compatibility notes.
- Acceptance Criteria: upgrade candidates are prioritized and blockers are documented.
- Testing: package update scans and targeted smoke tests after upgrades.
- Status: open

### CLEAN-DEP-003 - Verify dependency licenses and vulnerability posture
- Files: dependency manifests, security scans, compliance notes
- Description: Ensure commercial distribution is compatible with all licenses and known vulnerabilities are triaged.
- Acceptance Criteria: high-risk vulnerabilities and license conflicts are documented with owners.
- Testing: `flutter pub outdated`, `npm audit`, and license review.
- Status: open
