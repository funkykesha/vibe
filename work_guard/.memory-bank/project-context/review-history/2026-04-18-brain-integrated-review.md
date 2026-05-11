# 2026-04-18 Brain-integrated code review (session)

## Pre-search (Brain)

- `brain_search` (семантика: WorkGuard, macOS, мониторинг) — **совпадений не найдено**; специфичного контекста WorkGuard в Brain нет.
- `brain_get_context` — **Project Context** в MEMORY.md ссылался на другой репозиторий (memory_mcp), не на WorkGuard.

## Scope

Повторное/уточняющее ревью с опорой на исходники: [`work_guard.py`](../../../work_guard.py), [`monitor.py`](../../../monitor.py), [`config.py`](../../../config.py), [`settings_dialog.py`](../../../settings_dialog.py), [`overlay.py`](../../../overlay.py), сравнение с [2026-04-16](2026-04-16-architectural-review.md).

## Key confirmations

- Модель переработки: счёт вне `is_work_time` + `is_work_happening` (не «дневной баланс») — `WorkGuardApp._tick`.
- Риски: `m % interval` при нуле в конфиге → `ZeroDivisionError`; настройки из `settings_dialog.py` (субпроцесс) не перезагружают `self.cfg` в основном процессе без рестарта.
- Мёртвый код: `WorkGuardApp._show_settings_dialog` в `work_guard.py` не вызывается; живой UI — `settings_dialog.py` через `Popen`.
- Ключ меню `self.menu["Статус: загрузка..."]` — хрупкий.
- README: описан «Снять паузу», в текущем меню пункта нет; `work_apps` в README в таблице настроек не раскрыт.

## Outcome

Документация/память обновлены командой `/mmr` (UMB + `brain_save` + `brain_consolidate_dialog`). **Код не менялся** в этой сессии.

## References

- План-обзор в сессии Cursor: workguard project review (plan file, 2026-04-18).
