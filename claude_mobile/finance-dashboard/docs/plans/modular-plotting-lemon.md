# План: Финансовая система — бэкенд + бот + мигрированный дашборд

## Context

Текущий `index.html` — неиспользуемый MVP. Данные в localStorage, нет интеграций, нет бота. Пользователь вручную обновляет балансы 2 раза в месяц через таблицы. Цель: построить систему где Тинькоф синхронизируется автоматически, остальные банки — через команду в Telegram, дашборд читает данные из API.

---

## Архитектура

```
┌─────────────────────────────────────────────────────────┐
│  Telegram Bot (python-telegram-bot)                     │
│  /refresh — тянет TBank                                 │
│  /update яндекс 2643 — ручной ввод                      │
│  /snapshot — сохранить текущий срез                     │
└────────────────┬────────────────────────────────────────┘
                 │ HTTP
┌────────────────▼────────────────────────────────────────┐
│  FastAPI Backend  (localhost:8000)                      │
│  /api/accounts     GET/PUT                              │
│  /api/snapshot     POST                                 │
│  /api/settings     GET/PUT (cats, deds, usdRate, mort.) │
│  /api/tbank/sync   POST → tbank-mobile-api              │
└────────────────┬────────────────────────────────────────┘
                 │ SQLAlchemy
┌────────────────▼────────────────────────────────────────┐
│  SQLite  finance.db                                     │
│  accounts, snapshots, settings                          │
└─────────────────────────────────────────────────────────┘
                 ▲
┌────────────────┴────────────────────────────────────────┐
│  Dashboard  index.html  (React, без изменений в логике) │
│  localStorage → fetch('/api/...')                       │
└─────────────────────────────────────────────────────────┘
```

---

## Структура файлов

```
finance-dashboard/
├── backend/
│   ├── main.py              # FastAPI app, роуты
│   ├── models.py            # SQLAlchemy модели
│   ├── database.py          # SQLite init, сессия
│   ├── tbank_sync.py        # обёртка над tbank-mobile-api
│   ├── seed.py              # начальный импорт из INIT_ACCS
│   └── requirements.txt
├── bot/
│   └── bot.py               # Telegram bot
└── index.html               # дашборд (миграция с localStorage на API)
```

---

## Фаза 1: Бэкенд + миграция дашборда

### 1.1 Модели (`models.py`)

```python
Account: id, bank, name, type, cat, val, currency, tbank_id (nullable)
Snapshot: id, created_at, account_id, val
Settings: key, value  # JSON-значения: cats, deds, usdRate, mortgage
```

### 1.2 API роуты (`main.py`)

| Метод | Путь | Действие |
|-------|------|----------|
| GET | `/api/accounts` | список счетов с балансами |
| PUT | `/api/accounts/{id}` | обновить баланс вручную |
| GET | `/api/settings` | cats, deds, usdRate, mortgage |
| PUT | `/api/settings` | сохранить настройки |
| POST | `/api/snapshot` | сохранить снапшот всех балансов |
| POST | `/api/tbank/sync` | синхронизировать TBank счета |

CORS: разрешить `localhost` (dashboard обращается напрямую).

### 1.3 TBank синхронизация (`tbank_sync.py`)

- Использует `tbank-mobile-api` (`pip install tbank`)
- `FileStorage("~/.tbank")` — сессия сохраняется между запусками
- Первый запуск: интерактивный логин (телефон + СМС + пароль)
- Маппинг: `account.id` из TBank → `tbank_id` в БД
- При синхронизации: обновить `val` у счетов у которых `tbank_id` не null

### 1.4 Seed (`seed.py`)

Импортировать `INIT_ACCS` из `index.html` → записать в SQLite как начальные данные. Запускается один раз.

### 1.5 Миграция дашборда (`index.html`)

Заменить только слой данных:
- `localStorage.getItem('fin-v3')` → `fetch('http://localhost:8000/api/...')`
- `localStorage.setItem(...)` → PUT/POST к API
- Вся логика расчётов, JSX, стили — без изменений

---

## Фаза 2: Telegram бот (`bot.py`)

### Команды

| Команда | Действие |
|---------|----------|
| `/refresh` | Вызвать `/api/tbank/sync`, ответить что обновлено |
| `/update яндекс 2643.70` | PUT `/api/accounts/{id}` по частичному совпадению имени |
| `/snapshot` | POST `/api/snapshot`, ответить итогами по категориям |
| `/summary` | Показать текущие балансы по категориям |

### Парсинг `/update`

Матчить по `bank + name` (нечёткий поиск), показать что нашёл перед обновлением:
```
Нашёл: Яндекс / Дебетовый
Текущий баланс: 2 500 ₽
Обновить на 2 643,70 ₽? [Да / Нет]
```

### Vision (заглушка)

Команда `/photo` принимает фото, отвечает: "Vision обработка не реализована". Интерфейс для будущего рисёрча.

---

## Фаза 3: Деплой (в будущем)

- `requirements.txt` + `Procfile` для Railway/Render
- SQLite → PostgreSQL: поменять `DATABASE_URL` в `.env`
- Bot webhook вместо polling

---

## Файлы которые меняются

- `index.html` — только слой данных (localStorage → API)
- `backend/` — новая директория
- `bot/` — новая директория

---

## Верификация

1. `cd backend && uvicorn main:app --reload`
2. `python seed.py` → счета в БД
3. Открыть `http://localhost:8000/api/accounts` → JSON со счетами
4. Открыть `index.html` → данные из API, не из localStorage
5. `python tbank_sync.py` (ручной запуск) → балансы Тинькоф обновились
6. Telegram: `/summary` → список счетов с балансами
7. Telegram: `/update яндекс 5000` → баланс обновлён, в дашборде виден
8. Telegram: `/refresh` → TBank синхронизирован
