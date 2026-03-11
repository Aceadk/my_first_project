#!/usr/bin/env bash
set -euo pipefail

# Operator migration checkpoint for deprecated env aliases.
# This script verifies that release/CI execution paths are not emitting legacy
# aliases and enforces date-based migration/removal milestones.

FREEZE_DATE="2026-06-30"
REMOVAL_DATE="2026-09-30"
TODAY="$(date +%F)"

ALIASES=(
  "APP_ENV"
  "CRUSH_API_BASE_URL"
  "USE_EMULATORS"
  "EMULATOR_HOST"
)

is_on_or_after() {
  local date_a="$1"
  local date_b="$2"
  # ISO-8601 dates can be compared lexicographically.
  if [[ "${date_a}" == "${date_b}" || "${date_a}" > "${date_b}" ]]; then
    return 0
  fi
  return 1
}

echo "=== Env Alias Migration Checkpoint ==="
echo "Date: ${TODAY}"
echo "Freeze date: ${FREEZE_DATE}"
echo "Removal date: ${REMOVAL_DATE}"

# 1) Keep static allowlist guard green.
scripts/check_deprecated_env_aliases.sh

# 2) Ensure machine-executed paths are not emitting deprecated aliases.
#    We treat assignments and --dart-define usage as active emitters.
emitter_pattern='--dart-define=(APP_ENV|CRUSH_API_BASE_URL|USE_EMULATORS|EMULATOR_HOST)=|^[[:space:]]*(export[[:space:]]+)?(APP_ENV|CRUSH_API_BASE_URL|USE_EMULATORS|EMULATOR_HOST)=|run:[[:space:]].*\b(APP_ENV|CRUSH_API_BASE_URL|USE_EMULATORS|EMULATOR_HOST)='

emitter_hits="$(rg -n -e "${emitter_pattern}" \
  .github/workflows \
  scripts \
  --glob '!scripts/check_deprecated_env_aliases.sh' \
  --glob '!scripts/check_env_alias_migration_status.sh' \
  || true)"

if [[ -n "${emitter_hits}" ]]; then
  echo ""
  echo "Legacy alias emitters found in machine-executed paths:"
  echo "${emitter_hits}"
  exit 1
fi

# 3) Date-aware policy milestones.
if is_on_or_after "${TODAY}" "${FREEZE_DATE}"; then
  echo "Freeze checkpoint active (canonical keys only for new pipeline updates)."
else
  echo "Freeze checkpoint pending."
fi

if is_on_or_after "${TODAY}" "${REMOVAL_DATE}"; then
  # After removal date, even compatibility mentions should be gone from runtime
  # and operator paths.
  removal_hits=""
  for alias in "${ALIASES[@]}"; do
    alias_hits="$(rg -n "\\b${alias}\\b" \
      lib/config/app_config.dart \
      lib/core/firebase_emulator.dart \
      lib/data/repositories/fake_repositories.dart \
      scripts/build_release.sh \
      .env.example \
      2>/dev/null || true)"
    if [[ -n "${alias_hits}" ]]; then
      removal_hits+="${alias_hits}"$'\n'
    fi
  done

  if [[ -n "${removal_hits}" ]]; then
    echo ""
    echo "Removal date reached, but legacy alias compatibility references remain:"
    echo "${removal_hits}"
    exit 1
  fi
fi

echo "Env alias migration checkpoint passed."
