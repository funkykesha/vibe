# Refactor: WorkGuard → services-menu rails

## Context

WorkGuard разросся до 2184 строк / 8 модулей / 2 субпроцессов / опционального Swift агента / 3 daemon-тредов / 2 IPC файлов. Сосед `services-menu` (319 строк, чистый `rumps` + AppKit модалки, `rumps.Timer`-driven, без тредов) даёт минимальный шаблон macOS menu-bar приложения. Цель: привести WorkGuard к тем же «рельсам», не теряя фичи (overtime accounting, эскалация с overlay, deferral ladder, производственный календарь, уведомления, single-instance lock).

Ограничение архитектуры: overlay **обязан** запускаться отдельным процессом — требования AppKit main-thread compliance (зафиксировано в CLAUDE.md). Settings-диалог tkinter — текущий subprocess из-за конфликта Tk/AppKit; переход на AppKit `NSWindow` убирает и subprocess, и конфликт.

Утверждённые решения:
- Swift menu agent → **удалить полностью**.
- settings_dialog.py (tkinter) → **переписать на AppKit `NSWindowController`** в основном процессе.
- Daemon threads → **`rumps.Timer`** на main loop.
- Модульная структура сохраняется, выравнивается стиль под services-menu (`ValidationError`, builder-функции, глобальные константы, co-located `test_*.py`, `unittest`).

## Target Module Map

| Файл | Роль после рефакторинга |
|------|------|
| [work_guard.py](work_guard.py) | `WorkGuardApp(rumps.App)`, `rumps.Timer` тики, меню, lock, lifecycle. Удалены Swift IPC, status.json gate, command.json poll, threading-loop. |
| [monitor.py](monitor.py) | `ActivityMonitor` без изменений по сути; `start()`/`stop()` остаются (внутренние watchers идут отдельно). |
| [overlay.py](overlay.py) | Без изменений — остаётся `__main__`-entrypoint subprocess (mandatory). |
| [settings_window.py](settings_window.py) | **Новый**. `SettingsWindowController` на AppKit, заменяет [settings_dialog.py](settings_dialog.py). |
| [config.py](config.py) | + `ValidationError`, builder `build_period_settings(...)`, валидация в одном месте; load/save без изменений. |
| [production_calendar.py](production_calendar.py) | Без изменений. |
| [notifier.py](notifier.py) | + поглощает `_notify_osascript`/`_notify_started_menu_bar_hint`/`_notify_already_running` из work_guard.py (сейчас дублируется). |
| [ascii_art.py](ascii_art.py) | Без изменений. |
| `test_config.py`, `test_monitor.py`, `test_work_guard.py` | **Новые** в корне (co-located, `unittest`, fakes + temp dirs). |

Удаляются: `settings_dialog.py`, `WorkGuardMenu/` (целиком), все ветки `_swift_menu`, `status.json` / `command.json` payload-helpers (json-файлы на диске можно оставить пустыми/удалить).

## What Gets Deleted

В [work_guard.py](work_guard.py):
- Импорты/использование `threading` (после миграции на Timer)
- `_swift_menu_binary`, `_swift_menu_enabled`, `WORKGUARD_SWIFT_MENU` env branches
- `_start_swift_menu_agent`, `_stop_swift_menu_agent`, `_handle_swift_command`
- `_status_json_payload`, `_write_status_json`, `STATUS_JSON_PATH`, `COMMAND_JSON_PATH`, `_atomic_write_json`, `_last_status_json`
- `@rumps.timer(0.5) _poll_swift_commands`
- В `_sync_bar_title` — ветка `if self._swift_menu: self._write_status_json(); return`
- В `_pin_status_item` / `_delayed_status_item_diag` — ветки `if self._swift_menu`
- `self._loop_thread = threading.Thread(...)._monitoring_loop` → заменяется `@rumps.timer(CHECK_INTERVAL)`
- `threading.Thread(target=self.overlay.show, ...)` × 2 (в [work_guard.py:678](work_guard.py:678) и [work_guard.py:851](work_guard.py:851)) → `subprocess.Popen([sys.executable, overlay.__main__, ...])` (overlay уже сам процесс, выше нити лишние)

Файлы:
- `WorkGuardMenu/` (вся директория, включая `main.swift`, бинарник, `Package.swift` если есть)
- `settings_dialog.py`
- В `rebuild.sh` — все шаги сборки Swift агента, копирования бинаря в bundle, любые ссылки на `WORKGUARD_SWIFT_MENU`.

## Migration Sequence

Каждая фаза оставляет приложение запускаемым через `bash rebuild.sh`. После каждой — ручная проверка (см. Verification).

**Phase A — Strip Swift agent**
Удалить ветки `_swift_menu` в [work_guard.py](work_guard.py), удалить WorkGuardMenu/, очистить rebuild.sh от Swift шагов, убрать `STATUS_JSON_PATH`/`COMMAND_JSON_PATH` и связанный код. После: чистый rumps статус-бар, всё остальное как есть. Самая дешёвая фаза, проверяет что rumps один справляется.

**Phase B — Timers вместо threads**
В [work_guard.py](work_guard.py): `_monitoring_loop` + `threading.Thread` → `@rumps.timer(CHECK_INTERVAL)` метод `_tick`. Два `threading.Thread(target=self.overlay.show, ...)` остаются как `subprocess.Popen` (overlay уже spawned как `python -m overlay`, нить-обёртка не нужна). `monitor.start()` оставить — у него свои внутренние watchers, но если они уже фоновые (`KeyboardWatcher`, `LidWatcher` через pynput/CoreGraphics), оставить как есть; рефакторить только наш monitoring loop.

**Phase C — AppKit Settings**
Создать `settings_window.py` с `SettingsWindowController` (по образцу [services-menu/app.py:162-235](../../../services-menu/app.py:162) — `AddConfigWindowController`). Поля: 2× NSTextField для `work_start`/`work_end` (формат HH:MM), 7× NSButton checkbox (Пн–Вс), 3 кнопки: «Дефолт», «Предыдущий» (только в mode2), «Сохранить». Баннер-NSTextField вверху если `cfg["deferral"] is not None`. Валидация через новый `config.validate_period_settings(form) -> ValidationError`. В [work_guard.py](work_guard.py) `open_settings` → `self.settings_window.show()` вместо `subprocess.Popen`. Удалить `settings_dialog.py`.

**Phase D — Style alignment**
- [config.py](config.py): добавить `ValidationError(Exception)` + `validate_period_settings(form)` + `build_period_settings(work_start, work_end, work_days)` (как `build_launch_agent_config` в services-menu).
- [notifier.py](notifier.py): поглотить `_notify_osascript`, `_notify_started_menu_bar_hint`, `_notify_already_running` из [work_guard.py](work_guard.py).
- Все «магические» пути ([work_guard.py:33-39](work_guard.py:33)) — поднять в module-level constants блок сверху (как `LABEL_PREFIX`, `LAUNCH_AGENTS_DIR` в services-menu).
- Добавить `test_config.py`, `test_monitor.py`, `test_work_guard.py` (unittest + tempdir + module-level подмена `CONFIG_DIR`).

## rumps.Timer Consolidation

После Phase A исчезает `_poll_swift_commands` (1s). Остаётся:

| Timer | Что делает | Период |
|------|-----------|------|
| `_tick` (новый, главный) | reload cfg, check work_time/working, update icon, overtime/deferral state, fire overlay | 5s |
| `_sync_bar_title` | копирует `_bar_title_pending` в `nsstatusitem.button().setTitle_` | 1s |
| `_pin_status_item` | one-shot pin macOS 26 NSStatusItem (саморегулирующийся, останавливает себя) | 0.2s |
| `_delayed_status_item_diag` | one-shot diagnostic dump | 10s |

`_sync_bar_title` можно слить с `_tick`, обновляя title сразу в `_update_icon`. Это уберёт ещё один таймер. Оставить — если на macOS 26 beta всё ещё нужен retry (логи покажут). По умолчанию: **слить**. Если в верификации title не обновляется в реальном времени — откатить и оставить отдельный 1s timer.

## AppKit Settings Dialog Design

`SettingsWindowController` экспонирует:
- `__init__(self, on_save: Callable[[dict], None])` — `on_save` вызывается с валидным `form = {"work_start", "work_end", "work_days"}`.
- `show(self, cfg: dict)` — перечитывает `cfg` (свежий load_config), решает mode1/mode2 по `cfg["deferral"]`, заполняет поля из `pending_period_settings or current_period_settings`, показывает окно.
- `close()`, `applyDefaultsClicked_`, `applyPreviousClicked_`, `saveClicked_`, `cancelClicked_`.

Контракт сохранения (повторяет логику [settings_dialog.py:237-258](settings_dialog.py:237)): в mode1 пишем в `current_period_settings`, обнуляем `pending`. В mode2: если форма == текущему, обнуляем `pending`; иначе кладём в `pending_period_settings`. `_run_period_promotion` в [work_guard.py:854](work_guard.py:854) и так подхватит `pending` на границе периода.

Окно: `NSWindow` 480×340pt, `NSWindowStyleMaskTitled | NSWindowStyleMaskClosable`, `setReleasedWhenClosed_(False)` — чтобы переоткрывалось без пересоздания. Тёмная тема не обязательна (macOS системная тема покрывает); цветовые константы из tkinter варианта отбрасываются.

Banner mode2 (next-work-start hint): вычислять через `next_work_start_after(now, cfg["current_period_settings"], calendar)` — функция **уже есть** в [work_guard.py:226](work_guard.py:226); вынести в `production_calendar.py` или новый `schedule.py` чтобы settings_window.py не зависел от work_guard.py.

## Style Changes Per Module

`config.py` — добавить:
```python
class ValidationError(Exception): pass
def validate_period_settings(form: dict) -> None: ...  # raise ValidationError
def build_period_settings(work_start, work_end, work_days) -> dict: ...
```
Глобальные `CONFIG_DIR`, `CONFIG_FILE` уже есть — стиль совпадает.

`work_guard.py` — глобальные константы блоком сверху (как [services-menu/app.py:23-30](../../../services-menu/app.py:23)), `_notify_*` вынести в notifier.py, оставить только app class + `main()` + `_acquire_lock`/`_release_lock`/`_ensure_interpreter_info_plist`. Цель: < 600 строк после очистки.

`notifier.py` — обрастает функциями уведомлений (`notify_overtime`, `notify_started`, `notify_already_running`, `notify_osascript`). Сейчас 51 строка — станет ~100.

## Test Layout

В корне (co-located как services-menu/test_app.py):
- `test_config.py` — load/save, миграция legacy, validate_period_settings (ok/bad time format/empty days/start>=end).
- `test_monitor.py` — is_work_time с замоканным calendar, is_work_happening.
- `test_work_guard.py` — `next_work_start_after`/`last_work_end_before` (чистые функции, легко тестируются), defer ladder transitions.

Стиль: `unittest.TestCase`, `tempfile.TemporaryDirectory` + monkey-patch `config.CONFIG_DIR`, без `mock` / без `pytest`. Запуск: `conda run -n work_guard python -m unittest discover`.

## Risks & Mitigations

| Риск | Митигация |
|------|-----------|
| Перенос monitoring loop в rumps.Timer блокирует main loop, если tick медленный (calendar fetch) | `ProductionCalendar` кеширует на диск; первый fetch при холодном запуске может быть медленным — оставить как есть (уже редкий), либо обернуть в отложенный `rumps.Timer(once=True)` пред-загрузку. |
| Tk subprocess сейчас даёт «modal без блокировки» бесплатно; NSWindow окно из основного процесса может блокировать tick | `NSWindow.makeKeyAndOrderFront_` не модально — tick продолжит работать. Подтверждено поведением services-menu. |
| status.json удаление сломает внешних консьюмеров | По исходникам никто не читает status.json кроме Swift агента (которого удаляем). Подтвердить grep `status.json` по проекту перед фазой A. |
| `deferral` state теряется при смене схемы | Схема не меняется — только удаляем ветки кода, читающие/пишущие config; ключи остаются. |
| LaunchAgent после rebuild.sh не подхватит изменения | `rebuild.sh` уже делает unload+load; не трогаем bundle id `com.agaibadulin.workguard`. |
| macOS 26 NSStatusItem regress при удалении Swift fallback | Оставить `_pin_status_item` логику как есть. Если на macOS 26 беге title не виден — вернуться к гибридному варианту по обратной просьбе. |

## Verification

После каждой фазы:

```bash
bash rebuild.sh
# tail логов в отдельном терминале:
tail -f ~/.config/work_guard/work_guard.log
```

Ручные сценарии (последовательно):

1. **Запуск**: иконка `WG` появилась в строке меню; в Dock приложения нет (LSUIElement).
2. **Single-instance**: второй `/usr/bin/open /Applications/WorkGuard.app` — osascript уведомление «Уже запущен», старый процесс жив.
3. **Idle**: вне `work_start`–`work_end` → иконка `WG` (⚪), статус «Нерабочее время». Никаких overlay.
4. **Working**: внутри окна → иконка `WG 🟢`, статус «Рабочее время».
5. **Overtime**: дотянуть до `work_end`+1мин при активности → иконка `WG 🔴`, в меню «Отложить на 20 мин» активна.
6. **Overlay через 20 мин**: ждать или сдвинуть системные часы — overlay subprocess поднимается, lock 120s, ASCII-арт уровня 0.
7. **Deferral**: клик «Отложить на 20 мин» в overtime до cutoff — окно overlay не появляется до `next_overlay_at + 20мин`; «step_unlock_at» блокирует повторный клик на 15мин.
8. **Settings dialog**: меню «Настройки...» — окно NSWindow открывается на main process (без второго python в Activity Monitor), валидация ругается на «09:00»/«25:00»/пустые дни, «Сохранить» применяет → next tick подхватывает.
9. **mode2 banner**: с активным `deferral` открыть Настройки — баннер с датой следующего start.
10. **Production calendar**: 1 января — `calendar_ru_<year>.json` кешируется, классификация выходных корректна.
11. **Quit**: «Выйти» → процесс умирает, lock освобождён, повторный запуск работает.
12. **Tests**: `conda run -n work_guard python -m unittest discover` — зелёный.

После всей миграции — `bd close` для всех связанных beads issues, `git commit` + `git push`.
