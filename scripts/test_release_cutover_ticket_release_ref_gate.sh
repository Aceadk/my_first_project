#!/usr/bin/env bash
set -euo pipefail

# Focused regression checks for scripts/check_release_cutover_ticket_release_ref_gate.sh
# covering ref matching and ticket-path resolution behavior.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

GATE_SCRIPT="scripts/check_release_cutover_ticket_release_ref_gate.sh"

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
  output_file="$(mktemp /tmp/release_ref_gate_fail_out_XXXXXX.txt)"
  if "$@" >"${output_file}" 2>&1; then
    rm -f "${output_file}"
    fail "Expected command to fail but it succeeded: $*"
  fi
  cat "${output_file}"
  rm -f "${output_file}"
}

TMP_TICKET="/tmp/PRODUCTION_CUTOVER_GATE_TEST_$(date +%s)_$$.md"
TMP_RESOLVE_A="docs/reports/PRODUCTION_CUTOVER_2099-12-30.md"
TMP_RESOLVE_B="docs/reports/PRODUCTION_CUTOVER_2099-12-31.md"
TMP_EMPTY_DIR="$(mktemp -d /tmp/release_ref_gate_empty_XXXXXX)"
TMP_GLOB_VALID_TICKET="${TMP_EMPTY_DIR}/PRODUCTION_CUTOVER_2099-12-31.md"

cleanup() {
  rm -f "${TMP_TICKET}" "${TMP_RESOLVE_A}" "${TMP_RESOLVE_B}"
  rm -rf "${TMP_EMPTY_DIR}"
}
trap cleanup EXIT

scripts/create_production_cutover_ticket.sh 2026-03-11 "${TMP_TICKET}" >/dev/null

# 1) Unset ref should skip.
output="$(env -u GITHUB_REF "${GATE_SCRIPT}")"
assert_contains "${output}" "GITHUB_REF is not set; skipping release-ref concrete ticket gate."

# 2) Non-release ref should skip.
output="$(GITHUB_REF=refs/heads/main "${GATE_SCRIPT}")"
assert_contains "${output}" "concrete cutover ticket gate not required"

# 3) Release branch with explicit ticket override should pass.
output="$(GITHUB_REF=refs/heads/release/test RELEASE_CUTOVER_TICKET_PATH="${TMP_TICKET}" "${GATE_SCRIPT}")"
assert_contains "${output}" "Release-ref concrete cutover ticket gate passed."

# 4) Release tag with explicit ticket override should pass.
output="$(GITHUB_REF=refs/tags/v1.2.3 RELEASE_CUTOVER_TICKET_PATH="${TMP_TICKET}" "${GATE_SCRIPT}")"
assert_contains "${output}" "Release-ref concrete cutover ticket gate passed."

# 5) Explicit path override must take precedence over fallback glob.
output="$(GITHUB_REF=refs/heads/release/test RELEASE_CUTOVER_TICKET_PATH="${TMP_TICKET}" RELEASE_CUTOVER_TICKET_GLOB="${TMP_EMPTY_DIR}/PRODUCTION_CUTOVER_*.md" "${GATE_SCRIPT}")"
assert_contains "${output}" "Validating concrete cutover ticket: ${TMP_TICKET}"
assert_contains "${output}" "Release-ref concrete cutover ticket gate passed."

# 6) Without override, script should resolve the latest ticket path.
cat > "${TMP_RESOLVE_A}" <<'EOF'
# Production Cutover Ticket
- Env alias migration audit artifact: docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md
- Checkpoint status: PASS
- Allowlist guard status: PASS
EOF

cat > "${TMP_RESOLVE_B}" <<'EOF'
# Production Cutover Ticket
- Env alias migration audit artifact: docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md
- Checkpoint status: PASS
- Allowlist guard status: PASS
EOF

output="$(GITHUB_REF=refs/heads/release "${GATE_SCRIPT}")"
assert_contains "${output}" "Validating concrete cutover ticket: ${TMP_RESOLVE_B}"
assert_contains "${output}" "Release-ref concrete cutover ticket gate passed."

# 7) Invalid override path should fail on release refs.
output="$(run_expect_fail env GITHUB_REF=refs/heads/release/test RELEASE_CUTOVER_TICKET_PATH=/tmp/PRODUCTION_CUTOVER_DOES_NOT_EXIST.md "${GATE_SCRIPT}")"
assert_contains "${output}" "Cutover ticket not found"

# 8) Invalid explicit path must still fail even if fallback glob can resolve a valid ticket.
cat > "${TMP_GLOB_VALID_TICKET}" <<'EOF'
# Production Cutover Ticket
- Env alias migration audit artifact: docs/reports/ENV_ALIAS_MIGRATION_AUDIT_2026-03-11.md
- Checkpoint status: PASS
- Allowlist guard status: PASS
EOF
output="$(run_expect_fail env GITHUB_REF=refs/heads/release/test RELEASE_CUTOVER_TICKET_PATH=/tmp/PRODUCTION_CUTOVER_DOES_NOT_EXIST.md RELEASE_CUTOVER_TICKET_GLOB="${TMP_EMPTY_DIR}/PRODUCTION_CUTOVER_*.md" "${GATE_SCRIPT}")"
assert_contains "${output}" "Cutover ticket not found"

# 9) Without override and no resolvable ticket files should fail on release refs.
rm -f "${TMP_GLOB_VALID_TICKET}"
output="$(run_expect_fail env GITHUB_REF=refs/heads/release/test RELEASE_CUTOVER_TICKET_GLOB="${TMP_EMPTY_DIR}/PRODUCTION_CUTOVER_*.md" "${GATE_SCRIPT}")"
assert_contains "${output}" "no concrete cutover ticket was found"

echo "Release-ref cutover ticket gate tests passed."
