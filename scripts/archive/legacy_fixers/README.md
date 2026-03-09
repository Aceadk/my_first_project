# Legacy Root Python Scripts (Archived)

This folder contains deprecated root-level Python helper scripts from past cleanup/migration waves.

Examples include:
- `fix_*.py`
- `add_*.py`
- `remove_*.py`, `replace_*.py`, `refactor_*.py`, `rm_*.py`
- `run_*.py`, `trim_*.py`, `update_*.py`, `extract_*.py`, `generate_*.py`, `abstract_*.py`
- one-off utility files like `_migrate_debug_print.py`, `a11y_audit.py`, `auth_audit.py`, `final_lint_fixes.py`

## Status
- Deprecated
- Not part of the supported build, test, or release workflow
- Unsafe to run blindly on the current codebase

## Why Archived
Many of these scripts perform direct string replacements and file rewrites without AST validation, dependency checks, or dry-run safeguards. Some scripts also conflict with each other (for example `CallRepository` vs `CallManagerRepository` rewrites).

## Usage Policy
- Do not run these scripts in normal development.
- If a historical script is needed for forensic comparison, run it only on an isolated throwaway branch.
- Prefer targeted code changes + tests over mass text replacement scripts.

## Preferred Replacement
For future cleanup/migrations, use maintained tooling with:
- explicit file targeting,
- `--dry-run` support,
- preflight git-clean checks,
- post-change verification (`flutter analyze` / focused tests).
