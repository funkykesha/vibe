## Context

WorkGuard — macOS menu bar app (Python core, ~5s monitoring tick in
`work_guard.py:_tick`). Оверлей реализован как subprocess (`overlay.py`,
PyObjC NSPanel). Конфиг — `config.py` (`DEFAULTS` + atomic load/save). Граница
`ActivitySignals` задокументирована, но коллекторов нет. Эта фича добавляет первый
коллектор и первый opt-in исходящий вызов (Todoist API). Целевой пользователь
работает в Todoist через PWA Яндекс.Браузера `/Applications/Todoist.app`
(bundle id `ru.yandex.desktop.yandex-browser.app.dlgoh…`, CFBundleName `Todoist`,
общий профиль `YandexBrowser/Default`).

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
Фронт-апп `Todoist` ловит активный просмотр PWA без навигации; History ловит
навигации (вкладки и PWA, общий профиль) и считается interaction без проверки
active tab; API ловит правки с других устройств.
Альтернатива (только API) отвергнута: не видит просмотры; альтернатива (только
браузер) — не видит мобильные правки.

**D2. Чтение History через `sqlite3` URI `immutable=1`, read-only, без копии.**
Chromium лочит History (WAL) при запущенном браузере. `immutable=1` читает без
лока и без копирования 43 МБ-базы Яндекса. Возможна минутная задержка свежести WAL
— приемлемо при пороге 2 ч. Конвертация Chrome-эпохи (мкс с 1601). Троттл чтения
≥60 c. Профили Chromium вне TCC-зоны → **без Full Disk Access**.

**D3. API: active tasks для dashboard + activity/completed sources для recency.**
Фоновый polling периодически запрашивает active tasks через `GET /api/v1/tasks` и
сохраняет последний успешный Todoist Task Snapshot; overlay рендерит именно этот
последний snapshot, а не делает live-fetch при показе. Recency API-сигнала берётся
из Todoist-provided event/change time, а не из времени poll: activity log
`GET /api/v1/activities` с task event filters (`item:added`, `item:updated`,
`item:moved`, `item:reordered`, `item:completed`, `item:deleted`,
`item:uncompleted`) даёт `event_date`,
`initiator_id`, `extra_data`; для `item:updated` docs указывают extra data с
`old_item` и `update_intent`, что позволяет отличать user-visible update от System
Todoist Change вроде автоматического recurring due-date reschedule. Recent
completed tasks также можно сверять через
`GET /api/v1/tasks/completed/by_completion_date` и `completed_at`.

Снапшот active tasks = множество id + хэш полей (content/priority/due/updated_at).
User-visible мутация → Todoist Interaction; System Todoist Change не считается
interaction. Move/reorder events считаются Todoist Interaction. API-сигнал активен
только при непустом token; без token reminder
продолжает работать по app/browser сигналам. Не используем Sync incremental
(сложный sync_token + холодный старт даёт ложный full-diff). Priority-маппинг
REST: `4`=p1, `3`=p2, `2`=p3, `1`=p4. Overdue = `due.date < today`.
Completed/deleted/activity lookback = `idle_threshold_min + poll_interval_min + 5 min`,
потому что более старые события уже не блокируют reminder. Поллинг троттлится
`poll_interval_min` (по умолчанию 5), неблокирующий поток.

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
Non-Interaction Time, пока нет Todoist Interaction. Grace:
отсутствует для начала рабочего дня: первый доступный tick в рабочее время
проверяет последнюю Todoist Interaction. Если она свежее `now - threshold`,
overlay не показывается; если старше или отсутствует, overlay показывается сразу.

**D6. Персист состояния в `~/.config/work_guard/todoist_state.json`.**
`last_engagement` + Todoist Task Snapshot + dashboard переживают рестарт в течение
дня; для API-мутаций хранится Todoist Change Time, а не только poll time.

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
- Сопутствующее: удалить Beads из `CLAUDE.md`/`AGENTS.md` (OpenSpec остаётся),
  обновить строку про `ActivitySignals` в `CONTEXT.md`.

## Open Questions

- Settings-UI для токена — отдельная задача после MVP.
- Активное-время вместо wall-clock явно не входит в текущий intent.
