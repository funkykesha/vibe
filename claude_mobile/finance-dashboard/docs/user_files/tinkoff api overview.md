**Tinkoff Invest API**

Краткий технический обзор

Сбор данных со счетов и аналитика портфеля на Python

# **1. Что такое Tinkoff Invest API**

Tinkoff Invest API — gRPC-интерфейс для программного взаимодействия с торговой платформой Тинькофф Инвестиции. Позволяет автоматически получать данные счетов, управлять портфелем и создавать торговых роботов.

Все данные предоставляются бесплатно. Требуется быть клиентом Тинькофф Инвестиций и получить токен доступа.

**Продовый хост:** invest-public-api.tinkoff.ru:443

**Песочница:** sandbox-invest-public-api.tinkoff.ru:443

# **2. Продукты API**

|  |  |  |
| --- | --- | --- |
| **Продукт** | **Для кого** | **Ключевые возможности** |
| **Invest API** | Частные инвесторы, алготрейдеры | Счета, портфель, операции, котировки, заявки |
| **T-API (бизнес)** | Клиенты Т-Бизнеса с р/с | Платежи, счета, T-ID, зарплатный проект |
| **Payments API** | Интернет-магазины, сервисы | Онлайн-оплата, возвраты, сохранённые карты |

# **3. Данные, доступные со счёта**

## **3.1 Основные методы сервиса Operations**

|  |  |  |
| --- | --- | --- |
| **Метод** | **Тип** | **Описание** |
| GetOperations | REST/gRPC | Список операций по счёту за период |
| GetOperationsByCursor | REST/gRPC | Операции с пагинацией (курсор) |
| GetPortfolio | REST/gRPC | Текущий портфель: позиции, стоимость |
| GetPositions | REST/gRPC | Позиции ценных бумаг на счёте |
| GetWithdrawLimits | REST/gRPC | Доступный остаток для вывода |
| PortfolioStream | gRPC stream | Стрим обновлений портфеля в реальном времени |
| PositionsStream | gRPC stream | Стрим изменений позиций |

## **3.2 Пример запроса операций (JSON)**

{

"accountId": "XXXXXXXXX", // обязательный параметр

"instrumentId": "BBG000000001", // FIGI инструмента (опционально)

"from": "2024-01-01T00:00:00Z", // начало периода

"to": "2025-01-01T00:00:00Z", // конец периода

"state": "OPERATION\_STATE\_EXECUTED" // только исполненные

}

# **4. Готовые библиотеки Python**

|  |  |  |  |
| --- | --- | --- | --- |
| **Библиотека** | **Статус** | **Установка** | **Особенности** |
| **tinkoff-investments** | Официальная | pip install tinkoff-investments | Python 3.8–3.12, активно обновляется (нояб. 2025) |
| **TinkoffPy** | Community | github.com/cia76/TinkoffPy | Готовые примеры, видеоразборы, алготрейдинг |

# **5. Быстрый старт — скачать данные со счёта**

## **5.1 Установка и подключение**

pip install tinkoff-investments pandas

from tinkoff.invest import Client

TOKEN = "твой\_токен" # из личного кабинета Т-Инвестиций

with Client(TOKEN) as client:

accounts = client.users.get\_accounts().accounts

for acc in accounts:

print(acc.id, acc.name)

## **5.2 Скачать операции и сохранить в CSV**

from datetime import datetime, timedelta

import pandas as pd

with Client(TOKEN) as client:

ops = client.operations.get\_operations(

account\_id="ВАШ\_ACCOUNT\_ID",

from\_=datetime.now() - timedelta(days=365),

to=datetime.now()

)

df = pd.DataFrame([{

"дата": op.date,

"тип": op.operation\_type,

"сумма": op.payment.units,

"инструмент": op.figi

} for op in ops.operations])

df.to\_csv("operations.csv", index=False)

## **5.3 Получить портфель**

with Client(TOKEN) as client:

portfolio = client.operations.get\_portfolio(

account\_id="ВАШ\_ACCOUNT\_ID"

)

for pos in portfolio.positions:

print(pos.figi, pos.quantity, pos.current\_price)

# **6. Стек для аналитики**

|  |  |  |
| --- | --- | --- |
| **Задача** | **Инструмент** | **Зачем** |
| **Подключение к API** | tinkoff-investments | Официальный SDK, gRPC + REST proxy |
| **Обработка данных** | pandas | Датафреймы, фильтрация, агрегация |
| **Хранение** | SQLite / Parquet | Локальная БД или колоночный формат |
| **Графики** | plotly / matplotlib | Интерактивные / статичные графики |
| **Дашборд** | Jupyter Notebook | Анализ и визуализация в одном месте |
| **Планировщик** | schedule / cron | Автоматическое обновление данных |

# **7. Безопасность и токены**

* Токен получается в личном кабинете Тинькофф Инвестиций
* Токен только для чтения — не даёт права выставлять заявки
* Можно создать отдельный токен для каждого счёта
* Никогда не публикуйте токен в открытых репозиториях
* Храните в переменных окружения: os.environ['INVEST\_TOKEN']

Документация: tinkoff.github.io/investAPI | Портал разработчика: developer.tbank.ru