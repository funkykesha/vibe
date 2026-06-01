## 1. Config

- [x] 1.1 Добавить секцию `todoist_reminder` в `config.py` `DEFAULTS` (enabled=false, idle_threshold_min=120, poll_interval_min=5, reminder_cadence_min=30, grace_after_wake_min=5, history_browsers=["yandex","chrome"], frontmost_app_name="Todoist", open_app_path="/Applications/Todoist.app", task_list_cap=10); token не хранить в `config.json`
- [x] 1.2 Проверить auto-fill при `load_config` для старых конфигов без секции
- [x] 1.3 Читать Todoist token из gitignored `.env` (`TODOIST_API_TOKEN`) / process env; не логировать значение
- [x] 1.4 Добавить `.env` в `.gitignore` и `.env.example` без секретов

## 2. Сигналы (`todoist_signals.py`)

- [x] 2.1 `BrowserHistoryReader`: пути профилей Yandex/Chrome, чтение через `sqlite3.connect("file:<path>?immutable=1", uri=True)`, `SELECT MAX(last_visit_time) ... LIKE '%todoist.com%'`, конвертация Chrome-эпохи → datetime, троттл ≥60c, ошибки → None
- [x] 2.2 `TodoistApiClient.fetch_tasks(token)`: `GET /api/v1/tasks` с Bearer, timeout=30, **cursor-пагинация** — пройти все страницы по `next_cursor` (иначе только первая страница), вернуть полный список active tasks; ошибки → None/лог
- [x] 2.3 `TodoistApiClient.fetch_completed(token, since, until)`: `GET /api/v1/tasks/completed/by_completion_date`, **оба параметра `since` И `until` обязательны** (ISO `...Z`), `since=now-(idle_threshold_min+poll_interval_min+5min)`, `until=now`, cursor-пагинация по `next_cursor`, ошибки → None/лог
- [x] 2.4 `TodoistApiClient.fetch_deleted_activity(token, since)`: `GET /api/v1/activities` с `object_type=item`, cursor-пагинация (param `cursor`+`limit`, **нет `since`-параметра**), **клиентский** фильтр по `event_type in {deleted}` и `event_date >= since=now-(idle_threshold_min+poll_interval_min+5min)`, остановка пагинации когда `event_date < since`; роль — только удаления (completed берём из 2.3); ошибки → None/лог. ПРИМ.: `object_event_types`-список — это Sync-v9 синтаксис, в v1 его нет; для items activity log логирует только added/updated/deleted/completed/uncompleted (move/reorder/priority в activity НЕ приходят)
- [x] 2.5 `TodoistApiClient.snapshot_sig(tasks)`: map `id → (updated_at, content/priority/due-хэш)` — **основной** API-recency-источник: diff против предыдущего snapshot ловит любую правку active-задачи (priority/due/content/move), т.к. сервер бампает `updated_at` только при реальной мутации
- [x] 2.5a `TodoistApiClient.recurring_due_only_change(prev_task, cur_task)`: guard — вернуть True, если у задачи изменился **только** `due` И `cur.due.is_recurring==true` И на этой `id` нет нового `completed_at`/deleted-события → вероятный авто-rollover срока, НЕ считать interaction. Иначе любой сдвиг `updated_at` = interaction. (Проверить эмпирически нужен ли guard — см. 7.10a)
- [x] 2.6 `TodoistApiClient.recent_api_change_time(prev_snapshot, cur_snapshot, completed, deleted_activity)`: `max` из — `updated_at` задач со сдвигом snapshot-хэша (минус recurring-due-only guard 2.5a), `completed_at` (2.3), `event_date` deleted-событий (2.4)
- [x] 2.7 `TodoistApiClient.dashboard(tasks, cap)`: список p1+p2 (priority 4,3) с капом + overflow, счётчики p3/p4 (priority 2,1), overdue по `due.date < today`

## 3. Агрегатор (`engagement_monitor.py`)

- [x] 3.1 `TodoistEngagementMonitor`: хранит reader/client/config/env, `update_config`, `is_enabled` (enabled), `api_enabled` (`TODOIST_API_TOKEN` непустой)
- [x] 3.2 `update(active_app, now)`: фронт-апп==Todoist→engagement=now; History (троттл); `poll_if_due` только при `api_enabled` (периодический неблокирующий фоновой поток) — snapshot-diff `updated_at` (основной, 2.5/2.6) + completed (2.3) + deleted activity (2.4) → engagement=max Todoist Change Time; кэш последнего успешного Todoist Task Snapshot + dashboard
- [x] 3.2a Не засчитывать background-running Todoist как interaction; app-сигнал только по frontmost name
- [x] 3.2b **Thread-safety:** poll-поток пишет `last_engagement`/snapshot/dashboard, main tick читает. Защитить общее состояние `threading.Lock`; поток вычисляет новые значения, затем atomic-swap под локом; main `_check_todoist` читает копию под локом
- [x] 3.3 Холодный старт поллинга: первый active snapshot = база, НЕ interaction at `now`; дальше любой сдвиг `updated_at` (минус recurring-due guard 2.5a) / новый `completed_at` / deleted-событие = interaction по реальному Todoist Change Time
- [x] 3.4 Персист/загрузка `~/.config/work_guard/todoist_state.json` (last_engagement, последний успешный Todoist Task Snapshot, dashboard) — запись atomic (temp-файл + `os.rename`), под тем же локом что 3.2b
- [x] 3.5 `minutes_since(now)`, `dashboard()`

## 4. Оверлей (`todoist_overlay.py`)

- [x] 4.1 Subprocess-оверлей по образцу `overlay.py`: NSPanel, screensaver level, все экраны, payload через stdin {message, dashboard, app_path}, без NSTimer
- [x] 4.2 Рендер дашборда из последнего успешного Todoist Task Snapshot: NSTextField (не кликабельные) — список p1+p2, счётчики p3/p4, overdue; если snapshot отсутствует, показать простой reminder без деталей задач
- [x] 4.3 Кнопки NSButton: «Перейти в Todoist» → `open -a app_path` + terminate + result `open`; «Свернуть оверлей» → terminate + result `dismiss` без сброса last_engagement
- [x] 4.4 Тонкий лаунчер-класс в родителе (Popen + stdin + чтение action result из subprocess)

## 5. Интеграция (`work_guard.py`)

- [x] 5.1 `__init__`: создать `TodoistEngagementMonitor`, лаунчер оверлея, `self._todoist_next_fire_at=None`
- [x] 5.2 В `_tick` начало: `todoist.update_config(self.cfg)`; в ветке `if in_work_time:` перед return вызвать `_check_todoist(now)`; при выходе из рабочего времени сбрасывать `_todoist_next_fire_at`
- [x] 5.3 `_check_todoist`: is_enabled→update→`last_engagement is None or now-last_engagement >= threshold`→каденс-gate→показать оверлей с cached dashboard, иначе отложить 5 мин; после показа `next_fire=now+reminder_cadence_min`; не добавлять `working`/`user_active` gate
- [x] 5.3a **Wake-grace:** при старте процесса ИЛИ пробуждении из сна (детект gap между tick'ами > порога) не показывать reminder первые `grace_after_wake_min` (5); дать юзеру шанс самому открыть Todoist; если за это окно был Todoist Interaction — reminder не нужен. Цель — не швырять фуллскрин в лицо при открытии крышки. ПРИМ.: обед без сна крышки (комп не спал) grace НЕ покрывает — осознанно (D5/Non-Goals)
- [x] 5.4 При result `open` от Todoist overlay немедленно обновить `last_engagement=now`, персист и не армить cadence сверх normal threshold; при result `dismiss` не обновлять `last_engagement`, только оставить cadence

## 6. Доки и governance

- [x] 6.1 `CONTEXT.md`: обновить строку про `ActivitySignals` (первый opt-in коллектор)

## 7. Верификация

- [x] 7.1 Debug-запуск с `idle_threshold_min=1`, `reminder_cadence_min=1`, токеном → оверлей всплывает через ~1 мин Todoist Non-Interaction Time в рабочее время, независимо от активности за компьютером
- [x] 7.2 Кнопки: «Перейти» открывает Todoist.app и закрывает оверлей; «Свернуть» закрывает и армит каденс
- [x] 7.3 Сигналы по отдельности: фронт-апп Todoist (покрывает PWA-окно); навигация todoist.com в **обычной вкладке** Яндекса (History — PWA-окно в History не пишет, проверено 2026-06-01); правка задачи с телефона (API) — каждый сбрасывает engagement
- [x] 7.4 Morning check + wake-grace: после открытия крышки/возобновления в рабочее время reminder НЕ показывается первые `grace_after_wake_min`; если за окно был Todoist Interaction — не показывается совсем; иначе по истечении grace, если последняя Todoist Interaction старше threshold или отсутствует — показывается; regression: overtime-оверлей вне рабочих часов работает как раньше
- [x] 7.5 Enabled без `TODOIST_API_TOKEN`: нет API-вызовов, app/browser сигналы работают, reminder может показаться по Todoist Non-Interaction Time
- [x] 7.6 API/History error: недоступный сигнал логируется, не сбрасывает Todoist Non-Interaction Time и не suppress'ит reminder
- [x] 7.7 Overlay dashboard: при показе использует последний успешный Todoist Task Snapshot; API error перед показом не очищает dashboard
- [x] 7.8 Overlay без snapshot: показывается reminder overlay без деталей задач
- [x] 7.9 `bash rebuild.sh`, проверить отсутствие беды с TCC (при необходимости разовый промпт), `openspec validate --changes add-todoist-engagement-reminder`
- [x] 7.10 PWA→History assumption проверена эмпирически (2026-06-01): PWA app-mode окно НЕ пишет навигации в `Default/History`. Результат зафиксирован в design.md (Context/D1/D2/Risks). History-сигнал = только обычные вкладки.
- [x] 7.10a ~~Эмпирически проверить авто-rollover recurring-задачи~~ — снято. Guard 2.5a оставлен как безопасный узкий no-op (срабатывает только при изменении ровно `due` у recurring без completed/deleted); наблюдение не блокирует архив
- [x] 7.10b Свериться с параллельной change `add-overlay-deferral-period-policy`: D5 предполагает «overtime только при `in_work_time==False`»; убедиться что deferral-логика не сдвинула это и reminder не конфликтует с overtime/deferral в `_tick` (архивно, низкий приоритет). Проверено: параллельная change удалена из дерева; overtime/deferral срабатывают только в ветке `not in_work_time`, reminder — только в `if in_work_time:`, ветки взаимоисключающие → конфликта нет
