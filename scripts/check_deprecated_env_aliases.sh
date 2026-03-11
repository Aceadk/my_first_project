#!/usr/bin/env bash
set -euo pipefail

# Prevent new usages of deprecated env aliases outside approved compatibility
# files. This guard keeps migration progress enforceable while legacy fallback
# remains temporarily supported.

allowed_files_for_alias() {
  local alias="$1"
  case "$alias" in
    "APP_ENV")
      cat <<'EOF'
lib/config/app_config.dart
scripts/build_release.sh
docs/ENV_KEY_MATRIX.md
docs/RELEASE_GUIDE.md
docs/risk_notes.md
docs/reports/CRUSH_PARITY_RESTORATION_REPORT_2026-03-10.md
test/config/app_config_env_resolution_test.dart
EOF
      ;;
    "CRUSH_API_BASE_URL")
      cat <<'EOF'
lib/config/app_config.dart
lib/data/repositories/fake_repositories.dart
docs/ENV_KEY_MATRIX.md
docs/RELEASE_GUIDE.md
docs/risk_notes.md
docs/reports/CRUSH_PARITY_RESTORATION_REPORT_2026-03-10.md
test/fake_repositories_env_parity_test.dart
EOF
      ;;
    "USE_EMULATORS")
      cat <<'EOF'
lib/config/app_config.dart
lib/core/firebase_emulator.dart
.env.example
docs/ENV_KEY_MATRIX.md
docs/RELEASE_GUIDE.md
docs/risk_notes.md
docs/reports/CRUSH_PARITY_RESTORATION_REPORT_2026-03-10.md
EOF
      ;;
    "EMULATOR_HOST")
      cat <<'EOF'
lib/config/app_config.dart
lib/core/firebase_emulator.dart
.env.example
docs/ENV_KEY_MATRIX.md
docs/RELEASE_GUIDE.md
docs/risk_notes.md
docs/reports/CRUSH_PARITY_RESTORATION_REPORT_2026-03-10.md
test/core/firebase_emulator_env_parity_test.dart
EOF
      ;;
  esac
}

is_allowed() {
  local alias="$1"
  local file="$2"
  local allowed_file
  while IFS= read -r allowed_file; do
    [ -z "${allowed_file}" ] && continue
    if [ "${file}" = "${allowed_file}" ]; then
      return 0
    fi
  done <<EOF
$(allowed_files_for_alias "$alias")
EOF
  return 1
}

ALIASES=(
  "APP_ENV"
  "CRUSH_API_BASE_URL"
  "USE_EMULATORS"
  "EMULATOR_HOST"
)

violations=()

for alias in "${ALIASES[@]}"; do
  while IFS= read -r match; do
    [ -z "${match}" ] && continue
    file="${match%%:*}"
    if ! is_allowed "${alias}" "${file}"; then
      violations+=("${alias}:${match}")
    fi
  done < <(
    rg -n "\\b${alias}\\b" \
      --glob '!docs/ai_workboard.md' \
      --glob '!docs/Developer_agent_chat.md' \
      --glob '!docs/reports/lighthouse/**' \
      --glob '!scripts/check_deprecated_env_aliases.sh' \
      --glob '!scripts/check_env_alias_migration_status.sh' \
      --glob '!scripts/generate_env_alias_migration_audit_report.sh' \
      --glob '!build/**' \
      --glob '!.dart_tool/**' \
      --glob '!functions/lib/**' \
      || true
  )
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Deprecated env alias references found outside allowlist:"
  printf '  %s\n' "${violations[@]}"
  echo ""
  echo "Allowed compatibility files are defined in scripts/check_deprecated_env_aliases.sh."
  exit 1
fi

echo "Deprecated env alias guard passed."
