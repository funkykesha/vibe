# Current Status

## Latest Completed Work
- 2026-05-12: **закрыт и архивирован change `install-workguard-applications-launchagent`** — реализованы: `bash rebuild.sh` как единственный public install/rebuild entrypoint; packaging-only app templates under `packaging/`; `/Applications/WorkGuard.app` как единственный supported GUI target; stable bundle id `com.agaibadulin.workguard`; user LaunchAgent `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` with `/usr/bin/open /Applications/WorkGuard.app`, `RunAtLoad=true`, `KeepAlive=false`; `setup.sh` теперь hard error; добавлены manual verification scripts. Live rebuild and verification прошли; synced main specs в `openspec/specs/workguard-*`; archived в `openspec/changes/archive/2026-05-12-install-workguard-applications-launchagent/`.
- 2026-05-11: **закрыт и архивирован change `improve-status-calendar-overlay`** — реализованы: быстрый tick статуса (~5s), overtime по elapsed time, `xmlcalendar.ru` + кэш `calendar_ru_<year>.json`, поддержка `+/*` маркеров и сокращённого дня (`work_end - 1h`), эскалация `overlay_lock_initial_sec -> ... -> overlay_lock_max_sec`, адаптивный `settings_dialog`, обновлены README/C4, создан verification script `tests/manual/verify_production_calendar.py`, synced main specs в `openspec/specs/*`, archived в `openspec/changes/archive/2026-05-11-improve-status-calendar-overlay/`.
- 2026-05-11: **устранён рекурсивный автозапуск WorkGuard** — найден launchd источник `com.agaibadulin.WorkGuard` (open `/Applications/WorkGuard.app`) и старый `com.workguard`; оба отключены/выгружены, соответствующие plist удалены из `~/Library/LaunchAgents`; `scripts/stop_workguard.sh` усилен: scan+bootout+disable всех WorkGuard-like LaunchAgents.
- 2026-05-11: **architecture refresh** — обновлены C4-документы в `docs/architecture/`: контекст теперь явно показывает `xmlcalendar.ru` как сетевую зависимость, container view отделяет runtime-процессы от install/deployment artifacts, deployment view и новый dynamic view фиксируют proposal `install-workguard-applications-launchagent`: reinstall заменяет `/Applications/WorkGuard.app`, обновляет LaunchServices, пишет/reloads LaunchAgent, а LaunchAgent открывает установленный app bundle; сам bundle остаётся launcher к conda Python и project `work_guard.py`.
- 2026-05-11: **уборка структуры проекта** — удалены/заигнорены локальные кэши и окружения (`__pycache__`, `.DS_Store`, `.venv`, `venv`), ручные диагностики перенесены в `tests/manual/`, стоп-скрипт перенесён в `scripts/`, восстановлен шаблон `WorkGuard.app/Contents/MacOS/WorkGuard.in` и `Info.plist`, README дополнен кратким обзором устройства приложения.
- 2026-04-19: **нативная строка меню (Swift) + IPC** — [Swift menu bar agent + status.json / command.json](project-context/review-history/2026-04-19-swift-menu-bar-ipc.md): обход неотрисовки PyObjC/rumps на macOS 26 beta; `WorkGuardMenu/main.swift`, бинарник `workguard-menu` из legacy setup flow; Python пишет `status.json`, читает `command.json` (0.5 с); `WORKGUARD_SWIFT_MENU` (авто при наличии бинарника); при режиме Swift rumps status item скрывается, логика и оверлей остаются в Python.
- 2026-04-19: строка меню и уведомления — [Regular activation policy + Info.plist у интерпретатора](project-context/review-history/2026-04-19-menu-bar-regular-policy.md): по умолчанию `NSApplicationActivationPolicyRegular`, accessory только с `WORKGUARD_MENU_BAR_ONLY=1`; автосоздание `Info.plist` в `dirname(sys.executable)`; osascript с экранированием; убран `LSUIElement` из bundle; `_pin_status_item` (квадрат + SF Symbol); **критично:** из `_update_icon` убрано `self.title` — иначе гонка с фоновым `_tick` сбрасывает NSStatusItem после pin; состояние только в пункте «Статус».
- 2026-04-16: full architectural review (see [review history](project-context/review-history/index.md)).
- 2026-04-18: follow-up code review — [2026-04-18 brain-integrated review](project-context/review-history/2026-04-18-brain-integrated-review.md).
- 2026-04-18: отладка паузы и запуска — [pause / notifications / LaunchAgent](project-context/review-history/2026-04-18-pause-notification-launchd.md): фикс порядка `_update_icon` и обработки `rumps.notification`, `KeepAlive=false`, `stop_workguard.sh`, правки CLAUDE/setup.
- 2026-04-18: **запуск и UX по плану** — [WorkGuard launch UX](project-context/review-history/2026-04-18-workguard-launch-ux.md): без LaunchAgent, legacy local app launcher, `fcntl` lock, перезагрузка конфига в тике, один пункт паузы с toggle и приглушённым заголовком, миграция через `stop_workguard.sh`.

## Current Understanding
- Публичный install/run contract: `bash rebuild.sh` -> `/Applications/WorkGuard.app`.
- Единственный supported GUI target: `/Applications/WorkGuard.app`.
- LaunchAgent contract: `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`, `/usr/bin/open /Applications/WorkGuard.app`, `RunAtLoad=true`, `KeepAlive=false`.
- Legacy setup script path obsolete. Не current workflow. Не wrapper. Не fallback.
- После cleanup launchd старые агенты `com.agaibadulin.WorkGuard` и `com.workguard` отключены; рекурсивный автоподъём приложения через LaunchAgents остановлен.
- Direct Python launch остаётся только для debug/diagnostics. Старый memory-набросок про direct Python из LaunchAgent устарел.
- Один экземпляр: `work_guard.lock` + flock; повторный запуск — уведомление macOS.
- Пауза: один пункт меню; при активной паузе текст приглушён (attributed), клик снимает паузу.
- Конфиг: при старте и каждом тике читается с диска; `settings_dialog` сохраняет полный словарь с дефолтами из `config.py`.
- Уведомления: `Info.plist` у интерпретатора создаётся при старте при отсутствии; osascript-уведомления логируют ошибки stderr.
- Только строка меню без Dock: `WORKGUARD_MENU_BAR_ONLY=1`.
- Строка меню: не вызывать `self.title` из `_update_icon` (ломает pin); на macOS 26 при проблемах с PyObjC — нативный агент `workguard-menu` + `status.json` / `command.json` (см. review-history 2026-04-19-swift-menu-bar-ipc).
- ActivitySignals — только documented future boundary; local/coarse-only; collectors сейчас нет.
- Privacy boundary: наружу ничего без явного запроса; secrets машину не покидают никогда.
- Структура: runtime Python-файлы пока остаются в корне; ручные диагностики живут в `tests/manual/`; служебные скрипты — в `scripts/`; bundle templates/assets должны жить в отдельной packaging-директории, а не восприниматься как project-local launch target.
- Актуальный путь проекта: `/Users/agaibadulin/Desktop/projects/vibe/work_guard`; пользовательские данные приложения остаются в `~/.config/work_guard/`.

## Next Recommended Action
No active OpenSpec implementation change is pending. Next useful hardening can be chosen from Beads/OpenSpec backlog after checking `bd ready`.

По желанию: валидация полей в `config.py`, hot-reload при сохранении настроек в отдельном процессе без ожидания тика, унификация дублирующего UI настроек (встроенный `_show_settings_dialog` удалён из раннего кода при рефакторинге).
