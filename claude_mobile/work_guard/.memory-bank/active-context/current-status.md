# Current Status

## Latest Completed Work
- 2026-04-19: **нативная строка меню (Swift) + IPC** — [Swift menu bar agent + status.json / command.json](project-context/review-history/2026-04-19-swift-menu-bar-ipc.md): обход неотрисовки PyObjC/rumps на macOS 26 beta; `WorkGuardMenu/main.swift`, бинарник `workguard-menu` из `setup.sh`; Python пишет `status.json`, читает `command.json` (0.5 с); `WORKGUARD_SWIFT_MENU` (авто при наличии бинарника); при режиме Swift rumps status item скрывается, логика и оверлей остаются в Python.
- 2026-04-19: строка меню и уведомления — [Regular activation policy + Info.plist у интерпретатора](project-context/review-history/2026-04-19-menu-bar-regular-policy.md): по умолчанию `NSApplicationActivationPolicyRegular`, accessory только с `WORKGUARD_MENU_BAR_ONLY=1`; автосоздание `Info.plist` в `dirname(sys.executable)`; osascript с экранированием; убран `LSUIElement` из bundle; `_pin_status_item` (квадрат + SF Symbol); **критично:** из `_update_icon` убрано `self.title` — иначе гонка с фоновым `_tick` сбрасывает NSStatusItem после pin; состояние только в пункте «Статус».
- 2026-04-16: full architectural review (see [review history](project-context/review-history/index.md)).
- 2026-04-18: follow-up code review — [2026-04-18 brain-integrated review](project-context/review-history/2026-04-18-brain-integrated-review.md).
- 2026-04-18: отладка паузы и запуска — [pause / notifications / LaunchAgent](project-context/review-history/2026-04-18-pause-notification-launchd.md): фикс порядка `_update_icon` и обработки `rumps.notification`, `KeepAlive=false`, `stop_workguard.sh`, правки CLAUDE/setup.
- 2026-04-18: **запуск и UX по плану** — [WorkGuard launch UX](project-context/review-history/2026-04-18-workguard-launch-ux.md): без LaunchAgent, `WorkGuard.app` из `setup.sh`, `fcntl` lock, перезагрузка конфига в тике, один пункт паузы с toggle и приглушённым заголовком, миграция через `stop_workguard.sh`.

## Current Understanding
- Запуск: двойной клик по `WorkGuard.app` после `setup.sh`; автологин через launchd не используется.
- Один экземпляр: `work_guard.lock` + flock; повторный запуск — уведомление macOS.
- Пауза: один пункт меню; при активной паузе текст приглушён (attributed), клик снимает паузу.
- Конфиг: при старте и каждом тике читается с диска; `settings_dialog` сохраняет полный словарь с дефолтами из `config.py`.
- Уведомления: `Info.plist` у интерпретатора создаётся при старте при отсутствии; osascript-уведомления логируют ошибки stderr.
- Только строка меню без Dock: `WORKGUARD_MENU_BAR_ONLY=1`.
- Строка меню: не вызывать `self.title` из `_update_icon` (ломает pin); на macOS 26 при проблемах с PyObjC — нативный агент `workguard-menu` + `status.json` / `command.json` (см. review-history 2026-04-19-swift-menu-bar-ipc).

## Next Recommended Action
По желанию: валидация полей в `config.py`, hot-reload при сохранении настроек в отдельном процессе без ожидания тика, унификация дублирующего UI настроек (встроенный `_show_settings_dialog` удалён из раннего кода при рефакторинге).
