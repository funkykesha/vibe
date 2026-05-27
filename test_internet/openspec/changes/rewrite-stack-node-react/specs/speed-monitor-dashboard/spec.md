## ADDED Requirements

### Requirement: React SPA bundle
Дашборд SHALL быть собран как React SPA через Vite (plain JSX, без TypeScript). Артефакт сборки MUST находиться в `web/dist/` и состоять из `index.html` + `assets/*.js,*.css`. Бандл MUST загружаться по адресу `http://127.0.0.1:9876/` без отдельного dev-сервера в production.

#### Scenario: Production bundle loads
- **WHEN** пользователь открывает `http://127.0.0.1:9876/` в браузере
- **THEN** загружается `index.html` из `web/dist/`
- **AND** JS-бандл инициализирует React-приложение в `#root`
- **AND** дашборд рендерится без сетевых запросов к Vite-серверу

### Requirement: Two profile charts
Дашборд SHALL отображать два независимых time-series графика — один для профиля `vpn`, один для `modem`. Каждый график MUST показывать `download_mbps` как основную линию, `upload_mbps` и `ping_ms` как дополнительные ряды/оси, временную ось через `chartjs-adapter-date-fns`.

#### Scenario: Charts render on load
- **WHEN** дашборд загружается и `GET /api/series?bucket=1h` возвращает точки
- **THEN** отображаются два canvas-элемента, по одному на профиль
- **AND** точки распределены по временной оси
- **AND** легенда показывает названия рядов (`download`, `upload`, `ping`)

#### Scenario: Empty data state
- **WHEN** `GET /api/series` возвращает пустой `points`
- **THEN** графики показывают пустое состояние с подписью (например, "Нет данных")
- **AND** UI не падает с JS-ошибкой

### Requirement: Bucket selector
Дашборд SHALL предоставлять селектор для выбора bucket'а агрегации со значениями `30m`, `1h`, `3h`, `6h`, `12h`, `1d`. Изменение селектора MUST триггерить новый запрос `GET /api/series` с соответствующим `bucket` и перерисовку графиков.

#### Scenario: Switch bucket
- **WHEN** пользователь меняет значение селектора на `6h`
- **THEN** выполняется `GET /api/series?bucket=6h`
- **AND** графики перерисовываются с новыми точками

### Requirement: Date range picker
Дашборд SHALL предоставлять date-range picker (через `react-flatpickr`), позволяющий ограничить временной диапазон отображаемых данных. Выбор диапазона MUST добавлять `from` и `to` (unix timestamps) к запросу `/api/series`. MUST быть кнопка "All-time" для сброса диапазона.

#### Scenario: Select date range
- **WHEN** пользователь выбирает диапазон `2026-05-01 .. 2026-05-26`
- **THEN** запрос содержит `?bucket=...&from=<ts_2026-05-01>&to=<ts_2026-05-26+23:59>`
- **AND** графики обновляются только данными за этот период

#### Scenario: Clear range
- **WHEN** пользователь нажимает "All-time"
- **THEN** `from`/`to` убираются из запроса
- **AND** возвращаются все данные

### Requirement: Manual sample trigger
Дашборд SHALL иметь кнопку "Sample now", вызывающую `POST /api/sample`. Пока `sampling = true`, кнопка MUST быть disabled. После запуска UI MUST поллить `GET /api/state` каждые 2 секунды до `sampling = false`, после чего обновлять данные графиков.

#### Scenario: Trigger sample
- **WHEN** пользователь нажимает "Sample now" при `sampling = false`
- **THEN** выполняется `POST /api/sample`
- **AND** кнопка становится disabled
- **AND** статус-бейдж показывает "Sampling..."

#### Scenario: Polling completes
- **WHEN** последующий `GET /api/state` возвращает `sampling: false`
- **THEN** поллинг останавливается
- **AND** автоматически перезапрашивается `/api/series`
- **AND** кнопка снова доступна

### Requirement: Interval control
Дашборд SHALL иметь селектор/инпут для управления `interval_min`. Изменение значения MUST отправлять `POST /api/interval?minutes=N`. Селектор MUST показывать текущий `interval_min` из `/api/state`. Значение `0` MUST интерпретироваться как "выключено".

#### Scenario: Change interval
- **WHEN** пользователь выбирает интервал `15`
- **THEN** выполняется `POST /api/interval?minutes=15`
- **AND** UI обновляет отображаемое значение интервала

#### Scenario: Disable auto-sampling from UI
- **WHEN** пользователь выбирает `0` (выключено)
- **THEN** выполняется `POST /api/interval?minutes=0`
- **AND** статус-бейдж отражает выключенный режим (например, "Auto: off")

### Requirement: Status badge
Дашборд SHALL отображать статус-бейдж с информацией: текущий `interval_min`, время последнего замера (`last_sample_ts` в локальном формате), индикатор `sampling` (например, цвет/иконка). Данные MUST обновляться при каждом `GET /api/state`.

#### Scenario: Display last sample time
- **WHEN** `/api/state` возвращает `last_sample_ts: 1779786626.99`
- **THEN** в бейдже показывается локализованное время (например, `2026-05-26 14:30:26`)

#### Scenario: Show sampling state
- **WHEN** `/api/state` возвращает `sampling: true`
- **THEN** бейдж содержит визуальный индикатор активного замера (иконка, цвет)

### Requirement: Log tail viewer
Дашборд SHALL отображать tail логов из `GET /api/logs?limit=200`. UI MUST показывать последние строки в монospace-блоке с прокруткой. MUST быть кнопка "Refresh" для повторного запроса.

#### Scenario: Display logs
- **WHEN** дашборд загружается
- **THEN** выполняется `GET /api/logs?limit=200`
- **AND** строки отображаются в pre/code блоке с авто-скроллом вниз

#### Scenario: Refresh logs
- **WHEN** пользователь нажимает "Refresh" в секции логов
- **THEN** выполняется новый `GET /api/logs?limit=200`
- **AND** содержимое обновляется

### Requirement: Visual polish
Дашборд MUST иметь визуально аккуратное оформление: dark theme, последовательная типографика (один шрифт-стек), выровненные отступы (8/16/24 px grid), читаемый контраст (минимум WCAG AA для текста на фоне), responsive layout до ширины окна 1024px.

#### Scenario: Layout adapts to width
- **WHEN** окно браузера шириной 1280px
- **THEN** графики и панели управления располагаются с использованием полной ширины без горизонтального скролла

#### Scenario: Narrow layout
- **WHEN** окно браузера шириной 800px
- **THEN** layout сжимается без потери читаемости (например, контролы переносятся на новые строки)

### Requirement: Dev workflow with HMR
Дашборд MUST поддерживать локальную разработку с Hot Module Replacement через Vite. Команда `npm run dev` MUST поднимать Vite на `:5173` и Node-бек на `:9876` параллельно (через `concurrently`). Vite MUST проксировать `/api/*` на бек.

#### Scenario: Dev server start
- **WHEN** разработчик запускает `npm run dev`
- **THEN** оба процесса стартуют
- **AND** открытие `http://localhost:5173` отдаёт React-приложение с HMR
- **AND** все `fetch('/api/...')` уходят на `http://127.0.0.1:9876` через прокси

#### Scenario: Production build
- **WHEN** выполняется `npm run build`
- **THEN** создаётся `web/dist/` с минифицированным бандлом
- **AND** `node server/index.mjs server` отдаёт этот бандл на `:9876`
