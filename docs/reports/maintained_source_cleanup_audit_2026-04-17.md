# Maintained Source Cleanup Audit — 2026-04-17

Scope:
- `lib/**`
- `functions/src/**`
- `.github/**`
- `scripts/**`
- `tool/**`

Goal:
- confirm there are no remaining obsolete commented-out code fragments in maintained runtime paths,
- confirm there are no stray `print()` leftovers in maintained runtime code,
- distinguish intentional logging and archived tooling from real cleanup debt.

## Findings

### 1. `print()` in maintained runtime code

Result:
- No `print()` calls remain in maintained runtime source under `lib/**`, `functions/src/**`, `.github/**`, or `tool/**`.

Notes:
- `print()` still exists in `scripts/archive/legacy_fixers/**`, which is intentionally archived and excluded from runtime cleanup.

### 2. `debugPrint()` usage

Result:
- The only maintained-source `debugPrint()` usage is inside [`lib/core/app_logger.dart`](/Users/ace/my_first_project/lib/core/app_logger.dart), where it is the intentional sink for the app logging abstraction.

Decision:
- Retain `debugPrint()` in `AppLogger`; it is not a stray debug leftover.

### 3. Commented-out code scan

Result:
- After converting the barrel import example in [`lib/core/constants/constants.dart`](/Users/ace/my_first_project/lib/core/constants/constants.dart) to documentation comments, the maintained-source scan no longer returns obsolete commented-out code patterns.

Notes:
- Remaining comment hits in maintained source are descriptive comments such as animation or DTO notes, not disabled code.

## Conclusion

`CLEAN-DEAD-001` is satisfied for the maintained runtime surface:
- no stray `print()` leftovers,
- no obsolete commented-out code patterns in maintained source,
- intentional `debugPrint()` usage remains centralized in `AppLogger`.

Archived fixer scripts remain intentionally excluded from this cleanup scope.
