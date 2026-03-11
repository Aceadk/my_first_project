#!/usr/bin/env bash
set -euo pipefail

# Scaffolds a dated production cutover ticket from the canonical template with
# a prefilled env-alias migration audit artifact reference.
#
# Usage:
#   scripts/create_production_cutover_ticket.sh
#   scripts/create_production_cutover_ticket.sh 2026-03-11
#   scripts/create_production_cutover_ticket.sh 2026-03-11 docs/reports/PRODUCTION_CUTOVER_2026-03-11.md

TEMPLATE_PATH="docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md"

fail() {
  echo "ERROR: $1"
  exit 1
}

if [ "$#" -gt 2 ]; then
  fail "Usage: scripts/create_production_cutover_ticket.sh [cutover-date YYYY-MM-DD] [output-path]"
fi

CUTOVER_DATE="${1:-$(date -u +%F)}"
if [[ ! "${CUTOVER_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  fail "Invalid cutover date '${CUTOVER_DATE}'. Expected YYYY-MM-DD."
fi

OUTPUT_PATH="${2:-docs/reports/PRODUCTION_CUTOVER_${CUTOVER_DATE}.md}"
AUDIT_PATH="docs/reports/ENV_ALIAS_MIGRATION_AUDIT_${CUTOVER_DATE}.md"

[ -f "${TEMPLATE_PATH}" ] || fail "Missing template: ${TEMPLATE_PATH}"

if [ -e "${OUTPUT_PATH}" ]; then
  fail "Output already exists: ${OUTPUT_PATH}"
fi

mkdir -p "$(dirname "${OUTPUT_PATH}")"

sed \
  -e "s|YYYY-MM-DD|${CUTOVER_DATE}|g" \
  -e "s|<repo-relative path>|${AUDIT_PATH}|g" \
  "${TEMPLATE_PATH}" > "${OUTPUT_PATH}"

echo "Wrote production cutover ticket scaffold: ${OUTPUT_PATH}"
echo "Prefilled audit artifact path: ${AUDIT_PATH}"

if [ ! -f "${AUDIT_PATH}" ]; then
  echo "WARNING: Audit artifact not found yet: ${AUDIT_PATH}"
  echo "Generate it with: scripts/generate_env_alias_migration_audit_report.sh"
fi

echo "Next:"
echo "  scripts/check_release_cutover_ticket_contract.sh ${OUTPUT_PATH}"

