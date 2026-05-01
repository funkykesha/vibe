## Why

Текущий `index.html` — неиспользуемый MVP с данными в localStorage. Финансовая рутина (обновление балансов, расчёт распределения ЗП, сводка по капиталу) выполняется вручную через таблицы 2 раза в месяц. Цель — система где Тинькоф синхронизируется автоматически, остальные банки обновляются через Telegram бот, а дашборд читает данные из единой базы.

## What Changes

- **NEW**: Python/FastAPI бэкенд с SQLite хранилищем данных
- **NEW**: Telegram бот для управления балансами с телефона
- **NEW**: Автоматическая синхронизация счетов Тинькоф через неофициальный API
- **NEW**: История снапшотов капитала с динамикой во времени
- **NEW**: Сохранение событий зарплатных расчётов
- **MODIFIED**: `index.html` — слой данных переезжает с localStorage на REST API (логика расчётов и UI не меняются)
- **FUTURE RESEARCH**: Vision OCR для скринов других банков (Яндекс, ДОМ РФ, Финуслуги)

## Capabilities

### New Capabilities

- `config-layer`: Единый конфигурационный слой (.env, config.py) — основа для всех остальных компонентов. Stage -1.
- `backend-foundation`: FastAPI приложение, SQLAlchemy модели (Account, Snapshot, Settings), seed импорт из текущего INIT_ACCS, базовые CRUD роуты, статическая раздача index.html. Stage 0.
- `dashboard-api-migration`: Замена localStorage на fetch-вызовы к API в index.html. Debounce сохранений, loading states, конфигурируемый API_BASE_URL. Stage 1.
- `tbank-sync`: Адаптер над tbank-mobile-api, маппинг счетов, роут `/api/tbank/sync`, стратегия первичной авторизации (включая flow через бота для деплоя). Stage 2.
- `telegram-bot`: Бот с whitelist по user_id, команды `/summary`, `/refresh`, `/update`, `/snapshot`, заглушка `/photo`. Stage 3.
- `history-snapshots`: Модель Snapshot, роуты истории, вкладка в дашборде, импорт исторических данных из существующих таблиц, дельта между снапшотами. Stage 4.
- `salary-calculator`: Модель SalaryEvent, типы событий (payday_5, payday_20, vacation, bonus), история ЗП событий, сохранение расчётов. Stage 5.
- `vision-ocr`: Исследовательский спайк — Claude Vision API для извлечения балансов из скринов банковских приложений. Реализация `/photo` команды в боте. Stage 6.
- `deployment`: Docker/Procfile, переключение на webhook, конфигурирование для Railway/Render, стратегия бекапа БД, путь миграции SQLite→Postgres. Stage 7.

### Modified Capabilities

*(нет существующих specs — проект новый)*

## Impact

**Код:**
- `index.html` — изменяется только слой данных (~50-80 строк из 497)
- `backend/` — новая директория
- `bot/` — новая директория

**Зависимости (Python):**
- `fastapi`, `uvicorn`, `sqlalchemy`, `python-dotenv`
- `tbank` (tbank-mobile-api — неофициальный, риск нестабильности)
- `python-telegram-bot`
- `aiohttp` или `httpx`

**Риски:**
- `tbank-mobile-api` — 6 stars, неофициальный, может сломаться при обновлении приложения банка → митигировано через adapter pattern
- TBank первичная авторизация (SMS) не работает на сервере без терминала → нужен auth flow через бота
- SQLite ephemeral storage на Railway → исследовать до деплоя, путь на Postgres через DATABASE_URL

**Порядок реализации (зависимости):**
```
config-layer → backend-foundation → dashboard-api-migration → history-snapshots
                    └→ tbank-sync ──────────────────────────→ telegram-bot → vision-ocr
                    └→ salary-calculator
                                                              все выше → deployment
```
