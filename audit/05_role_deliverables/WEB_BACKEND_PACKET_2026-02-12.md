# Web/Backend Full-Stack Packet (2026-02-12)

## Backend Surface Summary
- Cloud Functions callable exports: 36
- REST endpoints (`/v1/*`): 29
- Firestore triggers: 5
- Pub/Sub scheduled/background jobs: 2
- Entry files and raw extracts:
- `functions/src/index.ts`
- `audit/raw/functions_exports_raw.txt`
- `audit/raw/api_paths_raw.txt`

## Security Findings
- App Check enforcement disabled (`functions/src/index.ts:297`).
- CORS allows all origins if allowlist is empty (`functions/src/index.ts:113`).

## Quality Gate Findings
- `npm test` failing (3 failures in profile completeness helpers).
- `npm run lint` failing (14 errors, including typed lint config mismatch).

## Infrastructure/CI Snapshot
- CI pipeline exists at `.github/workflows/ci.yml` with flutter, functions, and security jobs.
- Current local baseline indicates functions lint/tests are red and block healthy CI confidence.

## Data and API Documentation Gaps
- No canonical API/event catalog with request/response schema per endpoint.
- Rate limits and auth are present in code but not centralized in public/internal reference docs.

## Required Remediation
- Fix P0 security posture (App Check and CORS hardening).
- Restore green lint/test gates for functions.
- Generate versioned API + event contract documentation under `/audit` then publish to `/docs`.
- Add load/performance baseline report for p95 and failure budgets.
