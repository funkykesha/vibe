#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Narrow: outbound / bulk-pipeline wording — not benign logs like "diagnostics skipped".
PATTERN='telemetry|diagnostics[[:space:]]+upload|import[[:space:]]+requests|urllib\.request|http\.client|socket\.(create_connection|connect)\(|ActivitySignals.*(collector|ingestion|ingest|export[[:space:]]+(pipeline|to\b))'
TARGETS=(
    "$ROOT_DIR/rebuild.sh"
    "$ROOT_DIR/scripts"
    "$ROOT_DIR/work_guard.py"
    "$ROOT_DIR/monitor.py"
    "$ROOT_DIR/notifier.py"
    "$ROOT_DIR/overlay.py"
    "$ROOT_DIR/settings_dialog.py"
)

if rg -n -i "$PATTERN" "${TARGETS[@]}"; then
    echo "FAIL: outbound/telemetry-style patterns matched in install/runtime paths." >&2
    exit 1
fi

echo "OK: no outbound telemetry patterns matched in install/runtime paths."
