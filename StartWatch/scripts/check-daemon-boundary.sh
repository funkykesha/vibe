#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_PATHS=(
  "$ROOT_DIR/Sources/StartWatch/Daemon/AppDelegate.swift"
  "$ROOT_DIR/Sources/StartWatch/Daemon/CheckScheduler.swift"
  "$ROOT_DIR/Sources/StartWatch/Core"
)

FORBIDDEN_PATTERNS=(
  "import AppKit"
  "NSApplication"
  "NSStatusItem"
  "NSMenu"
  "NSWorkspace"
  "TerminalLauncher"
)

failed=0

for target in "${TARGET_PATHS[@]}"; do
  if [[ ! -e "$target" ]]; then
    continue
  fi

  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if rg -n -F "$pattern" "$target" >/dev/null; then
      echo "Boundary violation: '$pattern' found in $target"
      rg -n -F "$pattern" "$target"
      failed=1
    fi
  done
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Daemon/Core boundary check passed"
