#!/bin/zsh
set -e

BINARY_NAME="startwatch"
INSTALL_DIR="/usr/local/bin"
CLI_WRAPPER_PATH="$INSTALL_DIR/$BINARY_NAME"
CONFIG_DIR="$HOME/.config/startwatch"
STATE_DIR="$HOME/.local/state/startwatch"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.startwatch.plist"
PLIST_LABEL="com.user.startwatch"
SYSTEM_MENU_APP="/Applications/StartWatchMenu.app"
USER_MENU_APP="$HOME/Applications/StartWatchMenu.app"
MENU_APP=""
MENU_BIN=""

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓${RESET} $1"; }
warn() { echo "${YELLOW}⚠${RESET} $1"; }
fail() { echo "${RED}✗${RESET} $1"; exit 1; }

choose_menu_app_path() {
    if [[ -d "$SYSTEM_MENU_APP" || -w "/Applications" ]]; then
        MENU_APP="$SYSTEM_MENU_APP"
    else
        MENU_APP="$USER_MENU_APP"
    fi
    MENU_BIN="$MENU_APP/Contents/MacOS/startwatch"
}

echo ""
echo "StartWatch Installer"
echo "════════════════════"
echo ""

choose_menu_app_path
ok "App install target: $MENU_APP"

# 1. Build
echo "Building release binary..."
swift build -c release > /tmp/startwatch-build.log 2>&1 || { cat /tmp/startwatch-build.log; fail "Build failed"; }
ok "Build complete"

# 2. Build StartWatchMenu.app bundle (single source of truth binary)
BINARY_PATH=".build/release/StartWatch"
if [[ ! -f "$BINARY_PATH" ]]; then
    fail "Binary not found at $BINARY_PATH"
fi

if [[ "$MENU_APP" == "$SYSTEM_MENU_APP" ]]; then
    if [[ -w "/Applications" || -d "$MENU_APP" ]]; then
        mkdir -p "$MENU_APP/Contents/MacOS" 2>/dev/null || sudo mkdir -p "$MENU_APP/Contents/MacOS"
    else
        sudo mkdir -p "$MENU_APP/Contents/MacOS"
    fi
else
    mkdir -p "$MENU_APP/Contents/MacOS"
fi

if [[ -w "$MENU_APP/Contents/MacOS" ]]; then
    cp "$BINARY_PATH" "$MENU_BIN"
else
    sudo cp "$BINARY_PATH" "$MENU_BIN"
fi
if [[ -w "$MENU_APP/Contents" || ! -e "$MENU_APP/Contents/Info.plist" ]]; then
    cp "Resources/StartWatchMenu-Info.plist" "$MENU_APP/Contents/Info.plist"
else
    sudo cp "Resources/StartWatchMenu-Info.plist" "$MENU_APP/Contents/Info.plist"
fi

ok "StartWatchMenu.app installed at $MENU_APP"

# 2.1 Sign and verify menu app bundle (required for UI agent on newer macOS)
if codesign --force --deep --sign - "$MENU_APP" >/dev/null 2>&1; then
    ok "StartWatchMenu.app signed (ad-hoc)"
else
    warn "Failed to sign StartWatchMenu.app (menu icon may not appear)"
fi

if codesign -vvv "$MENU_APP" >/dev/null 2>&1; then
    ok "StartWatchMenu.app signature verified"
else
    warn "StartWatchMenu.app signature verification failed"
fi

# 2.2 Install CLI wrapper (avoids direct execution policy blocks on /usr/local/bin Mach-O)
WRAPPER_CONTENT="#!/bin/zsh
exec \"$MENU_BIN\" \"\$@\"
"
if [[ -w "$INSTALL_DIR" ]]; then
    printf "%s" "$WRAPPER_CONTENT" > "$CLI_WRAPPER_PATH"
    chmod +x "$CLI_WRAPPER_PATH"
else
    printf "%s" "$WRAPPER_CONTENT" | sudo tee "$CLI_WRAPPER_PATH" >/dev/null
    sudo chmod +x "$CLI_WRAPPER_PATH"
fi
ok "CLI wrapper installed to $CLI_WRAPPER_PATH"

# 3. Create directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$STATE_DIR"
ok "Directories created"

# 4. Create example config if not exists
if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
    cp config.example.json "$CONFIG_DIR/config.json"
    ok "Example config created at $CONFIG_DIR/config.json"
    warn "Edit $CONFIG_DIR/config.json with your services"
else
    warn "Config already exists, skipping"
fi

# 5. Install LaunchAgent
mkdir -p "$LAUNCH_AGENTS_DIR"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Install plist template as-is (already points to bundle daemon --no-menu)
cp "$PLIST_NAME" "$PLIST_DEST"
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $MENU_BIN" "$PLIST_DEST" >/dev/null 2>&1 || true

ok "LaunchAgent installed at $PLIST_DEST"

# 6. Bootstrap LaunchAgent
BOOT_STATUS=$(launchctl print "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null; echo $?)
if echo "$BOOT_STATUS" | grep -q "Could not find service"; then
    launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null && \
        ok "LaunchAgent bootstrapped" || warn "LaunchAgent bootstrap failed (may need logout/login)"
else
    launchctl bootout "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST" 2>/dev/null && \
        ok "LaunchAgent reloaded" || warn "LaunchAgent reload failed"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit config:   startwatch config"
echo "  2. Start daemon:  startwatch daemon &"
echo "  3. Check status:  startwatch doctor"
echo "  4. If menu icon is stale: startwatch doctor --repair-ui"
echo ""
