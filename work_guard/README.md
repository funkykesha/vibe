
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
- `~/.config/work_guard/todoist_state.json` — состояние Todoist-напоминалки (см. ниже)
- `work_guard/.env` — локальные секреты (Todoist token), gitignored; шаблон в `.env.example`

Календарь берётся из `https://xmlcalendar.ru/data/ru/<year>/calendar.json` и кэшируется локально.

### Параметры `config.json`

| Параметр | Тип | По умолчанию | Что значит |
|----------|-----|--------------|------------|
| `current_period_settings` | object | `09:00–19:00`, Пн–Пт | Активное расписание рабочего времени. |
| `current_period_settings.work_start` | `"HH:MM"` | `"09:00"` | Начало рабочего дня. |
| `current_period_settings.work_end` | `"HH:MM"` | `"19:00"` | Конец рабочего дня. В короткий предпраздничный день автоматически −1 час. |
| `current_period_settings.work_days` | list[int] | `[1,2,3,4,5]` | Рабочие дни недели, `1`=Пн … `7`=Вс. Праздники/переносы — из производственного календаря. |
| `pending_period_settings` | object \| null | `null` | Отложенное расписание; применяется автоматически на следующей границе периода (вход в рабочее время). |
| `deferral` | object \| null | `null` | Внутреннее состояние лестницы отсрочки overtime-оверлея. **Управляется приложением — руками не трогать.** |
| `calendar_source` | string | `"xmlcalendar_ru"` | Источник производственного календаря. |
| `calendar_cache_days` | int | `30` | Сколько дней держать кэш календаря до повторной загрузки. |
| `todoist_reminder` | object | см. ниже | Opt-in напоминалка о работе с Todoist. По умолчанию выключена. |

### Параметры `todoist_reminder`

| Параметр | Тип | По умолчанию | Что значит |
|----------|-----|--------------|------------|
| `enabled` | bool | `false` | Включает напоминалку. Пока `false` — модуль инертен, никаких API-вызовов и оверлеев. |
| `idle_threshold_min` | int | `120` | Порог Todoist Non-Interaction Time (мин): сколько в рабочее время не было взаимодействия с Todoist до показа оверлея. Считается wall-clock внутри рабочего окна (обед/простой не паузят). |
| `poll_interval_min` | int | `5` | Период фонового опроса Todoist API (мин). Неблокирующий поток. Влияет только при наличии токена. |
| `reminder_cadence_min` | int | `30` | Каденс повтора: если оверлей свернули, следующий покажется не раньше чем через столько минут. |
| `grace_after_wake_min` | int | `5` | Окно тишины (мин) после старта приложения или пробуждения из сна — не швырять фуллскрин в лицо при открытии крышки; за это время можно самому открыть Todoist. |
| `history_browsers` | list[str] | `["yandex","chrome"]` | Какие Chromium-профили читать на предмет визита `todoist.com` (обычные вкладки; PWA-окно в History не пишет). Поддержка: `yandex`, `chrome`. |
| `frontmost_app_name` | string | `"Todoist"` | Имя фронтального приложения, которое считается просмотром Todoist (`CFBundleName`). Фоновое окно не засчитывается. |
| `open_app_path` | string | `"/Applications/Todoist.app"` | Что открывает кнопка «Перейти в Todoist» (`open -a`). |
| `task_list_cap` | int | `10` | Максимум задач p1+p2 в мини-дашборде; сверх показывается «…ещё N». |

**Токен Todoist** в `config.json` **не хранится** — только в gitignored `work_guard/.env` (`TODOIST_API_TOKEN`) или в переменной окружения процесса. Без токена напоминалка работает по сигналам фронт-аппа и истории браузера; токен добавляет API-сигнал (правки задач с других устройств) и наполняет мини-дашборд.

**`todoist_state.json`** (пишется приложением, руками не трогать): `last_engagement` — время последнего Todoist Interaction; `snapshot_tasks` — последний успешный снимок активных задач; `dashboard` — кэш мини-дашборда. Переживает рестарт в течение дня.

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
