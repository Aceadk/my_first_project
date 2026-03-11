#!/usr/bin/env bash
set -euo pipefail

# Regression tests for invalid-input behavior in:
#   - scripts/create_production_cutover_ticket.sh
#   - scripts/check_release_cutover_ticket_contract.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CREATE_SCRIPT="scripts/create_production_cutover_ticket.sh"
CONTRACT_SCRIPT="scripts/check_release_cutover_ticket_contract.sh"

fail() {
  echo "ERROR: $1"
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "${haystack}" == *"${needle}"* ]] || fail "Expected output to contain: ${needle}"
}

run_expect_fail() {
  local output_file
  output_file="$(mktemp /tmp/release_cutover_invalid_out_XXXXXX.txt)"
  if "$@" >"${output_file}" 2>&1; then
    rm -f "${output_file}"
    fail "Expected command to fail but it succeeded: $*"
  fi
  cat "${output_file}"
  rm -f "${output_file}"
}

TS="$(date +%s)"
TMP_VALID_TICKET="/tmp/PRODUCTION_CUTOVER_INVALID_VALID_${TS}_$$.md"
TMP_EXISTING_OUTPUT="/tmp/PRODUCTION_CUTOVER_INVALID_EXISTS_${TS}_$$.md"
TMP_BAD_TICKET_MISSING_ARTIFACT="/tmp/PRODUCTION_CUTOVER_INVALID_MISSING_ARTIFACT_${TS}_$$.md"
TMP_BAD_TICKET_MISSING_STATUS="/tmp/PRODUCTION_CUTOVER_INVALID_MISSING_STATUS_${TS}_$$.md"

cleanup() {
  rm -f \
    "${TMP_VALID_TICKET}" \
    "${TMP_EXISTING_OUTPUT}" \
    "${TMP_BAD_TICKET_MISSING_ARTIFACT}" \
    "${TMP_BAD_TICKET_MISSING_STATUS}"
}
trap cleanup EXIT

# Seed valid ticket fixture for cases that need an existing ticket.
scripts/create_production_cutover_ticket.sh 2026-03-11 "${TMP_VALID_TICKET}" >/dev/null

# 1) create script: too many args
output="$(run_expect_fail "${CREATE_SCRIPT}" 2026-03-11 /tmp/a.md extra)"
assert_contains "${output}" "Usage: scripts/create_production_cutover_ticket.sh"

# 2) create script: invalid date format
output="$(run_expect_fail "${CREATE_SCRIPT}" 2026/03/11)"
assert_contains "${output}" "Invalid cutover date"

# 3) create script: output already exists
cat > "${TMP_EXISTING_OUTPUT}" <<'EOF'
already exists
EOF
output="$(run_expect_fail "${CREATE_SCRIPT}" 2026-03-11 "${TMP_EXISTING_OUTPUT}")"
assert_contains "${output}" "Output already exists"

# 4) contract script: too many args
output="$(run_expect_fail "${CONTRACT_SCRIPT}" a b)"
assert_contains "${output}" "Usage: scripts/check_release_cutover_ticket_contract.sh"

# 5) contract script: missing ticket file
output="$(run_expect_fail "${CONTRACT_SCRIPT}" /tmp/PRODUCTION_CUTOVER_DOES_NOT_EXIST.md)"
assert_contains "${output}" "Cutover ticket not found"

# 6) contract script: missing artifact reference
cat > "${TMP_BAD_TICKET_MISSING_ARTIFACT}" <<'EOF'
# Production Cutover Ticket
- Checkpoint status: PASS
- Allowlist guard status: PASS
EOF
output="$(run_expect_fail "${CONTRACT_SCRIPT}" "${TMP_BAD_TICKET_MISSING_ARTIFACT}")"
assert_contains "${output}" "must include exact dated audit artifact path"

# 7) contract script: missing required status
cat > "${TMP_BAD_TICKET_MISSING_STATUS}" <<'EOF'
# Production Cutover Ticket
- Env alias migration audit artifact: docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md
- Checkpoint status: PASS
EOF
output="$(run_expect_fail "${CONTRACT_SCRIPT}" "${TMP_BAD_TICKET_MISSING_STATUS}")"
assert_contains "${output}" "Allowlist guard status: PASS"

echo "Release cutover invalid-input tests passed."

