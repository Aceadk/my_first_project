#!/usr/bin/env bash
set -euo pipefail

# Generates a dated operator audit artifact for deprecated env alias migration.
# Usage:
#   scripts/generate_env_alias_migration_audit_report.sh
#   scripts/generate_env_alias_migration_audit_report.sh /custom/output.md

AUDIT_DATE="$(date +%F)"
DEFAULT_OUTPUT="docs/reports/ENV_ALIAS_MIGRATION_AUDIT_${AUDIT_DATE}.md"
OUTPUT_PATH="${1:-${DEFAULT_OUTPUT}}"

CHECKPOINT_STATUS="PASS"
ALLOWLIST_STATUS="PASS"

if CHECKPOINT_OUTPUT="$(scripts/check_env_alias_migration_status.sh 2>&1)"; then
  CHECKPOINT_STATUS="PASS"
else
  CHECKPOINT_STATUS="FAIL"
fi

if ALLOWLIST_OUTPUT="$(scripts/check_deprecated_env_aliases.sh 2>&1)"; then
  ALLOWLIST_STATUS="PASS"
else
  ALLOWLIST_STATUS="FAIL"
fi

mkdir -p "$(dirname "${OUTPUT_PATH}")"

cat > "${OUTPUT_PATH}" <<EOF
# Env Alias Migration Audit Report

- Date: ${AUDIT_DATE}
- Checkpoint status: ${CHECKPOINT_STATUS}
- Allowlist guard status: ${ALLOWLIST_STATUS}
- Source scripts:
  - \`scripts/check_env_alias_migration_status.sh\`
  - \`scripts/check_deprecated_env_aliases.sh\`

## Summary

This artifact captures the current deprecated env-alias migration state for operator and deployment workflows.

## Checkpoint Output

\`\`\`
${CHECKPOINT_OUTPUT}
\`\`\`

## Allowlist Guard Output

\`\`\`
${ALLOWLIST_OUTPUT}
\`\`\`

## Next Actions

1. Keep this checkpoint green in CI and before production release cutovers.
2. Complete external pipeline alias migration before \`2026-06-30\`.
3. Remove fallback compatibility aliases by \`2026-09-30\` (or document approved exception in \`docs/risk_notes.md\`).
EOF

echo "Wrote env alias migration audit report: ${OUTPUT_PATH}"

if [[ "${CHECKPOINT_STATUS}" != "PASS" || "${ALLOWLIST_STATUS}" != "PASS" ]]; then
  exit 1
fi
