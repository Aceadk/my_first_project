#!/usr/bin/env bash

set -euo pipefail

REQUIRED_DOCS=(
  "docs/ai_workboard.md"
  "docs/Developer_agent_chat.md"
)

DEPRECATED_DOCS=(
  "docs/ai_change_log.md"
  "docs/ai_tasks_board.md"
  "docs/ai_collab_chat.md"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/check_ai_docs_sync.sh [--range <git-diff-range>]
  scripts/check_ai_docs_sync.sh --files <file1> [file2 ...]

Rules enforced:
1) Any non-empty change set must include:
   - docs/ai_workboard.md
   - docs/Developer_agent_chat.md
2) Deprecated docs are removed and must not be reintroduced:
   - docs/ai_change_log.md
   - docs/ai_tasks_board.md
   - docs/ai_collab_chat.md
EOF
}

RANGE=""
USE_FILES=false
declare -a INPUT_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --range)
      RANGE="${2:-}"
      if [[ -z "${RANGE}" ]]; then
        echo "Error: --range requires a value."
        exit 2
      fi
      shift 2
      ;;
    --files)
      USE_FILES=true
      shift
      while [[ $# -gt 0 ]]; do
        INPUT_FILES+=("$1")
        shift
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'"
      usage
      exit 2
      ;;
  esac
done

declare -a CHANGED_FILES=()

if [[ "${USE_FILES}" == "true" ]]; then
  CHANGED_FILES=("${INPUT_FILES[@]}")
elif [[ -n "${RANGE}" ]]; then
  while IFS= read -r file; do
    [[ -z "${file}" ]] && continue
    CHANGED_FILES+=("${file}")
  done < <(git diff --name-only "${RANGE}")
else
  while IFS= read -r file; do
    [[ -z "${file}" ]] && continue
    CHANGED_FILES+=("${file}")
  done < <(git diff --name-only HEAD)
fi

# Include untracked files so local pre-commit checks work before `git add`.
while IFS= read -r file; do
  [[ -z "${file}" ]] && continue
  CHANGED_FILES+=("${file}")
done < <(git ls-files --others --exclude-standard)

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
  echo "Docs sync check: no changed files detected."
  exit 0
fi

contains_file() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

declare -a REINTRODUCED_DEPRECATED=()
for doc in "${DEPRECATED_DOCS[@]}"; do
  if contains_file "${doc}" "${CHANGED_FILES[@]}"; then
    # Deleting these files is allowed (one-time migration or cleanup).
    # Any add/modify that leaves the file present is blocked.
    if [[ -e "${doc}" ]]; then
      REINTRODUCED_DEPRECATED+=("${doc}")
    fi
  fi
done

if [[ ${#REINTRODUCED_DEPRECATED[@]} -gt 0 ]]; then
  echo "Docs sync check failed: deprecated docs were reintroduced/modified."
  for file in "${REINTRODUCED_DEPRECATED[@]}"; do
    echo "  - ${file}"
  done
  echo "Use docs/ai_workboard.md as the single source of truth."
  exit 1
fi

declare -a MISSING_REQUIRED=()
for required in "${REQUIRED_DOCS[@]}"; do
  if ! contains_file "${required}" "${CHANGED_FILES[@]}"; then
    MISSING_REQUIRED+=("${required}")
  fi
done

if [[ ${#MISSING_REQUIRED[@]} -gt 0 ]]; then
  echo "Docs sync check failed: required workflow docs are missing from this change set."
  for missing in "${MISSING_REQUIRED[@]}"; do
    echo "  - ${missing}"
  done
  echo "Every task update must include both docs/ai_workboard.md and docs/Developer_agent_chat.md."
  exit 1
fi

echo "Docs sync check passed."
