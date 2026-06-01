## 1. Config

- [ ] 1.1 Добавить секцию `todoist_reminder` в `config.py` `DEFAULTS` (enabled=false, idle_threshold_min=120, poll_interval_min=5, reminder_cadence_min=30, history_browsers=["yandex","chrome"], frontmost_app_name="Todoist", open_app_path="/Applications/Todoist.app", task_list_cap=10); token не хранить в `config.json`
- [ ] 1.2 Проверить auto-fill при `load_config` для старых конфигов без секции
- [ ] 1.3 Читать Todoist token из gitignored `.env` (`TODOIST_API_TOKEN`) / process env; не логировать значение
- [ ] 1.4 Добавить `.env` в `.gitignore` и `.env.example` без секретов

## 2. Сигналы (`todoist_signals.py`)

- [ ] 2.1 `BrowserHistoryReader`: пути профилей Yandex/Chrome, чтение через `sqlite3.connect("file:<path>?immutable=1", uri=True)`, `SELECT MAX(last_visit_time) ... LIKE '%todoist.com%'`, конвертация Chrome-эпохи → datetime, троттл ≥60c, ошибки → None
- [ ] 2.2 `TodoistApiClient.fetch_tasks(token)`: `GET /api/v1/tasks` с Bearer, timeout=30, ошибки → None/лог
- [ ] 2.3 `TodoistApiClient.fetch_completed(token, since, until)`: `GET /api/v1/tasks/completed/by_completion_date`, where `since=now-(idle_threshold_min+poll_interval_min+5min)`, ошибки → None/лог
- [ ] 2.4 `TodoistApiClient.fetch_task_activity(token, since, until)`: `GET /api/v1/activities` с `object_event_types=["item:added","item:updated","item:moved","item:reordered","item:completed","item:deleted","item:uncompleted"]`, paginate until events older than `since=now-(idle_threshold_min+poll_interval_min+5min)`, ошибки → None/лог
- [ ] 2.5 `TodoistApiClient.snapshot_sig(tasks)`: множество id + хэш полей (content/priority/due/updated_at) для dashboard/cache comparison
- [ ] 2.5a `TodoistApiClient.is_system_change(activity)`: использовать activity `event_type`, `event_date`, `extra_data` / `event_data_extra`, `old_item`, `update_intent`; распознать автоматический recurring due-date reschedule как system change
- [ ] 2.6 `TodoistApiClient.recent_api_change_time(completed, activities)`: max Todoist Change Time (`completed_at`, activity `event_date`) по non-system changes
- [ ] 2.7 `TodoistApiClient.dashboard(tasks, cap)`: список p1+p2 (priority 4,3) с капом + overflow, счётчики p3/p4 (priority 2,1), overdue по `due.date < today`

## 3. Агрегатор (`engagement_monitor.py`)

- [ ] 3.1 `TodoistEngagementMonitor`: хранит reader/client/config/env, `update_config`, `is_enabled` (enabled), `api_enabled` (`TODOIST_API_TOKEN` непустой)
- [ ] 3.2 `update(active_app, now)`: фронт-апп==Todoist→engagement=now; History (троттл); `poll_if_due` только при `api_enabled` (периодический неблокирующий фоновой polling) с activity/completed recency→engagement=max Todoist Change Time (`event_date`, `completed_at`) по non-system changes и кэш последнего успешного Todoist Task Snapshot + dashboard
- [ ] 3.2a Не засчитывать background-running Todoist как interaction; app-сигнал только по frontmost name
- [ ] 3.3 Холодный старт поллинга: первый active snapshot не считается interaction at `now`; engagement обновляется реальными Todoist Change Time из active (`updated_at`), completed (`completed_at`) и deleted activity данных, кроме System Todoist Change
- [ ] 3.4 Персист/загрузка `~/.config/work_guard/todoist_state.json` (last_engagement, последний успешный Todoist Task Snapshot, dashboard)
- [ ] 3.5 `minutes_since(now)`, `dashboard()`

## 4. Оверлей (`todoist_overlay.py`)

- [ ] 4.1 Subprocess-оверлей по образцу `overlay.py`: NSPanel, screensaver level, все экраны, payload через stdin {message, dashboard, app_path}, без NSTimer
- [ ] 4.2 Рендер дашборда из последнего успешного Todoist Task Snapshot: NSTextField (не кликабельные) — список p1+p2, счётчики p3/p4, overdue; если snapshot отсутствует, показать простой reminder без деталей задач
- [ ] 4.3 Кнопки NSButton: «Перейти в Todoist» → `open -a app_path` + terminate + result `open`; «Свернуть оверлей» → terminate + result `dismiss` без сброса last_engagement
- [ ] 4.4 Тонкий лаунчер-класс в родителе (Popen + stdin + чтение action result из subprocess)

## 5. Интеграция (`work_guard.py`)

- [ ] 5.1 `__init__`: создать `TodoistEngagementMonitor`, лаунчер оверлея, `self._todoist_next_fire_at=None`
- [ ] 5.2 В `_tick` начало: `todoist.update_config(self.cfg)`; в ветке `if in_work_time:` перед return вызвать `_check_todoist(now)`; при выходе из рабочего времени сбрасывать `_todoist_next_fire_at`
- [ ] 5.3 `_check_todoist`: is_enabled→update→`last_engagement is None or now-last_engagement >= threshold`→каденс-gate→показать оверлей с cached dashboard, иначе отложить 5 мин; morning check использует тот же recency rule без отдельной grace; после показа `next_fire=now+reminder_cadence_min`; не добавлять `working`/`user_active` gate
- [ ] 5.4 При result `open` от Todoist overlay немедленно обновить `last_engagement=now`, персист и не армить cadence сверх normal threshold; при result `dismiss` не обновлять `last_engagement`, только оставить cadence

## 6. Доки и governance

- [ ] 6.1 `CONTEXT.md`: обновить строку про `ActivitySignals` (первый opt-in коллектор)
- [ ] 6.2 Убрать Beads из `CLAUDE.md` и `AGENTS.md` (секция Beads, `bd prime` в Session Start, Task tracking в Source Of Truth Map, beads-части в OpenSpec and Beads); держать файлы идентичными; OpenSpec оставить

## 7. Верификация

- [ ] 7.1 Debug-запуск с `idle_threshold_min=1`, `reminder_cadence_min=1`, токеном → оверлей всплывает через ~1 мин Todoist Non-Interaction Time в рабочее время, независимо от активности за компьютером
- [ ] 7.2 Кнопки: «Перейти» открывает Todoist.app и закрывает оверлей; «Свернуть» закрывает и армит каденс
- [ ] 7.3 Сигналы по отдельности: фронт-апп Todoist; навигация todoist.com в Яндексе (History); правка задачи с телефона (API) — каждый сбрасывает engagement
- [ ] 7.4 Morning check: при первом tick в рабочее время после открытия ноутбука/возобновления WorkGuard, если последняя Todoist Interaction свежее threshold — overlay не показывается; если старше threshold или отсутствует — показывается сразу; regression: overtime-оверлей вне рабочих часов работает как раньше
- [ ] 7.5 Enabled без `TODOIST_API_TOKEN`: нет API-вызовов, app/browser сигналы работают, reminder может показаться по Todoist Non-Interaction Time
- [ ] 7.6 API/History error: недоступный сигнал логируется, не сбрасывает Todoist Non-Interaction Time и не suppress'ит reminder
- [ ] 7.7 Overlay dashboard: при показе использует последний успешный Todoist Task Snapshot; API error перед показом не очищает dashboard
- [ ] 7.8 Overlay без snapshot: показывается reminder overlay без деталей задач
- [ ] 7.9 `bash rebuild.sh`, проверить отсутствие беды с TCC (при необходимости разовый промпт), `openspec validate --changes add-todoist-engagement-reminder`
