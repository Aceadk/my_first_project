# TODO / Comment Debt Inventory (2026-02-12)

## Scan Scope
- `lib/`
- `functions/src/`
- `test/`
- `integration_test/`
- `web/`
- `docs/`

## Results
Raw output files:
- All matches (including docs): `audit/raw/todo_inventory_all_raw.txt`
- Code comment markers only: `audit/raw/todo_inventory_code_markers_raw.txt`

Counts:
- All matches including docs/history text: 56
- Code comment markers (`TODO|FIXME|HACK|XXX|NOTE`): 3

Code marker entries:
1. `functions/src/index.ts:3386`
2. `functions/src/index.ts:3461`
3. `lib/core/di.dart:93`

## Initial Classification
- Completed stale comments: 0 (not yet verified).
- Still relevant and should be ticketed: 3.
- Critical comments requiring immediate escalation: 0.

## Required Next Action
Convert the 3 active code markers into tracked backlog items and update comments to reference ticket IDs.
