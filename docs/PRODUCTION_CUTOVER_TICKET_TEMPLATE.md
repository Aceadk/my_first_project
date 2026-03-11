# Production Cutover Ticket Template

Use this template for every production cutover.

- Cutover date (UTC): `YYYY-MM-DD`
- Release owner: `<name>`
- Mobile build(s): `<android aab/apk + ios build>`
- Web deployment target: `<url/environment>`

## Env Alias Migration Gate (Required)

- Env alias migration audit artifact: `docs/reports/ENV_ALIAS_MIGRATION_AUDIT_YYYY-MM-DD.md`
- Checkpoint status: `PASS`
- Allowlist guard status: `PASS`

## Evidence Links

- Audit artifact file link: `<repo-relative path>`
- CI run link: `<url>`
- Release ticket/reference: `<url or id>`

## Approval

- Engineering: `<name>`
- QA: `<name>`
- Product/Operations: `<name>`

