#!/usr/bin/env bash
set -euo pipefail

APP_PATH="/Applications/WorkGuard.app"
LAUNCHER_PATH="${APP_PATH}/Contents/MacOS/WorkGuard"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"

if [ ! -d "$APP_PATH" ]; then
    echo "FAIL: $APP_PATH not found." >&2
    exit 1
fi

if [ ! -x "$LAUNCHER_PATH" ]; then
    echo "FAIL: launcher not executable at $LAUNCHER_PATH" >&2
    exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
if [ "$BUNDLE_ID" != "com.agaibadulin.workguard" ]; then
    echo "FAIL: bundle id '$BUNDLE_ID' does not match com.agaibadulin.workguard" >&2
    exit 1
fi

codesign --verify --deep --strict "$APP_PATH"
echo "OK: disk-state verification passed."
