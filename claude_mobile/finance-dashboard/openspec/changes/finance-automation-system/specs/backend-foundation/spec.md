## ADDED Requirements

### Requirement: GET /api/accounts — плоский список
`GET /api/accounts` SHALL возвращать плоский JSON массив всех счетов. Группировка по банкам — ответственность клиента.

Поля каждого счёта: `id`, `bank`, `name`, `type`, `cat`, `val`, `currency`, `tbank_id` (null если нет), `updated_at`.

#### Scenario: Запрос списка счетов
- **WHEN** клиент делает `GET /api/accounts`
- **THEN** возвращается HTTP 200 с массивом объектов счетов

#### Scenario: Пустая база
- **WHEN** `GET /api/accounts` вызван до seed
- **THEN** возвращается HTTP 200 с пустым массивом `[]`

---

### Requirement: PUT /api/accounts/{id} — обновить баланс
`PUT /api/accounts/{id}` SHALL принимать только поля `val` и `currency`. Прочие поля (name, bank, cat, type) MUST игнорироваться или возвращать ошибку 422. `updated_at` обновляется автоматически.

#### Scenario: Обновление баланса
- **WHEN** `PUT /api/accounts/5` с телом `{"val": 368182.84}`
- **THEN** HTTP 200, счёт обновлён, `updated_at` = текущее время

#### Scenario: Счёт не найден
- **WHEN** `PUT /api/accounts/999` с несуществующим id
- **THEN** HTTP 404

#### Scenario: Попытка изменить name
- **WHEN** `PUT /api/accounts/5` с телом `{"val": 100, "name": "Другое"}`
- **THEN** HTTP 200, `val` обновлён, `name` не изменился

---

### Requirement: GET /api/settings — все настройки одним объектом
`GET /api/settings` SHALL возвращать единый объект с полями `cats`, `deds`, `usdRate`, `mortgage`. Структура совместима с текущим форматом `fin-v3` из localStorage.

#### Scenario: Запрос настроек
- **WHEN** `GET /api/settings`
- **THEN** HTTP 200 с объектом `{cats: [...], deds: [...], usdRate: "80.33", mortgage: "11948583"}`

---

### Requirement: PUT /api/settings — сохранить настройки
`PUT /api/settings` SHALL принимать частичное обновление — можно передать только изменившиеся поля.

#### Scenario: Обновление курса доллара
- **WHEN** `PUT /api/settings` с телом `{"usdRate": "82.5"}`
- **THEN** HTTP 200, только `usdRate` обновлён, остальные поля не тронуты

---

### Requirement: Seed — только добавлять новые счета
`seed.py` SHALL добавлять счета из `INIT_ACCS` только если счёта с таким `(bank, name)` нет в БД. Существующие записи (включая `val`) MUST оставаться нетронутыми.

#### Scenario: Первый запуск
- **WHEN** `python seed.py` на пустой БД
- **THEN** все счета из INIT_ACCS добавлены, настройки из INIT_CATS/INIT_DEDS загружены

#### Scenario: Повторный запуск
- **WHEN** `python seed.py` на БД с уже существующими данными
- **THEN** никакие записи не изменены, дубликаты не созданы, скрипт завершается успешно

---

### Requirement: Статическая раздача index.html
FastAPI SHALL отдавать `index.html` по маршруту `GET /`. Дашборд MUST быть доступен по `http://localhost:8000` без отдельного сервера.

#### Scenario: Открытие дашборда
- **WHEN** браузер открывает `http://localhost:8000`
- **THEN** загружается `index.html`

---

### Requirement: CORS для локальной разработки
Бэкенд SHALL разрешать запросы с `http://localhost:8000` и `http://127.0.0.1:8000`. В продакшене CORS MUST ограничиваться через `ALLOWED_ORIGINS` в конфиге.

#### Scenario: Fetch из браузера
- **WHEN** дашборд делает `fetch('/api/accounts')` из `http://localhost:8000`
- **THEN** запрос проходит без CORS ошибки
