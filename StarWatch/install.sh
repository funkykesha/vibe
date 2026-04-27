#!/bin/zsh
set -e

BINARY_NAME="startwatch"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/startwatch"
STATE_DIR="$HOME/.local/state/startwatch"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.startwatch.plist"
PLIST_LABEL="com.user.startwatch"

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
RESET=$'\033[0m'

ok()   { echo "${GREEN}✓${RESET} $1"; }
warn() { echo "${YELLOW}⚠${RESET} $1"; }
fail() { echo "${RED}✗${RESET} $1"; exit 1; }

echo ""
echo "StartWatch Installer"
echo "════════════════════"
echo ""

# 1. Build
echo "Building release binary..."
swift build -c release > /tmp/startwatch-build.log 2>&1 || { cat /tmp/startwatch-build.log; fail "Build failed"; }
ok "Build complete"

# 2. Install binary
BINARY_PATH=".build/release/StartWatch"
if [[ ! -f "$BINARY_PATH" ]]; then
    fail "Binary not found at $BINARY_PATH"
fi

if [[ -w "$INSTALL_DIR" ]]; then
    cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
else
    sudo cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
fi
ok "Binary installed to $INSTALL_DIR/$BINARY_NAME"

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

# Update plist with actual binary path
sed "s|/usr/local/bin/startwatch|$INSTALL_DIR/$BINARY_NAME|g" \
    "$PLIST_NAME" > "$PLIST_DEST"

# Update log paths to use home directory
sed -i '' "s|/Users/Shared/startwatch|$HOME/.local/state/startwatch/daemon|g" "$PLIST_DEST"

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

# 7. Start daemon immediately
launchctl kickstart -k "gui/$(id -u)/$PLIST_LABEL" 2>/dev/null || true
sleep 2
if pgrep -f "startwatch daemon" > /dev/null 2>&1; then
    ok "Daemon started"
else
    warn "Daemon will start on next login (or run: startwatch daemon &)"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit config:   startwatch config"
echo "  2. Check status:  startwatch doctor"
echo "  3. View services: startwatch status"
echo ""
