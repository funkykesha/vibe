## Why

WorkGuard сейчас защищает только от переработки (оверлей вне рабочих часов). Нет
обратной защиты — от «залипания» в работе с потерей связи с планом задач. Нужно в
рабочее время отслеживать взаимодействие с Todoist и, если давно не было
Todoist Interaction, показывать фуллскрин-оверлей с мини-дашбордом задач. Это
первый реальный коллектор для до сих пор пустой границы `ActivitySignals`.

## What Changes

- Новый opt-in (по умолчанию выключенный) модуль мониторинга вовлечённости в Todoist
  с тремя локальными сигналами: фронтальное приложение `Todoist`, последний визит на
  `todoist.com` из истории Chromium-браузеров (Yandex, Chrome), и изменения задач
  через Todoist REST API.
- Новый тип фуллскрин-оверлея (без таймера) с двумя кнопками («Перейти в Todoist» →
  `open -a /Applications/Todoist.app`, «Свернуть оверлей») и не кликабельным
  мини-дашбордом: развёрнутый список задач p1+p2 (кап 10), счётчики p3/p4, число
  просроченных.
- Reminder срабатывает только в рабочее время, при Todoist Non-Interaction Time
  > 2 ч; активность или бездействие за компьютером не suppress-гейт; утром нет
  ожидания порога: при первой проверке рабочего периода overlay показывается
  сразу, если с начала периода не было Todoist Interaction; каденс повтора 30 мин.
- **BREAKING (intent):** граница `ActivitySignals` перестаёт быть «no collectors» —
  вводится первый коллектор. Впервые добавляется opt-in исходящий вызов с секретом
  (Todoist API token к `api.todoist.com`), хранится локально в gitignored `.env`.
- Удаление Beads из `CLAUDE.md`/`AGENTS.md` (task-tracking через beads больше не
  используется; OpenSpec остаётся).

## Capabilities

### New Capabilities
- `todoist-engagement-reminder`: локальный opt-in мониторинг Todoist Interaction
  (фронт-апп + история браузера + API-изменения) и фуллскрин reminder-оверлей с
  мини-дашбордом задач при Todoist Non-Interaction Time сверх порога в рабочее
  время.

### Modified Capabilities
- `workguard-activity-boundary`: граница `ActivitySignals` теперь допускает один
  opt-in локальный коллектор (выключен по умолчанию), оставаясь coarse-grained.
- `workguard-privacy-boundary`: явно разрешён единственный opt-in исходящий вызов —
  Todoist API под токеном, который настроил пользователь (это и есть его явный
  запрос на передачу); секрет остаётся локально, иные исходящие передачи запрещены.

## Impact

- Новые модули: `todoist_signals.py`, `engagement_monitor.py`, `todoist_overlay.py`.
- Правки: `work_guard.py` (`_tick` wiring), `config.py` (секция `todoist_reminder`),
  `.gitignore`, `.env.example`, `CONTEXT.md`, `CLAUDE.md`, `AGENTS.md`.
- Новый файл состояния `~/.config/work_guard/todoist_state.json`.
- Внешняя зависимость: Todoist API (`api.todoist.com`, текущие REST endpoints
  `/api/v1/...`), бесплатный тариф.
- Чтение History Chromium-профилей read-only (`immutable=1`), без Full Disk Access.
