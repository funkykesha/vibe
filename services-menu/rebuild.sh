#!/bin/bash
set -e

PYTHON="/opt/homebrew/Caskroom/miniforge/base/bin/python3"
PROJECT_DIR="/Users/agaibadulin/Desktop/projects/vibe/services-menu"
APP_NAME="ServicesMenu"
APP_DEST="/Applications/${APP_NAME}.app"
BUNDLE_ID_BASE="com.agaibadulin.services-menu"
LAUNCH_AGENT_LABEL="com.agaibadulin.services-menu"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

echo "▶ Останавливаем старый процесс..."
pkill -f "${APP_NAME}" 2>/dev/null || true
sleep 1

echo "▶ Удаляем старый .app из LaunchServices кэша..."
if [ -d "$APP_DEST" ]; then
    "$LSREGISTER" -u "$APP_DEST" 2>/dev/null || true
fi

echo "▶ Удаляем старый .app..."
rm -rf "$APP_DEST"

echo "▶ Чистим LaunchServices кэш полностью..."
"$LSREGISTER" -kill -r -domain local -domain system -domain user 2>/dev/null || true
sleep 2

echo "▶ Сборка .app..."
cd "$PROJECT_DIR"
rm -rf build dist
"$PYTHON" setup.py py2app 2>&1 | tail -5

echo "▶ Копируем в /Applications/..."
cp -R "dist/${APP_NAME}.app" "$APP_DEST"

echo "▶ Обновляем Bundle ID (сброс кэша LaunchServices)..."
NEW_ID="${BUNDLE_ID_BASE}.$(date +%s)"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $NEW_ID" \
    "$APP_DEST/Contents/Info.plist"

echo "▶ Подписываем..."
codesign --force --deep --sign - "$APP_DEST"

echo "▶ Регистрируем в LaunchServices..."
"$LSREGISTER" -f "$APP_DEST"
sleep 1

echo "▶ Обновляем LaunchAgent автозапуска..."
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCH_AGENT_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LAUNCH_AGENT_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>open</string>
    <string>${APP_DEST}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>${HOME}/Library/Logs/services-menu.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/Library/Logs/services-menu-error.log</string>
</dict>
</plist>
PLIST
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PATH" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PATH"

echo "▶ Перезапускаем SystemUIServer..."
killall SystemUIServer 2>/dev/null || true
sleep 2

echo "▶ Запускаем..."
open "$APP_DEST"

echo "✅ Готово! Ищи ⚙️ в menu bar."
