#!/usr/bin/env bash
# Останавливает WorkGuard: снимает старый LaunchAgent (если остался от прежней установки),
# затем шлёт сигнал по lock-файлу (PID) и добивает оставшиеся процессы.
set -euo pipefail

LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PID_FILE="${HOME}/.config/work_guard/work_guard.lock"
UID_NUM="$(id -u)"

if [[ -d "$LAUNCH_AGENTS_DIR" ]]; then
  while IFS= read -r plist; do
    match=0
    base="$(basename "$plist")"
    if [[ "$base" == *WorkGuard* || "$base" == *workguard* || "$base" == *work_guard* ]]; then
      match=1
    else
      if /usr/bin/grep -qiE 'WorkGuard|workguard|work_guard' "$plist"; then
        match=1
      fi
    fi
    if [[ "$match" -eq 0 ]]; then
      continue
    fi

    launchctl bootout "gui/${UID_NUM}" "$plist" 2>/dev/null || true

    label="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist" 2>/dev/null || true)"
    # Do not disable the canonical WorkGuard agent: bootstrap alone does not re-enable a disabled label.
    if [[ -n "$label" && "$label" != "com.agaibadulin.workguard" ]]; then
      launchctl disable "gui/${UID_NUM}/${label}" 2>/dev/null || true
    fi
  done < <(find "$LAUNCH_AGENTS_DIR" -maxdepth 1 -type f -name '*.plist' | sort)
fi

if [[ -f "$PID_FILE" ]]; then
  pid="$(tr -d ' \n' <"$PID_FILE" || true)"
  if [[ -n "${pid}" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
fi

# На случай второго экземпляра или устаревшего pid-файла
pkill -f '[/]work_guard\.py' 2>/dev/null || true

sleep 0.3
if pgrep -f '[/]work_guard\.py' >/dev/null 2>&1; then
  echo "Процесс всё ещё жив — принудительно: pkill -9 -f work_guard.py" >&2
  exit 1
fi
echo "WorkGuard остановлен."
