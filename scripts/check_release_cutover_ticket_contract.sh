#!/usr/bin/env bash
set -euo pipefail

# Enforces production cutover ticket requirements for env-alias migration audit
# evidence. Always validates template contract; optionally validates a concrete
# cutover ticket file when provided.
#
# Usage:
#   scripts/check_release_cutover_ticket_contract.sh
#   scripts/check_release_cutover_ticket_contract.sh docs/reports/PRODUCTION_CUTOVER_2026-03-11.md

TEMPLATE_PATH="docs/PRODUCTION_CUTOVER_TICKET_TEMPLATE.md"

fail() {
  echo "ERROR: $1"
  exit 1
}

check_template_contract() {
  [ -f "${TEMPLATE_PATH}" ] || fail "Missing template: ${TEMPLATE_PATH}"

  rg -q "Env Alias Migration Gate \\(Required\\)" "${TEMPLATE_PATH}" \
    || fail "Template must include 'Env Alias Migration Gate (Required)' section."

  rg -q "docs/reports/ENV_ALIAS_MIGRATION_AUDIT_YYYY-MM-DD\\.md" "${TEMPLATE_PATH}" \
    || fail "Template must include required audit artifact placeholder path."

  rg -q 'Checkpoint status:[[:space:]]*`PASS`' "${TEMPLATE_PATH}" \
    || fail "Template must include 'Checkpoint status' field set to PASS."

  rg -q 'Allowlist guard status:[[:space:]]*`PASS`' "${TEMPLATE_PATH}" \
    || fail "Template must include 'Allowlist guard status' field set to PASS."
}

check_ticket_file() {
  local ticket_path="$1"
  local audit_ref

  [ -f "${ticket_path}" ] || fail "Cutover ticket not found: ${ticket_path}"

  audit_ref="$(rg -o "docs/reports/ENV_ALIAS_MIGRATION_AUDIT_[0-9]{4}-[0-9]{2}-[0-9]{2}\\.md" "${ticket_path}" | head -n 1 || true)"
  [ -n "${audit_ref}" ] || fail "Cutover ticket must include exact dated audit artifact path."

  [ -f "${audit_ref}" ] || fail "Referenced audit artifact does not exist: ${audit_ref}"

  rg -q 'Checkpoint status:[[:space:]]*`?PASS`?' "${ticket_path}" \
    || fail "Cutover ticket must include 'Checkpoint status: PASS'."

  rg -q 'Allowlist guard status:[[:space:]]*`?PASS`?' "${ticket_path}" \
    || fail "Cutover ticket must include 'Allowlist guard status: PASS'."
}

check_template_contract

if [ "$#" -gt 1 ]; then
  fail "Usage: scripts/check_release_cutover_ticket_contract.sh [cutover-ticket-path]"
fi

if [ "$#" -eq 1 ]; then
  check_ticket_file "$1"
  echo "Release cutover ticket contract check passed (template + ticket)."
else
  echo "Release cutover ticket template contract check passed."
fi
