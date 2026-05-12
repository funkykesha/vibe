#!/usr/bin/env bash
set -euo pipefail

PLIST_PATH="$HOME/Library/LaunchAgents/com.agaibadulin.workguard.plist"
if [ ! -f "$PLIST_PATH" ]; then
    echo "FAIL: LaunchAgent plist not found at $PLIST_PATH" >&2
    exit 1
fi

LABEL="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$PLIST_PATH")"
if [ "$LABEL" != "com.agaibadulin.workguard" ]; then
    echo "FAIL: Label '$LABEL' is not com.agaibadulin.workguard" >&2
    exit 1
fi

ARG0="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$PLIST_PATH")"
ARG1="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:1' "$PLIST_PATH")"
if [ "$ARG0" != "/usr/bin/open" ] || [ "$ARG1" != "/Applications/WorkGuard.app" ]; then
    echo "FAIL: ProgramArguments are not /usr/bin/open + /Applications/WorkGuard.app" >&2
    exit 1
fi

RUN_AT_LOAD="$(/usr/libexec/PlistBuddy -c 'Print :RunAtLoad' "$PLIST_PATH")"
KEEP_ALIVE="$(/usr/libexec/PlistBuddy -c 'Print :KeepAlive' "$PLIST_PATH")"
if [ "$RUN_AT_LOAD" != "true" ]; then
    echo "FAIL: RunAtLoad is not true" >&2
    exit 1
fi
if [ "$KEEP_ALIVE" != "false" ]; then
    echo "FAIL: KeepAlive is not false" >&2
    exit 1
fi

launchctl print "gui/$(id -u)/com.agaibadulin.workguard" >/dev/null
echo "OK: LaunchAgent verification passed."
