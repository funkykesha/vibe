#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

set +e
SETUP_OUTPUT="$(bash "$ROOT_DIR/setup.sh" 2>&1)"
SETUP_STATUS=$?
set -e

if [ "$SETUP_STATUS" -eq 0 ]; then
    echo "FAIL: setup.sh exited 0; expected non-zero." >&2
    exit 1
fi

if echo "$SETUP_OUTPUT" | grep -q "bash rebuild.sh"; then
    echo "OK: setup.sh points to bash rebuild.sh."
else
    echo "FAIL: setup.sh output missing 'bash rebuild.sh'." >&2
    echo "$SETUP_OUTPUT" >&2
    exit 1
fi
