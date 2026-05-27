## ADDED Requirements

### Requirement: Process model
Система SHALL запускать один long-running Node.js процесс, который объединяет HTTP API, sampling-scheduler и раздачу собранного фронтенда. Процесс MUST биндиться на `127.0.0.1` (по умолчанию) и порт `9876` (по умолчанию). Процесс MUST поддерживаться launchd через plist-файл с абсолютным путём к `node`.

#### Scenario: Default server start
- **WHEN** запускается `node server/index.mjs server` без флагов
- **THEN** Fastify слушает на `127.0.0.1:9876`
- **AND** scheduler инициализируется с `interval_min = SPEED_INTERVAL_MIN` (default 30)
- **AND** первый замер не выполняется сразу — только по таймеру или ручному триггеру

#### Scenario: Custom host/port via flags
- **WHEN** запускается `node server/index.mjs server --host 0.0.0.0 --port 9877`
- **THEN** сервер слушает на `0.0.0.0:9877`

### Requirement: CLI subcommands
Система SHALL предоставлять CLI с тремя подкомандами: `doctor`, `sample`, `server`. Семантика подкоманд MUST совпадать с текущей Python-версией.

#### Scenario: Doctor checks environment
- **WHEN** выполняется `node server/index.mjs doctor`
- **THEN** проверяется наличие `networkQuality`, `curl`, `ping`, `route`, `ifconfig` в PATH
- **AND** проверяется существование/создаваемость `data/` и `logs/`
- **AND** выводится список найденных сетевых интерфейсов
- **AND** код выхода 0 если всё ок, иначе ненулевой

#### Scenario: One-shot sample
- **WHEN** выполняется `node server/index.mjs sample`
- **THEN** выполняется один VPN-замер и один modem-замер
- **AND** обе записи добавляются в `data/speed-tests.ndjson`
- **AND** результат печатается в stdout как JSON
- **AND** процесс завершается после замера

### Requirement: Environment variables
Система SHALL читать те же env vars, что и текущая Python-версия. `SPEED_MODEM_IFACE` MUST переопределять интерфейс для modem-профиля (по умолчанию `en0`). `SPEED_INTERVAL_MIN` MUST переопределять стартовый интервал sampling в минутах (по умолчанию `30`).

#### Scenario: Modem interface override
- **WHEN** процесс запущен с `SPEED_MODEM_IFACE=en1`
- **THEN** modem-sampler использует `en1` для `curl --interface` и `ifconfig`-парсинга

#### Scenario: Interval override at startup
- **WHEN** процесс запущен с `SPEED_INTERVAL_MIN=10`
- **THEN** scheduler стартует с `interval_min = 10`
- **AND** этот интервал может быть позже изменён через `POST /api/interval`

### Requirement: VPN sampling
Система SHALL измерять VPN-профиль через `networkQuality -c` (с захватом JSON stdout). Запись MUST содержать `profile: "vpn"`, `method: "networkQuality"`, `interface_name` дефолтного маршрута, `source_ip` интерфейса, `public_ip` из внешнего запроса, `download_mbps`, `upload_mbps`, `ping_ms`, `ok`, `error`, `duration_sec`, `ts`.

#### Scenario: Successful VPN sample
- **WHEN** запускается `sampleVpn()` и `networkQuality -c` возвращает корректный JSON
- **THEN** в NDJSON добавляется запись с `ok: true`
- **AND** `download_mbps` и `upload_mbps` сконвертированы из bps в Mbps
- **AND** `ping_ms` взят из `base_rtt`

#### Scenario: VPN tool error
- **WHEN** `networkQuality` завершается с ненулевым кодом или невалидным JSON
- **THEN** в NDJSON добавляется запись с `ok: false`
- **AND** поле `error` содержит человеко-читаемое описание (stderr или причина парсинга)
- **AND** `download_mbps`, `upload_mbps`, `ping_ms` — `null`

### Requirement: Modem sampling
Система SHALL измерять modem-профиль через `curl --interface <iface>` для download/upload + `ping -S <source_ip>` для latency. `iface` MUST равняться `SPEED_MODEM_IFACE` (default `en0`). Запись MUST содержать `profile: "modem"`, `method: "curl-bound"`, `bypass_verified` (boolean — `public_ip` modem-замера отличается от `public_ip` VPN-замера).

#### Scenario: Successful modem sample
- **WHEN** запускается `sampleModem(vpnPublicIp)` и все три утилиты успешны
- **THEN** в NDJSON добавляется запись с `ok: true`
- **AND** `bypass_verified = (public_ip !== vpnPublicIp)`
- **AND** `download_mbps`, `upload_mbps`, `ping_ms` заполнены

#### Scenario: Interface has no IPv4
- **WHEN** `ifconfig <iface>` не возвращает `inet`-строку
- **THEN** запись добавляется с `ok: false` и `error` с описанием
- **AND** curl/ping не запускаются

### Requirement: Sampling scheduler
Система SHALL поддерживать авто-цикл sampling: после завершения каждого замера планируется следующий через `interval_min` минут. Scheduler MUST гарантировать single-flight (одновременно может выполняться только один цикл). `interval_min = 0` MUST полностью отключать таймер.

#### Scenario: Sequential auto-sampling
- **WHEN** scheduler стартует с `interval_min = 30`
- **AND** замер завершается в момент `T`
- **THEN** следующий замер запланирован на `T + 30min` через `setTimeout`

#### Scenario: Concurrent trigger rejected
- **WHEN** замер уже выполняется
- **AND** приходит ещё один `trigger()` (через `POST /api/sample` или авто-таймер)
- **THEN** возвращается `{ started: false }`
- **AND** новый процесс замера не стартует

#### Scenario: Interval zero disables timer
- **WHEN** scheduler получает `setInterval(0)`
- **THEN** существующий `setTimeout` отменяется
- **AND** новый таймер не создаётся
- **AND** замеры можно запускать только вручную через API

### Requirement: NDJSON storage
Система SHALL хранить замеры в `data/speed-tests.ndjson` в append-only режиме. Каждая запись — одна строка JSON. Схема записи MUST совпадать с текущей Python-версией (поля: `ts`, `profile`, `method`, `interface_name`, `source_ip`, `public_ip`, `bypass_verified`, `download_mbps`, `upload_mbps`, `ping_ms`, `ok`, `error`, `duration_sec`).

#### Scenario: Append new record
- **WHEN** замер завершается
- **THEN** в конец `data/speed-tests.ndjson` дописывается строка `JSON.stringify(record) + "\n"`
- **AND** существующие строки не модифицируются

#### Scenario: Read history for series
- **WHEN** обрабатывается `GET /api/series`
- **THEN** файл читается построчно
- **AND** каждая строка парсится как JSON
- **AND** невалидные строки пропускаются с warn в лог, не падают весь запрос

### Requirement: Time-bucketed series API
Система SHALL предоставлять `GET /api/series` с query-параметрами `bucket` (одно из `30m|1h|3h|6h|12h|1d`) и опционально `from`, `to` (unix timestamps). Ответ MUST содержать `bucket_sec`, `points: [{ts, profile, download_mbps, upload_mbps, ping_ms, count}]`, `from`, `to`, `total`. Значения per-bucket MUST вычисляться как trimmed median (10% / 90% по краям, при `< 3` точек — обычный median).

#### Scenario: Default bucket
- **WHEN** запрос `GET /api/series` без `bucket`
- **THEN** используется bucket `1h` (или дефолт текущей Python-версии)
- **AND** возвращается JSON с `bucket_sec = 3600`

#### Scenario: Range filtering
- **WHEN** запрос с `?from=1779000000&to=1779100000`
- **THEN** в `points` попадают только bucket'ы с `ts` в диапазоне
- **AND** `total` — общее число точек до фильтрации (или другое значение, совпадающее с Python-версией)

#### Scenario: Trimmed median calculation
- **WHEN** в bucket'е 10 download-значений
- **THEN** значения сортируются по возрастанию
- **AND** обрезаются 10% с каждого края (т.е. 1 значение слева и 1 справа)
- **AND** возвращается median оставшихся 8

### Requirement: State and control API
Система SHALL предоставлять API для чтения состояния и управления интервалом / ручным запуском.

#### Scenario: GET /api/state
- **WHEN** запрос `GET /api/state`
- **THEN** возвращается JSON `{ interval_min, last_sample_ts, sampling }`
- **AND** `last_sample_ts` — `ts` последней записи в NDJSON (или `null` если файл пуст)
- **AND** `sampling` — текущий флаг scheduler

#### Scenario: POST /api/sample
- **WHEN** запрос `POST /api/sample` и `sampling = false`
- **THEN** scheduler триггерит замер асинхронно
- **AND** ответ `{ started: true }` возвращается немедленно (не ждёт завершения)

#### Scenario: POST /api/interval
- **WHEN** запрос `POST /api/interval?minutes=15`
- **THEN** scheduler обновляет `interval_min = 15`
- **AND** существующий `setTimeout` отменяется и пересоздаётся с новым интервалом
- **AND** ответ `{ interval_min: 15 }`

#### Scenario: Disable auto-sampling
- **WHEN** запрос `POST /api/interval?minutes=0`
- **THEN** `interval_min = 0`
- **AND** `setTimeout` отменяется и не создаётся новый

### Requirement: Logs API
Система SHALL предоставлять `GET /api/logs?limit=N` (default `200`), возвращающий последние N строк из `logs/internet-speed.log` как `text/plain`.

#### Scenario: Tail log lines
- **WHEN** запрос `GET /api/logs?limit=50`
- **THEN** возвращается `text/plain` с последними 50 строками файла
- **AND** если файла нет — возвращается пустое тело со статусом 200

### Requirement: Static asset serving
Система SHALL отдавать собранный React-бандл из `web/dist/` для всех не-API GET-запросов. Корневой `GET /` MUST возвращать `web/dist/index.html`. Неизвестные роуты (не начинающиеся с `/api/`) MUST возвращать `index.html` для SPA-routing.

#### Scenario: Root serves index.html
- **WHEN** запрос `GET /`
- **THEN** возвращается содержимое `web/dist/index.html` со статусом 200 и `Content-Type: text/html`

#### Scenario: Asset served directly
- **WHEN** запрос `GET /assets/main-abc123.js`
- **THEN** возвращается соответствующий файл из `web/dist/assets/` с правильным MIME-типом

### Requirement: Launchd compatibility
Система SHALL запускаться через launchd-plist аналогично текущей Python-версии. Plist MUST содержать абсолютный путь к `node` (не `/usr/bin/env node`), `KeepAlive: true`, рабочую директорию равную корню проекта, stdout/stderr в `logs/launchd-server.node.{out,err}`.

#### Scenario: Auto-restart on crash
- **WHEN** Node-процесс завершается с любым кодом
- **THEN** launchd перезапускает его (через `KeepAlive: true`)

#### Scenario: Survive Mac reboot
- **WHEN** Mac перезагружается
- **THEN** plist в `~/Library/LaunchAgents/` автоматически грузится
- **AND** Node-процесс стартует и слушает `:9876`
