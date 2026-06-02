#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="$HOME/.config/work_guard/work_guard.lock"
APP_PATH="/Applications/WorkGuard.app"

if [ ! -f "$LOCK_FILE" ]; then
    echo "FAIL: lock file not found at $LOCK_FILE" >&2
    exit 1
fi

ORIGINAL_PID="$(tr -d ' \n' <"$LOCK_FILE")"
if [ -z "$ORIGINAL_PID" ]; then
    echo "FAIL: lock file is empty." >&2
    exit 1
fi

/usr/bin/open "$APP_PATH"
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

echo "OK: lock pid unchanged and single work_guard.py process."
