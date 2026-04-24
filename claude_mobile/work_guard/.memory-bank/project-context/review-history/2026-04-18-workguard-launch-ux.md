# 2026-04-18 — Запуск WorkGuard без LaunchAgent, single-instance, пауза-toggle

## Цель

Реализовать план: один способ запуска (двойной клик по `WorkGuard.app`), честный выход без перезапуска launchd, отсутствие дублей процесса, актуальный `config.json` при старте и в тике, один пункт меню паузы с визуальным «приглушением» и снятием паузы тем же кликом.

## Изменения

### Установка и запуск

- **`setup.sh`**: только conda env, `pip install`, сборка launcher в `WorkGuard.app/Contents/MacOS/WorkGuard` из шаблона `WorkGuard.in` (подстановка путей к Python и `work_guard.py`). LaunchAgent, `launchctl load`, фоновый запуск в конце — **удалены**.
- **`WorkGuard.app`**: `Contents/Info.plist`, шаблон `MacOS/WorkGuard.in`; сгенерированный `MacOS/WorkGuard` в `.gitignore`.
- **`com.workguard.plist`**: удалён из репозитория.

### Процесс и конфиг

- **`work_guard.py`**: эксклюзивная блокировка `fcntl.flock` на `~/.config/work_guard/work_guard.lock`; при втором экземпляре — уведомление через `osascript` и выход.
- **`main()`**: `cfg = load_config()` до старта UI; в **`_tick`** каждые 60 с — снова `load_config()` + `monitor.update_config`.
- **`settings_dialog.py`**: импорт `DEFAULTS`/`CONFIG_FILE` из `config.py`; `load()` с `setdefault`; `save()` не теряет `work_apps`, `pause_until` и пр.

### Меню паузы

- Один `rumps.MenuItem` с `toggle_pause`: включает паузу или снимает; в режиме паузы заголовок через **атрибутированный текст** (`NSColor.secondaryLabelColor()`), без `enabled=False`.

### Миграция и документация

- **`stop_workguard.sh`**: по-прежнему `bootout` старого plist при наличии; PID из `work_guard.lock`.
- **`CLAUDE.md`**, **`README.md`**: описание нового сценария.

## Заметки

- После переноса каталога проекта — снова `bash setup.sh`, чтобы переписать пути в launcher.
- Gatekeeper может потребовать «Открыть» для неподписанного `.app`.
