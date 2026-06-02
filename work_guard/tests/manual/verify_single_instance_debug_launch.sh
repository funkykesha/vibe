#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK_FILE="$HOME/.config/work_guard/work_guard.lock"

if [ ! -f "$LOCK_FILE" ]; then
    echo "FAIL: lock file not found at $LOCK_FILE" >&2
    exit 1
fi

ORIGINAL_PID="$(tr -d ' \n' <"$LOCK_FILE")"
if [ -z "$ORIGINAL_PID" ]; then
    echo "FAIL: lock file is empty." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ROOT_DIR/scripts/lib/conda_discovery.sh"
CONDA_BIN="$(workguard_require_conda)"
CONDA_BASE="$(dirname "$(dirname "$CONDA_BIN")")"
# shellcheck disable=SC1091
source "$CONDA_BASE/etc/profile.d/conda.sh"

conda run -n workguard python3 "$ROOT_DIR/work_guard.py" >/tmp/workguard_debug_launch.log 2>&1 &
DEBUG_PID=$!
sleep 2

NEW_PID="$(tr -d ' \n' <"$LOCK_FILE")"
if [ "$NEW_PID" != "$ORIGINAL_PID" ]; then
    echo "FAIL: lock pid changed from $ORIGINAL_PID to $NEW_PID" >&2
    exit 1
fi

PROC_COUNT="$(pgrep -f '[/]work_guard\.py' | wc -l | tr -d ' ')"
if [ "$PROC_COUNT" -ne 1 ]; then
    echo "FAIL: expected 1 work_guard.py process, found $PROC_COUNT" >&2
    exit 1
fi

SWIFT_COUNT="$(pgrep -f '[/]WorkGuardMenu[/]workguard-menu' | wc -l | tr -d ' ')"
if [ "$SWIFT_COUNT" -gt 1 ]; then
    echo "FAIL: expected at most 1 workguard-menu process, found $SWIFT_COUNT" >&2
    exit 1
fi

if kill -0 "$DEBUG_PID" 2>/dev/null; then
    kill "$DEBUG_PID" 2>/dev/null || true
fi

echo "OK: lock pid unchanged and single work_guard.py process."
