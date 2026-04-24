#!/bin/bash

LOCK="$HOME/.config/work_guard/work_guard.lock"

if [ -f "$LOCK" ]; then
    PID=$(cat "$LOCK" 2>/dev/null || true)
    if [ -n "$PID" ]; then
        if kill -0 "$PID" 2>/dev/null; then
            kill -TERM "$PID" 2>/dev/null && echo "Отправлен SIGTERM процессу $PID"
            sleep 1
            if kill -0 "$PID" 2>/dev/null; then
                kill -9 "$PID" 2>/dev/null && echo "Отправлен SIGKILL процессу $PID"
            fi
        fi
    fi
fi

pkill -f "WorkGuard.app/Contents/MacOS/WorkGuard" 2>/dev/null || true

rm -f "$LOCK"

echo "✅ WorkGuard остановлен"
