## Context

Текущий стек: статический `index.html` с inline React/Babel, данные в localStorage. Нет бэкенда, нет истории, нет интеграций. Единственный пользователь. Данные частично зафиксированы в `INIT_ACCS/INIT_CATS/INIT_DEDS` в исходнике.

Ограничения:
- Один пользователь — не нужна auth система, достаточно whitelist
- Локальная разработка сначала, деплой потом
- Не переписывать дашборд — только слой данных

## Goals / Non-Goals

**Goals:**
- Python бэкенд с SQLite, доступный по REST API
- Dashboard читает/пишет данные через API вместо localStorage
- Telegram бот как основной мобильный интерфейс
- Тинькоф счета синхронизируются автоматически
- Конфиг через `.env` — один файл для локальной и деплой среды

**Non-Goals:**
- Переписывать dashboard на TypeScript/Vite/etc.
- Мультипользовательность и auth
- Автоматические переводы между счетами
- Интеграция других банков кроме Тинькоф (пока)

## Decisions

### D1: Sync SQLAlchemy, не async

**Выбрано:** sync SQLAlchemy + sync FastAPI endpoint (`def`, не `async def`)

**Почему:** aiosqlite добавляет сложность без выгоды для однопользовательского приложения. Blocking I/O на локальном SQLite незаметно. При переходе на Postgres можно добавить async тогда.

**Альтернатива:** SQLAlchemy 2.0 async + aiosqlite — оправдано при высокой нагрузке, здесь избыточно.

---

### D2: Adapter pattern для TBank

**Выбрано:** абстрактный `AccountProvider` + `TBankProvider` реализация

```
providers/
├── base.py       # AccountProvider ABC: get_balances() -> list[AccountBalance]
└── tbank.py      # TBankProvider: вся логика tbank-mobile-api здесь
```

**Почему:** `tbank-mobile-api` неофициальный (6 stars, 2 commits). Если сломается — меняется только `TBankProvider`, роут и бот не трогаются.

**Альтернатива:** прямой вызов из роута — быстрее, но тесно связывает нестабильную зависимость с API.

---

### D3: TBank авторизация через бота

**Выбрано:** команда `/auth_tbank` в Telegram боте

**Поток:**
```
/auth_tbank → бот спрашивает телефон
→ пользователь вводит → бот инициирует SMS
→ пользователь вводит SMS код → сессия сохранена в TBANK_STORAGE
→ следующие /refresh работают без auth
```

**Почему:** `login_interactive()` из библиотеки ждёт ввода в терминале — не работает на Railway/Render. Бот даёт тот же интерактивный flow без терминала.

**Альтернатива:** прогнать auth локально → скопировать `~/.tbank` на сервер вручную — работает, но неудобно при смене пароля.

---

### D4: API_BASE в дашборде

**Выбрано:** inline конфиг в `index.html`

```html
<!-- в начале <script type="text/babel"> -->
const API_BASE = window.__API_BASE__ || 'http://localhost:8000';
```

FastAPI отдаёт `index.html` как статику с подстановкой `__API_BASE__` из env при необходимости, или достаточно дефолта для локальной разработки.

**Почему:** нет build step, минимальное изменение файла.

---

### D5: Стратегия сохранения в дашборде

**Выбрано:** debounce 500ms для settings (cats, deds, usdRate, mortgage), немедленное PUT для обновления баланса счёта

**Почему:** текущий паттерн `useEffect → save` на каждое нажатие клавиши = шквал запросов. Баланс счёта — дискретное действие, сохраняется сразу.

---

### D6: Снапшоты — только по явному запросу

**Выбрано:** снапшот создаётся вручную (`/snapshot` в боте или кнопка в дашборде)

**Почему:** снапшот = осознанный "чекпоинт" (обычно после зарплатного дня). Автоматический снапшот при каждом изменении засоряет историю.

---

### D7: Seed идемпотентный через upsert

**Выбрано:** `INSERT OR IGNORE` / `merge()` в SQLAlchemy по уникальному ключу `(bank, name)`

**Почему:** безопасно запускать повторно, не создаёт дубликаты.

---

## Структура файлов

```
finance-dashboard/
├── backend/
│   ├── config.py           # pydantic Settings, читает .env
│   ├── database.py         # engine, SessionLocal, Base
│   ├── models.py           # Account, Snapshot, Settings, SalaryEvent
│   ├── main.py             # FastAPI app, CORS, static files mount
│   ├── seed.py             # идемпотентный импорт из INIT_ACCS
│   ├── routers/
│   │   ├── accounts.py     # GET /api/accounts, PUT /api/accounts/{id}
│   │   ├── settings.py     # GET/PUT /api/settings
│   │   ├── snapshots.py    # GET /api/snapshots, POST /api/snapshot
│   │   ├── salary.py       # GET/POST /api/salary-events
│   │   └── tbank.py        # POST /api/tbank/sync, POST /api/tbank/auth-step
│   └── providers/
│       ├── base.py         # AccountProvider ABC
│       └── tbank.py        # TBankProvider
├── bot/
│   └── bot.py              # Telegram bot, whitelist, все команды
├── index.html              # дашборд (минимальные изменения)
├── .env.example
└── requirements.txt
```

---

## Схема данных

```
Account
  id          INTEGER PK
  bank        TEXT            # "Тинькоф", "Яндекс", ...
  name        TEXT            # "НЗ", "Семейный накоп", ...
  type        TEXT            # Счет / Вклад / ИИС / Брокер / Долг / Наличка
  cat         TEXT            # Быстрые / Семейные / Жизнь / ...
  val         REAL            # текущий баланс
  currency    TEXT            # RUB / USD
  tbank_id    TEXT NULL       # ID из TBank API (если есть)
  updated_at  DATETIME

Snapshot
  id          INTEGER PK
  created_at  DATETIME
  label       TEXT NULL       # "Апрель 5, 2026" или пусто
  (связанные SnapshotEntry)

SnapshotEntry
  id          INTEGER PK
  snapshot_id FK → Snapshot
  account_id  FK → Account
  val         REAL

Settings
  key         TEXT PK         # "cats" / "deds" / "usdRate" / "mortgage"
  value       TEXT            # JSON

SalaryEvent
  id          INTEGER PK
  event_date  DATE
  event_type  TEXT            # payday_5 / payday_20 / vacation / bonus
  gross       REAL
  deductions  TEXT            # JSON [{name, val}]
  net         REAL
  distribution TEXT           # JSON {cat: amount}
```

---

## Risks / Trade-offs

- **tbank-mobile-api нестабильность** → Adapter pattern (D2) изолирует. При поломке — только `TBankProvider` меняется.
- **SQLite на Railway ephemeral storage** → 🔬 исследовать до Stage 7. Путь эвакуации: `DATABASE_URL=postgresql://...` в `.env`, SQLAlchemy переключается без изменений кода.
- **Telegram бот polling vs webhook** → Polling для локальной разработки, webhook для деплоя. Переключение через `BOT_MODE=webhook` в `.env`.
- **index.html через `file://`** → FastAPI отдаёт его как статику, браузер открывает через `http://localhost:8000`. Нельзя открывать файл напрямую после Stage 1.
- **Потеря localStorage данных при миграции** → `seed.py` использует захардкоженные INIT_ACCS, не читает localStorage. Данные в localStorage теряются (приемлемо — пользователь сам обновит балансы).

## Migration Plan

Каждый Stage — независимо рабочая система:

1. `config-layer`: `.env` + `config.py` — без них ничего не запускается
2. `backend-foundation`: `uvicorn main:app` + `python seed.py` → curl работает
3. `dashboard-api-migration`: открыть `http://localhost:8000` → дашборд работает через API
4. `tbank-sync`: `POST /api/tbank/sync` → балансы Тинькоф обновились
5. `telegram-bot`: `/summary` в боте → данные из той же БД что и дашборд
6. Далее: история, salary events, vision, деплой

Rollback: на любом этапе можно вернуться к исходному `index.html` с localStorage — он не менялся до Stage 1.

## Open Questions

1. **TBank account mapping**: первый запуск sync — автоматически матчить по имени или показывать список для ручного сопоставления? Имена в TBank API могут не совпадать с нашими.
2. **SQLite на Railway**: persistent disk доступен? Цена? Или сразу Postgres через Railway's Postgres addon?
3. **Bot hosting**: запускать бота как отдельный процесс или вместе с FastAPI (в одном `main.py`)? Отдельно чище, но два процесса на сервере.
4. **Historical data import**: импортировать данные из `!3 2026 финансы.md` как начальные снапшоты? Или только с момента запуска системы?
