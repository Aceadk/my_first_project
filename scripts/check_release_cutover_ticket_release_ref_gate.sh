#!/usr/bin/env bash
set -euo pipefail

# CI gate for concrete production cutover ticket validation on release refs.
# Release refs include:
#   - refs/heads/release
#   - refs/heads/release/*
#   - refs/heads/release-*
#   - refs/tags/*
#
# Optional override:
#   RELEASE_CUTOVER_TICKET_PATH=<path>
#   RELEASE_CUTOVER_TICKET_GLOB=<glob-pattern>

fail() {
  echo "ERROR: $1"
  exit 1
}

is_release_ref() {
  local ref="$1"
  case "${ref}" in
    refs/heads/release|refs/heads/release/*|refs/heads/release-*|refs/tags/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_ticket_path() {
  local ticket_glob
  local ticket_candidates=()

  if [ -n "${RELEASE_CUTOVER_TICKET_PATH:-}" ]; then
    echo "${RELEASE_CUTOVER_TICKET_PATH}"
    return 0
  fi

  ticket_glob="${RELEASE_CUTOVER_TICKET_GLOB:-docs/reports/PRODUCTION_CUTOVER_*.md}"

  # Use nullglob so non-matching patterns resolve to an empty array.
  shopt -s nullglob
  ticket_candidates=( ${ticket_glob} )
  shopt -u nullglob

  if [ "${#ticket_candidates[@]}" -eq 0 ]; then
    return 0
  fi

  printf '%s\n' "${ticket_candidates[@]}" | sort | tail -n 1
}

GITHUB_REF_VALUE="${GITHUB_REF:-}"

if [ -z "${GITHUB_REF_VALUE}" ]; then
  echo "GITHUB_REF is not set; skipping release-ref concrete ticket gate."
  exit 0
fi

if ! is_release_ref "${GITHUB_REF_VALUE}"; then
  echo "Non-release ref (${GITHUB_REF_VALUE}); concrete cutover ticket gate not required."
  exit 0
fi

TICKET_PATH="$(resolve_ticket_path)"
if [ -z "${TICKET_PATH}" ]; then
  fail "Release ref detected (${GITHUB_REF_VALUE}) but no concrete cutover ticket was found. Set RELEASE_CUTOVER_TICKET_PATH or add docs/reports/PRODUCTION_CUTOVER_YYYY-MM-DD.md."
fi

echo "Release ref detected: ${GITHUB_REF_VALUE}"
echo "Validating concrete cutover ticket: ${TICKET_PATH}"
scripts/check_release_cutover_ticket_contract.sh "${TICKET_PATH}"
echo "Release-ref concrete cutover ticket gate passed."
