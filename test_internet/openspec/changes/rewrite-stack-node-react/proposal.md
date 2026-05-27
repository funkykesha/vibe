## Why

Сейчас весь проект — питоновский монолит `internet_speed_monitor.py` (717 строк), где stdlib HTTP-сервер отдаёт зашитую HTML-строку с vanilla JS. Дальше развивать UI неудобно: любые изменения CSS/JS править внутри Python-строки. Нужен единый JS-стек (Node на беке, React на фронте) для удобства дальнейшей разработки и обучения, при этом UI должен выглядеть аккуратнее, чем сейчас.

## What Changes

- **BREAKING**: бекенд переписывается с Python (stdlib `http.server`) на Node.js (Fastify, ESM, plain JS).
- **BREAKING**: фронтенд из inline-HTML внутри Python-строки переезжает в отдельный React-проект (Vite, plain JSX, `react-chartjs-2`, `react-flatpickr`).
- Sampling (`networkQuality`, `curl`, `ping`) переносится с `subprocess` Python на `child_process` Node — поведение, env vars (`SPEED_MODEM_IFACE`, `SPEED_INTERVAL_MIN`), интерфейсы и параметры запуска сохраняются.
- Хранилище `data/speed-tests.ndjson` остаётся без изменений — Node-версия читает существующую историю, формат записи идентичен Python-версии.
- REST API surface (`GET /api/series`, `GET /api/logs`, `GET /api/state`, `POST /api/sample`, `POST /api/interval`) сохраняется один-в-один (те же query-параметры, та же форма JSON-ответов).
- CLI-подкоманды (`doctor`, `sample`, `server`) сохраняются.
- launchd-plist обновляется: `python3 ... server` → `node server/index.mjs server`.
- UI получает косметический рефреш (типографика, отступы, цвета) — функционал и набор контролов остаётся прежним.
- `internet_speed_monitor.py` удаляется отдельным коммитом ПОСЛЕ ручной проверки паритета.

## Capabilities

### New Capabilities

- `speed-monitor-server`: Node-процесс, объединяющий sampling (VPN/modem через `child_process`), NDJSON-хранилище, time-bucketing с trimmed median, scheduler с single-flight, HTTP API (Fastify) и раздачу собранного React-бандла. Один long-running процесс под launchd.
- `speed-monitor-dashboard`: React SPA (Vite + plain JSX), визуализирующий два графика скорости (VPN/modem), date-range picker, селектор bucket, ручной триггер замера, статус sampling, tail логов. Косметически аккуратнее текущего inline-HTML.

### Modified Capabilities

(нет — `openspec/specs/` пуст, существующих capability не было)

## Impact

- **Удаляется**: `internet_speed_monitor.py` (после паритета).
- **Создаётся**: `package.json`, `vite.config.js`, `server/*.mjs`, `web/src/*.jsx`, `web/index.html`, `web/src/styles.css`.
- **Изменяется**: `launchd/com.user.speedmon.server.plist` (или вводится новый `*.node.plist`, старый выгружается).
- **Сохраняется без изменений**: `data/speed-tests.ndjson`, `logs/internet-speed.log`, env vars, REST-контракт, CLI-подкоманды, порт `:9876`, бинды `127.0.0.1`.
- **Новые runtime-зависимости**: Node.js 20+, `fastify`, `@fastify/static`, `react`, `react-dom`, `react-chartjs-2`, `chart.js`, `chartjs-adapter-date-fns`, `react-flatpickr`, `vite`, `concurrently` (dev only).
- **macOS-only**: остаётся (sampler вызывает `networkQuality`, `route`, `ifconfig`, `curl`).
- **Риск регрессии**: возможен дрейф числовых значений между Python-curl и Node-curl парсингом — митигируется side-by-side запуском на разных портах и diff-сравнением `/api/series`.
