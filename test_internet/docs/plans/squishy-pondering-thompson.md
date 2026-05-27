# План: миграция Internet Speed Monitor на Node.js + React

## Context

Сейчас проект — питоновский монолит `internet_speed_monitor.py` (717 строк): stdlib HTTP-сервер, в строке зашиты HTML+CSS+vanilla JS, sampler через subprocess (`networkQuality`, `curl`, `ping`), хранение в `data/speed-tests.ndjson`, автозапуск через launchd. Дашборд использует Chart.js + flatpickr с CDN.

Юзер хочет:
1. Единый JS-стек (бек + фронт) — для изучения и удобства поддержки.
2. Тот же UI, но «покрасивее» — никаких новых фич, просто аккуратнее визуально.
3. Сохранить надёжность: NDJSON оставляем (работает, нулевые зависимости, append-only).
4. Совместимость с launchd, CLI subcommands, env vars, NDJSON-схемой.

Итог — переписать процесс на Node.js, дашборд на React (Vite), оставить один процесс под launchd, читать существующий `data/speed-tests.ndjson` без миграции.

## Stack

- **Backend**: Node.js 20+ (LTS), ESM, plain JavaScript (`.mjs`). Никакого TypeScript — учится проще без него; добавить позже легко.
- **HTTP**: Fastify — маленький, быстрый, нативный JSON, встроенный static-плагин.
- **Frontend**: React 18 + Vite + plain JS (`.jsx`).
- **Charts**: `react-chartjs-2` (обёртка над тем же Chart.js) + `chartjs-adapter-date-fns`.
- **Date picker**: `react-flatpickr` (та же библиотека, что сейчас).
- **CLI**: встроенный `node:util.parseArgs` (без зависимостей).
- **Storage**: `data/speed-tests.ndjson` — без изменений, read append-only через `node:fs`.

## Directory layout

```
test_internet/
├── internet_speed_monitor.py        # СТАРЫЙ — НЕ ТРОГАЕМ до подтверждения паритета
├── package.json                     # NEW: deps, scripts (dev/build/start)
├── vite.config.js                   # NEW: dev proxy → :9876, build → web/dist
├── server/
│   ├── index.mjs                    # NEW: entry, CLI dispatch (doctor|sample|server)
│   ├── http.mjs                     # NEW: Fastify app, routes, static serving
│   ├── sampler.mjs                  # NEW: sampleVpn(), sampleModem() через child_process
│   ├── scheduler.mjs                # NEW: класс с trigger()/setInterval(), single-flight
│   ├── storage.mjs                  # NEW: readRecords(), appendRecord()
│   ├── bucketing.mjs                # NEW: bucketSeries() — trimmed median + grouping
│   └── netutil.mjs                  # NEW: defaultRouteIface(), ifaceIp(), publicIp()
├── web/
│   ├── index.html                   # NEW: React root
│   ├── src/
│   │   ├── main.jsx                 # NEW: createRoot
│   │   ├── App.jsx                  # NEW: layout, fetch hooks
│   │   ├── api.js                   # NEW: fetch wrappers для /api/*
│   │   ├── components/
│   │   │   ├── SpeedChart.jsx       # NEW: один график для профиля
│   │   │   ├── Controls.jsx         # NEW: bucket/interval/date-range/buttons
│   │   │   ├── StatusBadge.jsx      # NEW: sampling + last_ts
│   │   │   └── LogTail.jsx          # NEW: viewer для /api/logs
│   │   └── styles.css               # NEW: dark theme, портируем из старого CSS
│   └── dist/                        # build output (gitignore)
├── data/speed-tests.ndjson          # БЕЗ ИЗМЕНЕНИЙ
├── logs/                            # БЕЗ ИЗМЕНЕНИЙ
└── launchd/
    ├── com.user.speedmon.server.plist        # СТАРЫЙ — Python — пока активен
    └── com.user.speedmon.server.node.plist   # NEW — Node — активируем после паритета
```

## Ключевые реализации

### Sampler (`server/sampler.mjs`)

VPN-профиль — `networkQuality -c` через `child_process.spawn`, парсим JSON, конвертируем `dl_throughput`/`ul_throughput` (bps → Mbps), `base_rtt` (ms).

Modem-профиль:
- `ifaceIp(iface)` — парсим `ifconfig <iface>` regex'ом.
- Download: `curl --interface <iface> -o /dev/null -w "%{speed_download}" <url>` — байт/сек → Mbps.
- Upload: `curl --interface <iface> -X POST --data-binary @<file> -w "%{speed_upload}" <url>` (5MB temp file через `os.tmpdir()`).
- Ping: `ping -S <source_ip> -c 5 1.1.1.1` — regex по `avg/([\d.]+)/`.
- `bypass_verified` — сравниваем `public_ip` modem-профиля с VPN-профилем (должны отличаться).

Каждая функция возвращает `{ value, error }` или `null`. Никаких throw — ловим всё и пишем в запись.

### Scheduler (`server/scheduler.mjs`)

Класс с одним boolean `sampling` (single-flight, как в Python), `setTimeout` для авто-цикла. `setInterval(min)` — `0` отключает таймер. `trigger()` возвращает `{started: false}` если уже идёт.

### Bucketing (`server/bucketing.mjs`)

Алгоритм один-в-один с Python:
1. Стримим NDJSON (`readline` over `createReadStream`) — фильтр по `ts ∈ [from, to]`.
2. Группировка: `bucketKey = Math.floor(ts / bucketSec) * bucketSec`, `(bucketKey, profile)`.
3. Trimmed median: если `< 3` точек — обычный median; иначе сортировка, обрезка 10%/90%, median середины.

`bucketSec` для `30m|1h|3h|6h|12h|1d` — те же значения что в Python.

### HTTP (`server/http.mjs`)

Fastify routes:
- `GET /api/series?bucket=&from=&to=` → `{bucket_sec, points, from, to, total}`
- `GET /api/logs?limit=200` → `text/plain` tail (читаем последние N строк `logs/internet-speed.log`)
- `GET /api/state` → `{interval_min, last_sample_ts, sampling}`
- `POST /api/sample` → `{started}`
- `POST /api/interval?minutes=N` → `{interval_min}`
- `GET /*` → `@fastify/static` отдаёт `web/dist/` (SPA fallback на `index.html`).

### Dev workflow

`npm run dev` запускает два процесса через `concurrently`:
- `node server/index.mjs server --port 9876` — API.
- `vite` на :5173 с `server.proxy = { '/api': 'http://127.0.0.1:9876' }`.

`npm run build` — `vite build` → `web/dist/`.

`npm start` — `node server/index.mjs server` (отдаёт API + `web/dist/`).

### Launchd

Новый plist `com.user.speedmon.server.node.plist`:
```
ProgramArguments:
  - /usr/local/bin/node  (или результат `which node`)
  - /Users/agaibadulin/Desktop/projects/vibe/test_internet/server/index.mjs
  - server
  - --host=127.0.0.1
  - --port=9876
```
Старый Python-plist выгружаем (`launchctl unload`), новый загружаем — только после ручной проверки паритета.

## Существующий код для переиспользования

- `data/speed-tests.ndjson` — формат записи остаётся идентичный.
- `logs/internet-speed.log` — тот же файл, тот же формат логов (`level=info ts=... msg=...`).
- Алгоритмы из `internet_speed_monitor.py`:
  - bucketing+trimmed median (Python `_trimmed_median`, ~строки 200–250).
  - sampleVpn/sampleModem спецификация (env vars, fallback iface).
  - CLI subcommands `doctor`, `sample`, `server`.
- Существующая HTML-структура и CSS дарк-темы — портируем стили в `web/src/styles.css`, не сочиняем заново.

## Verification

1. **Параллельная работа на разных портах**: Python остаётся на `:9876`, Node стартует на `:9877` (флаг `--port 9877`). Сравниваем визуально + curl.
2. **API parity** (curl или скрипт):
   - `diff <(curl :9876/api/state) <(curl :9877/api/state)` — должны совпадать (sampling, last_sample_ts могут отличаться).
   - `curl :9876/api/series?bucket=1h > py.json && curl :9877/api/series?bucket=1h > node.json && diff py.json node.json` — точки должны совпадать (одинаковый NDJSON, одинаковая логика).
3. **Sampling parity**: запустить `node server/index.mjs sample` и `python3 internet_speed_monitor.py sample` подряд на одной и той же сети, сравнить записи в NDJSON (download/upload в пределах ±10% — погрешность измерения).
4. **UI**: открыть `:9877` в браузере, проверить:
   - Два графика рендерятся, данные загружаются.
   - Bucket-селектор переключает агрегацию.
   - Date range picker работает.
   - "Sample now" триггерит замер, статус-бейдж обновляется.
   - Логи подгружаются.
5. **Launchd swap**: `launchctl unload` старого plist, `launchctl load` нового, проверить `curl :9876` после рестарта Mac.
6. **Только после полного OK** — удалить `internet_speed_monitor.py` отдельным коммитом.

## Что НЕ делаем сейчас

- Не мигрируем NDJSON в SQLite.
- Не добавляем фичи (графики, метрики, экспорт).
- Не переходим на TypeScript.
- Не пишем тесты — проект MVP, паритет проверяем руками.
- Не трогаем `data/`, `logs/`, старый plist до подтверждения паритета.
