# Todoist Engagement Reminder

## Context

WorkGuard сегодня бьёт оверлеем только за **переработку** (работа вне рабочих часов).
Пользователь хочет обратное: в **рабочее время** мониторить вовлечённость в Todoist
(визиты на `app.todoist.com` + работу с задачами) и напоминать оверлеем, если давно
не заходил.

Это первый реальный коллектор для документированной, но пустой границы
**ActivitySignals** (`CONTEXT.md`, `docs/architecture/c4-components-core.md`,
`openspec/specs/workguard-activity-boundary/spec.md`). Он также впервые вводит
**исходящий сетевой вызов с секретом** (Todoist API token) — пользователь явно
согласился. Privacy-контракт надо обновить: коллектор opt-in, выключен по умолчанию,
активен только при наличии токена.

**Решения пользователя:**
- Источники: браузер (локально, без токена) **+** Todoist REST API (токен, сеть).
- Порог: только в рабочее время, простой Todoist > **2 ч**.
- Браузеры активной вкладки: Yandex (`Yandex`), Chrome (`Google Chrome`), Safari.

## Approach

Два независимых сигнала сводятся в один timestamp `last_todoist_engagement =
max(последняя активная вкладка todoist, последняя активность по API)`. В рабочее
время, если пользователь работает (`is_work_happening()`) и простой превысил порог —
показываем reminder-оверлей с антиспам-каденцией.

**Важно (исправление):** reminder работает в ветке `in_work_time == True`, а
не в overtime. Overtime-оверлей и Todoist-reminder временно взаимоисключающие
(overtime фактически только при `in_work_time == False`), так что конфликта нет.

### Источники сигнала
- **Браузер** — каждый тик (5 c): только если `get_active_app()` входит в
  `browser_apps`, дёргаем `osascript` за URL активной вкладки. Substring
  `todoist.com` → фиксируем `now`. Полностью локально. Ограничение: ловит только
  активную (foreground) вкладку; фоновая вкладка не считается — это и есть
  «вовлечённость».
- **API** — медленный фоновый поллинг (по умолчанию раз в 5 мин), по образцу
  `production_calendar.py` (HTTP + кэш в локальный JSON). `GET
  https://api.todoist.com/rest/v2/tasks?...` либо `/sync` с
  `Authorization: Bearer <token>`; берём максимальный `updated_at` / completed-время.
  Кэш + last-activity в `~/.config/work_guard/todoist_last_activity.json`.

### State и устойчивость к рестарту
`last_todoist_engagement` **персистится** в
`~/.config/work_guard/todoist_last_activity.json` (тот же файл, что кэш API).
При рестарте загружается — порог считается от реального последнего контакта, а не
обнуляется. Антиспам-таймер `_todoist_reminder_next_fire_at` — in-memory (после
рестарта первый чек просто отложен).

## Files

### Новые

**`todoist_signals.py`** — два детектора:
- `BrowserTabDetector` — словарь `BROWSERS` (`Google Chrome` → `URL of active tab
  of front window`; `Safari` → `URL of current tab of front window`; `Yandex` →
  `URL of active tab of front window`). `is_todoist_open(active_app) -> bool`:
  если `active_app` в `BROWSERS`, запускает `osascript`, ищет `todoist.com`.
  Любая ошибка/нет прав TCC → `False` (fail-safe, не нагнетать).
- `TodoistAPIPoller` — `poll_if_due()` (неблокирующий, спавнит поток если прошло
  `poll_interval_min`), `_do_poll()` (HTTP с timeout=30, кэш в JSON,
  `try/except` всё), `get_last_activity_time() -> Optional[datetime]`. Нет токена →
  no-op.

**`engagement_monitor.py`** — `TodoistEngagementMonitor`:
- Оборачивает оба детектора + `update_config()`.
- `update_from_tick(active_app)`: если `is_todoist_open` → engagement=now;
  `api_poller.poll_if_due()`; пересчёт `last_engagement = max(...)`; персист в JSON.
- `get_minutes_since_engagement() -> Optional[int]` (None если данных нет → не нагнетать).
- `is_enabled() -> bool` (`enabled and bool(api_token)`; браузерный сигнал может
  работать и без токена — допустимо, см. вопрос ниже).

### Правки

**`config.py`** — в `DEFAULTS` новая секция (auto-fill при `load_config`, миграция не нужна):
```python
"todoist_reminder": {
    "enabled": False,            # opt-in, выключено по умолчанию
    "api_token": "",             # секрет, хранится локально в config.json
    "idle_threshold_min": 120,   # порог простоя = 2 ч
    "browser_apps": ["Google Chrome", "Safari", "Yandex"],
    "poll_interval_min": 5,
    "reminder_cadence_min": 30,  # антиспам между оверлеями
    "overlay_lock_sec": 15,
},
```

**`ascii_art.py`** — новая ENTRY + `get_todoist_reminder_entry(level)` →
`(art, message)`, текст в духе «Давно не заходил в Todoist — проверь задачи».
Переиспользует существующий рендер оверлея.

**`work_guard.py`** — точечная интеграция в `_tick()` (~705):
- `__init__`: `self.todoist_engagement = TodoistEngagementMonitor(cfg)`,
  `self._todoist_reminder_next_fire_at = None`.
- В начале тика: `self.todoist_engagement.update_config(self.cfg)`.
- В ветке **`if in_work_time:`** (сейчас ~720-723, reset + 🟢 + return) — перед
  return вызвать `self._check_todoist_engagement(now, working, active_app)`.
- В ветках выхода из рабочего времени / простоя — `self._reset_todoist_reminder_state()`.
- Новые методы:
  - `_reset_todoist_reminder_state()` → `self._todoist_reminder_next_fire_at = None`.
  - `_check_todoist_engagement(now, working, active_app)`:
    - `if not self.todoist_engagement.is_enabled(): return`
    - `self.todoist_engagement.update_from_tick(active_app)` (всегда — копит сигнал)
    - `if not working: return` (юзер отошёл — не нагнетать)
    - каденс-гейт: `if next_fire_at and now < next_fire_at: return`
    - `mins = get_minutes_since_engagement()`; `if mins is None:` отложить на 5 мин, return
    - `if mins >= idle_threshold_min:` показать оверлей через
      `self.overlay.show(art, msg, lock_sec)` (как overtime, в daemon-потоке),
      затем `next_fire_at = now + reminder_cadence_min`
    - иначе `next_fire_at = now + 5 мин`

**`settings_dialog.py`** (можно отложить на v1.1) — тумблер enable, поле токена
(маскированное), порог простоя, интервал поллинга, каденс. Привязка к
`cfg["todoist_reminder"][...]`.

### Privacy / governance
- **`CLAUDE.md` / `AGENTS.md`** (держать идентичными) и **`CONTEXT.md`** — обновить
  строку «ActivitySignals = future boundary only, no collectors»: появился первый
  коллектор; opt-in; единственный исходящий вызов — Todoist API под токеном юзера;
  токен хранится локально в `config.json`, в логи не пишется, наружу кроме
  api.todoist.com не уходит.
- **`openspec/`** — создать change, фиксирующий смену intent (граница
  activity-boundary теперь имеет один сетевой коллектор), затем beads-задачи
  (epic + tasks), потом код. Порядок per CLAUDE.md: OpenSpec → Beads → код/доки.

## Failure modes (все fail-safe — ложно не срабатывать)
| Случай | Поведение |
|---|---|
| TCC Automation запрещён | osascript err → `False` → нет engagement, но и нет ложного reminder; полагаемся на API |
| Браузер не запущен / не frontmost | нет URL → сигнал не обновляется |
| Нет токена | API no-op; работает только браузерный сигнал |
| API timeout/offline/401 | лог, кэш или None; reminder не фейкается |
| Юзер отошёл (`working=False`) | reminder не показываем |
| `mins is None` (нет данных) | откладываем чек, не нагнетаем |

## Verification
1. Debug-запуск: `conda run -n work_guard python work_guard.py`.
2. В `config.json` выставить `todoist_reminder.enabled=true`, вставить токен,
   `idle_threshold_min=1`, `reminder_cadence_min=1` для быстрого цикла.
3. Закрыть вкладку Todoist, не трогать задачи → через ~1 мин в рабочее время
   при активном вводе должен всплыть reminder-оверлей.
4. Открыть `app.todoist.com` активной вкладкой → engagement сбрасывается, оверлей
   не всплывает (проверить лог «Todoist reminder … min idle» не пишется).
5. Завершить задачу через API/телефон → после поллинга engagement обновляется.
6. Антиспам: игнорировать первый оверлей → следующий не раньше `reminder_cadence_min`.
7. Проверить TCC: первый `osascript` к браузеру вызовет системный промпт Automation
   — подтвердить вручную (manual-check).
8. Regression: вне рабочего времени переработка-оверлей работает как раньше.
