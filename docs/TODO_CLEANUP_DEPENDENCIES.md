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
- Status: done (2026-06-04). Inventoried mobile (52 deps/21 dev), functions (12/11), and crush-web manifests by group with purpose + risk + owner. Flagged: no `dependency_overrides` (good), `any`-pinned dev platform-interface deps (reproducibility risk). Report: `docs/reports/dependency_audit_2026-06-04.md`.

### CLEAN-DEP-002 - Update stale packages and replace deprecated libraries
- Files: dependency manifests and impacted integration points
- Description: Identify outdated or deprecated packages, then plan upgrades or replacements with compatibility notes.
- Acceptance Criteria: upgrade candidates are prioritized and blockers are documented.
- Testing: package update scans and targeted smoke tests after upgrades.
- Status: done (2026-06-04). Ran `flutter pub outdated` + `npm outdated`; prioritized safe within-constraint minors vs major-version candidates needing per-package smoke tests (app_links 6→7, package_info_plus 8→10, share_plus 10→13, stripe 16→22, express 4→5, file-type 16→22). Documented blockers: deprecated `multer` v1→v2 and `agora-access-token`→`agora-token`; `image` held at 4.8.0 by a transitive constraint. No upgrades applied (planning deliverable). Report: `docs/reports/dependency_audit_2026-06-04.md`.

### CLEAN-DEP-003 - Verify dependency licenses and vulnerability posture
- Files: dependency manifests, security scans, compliance notes
- Description: Ensure commercial distribution is compatible with all licenses and known vulnerabilities are triaged.
- Acceptance Criteria: high-risk vulnerabilities and license conflicts are documented with owners.
- Testing: `flutter pub outdated`, `npm audit`, and license review.
- Status: done (2026-06-04). `npm audit` → 29 vulns (1 critical `protobufjs`, 8 high incl `node-forge`/`lodash`/`path-to-regexp`/`fast-xml-parser`), all transitive via the `@google-cloud`/`firebase-admin`/`firebase-functions` chain — remediation: bump firebase-admin→13.10.0 + firebase-functions→7.2.5 then re-audit (owner: backend). **Do NOT run `npm audit fix`** — its dry-run proposed adding unfamiliar packages; pin patched versions manually. Licenses: mobile+functions stacks are permissive (MIT/BSD/Apache-2.0), no copyleft found; tracked follow-up: automated license SBOM for store sign-off. Report: `docs/reports/dependency_audit_2026-06-04.md`.
