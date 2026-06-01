# Todoist Engagement Reminder

## Context

WorkGuard сегодня показывает оверлей только за **переработку** (работа вне рабочих
часов). Нужно обратное: в **рабочее время** мониторить вовлечённость в Todoist и,
если давно не заходил, показывать фуллскрин-оверлей с мини-дашбордом задач.

Это первый реальный коллектор для документированной, но до сих пор пустой границы
**ActivitySignals** (`CONTEXT.md`, `docs/architecture/c4-components-core.md`,
`openspec/specs/workguard-activity-boundary/spec.md` — там прямо «no collectors,
nothing leaves machine»). Фича впервые вводит **opt-in исходящий вызов с секретом**
(Todoist API token). Privacy-границу надо обновить формально через OpenSpec.

### Решения (зафиксированы с пользователем)
- **Вовлечённость = max из 3 сигналов**, recency-timestamp:
  1. **Фронт-апп** `get_active_app() == "Todoist"` (PWA Яндекс.Браузера — отдельный
     процесс, CFBundleName `Todoist`). Ловит «смотрю в окно Todoist» без навигации.
  2. **History-визит** на `todoist.com` — последний `last_visit_time` из Chromium
     History (Yandex + Chrome). Ловит навигации, в т.ч. внутри PWA (общий профиль
     `YandexBrowser/Default`) и обычные вкладки.
  3. **API-изменение** — `GET /tasks`, diff снапшота активных задач (любая мутация:
     завершил/добавил/изменил). Ловит работу с телефона.
- **Браузеры**: только Chromium (Yandex осн., Chrome). **Без Full Disk Access**
  (их History вне TCC-зоны). Safari исключён намеренно (требовал бы FDA).
- **Порог**: только в рабочее время, простой > **2 ч** (`idle_threshold_min=120`).
- **Grace утром**: отсчёт от `max(work_start_today, last_engagement)` → первый
  reminder не раньше `work_start + 2ч`. Вчерашний хвост игнор.
- **Обед/простой**: wall-clock, паузы нет; но оверлей показываем только когда юзер
  за компом (`is_work_happening()` == True).
- **Каденс после «Свернуть»**: плоско 30 мин (`reminder_cadence_min`). Без эскалации.
  Реальный заход или «Перейти в Todoist» сбрасывают всё.
- **Токен**: правка `config.json` вручную (MVP). Settings-UI — отдельной задачей.
- **Governance**: OpenSpec-change обновляет activity-boundary spec; **beads убрать**
  из `CLAUDE.md`/`AGENTS.md`.

### Оверлей (новый тип, отдельно от overtime)
- Фуллскрин, **без таймера/lock**.
- 2 кликабельные кнопки: **«Перейти в Todoist»** (`open -a /Applications/Todoist.app`,
  затем закрыть оверлей) и **«Свернуть оверлей»** (закрыть).
- Мини-дашборд (**не кликабельный**, данные из кэша последнего поллинга — preload):
  - Развёрнутый список задач **p1+p2** (в REST API priority `4` и `3`), кап **10**
    строк + «…ещё N».
  - Счётчики **p3** (priority `2`) и **p4** (priority `1`).
  - Число **просроченных** (`due.date < today`).

## Files

### Новые

**`todoist_signals.py`**
- `BrowserHistoryReader` — для каждого Chromium-профиля (Yandex
  `~/Library/Application Support/Yandex/YandexBrowser/Default/History`, Chrome
  `.../Google/Chrome/Default/History`) открывает SQLite в режиме
  `sqlite3.connect("file:<path>?immutable=1", uri=True)` (read-only, без копии и без
  конфликта с WAL-локом запущенного браузера). Запрос
  `SELECT MAX(last_visit_time) FROM urls WHERE url LIKE '%todoist.com%'`; конвертация
  Chrome-эпохи (мкс с 1601-01-01) → `datetime`. Возвращает максимум по профилям.
  Любая ошибка → `None` (fail-safe). Чтение троттлится (≥60 c).
- `TodoistApiClient` — `fetch_tasks(token)` → `GET https://api.todoist.com/rest/v2/tasks`
  с `Authorization: Bearer`, timeout=30. `snapshot_sig(tasks)` (множество id + хэш
  полей content/priority/due) для diff. `dashboard(tasks, cap)` →
  `{p1p2: [...], p3: int, p4: int, overdue: int, total: int}` (priority-маппинг и
  overdue по `due.date`). Все ошибки → лог + None/кэш.

**`engagement_monitor.py`** — `TodoistEngagementMonitor`
- Держит `BrowserHistoryReader`, `TodoistApiClient`, конфиг.
- `update(active_app, now)` каждый тик: фронт-апп==Todoist → `engagement=now`;
  History-read (троттл) → обновить; `poll_if_due()` (троттл `poll_interval_min`,
  неблокирующий поток) → при diff снапшота `engagement=now`, кэшировать snapshot +
  dashboard. `last_engagement = max(...)`, персист в
  `~/.config/work_guard/todoist_state.json` (пережить рестарт).
- `minutes_since(now)`, `dashboard()`, `snapshot_or_none()`, `is_enabled()`
  (`enabled and bool(api_token)`).

**`todoist_overlay.py`** — отдельный subprocess-оверлей (по образцу `overlay.py`:
PyObjC NSPanel, `NSScreenSaverWindowLevel`, на всех экранах). Payload через stdin:
`{message, dashboard, app_path}`. Рендер: заголовок-сообщение + дашборд (NSTextField,
не кликабельные) + две NSButton. «Перейти» → `subprocess` `open -a app_path` →
`terminate`. «Свернуть» → `terminate`. Без countdown/NSTimer. `__main__` для запуска.
Тонкий лаунчер-класс в родителе (Popen + stdin), не трогает overtime-`overlay.py`.

### Правки

**`config.py`** — в `DEFAULTS` (auto-fill при `load_config`, миграции не надо):
```python
"todoist_reminder": {
    "enabled": False,             # opt-in
    "api_token": "",              # секрет, локально
    "idle_threshold_min": 120,
    "poll_interval_min": 5,
    "reminder_cadence_min": 30,
    "history_browsers": ["yandex", "chrome"],
    "frontmost_app_name": "Todoist",
    "open_app_path": "/Applications/Todoist.app",
    "task_list_cap": 10,
},
```

**`work_guard.py`** — точечно в `_tick()` (~705):
- `__init__`: `self.todoist = TodoistEngagementMonitor(cfg)`,
  `self._todoist_next_fire_at = None`, лаунчер `self.todoist_overlay`.
- В начале тика: `self.todoist.update_config(self.cfg)`.
- В ветке `if in_work_time:` (сейчас reset+🟢+return) — перед return:
  `self._check_todoist(now, working)`.
- В ветках выхода из рабочего времени/простоя — `self._todoist_next_fire_at = None`.
- `_check_todoist(now, working)`:
  - `if not self.todoist.is_enabled(): return`
  - `self.todoist.update(active_app, now)` (всегда копим сигнал)
  - `if not working: return`
  - grace: `baseline = max(today_work_start, last_engagement)`;
    `if now < baseline + threshold: return`
  - каденс: `if self._todoist_next_fire_at and now < self._todoist_next_fire_at: return`
  - `mins = self.todoist.minutes_since(now)`; `if mins is None or mins < threshold:`
    отложить чек на 5 мин, return
  - иначе: показать `todoist_overlay` с `dashboard()` (кэш) → лог →
    `self._todoist_next_fire_at = now + reminder_cadence_min`

### Governance / docs
- **`openspec/`** — новый change (напр. `add-todoist-engagement-reminder`):
  proposal + дельта к `workguard-activity-boundary/spec.md` (граница теперь
  допускает **один opt-in сетевой коллектор** под токеном юзера, выключен по
  умолчанию; токен локально, наружу только `api.todoist.com`; браузерный/фронт-апп
  сигналы остаются local/coarse).
- **`CONTEXT.md`** — обновить строку про ActivitySignals (появился первый коллектор).
- **`CLAUDE.md` + `AGENTS.md`** — **убрать beads**: секцию `## Beads`, пункт
  `bd prime` в Session Start, строку `Task tracking: bd / beads` в Source Of Truth
  Map, beads-части в `## OpenSpec and Beads` (OpenSpec оставить). Держать оба файла
  идентичными.

## Failure modes (всё fail-safe — ложно не нудить)
| Случай | Поведение |
|---|---|
| History недоступна / нет прав | `None` → сигнал не падает, ложно не срабатывает |
| Браузер не запущен | immutable-read отдаёт последнее сохранённое |
| Нет токена | API no-op; работают фронт-апп + History |
| API timeout/offline/401 | лог, кэш/None; reminder не фейкается; дашборд из кэша |
| Юзер отошёл (`working=False`) | не показываем |
| `mins is None` / нет данных | отложить, не нудить |
| Todoist.app отсутствует | «Перейти» — `open` тихо фейлится, оверлей всё равно закрыт |

## Verification
1. Debug: `conda run -n work_guard python work_guard.py`.
2. В `config.json`: `enabled=true`, вставить токен, `idle_threshold_min=1`,
   `reminder_cadence_min=1` для быстрого цикла.
3. Не трогать Todoist ~1 мин в рабочее время, будучи за компом → всплывает
   фуллскрин-оверлей с дашбордом (p1+p2 список ≤10, счётчики p3/p4, просрочено).
4. Кнопка «Перейти в Todoist» → открывается `/Applications/Todoist.app`, оверлей
   закрывается; фронт-апп `Todoist` сбрасывает engagement → новый оверлей не лезет.
5. «Свернуть» → закрылся; следующий не раньше `reminder_cadence_min`.
6. Сигналы по отдельности: (a) переключиться в Todoist.app → engagement сброшен;
   (b) открыть todoist.com вкладкой в Яндексе (навигация) → History обновляет;
   (c) завершить задачу с телефона → после поллинга engagement обновляется.
7. Grace: на старте рабочего дня оверлей не лезет до `work_start + порог`.
8. Regression: вне рабочих часов overtime-оверлей работает как раньше; reminder
   не показывается.
9. После убирания beads — `CLAUDE.md`/`AGENTS.md` идентичны и без beads-упоминаний.
