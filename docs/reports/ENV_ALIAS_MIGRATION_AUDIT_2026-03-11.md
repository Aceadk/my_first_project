# Env Alias Migration Audit Report

- Date: 2026-03-11
- Checkpoint status: PASS
- Allowlist guard status: PASS
- Source scripts:
  - `scripts/check_env_alias_migration_status.sh`
  - `scripts/check_deprecated_env_aliases.sh`

## Summary

This artifact captures the current deprecated env-alias migration state for operator and deployment workflows.

## Checkpoint Output

```
=== Env Alias Migration Checkpoint ===
Date: 2026-03-11
Freeze date: 2026-06-30
Removal date: 2026-09-30
Deprecated env alias guard passed.
Freeze checkpoint pending.
Env alias migration checkpoint passed.
```

## Allowlist Guard Output

```
Deprecated env alias guard passed.
```

## Next Actions

1. Keep this checkpoint green in CI and before production release cutovers.
2. Complete external pipeline alias migration before `2026-06-30`.
3. Remove fallback compatibility aliases by `2026-09-30` (or document approved exception in `docs/risk_notes.md`).
