## Context

Текущий стек — Python 3 stdlib монолит `internet_speed_monitor.py` (717 строк): встроенный `ThreadingHTTPServer`, HTML/CSS/JS склеены строкой, sampler через `subprocess`, хранилище NDJSON, автозапуск launchd. Юзер просит унифицировать стек на JS для удобства поддержки + изучения, UI оставить функционально таким же, но визуально аккуратнее.

Ограничения окружения:
- macOS-only (sampler полагается на `networkQuality`, `route -n get default`, `ifconfig`, `curl`).
- Один пользователь, локалхост, порт `:9876`.
- launchd-friendly: один long-running процесс, без daemonизации в коде.
- Существующий `data/speed-tests.ndjson` должен читаться без миграции.
- Никаких внешних сервисов, никакой БД, никаких облачных зависимостей.

## Goals / Non-Goals

**Goals:**
- Бек и фронт на JS, один процесс, тот же порт, та же CLI-семантика.
- API surface, NDJSON-схема, env vars, launchd-контракт — без изменений.
- React-дашборд функционально эквивалентен текущему inline-HTML.
- Visual polish: ровная типографика, корректные отступы, последовательная цветовая палитра.
- Side-by-side smoke-проверка с Python-версией до удаления старого файла.

**Non-Goals:**
- Миграция NDJSON в SQLite или другую БД.
- Новые фичи в UI (экспорт CSV, alerts, дополнительные метрики).
- Кроссплатформенность (Linux/Windows sampler).
- Перевод на TypeScript.
- Автоматические тесты — паритет проверяется руками side-by-side.
- Графики/виджеты помимо тех, что уже есть.

## Decisions

### Решение 1: HTTP-фреймворк — Fastify
Альтернативы: native `node:http`, Express, Hono.
- Native `http` — низкоуровнево, надо вручную писать роутинг, парсинг query, статикой раздачу. Минимизирует зависимости, но удлиняет код без выгоды.
- Express — устоявшийся, но callback-based, медленнее, плагины слабее типизированы.
- Hono — современный, но ориентирован на edge-runtime, в Node-only сценарии Fastify даёт меньше сюрпризов.
- **Fastify**: нативный JSON, schema-validation бесплатно, плагин `@fastify/static` решает SPA-фоллбек одной строкой, отличная производительность, активная поддержка. Win.

### Решение 2: React-бандлер — Vite
Альтернативы: Next.js, Webpack, Parcel.
- Next.js — overkill для локального SPA, тащит SSR/RSC которые не нужны (один long-running Node-процесс уже есть).
- Webpack — много конфигурации.
- Parcel — норм, но Vite быстрее на dev и популярнее в react-сообществе.
- **Vite**: zero-config для React+JSX, быстрый HMR, прямой `vite build` → статика для Fastify. Win.

### Решение 3: Plain JavaScript, не TypeScript
Юзер сам сказал «надёжно и просто» + изучение. Plain JS убирает шаг компиляции, проще отладка, меньше моментов где «что-то не собирается». TypeScript можно ввести инкрементально позже, файл за файлом, если понадобится. Сейчас типизация даст шум без выигрыша.

### Решение 4: NDJSON — оставить, не SQLite
- Файл небольшой (один замер каждые 30 минут × годы → десятки тысяч строк).
- Read full + filter в памяти — приемлемо до сотен MB.
- Append-only — крах-безопасно, легко бэкапить.
- Существующие записи читаются той же логикой парсинга.
- Если когда-то будет N миллионов записей — индексация по `ts` в SQLite станет нужна, но не сейчас.

### Решение 5: Один процесс отдаёт API + статику
В production: `node server/index.mjs server` поднимает Fastify, который и `@fastify/static` отдаёт `web/dist/`, и `/api/*` обслуживает. Один порт `:9876`, один процесс для launchd, никаких reverse-proxy.

В dev: два процесса (`vite` на `:5173` с HMR + `node ... server` на `:9876`), Vite проксирует `/api/*` на бек. Запускается одной командой `npm run dev` через `concurrently`.

### Решение 6: Sampler — child_process.spawn, не exec
`spawn` стримит stdout/stderr, не падает на больших выводах, корректнее обрабатывает таймауты. Каждая утилита запускается с явными аргументами (массив, не shell-строка) — никаких shell-инъекций даже от env vars.

### Решение 7: Scheduler — class + setTimeout, не cron-libs
- Один `setTimeout` цепляется на следующий цикл после завершения текущего (как в Python).
- `setInterval` НЕ используется — дрейф и риск перекрытия при долгом замере.
- `sampling: boolean` гарантирует single-flight: повторный `trigger()` возвращает `{started: false}`.
- `setInterval(0)` — таймер не ставится, авто-режим отключён.

### Решение 8: Side-by-side миграция
Старый `internet_speed_monitor.py` остаётся в репо до подтверждения паритета. Node-версия временно стартует на `--port 9877`, Python — на штатных `:9876`. Сравниваем `/api/series`, `/api/state`, делаем ручные `sample` обеими — записи в NDJSON должны быть похожи. После OK — выгружаем старый launchd-plist, грузим новый, удаляем Python-файл отдельным коммитом.

## Risks / Trade-offs

- **Дрейф измерений между Python-curl и Node-curl** → side-by-side замеры на одной сети, ±10% допуск (нативная погрешность измерения скорости).
- **Парсинг `networkQuality -c` JSON меняется между macOS версиями** → один источник правды (`server/sampler.mjs`), тесты на фикстурах в отдельный момент, сейчас — ручная проверка.
- **launchd запускает Node не из того PATH** → в plist абсолютный путь к `node` (получить через `which node` на этапе установки), не `/usr/bin/env node`.
- **`@fastify/static` не делает SPA fallback из коробки на новые версии** → явно настроить `wildcard: true` + handler для unknown routes возвращающий `index.html` с правильным Content-Type.
- **node_modules в репо** — добавить в `.gitignore`, `package-lock.json` коммитим для воспроизводимых билдов.
- **Существующий NDJSON может содержать записи с неполными полями** (старые записи без `bypass_verified`) → парсер пропускает `undefined`, дефолты не дописывает.
- **Удаление `internet_speed_monitor.py` ломает откат** → коммитим удаление отдельно после паритета; `git revert` восстановит файл.

## Migration Plan

1. Создать `package.json`, установить deps (`npm install`).
2. Реализовать `server/*.mjs` (sampler, storage, bucketing, scheduler, http, index, cli).
3. Реализовать `web/src/*.jsx` + styles.
4. `npm run build` → `web/dist/`.
5. Запустить Node-версию на `--port 9877` параллельно Python `:9876`.
6. Сравнить:
   - `curl :9876/api/series?bucket=1h | jq` vs `curl :9877/api/series?bucket=1h | jq` — `points` должны совпадать (одинаковый NDJSON, одинаковая логика bucketing).
   - `curl :9876/api/state` vs `curl :9877/api/state`.
   - Триггер `POST /api/sample` обеими версиями, проверить новые записи в NDJSON.
   - Открыть оба UI, сверить графики и контролы.
7. Создать `launchd/com.user.speedmon.server.node.plist` с правильным путём к `node`.
8. `launchctl unload ~/Library/LaunchAgents/com.user.speedmon.server.plist`.
9. `cp launchd/com.user.speedmon.server.node.plist ~/Library/LaunchAgents/` и `launchctl load`.
10. Проверить `curl http://localhost:9876` после перезагрузки — Node-версия должна стартануть автоматом.
11. Отдельный коммит: удалить `internet_speed_monitor.py`, оставить старый plist в `launchd/` как исторический справочник или удалить.

**Rollback**: `launchctl unload` нового plist → `launchctl load` старого. Python-файл доступен через `git revert <commit>` если был удалён.

## Open Questions

- Нужно ли сохранить старый `com.user.speedmon.server.plist` в репо как пример / для возможного отката? (по умолчанию — удалим вместе с Python-файлом)
- Стоит ли добавить тёмную/светлую тему-переключатель в новый UI или оставить только dark? (по умолчанию — только dark, как сейчас)
- Куда направлять stderr Node-процесса в launchd? (предложение: `logs/launchd-server.node.{out,err}`)
