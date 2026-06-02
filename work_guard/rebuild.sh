#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
WORK_GUARD_SCRIPT="$PROJECT_ROOT/work_guard.py"

if [ ! -f "$WORK_GUARD_SCRIPT" ]; then
    echo "work_guard.py not found at $WORK_GUARD_SCRIPT" >&2
    exit 1
fi

STOP_SCRIPT="$PROJECT_ROOT/scripts/stop_workguard.sh"
if [ ! -f "$STOP_SCRIPT" ]; then
    echo "stop_workguard.sh not found at $STOP_SCRIPT" >&2
    exit 1
fi

echo "Stopping WorkGuard before rebuild..."
if ! bash "$STOP_SCRIPT"; then
    echo "stop_workguard.sh failed; aborting rebuild." >&2
    exit 1
fi

# Belt-and-suspenders: kill any straggler WorkGuard/work_guard.py processes
pkill -f "WorkGuard\\.app/Contents/MacOS/WorkGuard" 2>/dev/null || true
pkill -f "work_guard\\.py" 2>/dev/null || true
sleep 1
if pgrep -f "work_guard\\.py" >/dev/null 2>&1; then
    echo "WorkGuard still alive; force-killing..." >&2
    pkill -9 -f "WorkGuard\\.app/Contents/MacOS/WorkGuard" 2>/dev/null || true
    pkill -9 -f "work_guard\\.py" 2>/dev/null || true
    sleep 1
fi

CONDA_DISCOVERY="$PROJECT_ROOT/scripts/lib/conda_discovery.sh"
if [ ! -f "$CONDA_DISCOVERY" ]; then
    echo "conda_discovery.sh not found at $CONDA_DISCOVERY" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$CONDA_DISCOVERY"
CONDA_BIN="$(workguard_require_conda)"
echo "Resolved conda: $CONDA_BIN"

CONDA_ENV="workguard"
CONDA_BASE="$(dirname "$(dirname "$CONDA_BIN")")"
# shellcheck disable=SC1091
source "$CONDA_BASE/etc/profile.d/conda.sh"

if conda run -n "$CONDA_ENV" true >/dev/null 2>&1; then
    echo "Conda env '$CONDA_ENV' already exists."
else
    echo "Creating conda env '$CONDA_ENV' (Python 3.11)..."
    conda create -n "$CONDA_ENV" python=3.11 -y --quiet
    echo "Conda env created."
fi

PYTHON_BIN="$(conda run -n "$CONDA_ENV" which python3)"
echo "Resolved Python: $PYTHON_BIN"

REQUIREMENTS_FILE="$PROJECT_ROOT/requirements.txt"
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "requirements.txt not found at $REQUIREMENTS_FILE" >&2
    exit 1
fi

echo "Installing Python dependencies..."
conda run -n "$CONDA_ENV" pip install --quiet -r "$REQUIREMENTS_FILE"
echo "Dependencies installed."

SWIFT_MENU_SRC="$PROJECT_ROOT/WorkGuardMenu/main.swift"
SWIFT_MENU_BIN="$PROJECT_ROOT/WorkGuardMenu/workguard-menu"

if command -v swiftc >/dev/null 2>&1 && [ -f "$SWIFT_MENU_SRC" ]; then
    echo "Building Swift menu binary..."
    swiftc "$SWIFT_MENU_SRC" -framework Cocoa -o "$SWIFT_MENU_BIN"
    chmod +x "$SWIFT_MENU_BIN"
    echo "Swift menu binary built: $SWIFT_MENU_BIN"
else
    if [ ! -f "$SWIFT_MENU_SRC" ]; then
        echo "Warning: missing Swift menu source at $SWIFT_MENU_SRC"
    else
        echo "Warning: swiftc not found; install Xcode Command Line Tools"
    fi
    echo "Swift menu build skipped; Python fallback remains available."
fi

APP_TEMPLATE_DIR="$PROJECT_ROOT/packaging/WorkGuard.app"
APP_TEMPLATE_LAUNCHER_IN="$APP_TEMPLATE_DIR/Contents/MacOS/WorkGuard.in"
APP_LAUNCHER_OUT="$APP_TEMPLATE_DIR/Contents/MacOS/WorkGuard"

if [ ! -f "$APP_TEMPLATE_LAUNCHER_IN" ]; then
    echo "Launcher template not found at $APP_TEMPLATE_LAUNCHER_IN" >&2
    exit 1
fi

mkdir -p "$(dirname "$APP_LAUNCHER_OUT")"
PYTHON_ESC="${PYTHON_BIN//\\/\\\\}"
SCRIPT_ESC="${WORK_GUARD_SCRIPT//\\/\\\\}"
sed \
    -e "s|PYTHON_PATH_PLACEHOLDER|$PYTHON_ESC|g" \
    -e "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_ESC|g" \
    "$APP_TEMPLATE_LAUNCHER_IN" > "$APP_LAUNCHER_OUT"
chmod +x "$APP_LAUNCHER_OUT"
echo "Generated app launcher: $APP_LAUNCHER_OUT"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
if [ -d "/Applications/WorkGuard.app" ]; then
    echo "Unregistering existing /Applications/WorkGuard.app..."
    "$LSREGISTER" -u "/Applications/WorkGuard.app"
fi

APP_INSTALL_TARGET="/Applications/WorkGuard.app"
if [ ! -w "/Applications" ]; then
    echo "Cannot write to /Applications; aborting rebuild." >&2
    exit 1
fi

echo "Replacing $APP_INSTALL_TARGET from packaging output..."
rm -rf "$APP_INSTALL_TARGET"
cp -rf "$APP_TEMPLATE_DIR" "$APP_INSTALL_TARGET"
echo "Signing $APP_INSTALL_TARGET (ad-hoc)..."
codesign --force --deep --sign - "$APP_INSTALL_TARGET"
echo "Refreshing LaunchServices..."
# macOS (e.g. Tahoe 26+): `lsregister -kill` was removed as dangerous; rely on
# unregister-before-replace above plus force-register of the new bundle.
"$LSREGISTER" -f "$APP_INSTALL_TARGET"

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.agaibadulin.workguard.plist"
LAUNCH_AGENT_PROGRAM="/usr/bin/open"
LAUNCH_AGENT_APP="/Applications/WorkGuard.app"
mkdir -p "$LAUNCH_AGENT_DIR"
cat > "$LAUNCH_AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.agaibadulin.workguard</string>
    <key>ProgramArguments</key>
    <array>
        <string>$LAUNCH_AGENT_PROGRAM</string>
        <string>$LAUNCH_AGENT_APP</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

LAUNCHCTL_DOMAIN="gui/$(id -u)"
launchctl bootout "$LAUNCHCTL_DOMAIN" "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
launchctl bootstrap "$LAUNCHCTL_DOMAIN" "$LAUNCH_AGENT_PLIST"
launchctl enable "$LAUNCHCTL_DOMAIN/com.agaibadulin.workguard" 2>/dev/null || true
echo "Launching $APP_INSTALL_TARGET via LaunchAgent RunAtLoad..."
echo "GUI target: $APP_INSTALL_TARGET"

echo "Rebuild complete."
exit 0
