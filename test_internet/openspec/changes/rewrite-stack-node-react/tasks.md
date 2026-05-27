## 1. Project scaffolding

- [x] 1.1 Создать `package.json` с `"type": "module"`, scripts (`dev`, `build`, `start`, `doctor`, `sample`), deps (`fastify`, `@fastify/static`), devDeps (`vite`, `react`, `react-dom`, `react-chartjs-2`, `chart.js`, `chartjs-adapter-date-fns`, `react-flatpickr`, `flatpickr`, `concurrently`, `@vitejs/plugin-react`).
- [x] 1.2 Создать `.gitignore` со строками `node_modules/`, `web/dist/`.
- [x] 1.3 Создать пустые директории `server/`, `web/src/components/`.
- [x] 1.4 Запустить `npm install` и закоммитить `package-lock.json`.

## 2. Backend: utilities + storage

- [x] 2.1 `server/netutil.mjs`: реализовать `defaultRouteIface()` (через `route -n get default`), `ifaceIp(iface)` (через `ifconfig <iface>` + regex `inet (\d+\.\d+\.\d+\.\d+)`), `publicIp({iface})` (fetch на `https://api.ipify.org`, опциональный binding через `dispatcher` или curl-fallback).
- [x] 2.2 `server/storage.mjs`: реализовать `appendRecord(record)` (atomic-ish append через `fs.appendFile` с `\n`), `readRecords({from, to})` (streaming через `readline`+`createReadStream`, фильтрация по `ts`, пропуск невалидных строк с warn).
- [x] 2.3 `server/storage.mjs`: реализовать `lastRecordTs()` для `/api/state`.

## 3. Backend: sampling

- [x] 3.1 `server/sampler.mjs`: реализовать `runCommand(cmd, args, {timeoutMs, stdin})` — обёртка над `child_process.spawn` возвращающая `{stdout, stderr, code, durationSec}`.
- [x] 3.2 `server/sampler.mjs`: реализовать `sampleVpn()` — `networkQuality -c`, парсинг JSON, конвертация bps → Mbps, заполнение записи.
- [x] 3.3 `server/sampler.mjs`: реализовать `sampleModem(iface, vpnPublicIp)` — `ifaceIp` → download через `curl --interface ... -w "%{speed_download}"` → upload через `curl -X POST ...` → ping через `ping -S ... -c 5` → `publicIp` через curl-bound → `bypass_verified`.
- [x] 3.4 `server/sampler.mjs`: реализовать `sampleAll()` — последовательно VPN, затем modem с переданным VPN-public-ip; обе записи через `appendRecord`.
- [x] 3.5 Обработка ошибок: каждая утилита пишет `ok: false` + `error` вместо throw; `duration_sec` всегда заполняется.

## 4. Backend: bucketing + scheduler

- [x] 4.1 `server/bucketing.mjs`: реализовать `bucketSeries(records, bucketSec)` — группировка по `(floor(ts/bucketSec)*bucketSec, profile)`, trimmed median 10%/90% (с fallback на обычный median при `< 3` точках) для `download_mbps`, `upload_mbps`, `ping_ms`, плюс `count`.
- [x] 4.2 `server/scheduler.mjs`: класс `Scheduler` с полями `intervalMin`, `sampling`, `timer`; методы `trigger()`, `setIntervalMin(n)`, `_runOnce()`, `_resetTimer()`.
- [x] 4.3 `Scheduler.trigger()` — single-flight через `if (sampling) return {started: false}`, вызов `sampleAll()` в async-задаче, по завершении `_resetTimer()`.
- [x] 4.4 `Scheduler.setIntervalMin(0)` — отменяет `setTimeout`, не создаёт новый.

## 5. Backend: HTTP + CLI

- [x] 5.1 `server/http.mjs`: создать Fastify app, зарегистрировать `@fastify/static` на `web/dist/` с SPA-fallback на `index.html` для не-API GET.
- [x] 5.2 `server/http.mjs`: роуты `GET /api/series`, `GET /api/logs`, `GET /api/state`, `POST /api/sample`, `POST /api/interval` — поведение по спеке (`speed-monitor-server`).
- [x] 5.3 `server/index.mjs`: парсинг `process.argv` через `node:util.parseArgs` для subcommands `doctor|sample|server` + флаги `--host`, `--port`.
- [x] 5.4 `server/index.mjs`: команда `doctor` — проверки PATH утилит, создание `data/`/`logs/`, листинг интерфейсов; код выхода.
- [x] 5.5 `server/index.mjs`: команда `sample` — `await sampleAll()`, печать JSON в stdout, exit.
- [x] 5.6 `server/index.mjs`: команда `server` — создание Scheduler, старт Fastify, биндинг env vars `SPEED_MODEM_IFACE`/`SPEED_INTERVAL_MIN`.

## 6. Frontend: scaffolding

- [x] 6.1 `vite.config.js`: `@vitejs/plugin-react`, `build.outDir: 'web/dist'`, `server.proxy: { '/api': 'http://127.0.0.1:9876' }`.
- [x] 6.2 `web/index.html`: минимальный HTML с `#root` div и `<script type="module" src="/src/main.jsx">`.
- [x] 6.3 `web/src/main.jsx`: `createRoot(...).render(<App />)`.
- [x] 6.4 `web/src/api.js`: обёртки `fetchSeries({bucket, from, to})`, `fetchState()`, `fetchLogs({limit})`, `postSample()`, `postInterval(minutes)`.
- [x] 6.5 `web/src/styles.css`: dark-theme переменные (--bg, --fg, --muted, --accent), типографика, 8/16/24 grid, responsive до 1024px.

## 7. Frontend: components

- [x] 7.1 `web/src/components/SpeedChart.jsx`: обёртка над `react-chartjs-2 Line` с тремя рядами (download/upload/ping), `chartjs-adapter-date-fns` для времени.
- [x] 7.2 `web/src/components/Controls.jsx`: bucket-селектор, date-range через `react-flatpickr`, кнопки "All-time"/"Refresh"/"Sample now", interval-селектор.
- [x] 7.3 `web/src/components/StatusBadge.jsx`: отображение `interval_min`, `last_sample_ts` (локальный формат через `Intl.DateTimeFormat`), индикатор `sampling`.
- [x] 7.4 `web/src/components/LogTail.jsx`: `<pre>` с tail-логом, кнопка Refresh.
- [x] 7.5 `web/src/App.jsx`: layout (header + 2 чарта + контролы + лог), состояние series/state/logs, эффект для поллинга `/api/state` каждые 2s при `sampling=true`.

## 8. Build + launchd

- [x] 8.1 Прогнать `npm run build` — убедиться что `web/dist/` создан и в нём `index.html` + `assets/`.
- [ ] 8.2 Запустить `node server/index.mjs server --port 9877` параллельно Python `:9876` — открыть `http://localhost:9877` в браузере, проверить рендер.
- [x] 8.3 Создать `launchd/com.user.speedmon.server.node.plist` с абсолютным путём к `node` (получить через `which node`), `KeepAlive: true`, `WorkingDirectory` равной корню проекта, stdout/stderr в `logs/launchd-server.node.{out,err}`.

## 9. Parity verification

- [x] 9.1 Сравнить `curl :9876/api/series?bucket=1h` и `curl :9877/api/series?bucket=1h` — `points` должны совпадать (одинаковый NDJSON-вход). _Результат: keys/total/count идентичны, значения внутри 0.01 (Python banker's rounding vs JS round-half-away)._
- [x] 9.2 Сравнить `curl :9876/api/state` и `curl :9877/api/state` — структура и значения совпадают (модулу `last_sample_ts`). _Структура идентична; значения отличаются ожидаемо (разные процессы с разным interval_min)._
- [ ] 9.3 Запустить `node server/index.mjs sample` и `python3 internet_speed_monitor.py sample` подряд, сверить новые записи в NDJSON: `download_mbps` в пределах ±10%, остальные поля корректны.
- [ ] 9.4 В обоих UI: проверить переключение bucket, date-range, ручной "Sample now", interval-смену, отображение логов.
- [ ] 9.5 Дать Node-версии поработать сутки на `:9877` параллельно Python — убедиться что записи добавляются, scheduler не зависает, нет утечек памяти (`top -pid`).

## 10. Cutover

- [ ] 10.1 `launchctl unload ~/Library/LaunchAgents/com.user.speedmon.server.plist`.
- [ ] 10.2 Скопировать `launchd/com.user.speedmon.server.node.plist` в `~/Library/LaunchAgents/` и `launchctl load`.
- [ ] 10.3 Проверить `curl http://localhost:9876` — отвечает Node-версия.
- [ ] 10.4 Перезагрузить Mac, убедиться что Node-процесс стартует автоматически.
- [ ] 10.5 Отдельный коммит: удалить `internet_speed_monitor.py`, обновить `README.md` (новые команды, новый стек).
- [ ] 10.6 Отдельный коммит: удалить старый `launchd/com.user.speedmon.server.plist` (либо переименовать в `*.python.plist.bak`).
