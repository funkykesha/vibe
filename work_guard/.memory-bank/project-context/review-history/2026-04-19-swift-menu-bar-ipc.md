# 2026-04-19: Swift menu bar + IPC (macOS 26 / PyObjC)

## Контекст

На macOS 26 beta NSStatusItem, созданный через Python/PyObjC (rumps), может не отображаться в строке меню: объект и activation policy выглядят корректно, но WindowServer не рендерит слот для процесса интерпретатора. Нативный Swift с тем же API отображается нормально.

## Решение

Разделение UI и логики:

- **`work_guard.py`** — мониторинг, конфиг, оверлей, уведомления, цикл тиков; по-прежнему `rumps` для NSApplication и внутреннего меню (скрытый status item при режиме Swift).
- **`WorkGuardMenu/main.swift`** — тонкий агент: `NSStatusItem`, `NSMenu`, accessory policy.
- **IPC через файлы** в `~/.config/work_guard/`:
  - **`status.json`** (Python → Swift): `title`, `tooltip`, `paused`, `items[]` с полями `id`, `text`, `enabled`.
  - **`command.json`** (Swift → Python): `action`, `ts`; атомарная запись `.tmp` + move.

## Включение

- Бинарник: `WorkGuardMenu/workguard-menu`, сборка в **`setup.sh`** через `swiftc … -framework Cocoa`.
- **`WORKGUARD_SWIFT_MENU`**: `0` — только rumps; `1` — требовать бинарник; если переменная **не задана** — режим включается **автоматически**, если `workguard-menu` существует и исполняемый.
- Python стартует Swift через **`subprocess.Popen`**; при выходе — **`terminate`** / kill.
- Опрос **`command.json`**: таймер rumps **0.5 с**; действия: `settings`, `pause`, `resume`, `test_overlay`, `quit` (пункты `status`/`overtime` игнорируются).
- Синхронизация **`status.json`**: дедупликация по сериализованному JSON; периодическое обновление через **`_sync_bar_title`** (1 с) в режиме Swift.

## Не ломать

- Не возвращать **`self.title`** из **`_update_icon`** (гонка с тиками); заголовок строки меню для нативного UI — через **`_bar_title_pending`** и файл.
- Диагностика PyObjC (**`_pin_status_item`**, **`STATUS_ITEM_DIAG`**) отключается в режиме Swift (скрытие rumps status item).

## Связанные заметки

- [2026-04-19 Menu bar: Regular activation policy](2026-04-19-menu-bar-regular-policy.md) — предыдущий слой (policy, Info.plist, pin).
