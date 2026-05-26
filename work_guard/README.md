
# WorkGuard

WorkGuard — локальное macOS menu bar приложение, которое следит за переработкой, показывает уведомления и при необходимости поднимает полноэкранный overlay.

Во время переработки доступна лестница отсрочек (20 → 10 → 5 мин): одна позиция в меню с контекстной подписью. Функция «пауза» удалена; настройки расписания, изменённые во время активного периода переработки, применяются только с начала следующего рабочего периода.

## Текущий поддерживаемый путь

Публичный entrypoint один:

```bash
bash rebuild.sh

```

Ожидаемый результат:

- обновлённый runnable app живёт только в `/Applications/WorkGuard.app`
- login startup управляется через `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`
- LaunchAgent использует `/usr/bin/open /Applications/WorkGuard.app`
- `RunAtLoad=true`
- `KeepAlive=false`

Legacy setup script path не является текущим путём. Это obsolete path: не wrapper и не fallback.
`bash setup.sh` завершится с ошибкой и укажет на `bash rebuild.sh`.

## Запуск, остановка, debug

| Действие | Как |
| --- | --- |
| Пересобрать и переустановить | `bash rebuild.sh` |
| Запустить GUI | `open /Applications/WorkGuard.app` |
| Остановить приложение | Пункт меню **«Выйти»** или `bash scripts/stop_workguard.sh` |
| Debug / diagnostics | `conda run -n workguard python3 work_guard.py` (только для отладки) |

Project-local `.app` не считается supported launch target.

## Первичная проверка после rebuild

1. Запусти `bash rebuild.sh`.
2. Открой `/Applications/WorkGuard.app`.
3. Убедись, что в меню появился статус WorkGuard.
4. При необходимости выйди через меню **«Выйти»**.

Если нужно снять старый или сломанный login startup state, используй:

```bash
bash scripts/stop_workguard.sh

```

## Разрешения macOS

После первого запуска нужны:

1. **Accessibility** — для мониторинга клавиатуры и coarse local activity.
2. **Notifications** — для overtime alerts.

Путь в настройках macOS:

`System Settings -> Privacy & Security`

## Настройки и данные

Рабочие данные лежат локально:

- `~/.config/work_guard/config.json`
- `~/.config/work_guard/work_guard.log`
- `~/.config/work_guard/status.json`
- `~/.config/work_guard/command.json`
- `~/.config/work_guard/calendar_ru_<year>.json`

Календарь берётся из `https://xmlcalendar.ru/data/ru/<year>/calendar.json` и кэшируется локально.

## Privacy

- По умолчанию наружу ничего не отправляется.
- Любой export наружу требует явного запроса пользователя.
- Secrets не покидают машину никогда.

## Planned vs current

- **Current:** `bash rebuild.sh` -> `/Applications/WorkGuard.app` -> optional login startup via user LaunchAgent.
- **Planned/documented boundary:** ActivitySignals как future local/coarse-only boundary без collectors/ingestion/export в текущей реализации.
- **Debug only:** direct Python launch.

## Для разработчика

- Архитектурные диаграммы: [docs/architecture/README.md](docs/architecture/README.md)
- Glossary/domain context: [CONTEXT.md](CONTEXT.md)
- Agent instructions: [AGENTS.md](AGENTS.md)
