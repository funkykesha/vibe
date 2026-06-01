## Context

WorkGuard — macOS menu bar app (Python core, ~5s monitoring tick in
`work_guard.py:_tick`). Оверлей реализован как subprocess (`overlay.py`,
PyObjC NSPanel). Конфиг — `config.py` (`DEFAULTS` + atomic load/save). Граница
`ActivitySignals` задокументирована, но коллекторов нет. Эта фича добавляет первый
коллектор и первый opt-in исходящий вызов (Todoist API). Целевой пользователь
работает в Todoist через PWA Яндекс.Браузера `/Applications/Todoist.app`
(bundle id `ru.yandex.desktop.yandex-browser.app.dlgoh…`, CFBundleName `Todoist`,
профиль `YandexBrowser/Default`).

> **Эмпирически проверено (2026-06-01):** PWA-окно app-mode Яндекс.Браузера
> **не пишет** свои навигации в общий `YandexBrowser/Default/History`. Запуск
> PWA с загрузкой `app.todoist.com/app/filter/...` дал 0 новых строк в History за
> 3+ мин (при том что DB в это время писалась другими навигациями — служба
> History жива, WAL нет). Существующие `todoist.com/app/*` строки в Default —
> это обычные вкладки браузера, не PWA. Вывод: **History-сигнал ловит только
> навигацию в обычных вкладках, не использование PWA-окна.** Для PWA-центричного
> пользователя просмотр Todoist держится на фронт-апп сигнале (`Todoist` frontmost)
> + API (правки с других устройств); History — вспомогательный сигнал на случай
> работы через обычную вкладку.

## Goals / Non-Goals

**Goals:**
- В рабочее время напоминать фуллскрин-оверлеем при Todoist Non-Interaction Time
  > 2 ч.
- Свести три локальных сигнала в один recency-timestamp.
- Показать мини-дашборд задач (p1+p2 список, счётчики p3/p4, просрочка).
- Ошибки сигналов не засчитывать как Todoist Interaction и не suppress'ить
  reminder сами по себе.
- Не трогать существующий overtime-оверлей.

**Non-Goals:**
- Settings-UI для токена (позже; MVP — правка gitignored `.env`).
- Safari (требовал бы Full Disk Access).
- Пауза порога на время простоя/обеда: время считается wall-clock внутри рабочего
  времени.
- Отдельная модель обеда/перерывов: внутри рабочего окна Todoist Non-Interaction
  Time идёт wall-clock.
- Эскалация интенсивности оверлея.
- Активная-вкладка через `osascript` (заменено чтением History).

## Decisions

**D1. Три сигнала, `last_engagement = max(...)`, recency-timestamp.**
Фронт-апп `Todoist` ловит активный просмотр PWA (frontmost) — **основной** сигнал
для PWA-центричного пользователя; History ловит навигации в **обычных вкладках**
браузера (не PWA-окно — см. Context, эмпирически проверено) и считается interaction
без проверки active tab; API ловит правки с других устройств.
Альтернатива (только API) отвергнута: не видит просмотры; альтернатива (только
браузер) — не видит ни мобильные правки, ни просмотр в PWA-окне.

**D2. Чтение History через `sqlite3` URI `immutable=1`, read-only, без копии.**
Chromium лочит History (WAL) при запущенном браузере. `immutable=1` читает без
лока и без копирования 43 МБ-базы Яндекса. Возможна минутная задержка свежести WAL
— приемлемо при пороге 2 ч. Конвертация Chrome-эпохи (мкс с 1601). Троттл чтения
≥60 c. Профили Chromium вне TCC-зоны → **без Full Disk Access**.
Scope-уточнение (2026-06-01, эмпирически): этот сигнал покрывает только
todoist.com в обычных вкладках; PWA-окно app-mode в History не пишет. Не
архитектурный блокер — fallback на фронт-апп/API, — но History нельзя считать
покрытием PWA-просмотра.

**D3. API: snapshot-`updated_at` diff — основной recency; completed/deleted — вторичный.**
(Пересмотрено 2026-06-01 после сверки с реальными доками Todoist API v1.)
Фоновый polling запрашивает active tasks через `GET /api/v1/tasks` (cursor-пагинация,
пройти все страницы), сохраняет последний успешный Todoist Task Snapshot; overlay
рендерит этот snapshot, не live-fetch.

**Основной API-recency-источник — snapshot-diff по `updated_at`.** Сервер бампает
`updated_at` задачи только при реальной серверной мутации; «текущая итерация»
recurring-задачи — клиентское вычисление, `updated_at` не трогает. Поэтому сдвиг
`updated_at` между снапшотами = реальная правка задачи (priority/due/content/move) =
Todoist Interaction. Это покрывает больше кейсов, чем activity log.

**Почему НЕ activity log как основной (исправление прошлой версии):**
- v1 `/api/v1/activities` фильтруется параметрами `object_type`(single)/`object_id`/
  `event_type`; параметра-списка `object_event_types` (Sync-v9) в v1 НЕТ.
- Для items activity log логирует только added/updated/deleted/completed/uncompleted,
  причём `updated` — **только** изменения `content`/`description`/`due_date`/
  `responsible_uid`. `item:moved`/`item:reordered`/смена priority в activity НЕ
  приходят. Опираться на них (как в прошлой версии) — ошибка.
- `old_item`/`update_intent` документированы в секции **webhooks**, не гарантированы
  в `/activities` response → детект system-change через них ненадёжен.

**Роль activity/completed сведена к вторичной:** snapshot-diff не видит исчезнувшие
задачи (completed/deleted), т.к. их нет в active-списке. Их recency берём из
`GET /api/v1/tasks/completed/by_completion_date` (`completed_at`; **оба** `since`+
`until` обязательны) и из `/activities` (`object_type=item`, клиентский фильтр
`event_type==deleted` + `event_date>=since`).

**System-change-detection убрана** (была: `is_system_change`/`update_intent`/
`old_item`). Вместо неё узкий guard: если у задачи изменился ТОЛЬКО `due` И
`due.is_recurring==true` И нет нового `completed_at`/deleted на этой id → вероятный
авто-rollover, не считать interaction. Нужность guard'а проверяется эмпирически
(task 7.10a): если сервер не бампает `updated_at` при rollover без действий юзера —
guard удаляется.

API-сигнал активен только при непустом token; без token reminder работает по
app/browser сигналам. Не используем Sync incremental (sync_token + холодный старт
даёт ложный full-diff). Priority-маппинг REST (подтверждён доками: «p1 returns 4»):
`4`=p1, `3`=p2, `2`=p3, `1`=p4. Overdue = `due.date < today`. Lookback completed/
deleted = `idle_threshold_min + poll_interval_min + 5 min`. Поллинг троттлится
`poll_interval_min` (5), неблокирующий поток (thread-safety — D6).

**D4. Оверлей — отдельный модуль `todoist_overlay.py`, не расширяем `overlay.py`.**
Разные UX: overtime — блок с таймером и эскалацией; reminder — без таймера, 2 кнопки,
дашборд. Изоляция исключает регресс overtime. Тот же subprocess/stdin-паттерн.
Список задач — `NSTextField` (не кликабельный). Кнопки — `NSButton`: «Перейти» →
`open -a /Applications/Todoist.app` + terminate + немедленный Todoist Interaction
в parent state; «Свернуть» → terminate без сброса interaction. Так как overlay
живёт в subprocess, launcher должен получить результат действия (например,
stdout/json result или маленький action-файл) и только для open-action обновить
`last_engagement` сразу, не ожидая следующего monitoring tick.

**D5. Интеграция в ветке `if in_work_time:` (не overtime).** Reminder и overtime
временно взаимоисключающие (overtime фактически при `in_work_time == False`) →
конфликта показа нет. Anti-spam через `self._todoist_next_fire_at` (паттерн как
`deferral.next_overlay_at`). Нет `working`/`user_active` gate: активная работа в
другом приложении и бездействие за компьютером одинаково считаются Todoist
Non-Interaction Time, пока нет Todoist Interaction.

**Wake-grace (пересмотрено 2026-06-01):** при старте процесса или пробуждении из
сна reminder подавляется первые `grace_after_wake_min` (5). `last_engagement`
переживает рестарт (D6), поэтому без grace при открытии крышки в рабочее время
фуллскрин прилетал бы в лицо мгновенно (last_engagement = вчера). Grace даёт окно
самому открыть Todoist; если за окно был Interaction — reminder не нужен. Детект
wake — gap между monitoring tick'ами > порога. Обед без сна крышки (комп не спал)
grace НЕ покрывает — осознанно (Non-Goals: wall-clock внутри рабочего окна).

**D6. Персист состояния в `~/.config/work_guard/todoist_state.json`.**
`last_engagement` + Todoist Task Snapshot + dashboard переживают рестарт в течение
дня; для API-мутаций хранится Todoist Change Time, а не только poll time.
**Thread-safety:** poll-поток пишет state, main tick читает — общее состояние под
`threading.Lock`, поток делает atomic-swap новых значений; запись файла atomic
(temp + `os.rename`) под тем же локом.

## Risks / Trade-offs

- [Токен покидает машину к `api.todoist.com`] → opt-in, выключен по умолчанию, токен
  только локально в gitignored `.env`, в логи не пишется, отправляется лишь на свой
  эндпоинт; зафиксировано дельтой privacy-boundary.
- [Чужой профиль Chromium / другой путь History] → пути в конфиге; ошибка чтения →
  `None`, это не Todoist Interaction и не suppress-гейт.
- [TCC-промпт на новом macOS при первом чтении] → одноразовое подтверждение; до
  выдачи — сигнал History просто отсутствует, это не Todoist Interaction.
- [WAL-задержка свежести History] → допустимо при пороге 2 ч; фронт-апп сигнал
  компенсирует активный просмотр.
- [PWA-окно не пишет в History — эмпирически проверено 2026-06-01] → History ловит
  только обычные вкладки; PWA-просмотр держится на фронт-апп сигнале (`Todoist`
  frontmost) + API. Mitigation уже встроена в D1 (три независимых сигнала, `max`).
  Деградация: если пользователь смотрит задачи в PWA-окне, которое НЕ frontmost
  (фоном), и не правит их — interaction не зафиксируется; считается приемлемым,
  т.к. чтение задач требует фокуса окна.
- [Много p1/p2 задач] → кап 10 + «…ещё N».
- [Todoist.app отсутствует] → `open` тихо фейлится, оверлей всё равно закрывается.
- [Холодный старт API без снапшота] → первый поллинг устанавливает базовый снапшот
  и может обновить engagement реальным Todoist Change Time (`updated_at`,
  `completed_at`, deleted activity event time), кроме System Todoist Change; полный
  initial snapshot не считается interaction at `now`.
- [Overlay показан после API error] → используется последний успешный Todoist Task
  Snapshot; ошибка не запускает live-fetch и не suppress'ит reminder.
- [Overlay показан до первого snapshot] → показывается простой reminder без деталей
  задач; отсутствие snapshot не suppress-гейт.

## Migration Plan

- Чистое добавление, дефолт выключен → нулевой эффект на текущих пользователей.
- Включение: правка `config.json` (`enabled=true`) + при необходимости gitignored
  `.env` (`TODOIST_API_TOKEN=...`) + `bash rebuild.sh`; token добавляет API-сигнал,
  но не обязателен для app/browser reminder.
- Откат: `enabled=false` или удаление секции; новые модули инертны.
- Сопутствующее: обновить строку про `ActivitySignals` в `CONTEXT.md`.

## Open Questions

- Settings-UI для токена — отдельная задача после MVP.
- Активное-время вместо wall-clock явно не входит в текущий intent.
- Нужен ли recurring-due guard (2.5a) — зависит от эмпирики `updated_at` при
  авто-rollover (task 7.10a).
- Сверка с параллельной change `add-overlay-deferral-period-policy` на предмет
  взаимодействия reminder ↔ overtime/deferral в `_tick` (task 7.10b, архивно).
- Beads-removal из `CLAUDE.md`/`AGENTS.md` вынесен из этой change — будет отдельной
  сессией/change (scope: фича = коллектор активности, не task-tracking governance).
