#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="$HOME/.config/work_guard/work_guard.lock"
LOG_FILE="$HOME/.config/work_guard/work_guard.log"
FRESH_WINDOW_SEC=300

if [ ! -f "$LOCK_FILE" ]; then
    echo "FAIL: lock file not found at $LOCK_FILE" >&2
    exit 1
fi

LOCK_PID="$(tr -d ' \n' <"$LOCK_FILE")"
if [ -z "$LOCK_PID" ]; then
    echo "FAIL: lock file is empty." >&2
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "FAIL: log file not found at $LOG_FILE" >&2
    exit 1
fi

NOW_TS="$(date +%s)"
LOG_TS="$(stat -f %m "$LOG_FILE")"
LOG_AGE=$((NOW_TS - LOG_TS))
if [ "$LOG_AGE" -gt "$FRESH_WINDOW_SEC" ]; then
    echo "FAIL: log file not updated within ${FRESH_WINDOW_SEC}s." >&2
    exit 1
fi

echo "OK: lock pid=${LOCK_PID}, log updated ${LOG_AGE}s ago."
