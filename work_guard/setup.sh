#!/usr/bin/env bash
# WorkGuard - установка зависимостей и сборка WorkGuard.app (двойной клик для запуска).
# Запуск: bash /path/to/work_guard/setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/work_guard.py"
LOG_DIR="$HOME/.config/work_guard"
CONDA_ENV="workguard"
APP_TEMPLATE_LAUNCHER_IN="$SCRIPT_DIR/WorkGuard.app/Contents/MacOS/WorkGuard.in"
APP_LAUNCHER_OUT="$SCRIPT_DIR/WorkGuard.app/Contents/MacOS/WorkGuard"

echo ""
echo "╔══════════════════════════════════╗"
echo "║    WorkGuard Setup               ║"
echo "╚══════════════════════════════════╝"
echo ""

# 1. Find conda (miniforge / anaconda / miniconda)
CONDA_BIN=""
for candidate in \
    "$HOME/miniforge3/bin/conda" \
    "$HOME/mambaforge/bin/conda" \
    "$HOME/miniconda3/bin/conda" \
    "$HOME/anaconda3/bin/conda" \
    "/opt/homebrew/Caskroom/miniforge/base/bin/conda" \
    "/opt/miniforge3/bin/conda"; do
    if [ -x "$candidate" ]; then
        CONDA_BIN="$candidate"
        break
    fi
done

if [ -z "$CONDA_BIN" ]; then
    echo "❌  conda не найдена. Homebrew Python (3.13/3.14) сломан на этом macOS."
    echo ""
    echo "Установи miniforge:"
    echo "  brew install miniforge"
    echo ""
    echo "Затем перезапусти setup.sh"
    exit 1
fi

CONDA_BASE="$(dirname "$(dirname "$CONDA_BIN")")"
echo "✓  conda: $CONDA_BIN"

# 2. Create or reuse conda env with Python 3.11
# shellcheck disable=SC1091
source "$CONDA_BASE/etc/profile.d/conda.sh"

if conda env list | grep -q "^$CONDA_ENV "; then
    echo "✓  conda env '$CONDA_ENV' уже существует"
else
    echo "→  Создаём conda env '$CONDA_ENV' (Python 3.11)..."
    conda create -n "$CONDA_ENV" python=3.11 -y --quiet
    echo "✓  conda env создан"
fi

conda activate "$CONDA_ENV"
PYTHON="$(conda run -n "$CONDA_ENV" which python3)"
echo "✓  Python: $PYTHON ($(conda run -n "$CONDA_ENV" python3 --version))"

# rumps ищет Info.plist рядом с sys.executable (см. site-packages/rumps/notifications.py).
# Лаунчер делает exec python3 — без этого ломаются уведомления и привязка к bundle id.
PYTHON_BIN_DIR="$(dirname "$PYTHON")"
INFO_PLIST_PY="$PYTHON_BIN_DIR/Info.plist"
cat > "$INFO_PLIST_PY" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.workguard.app</string>
    <key>CFBundleName</key>
    <string>WorkGuard</string>
</dict>
</plist>
EOF
echo "✓  Info.plist для интерпретатора conda (rumps / уведомления): $INFO_PLIST_PY"

# 3. Install dependencies
echo ""
echo "→  Installing Python dependencies..."
conda run -n "$CONDA_ENV" pip install --quiet -r "$SCRIPT_DIR/requirements.txt"
echo "✓  Dependencies installed"

# 4. Log directory
mkdir -p "$LOG_DIR"

# 5. Сборка launcher в WorkGuard.app (абсолютные пути к python и скрипту)
echo ""
echo "→  Собираем WorkGuard.app..."
if [ ! -f "$APP_TEMPLATE_LAUNCHER_IN" ]; then
    echo "❌  Не найден шаблон: $APP_TEMPLATE_LAUNCHER_IN"
    exit 1
fi
mkdir -p "$(dirname "$APP_LAUNCHER_OUT")"
# Экранируем слэши для sed
PYTHON_ESC="${PYTHON//\\/\\\\}"
SCRIPT_ESC="${SCRIPT//\\/\\\\}"
sed \
    -e "s|PYTHON_PATH_PLACEHOLDER|$PYTHON_ESC|g" \
    -e "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_ESC|g" \
    "$APP_TEMPLATE_LAUNCHER_IN" > "$APP_LAUNCHER_OUT"
chmod +x "$APP_LAUNCHER_OUT"
echo "✓  Launcher: $APP_LAUNCHER_OUT"

# 5b. Нативный агент строки меню (Swift) — обход PyObjC на macOS 26 beta
SWIFT_MENU_SRC="$SCRIPT_DIR/WorkGuardMenu/main.swift"
SWIFT_MENU_BIN="$SCRIPT_DIR/WorkGuardMenu/workguard-menu"
if command -v swiftc >/dev/null 2>&1 && [ -f "$SWIFT_MENU_SRC" ]; then
    echo ""
    echo "→  Собираем WorkGuardMenu (Swift)..."
    swiftc "$SWIFT_MENU_SRC" -framework Cocoa -o "$SWIFT_MENU_BIN"
    chmod +x "$SWIFT_MENU_BIN"
    echo "✓  Swift menu bar: $SWIFT_MENU_BIN"
else
    echo ""
    if [ ! -f "$SWIFT_MENU_SRC" ]; then
        echo "⚠  Нет $SWIFT_MENU_SRC — пропуск сборки Swift."
    else
        echo "⚠  swiftc не найден — нативная строка меню не собрана."
        echo "   Установите Xcode Command Line Tools: xcode-select --install"
    fi
    echo "   Будет только rumps; явно: WORKGUARD_SWIFT_MENU=0 или соберите workguard-menu."
fi

# 6. Напоминание про разрешения
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ВАЖНО: Нужны разрешения macOS                       ║"
echo "║                                                      ║"
echo "║  1. System Settings → Privacy & Security             ║"
echo "║     → Accessibility → добавь WorkGuard.app / python3 ║"
echo "║     (для мониторинга клавиатуры)                     ║"
echo "║                                                      ║"
echo "║  2. При первом уведомлении macOS спросит разрешение  ║"
echo "║     на Notifications — разреши.                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "→  Запуск: двойной клик по:"
echo "     $SCRIPT_DIR/WorkGuard.app"
echo ""
echo "   (при переносе папки проекта снова выполни setup.sh)"
echo ""
echo "Остановка: меню WorkGuard → «Выйти», либо:"
echo "  bash \"$SCRIPT_DIR/scripts/stop_workguard.sh\""
echo ""
echo "Логи: tail -f $LOG_DIR/work_guard.log"
echo ""
