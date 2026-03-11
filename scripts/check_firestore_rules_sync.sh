#!/usr/bin/env bash
set -euo pipefail

ROOT_RULES="firestore.rules"
FUNCTIONS_RULES="functions/firestore.rules"

if [[ ! -f "$ROOT_RULES" ]]; then
  echo "Missing $ROOT_RULES"
  exit 1
fi

if [[ ! -f "$FUNCTIONS_RULES" ]]; then
  echo "Missing $FUNCTIONS_RULES"
  exit 1
fi

if ! cmp -s "$ROOT_RULES" "$FUNCTIONS_RULES"; then
  echo "Firestore rules drift detected between:"
  echo "  - $ROOT_RULES"
  echo "  - $FUNCTIONS_RULES"
  echo
  diff -u "$ROOT_RULES" "$FUNCTIONS_RULES" || true
  exit 1
fi

echo "Firestore rules are in sync."
