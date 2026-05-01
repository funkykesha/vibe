## ADDED Requirements

### Requirement: Environment variables с дефолтами
Система SHALL читать конфигурацию из `.env` файла через `python-dotenv`. Все переменные MUST иметь дефолтные значения кроме `BOT_TOKEN` и `TELEGRAM_USER_ID` — они обязательны только при запуске бота.

| Переменная | Дефолт | Обязательна |
|---|---|---|
| `DATABASE_URL` | `sqlite:///./finance.db` | нет |
| `TBANK_STORAGE` | `~/.tbank` | нет |
| `API_BASE_URL` | `http://localhost:8000` | нет |
| `BOT_TOKEN` | нет | только для бота |
| `TELEGRAM_USER_ID` | нет | только для бота |

#### Scenario: Запуск бэкенда без .env
- **WHEN** `uvicorn main:app` запускается без `.env` файла
- **THEN** сервер стартует успешно, использует SQLite по умолчанию

#### Scenario: Запуск бота без BOT_TOKEN
- **WHEN** `python bot/bot.py` запускается без `BOT_TOKEN` в `.env`
- **THEN** бот выбрасывает ошибку с сообщением "BOT_TOKEN is required"

#### Scenario: Кастомный DATABASE_URL
- **WHEN** `DATABASE_URL=postgresql://...` задан в `.env`
- **THEN** бэкенд подключается к Postgres без изменений кода

---

### Requirement: .env.example в репозитории
Репозиторий SHALL содержать `.env.example` со всеми переменными, дефолтами и комментариями. `.env` MUST быть в `.gitignore`.

#### Scenario: Новый разработчик
- **WHEN** разработчик клонирует репозиторий
- **THEN** `cp .env.example .env` достаточно для запуска бэкенда локально

---

### Requirement: Единый объект конфига
`config.py` SHALL экспортировать один объект `settings` (Pydantic `BaseSettings`). Все модули MUST импортировать конфиг из `config.py`, не читать `os.environ` напрямую.

#### Scenario: Доступ к конфигу
- **WHEN** любой модуль бэкенда нуждается в конфиге
- **THEN** `from config import settings` даёт типизированный доступ к переменным
