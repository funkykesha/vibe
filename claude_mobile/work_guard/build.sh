#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/WorkGuard.app"
BINARY="$DIR/WorkGuard_bin"

echo "Остановка старого инстанса..."
"$DIR/stop_workguard.sh" 2>/dev/null || true

echo "Компиляция Swift..."
swiftc "$DIR/Sources/"*.swift \
  -framework Cocoa \
  -framework UserNotifications \
  -o "$BINARY" 2>&1 || {
    echo "Ошибка компиляции"
    exit 1
}

echo "Компиляция WorkGuardMenu (standalone menu agent)..."
swiftc "$DIR/Sources/WorkGuardMenu/main.swift" \
  -framework Cocoa \
  -o "$DIR/WorkGuardMenu_bin" 2>&1 || {
    echo "Ошибка компиляции WorkGuardMenu"
    exit 1
}

echo "Сборка WorkGuard.app..."
mkdir -p "$APP/Contents/MacOS"
cp "$BINARY" "$APP/Contents/MacOS/WorkGuard"
cp "$DIR/WorkGuardMenu_bin" "$APP/Contents/MacOS/WorkGuardMenu"
cp "$DIR/Resources/Info.plist" "$APP/Contents/Info.plist"
rm -f "$BINARY" "$DIR/WorkGuardMenu_bin"
chmod +x "$APP/Contents/MacOS/WorkGuard"
chmod +x "$APP/Contents/MacOS/WorkGuardMenu"

echo "Подпись бинарников (ad-hoc)..."
codesign --force --sign - "$APP/Contents/MacOS/WorkGuardMenu" 2>&1 || true
codesign --force --deep --sign - "$APP" 2>&1 || true

echo "✅ Готово: $APP"
echo ""
echo "Запуск:"
echo "  open $APP"
echo ""
echo "Логи:"
echo "  tail -f ~/.config/work_guard/work_guard.log"
