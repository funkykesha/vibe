---
title: От базы данных к Supabase
description: Полное руководство по освоению Supabase - от базовых концепций БД до применения в реальных приложениях
---

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-2/backend/database-supabase.md) · [Расширенно](../../../lesson-summaries-full/stage-2/backend/database-supabase.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/database-supabase/index.md)

# От базы данных к Supabase

В предыдущем уроке мы изучили основы UI-дизайна в Mastergo и Figma, научились использовать GitHub для управления кодом и версиями, а также развернули веб-сайт через Zeabur, чтобы поделиться своим приложением с большей аудиторией.

Чтобы лучше закрепить знания, давайте кратко повторим ключевые концепции предыдущего урока через несколько простых вопросов:

1. Что такое инструменты UI-дизайна, Figma, MasterGo и как их использовать.
2. Основные методы преобразования макета в код.
3. Что такое Github, как настроить SSH и создать свой первый репозиторий.
4. Что означает деплой, как использовать Zeabur и развернуть код на публичную сеть.

Если какие-то моменты остались неясными, рекомендуем вернуться к материалам предыдущего урока. Не стесняйтесь задавать вопросы в группе обучения.

В этом уроке мы научимся превращать приложение из работающего прототипа в полноценный онлайн-продукт. Помимо управления данными через базу данных, нужно реализовать полноценную систему пользователей (регистрация, вход, права доступа) и другие критические функции бэкенда. Мы будем работать с платформой Supabase, которая позволит нам реализовать "базу данных + систему пользователей", а затем глубже разберёмся с архитектурой современных облачных сервисов.

# Вы научитесь

1. Что такое данные и база данных, основные типы БД и способы их использования
2. Что такое Supabase и как выполнять базовые операции с БД
3. Как добавить в приложение базовую систему управления пользователями
4. Продвинутые функции Supabase: realtime, storage, edge function
5. Как добавить поддержку входа через Google и GitHub

## Практические результаты:

- Готовое приложение с регистрацией/входом и сохранением данных в облачную БД
- Переиспользуемый шаблон кода Supabase (база данных + управление пользователями) для будущих проектов

# 1. Что такое база данных

## 1.1 Что такое данные

В цифровом мире данные (Data) окружают нас везде. Проще говоря, данные — это носитель информации. Номер телефона друга, статья в WeChat, видео, уровень персонажа в игре — всё это данные. В наших приложениях данные — это информация, которую нужно записать и управлять: профиль пользователя, историю заказов, настройки приложения и т.д.

Обычно данные в программе представляются по-разному. Самый простой способ — переменные:

```python
# Примеры определения переменных на Python

# Целочисленная переменная: хранит информацию о возрасте
age = 30

# Логическая переменная: хранит статус (активен ли)
is_active = True  # True = активен, False = не активен

# Список: хранит набор оценок
scores = [85, 92, 78, 90]  # Содержит 4 числовых элемента

# Словарь: хранит несколько связанных данных пользователя
user_info = {
    "age": 30,           # Ключ "age" соответствует значению возраста
    "height": 1.80,      # Ключ "height" соответствует значению роста (в метрах)
    "login_count": 156   # Ключ "login_count" соответствует количеству входов
}
```

Для сложных данных вроде профилей и истории заказов используются таблицы:

| user_id | name  | email             |
| ------- | ----- | ----------------- |
| 1001    | Alice | alice@example.com |
| 1002    | Bob   | bob@example.com   |

| order_id | user_id | amount | status    |
| -------- | ------- | ------ | --------- |
| 901      | 1001    | 29.99  | completed |
| 902      | 1002    | 15.50  | pending   |

Для данных сложной структуры, иерархии или изменяемых полей удобен формат JSON — универсальный формат обмена данными в интернете, понятный всем системам. Например, заказ может содержать несколько товаров, каждый с названием, количеством и ценой. Таблица здесь неудобна — либо нужны отдельные таблицы "заказы" и "товары" с ссылками, либо дублирование полей. JSON справляется элегантнее через вложенность:

```json
{
  "order_id": 901,
  "user_id": 1001,
  "amount": 29.99,
  "status": "completed",
  "items": [
    { "sku": "BG-001", "name": "Говяжий бургер", "quantity": 1, "price": 18.00 },
    { "sku": "SD-003", "name": "Картофель фри", "quantity": 1, "price": 6.99 },
    { "sku": "DK-002", "name": "Кола", "quantity": 1, "price": 5.00 }
  ],
  "shipping_address": {
    "street": "ул. Технопарка 123",
    "city": "Шэньчжэнь",
    "zip_code": "518057"
  }
}
```

Если рассмотреть данные, закодированные в векторы (Vector) — это обычно числовые представления неструктурированных данных (текст, изображения, аудио) после обработки моделью AI (например, Embedding):

`[0.123, -0.456, 0.789, ..., -0.234]` (массив из сотен или тысяч чисел)

Короче, реальный мир содержит огромное разнообразие данных разных форм и назначений. Каждый тип может требовать специальную БД. Посмотрите на диаграмму ниже — разнообразия много!

![типы данных](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image1.png)

## 1.2 Почему нам нужна база данных

Мы увидели, что реальные данные часто имеют сложную структуру. **Чтобы эффективно хранить и использовать такие данные, нам нужна специальная программа для их управления** — база данных (Database). По сути, БД — это специальная программа, которая организует данные по规стандартам, безопасно их хранит, управляет ими систематически и поддерживает быстрый поиск.

Представьте, что произойдёт без БД: когда пользователь закрывает браузер или выходит из приложения, все временные данные теряются. Мы не можем сохранить состояние пользователя (логин, настройки) или поделиться данными между пользователями (каталог товаров, заказы). Нам нужно хранилище!

Гибкость БД состоит в том, что она может быть развёрнута по-разному: локально на сервере для контроля данных или в облаке. Облачные БД поддерживают масштабирование (Scale) — они растут с вашими данными и трафиком, поддерживая миллионы пользователей без потери производительности.

Коротко, база данных решает следующие ключевые проблемы:

- **Постоянное хранение данных**: Без БД данные существуют только в памяти приложения. После закрытия приложения они теряются. БД сохраняет данные на диск, обеспечивая долгосрочное хранение.
- **Удобный поиск и анализ**: БД предоставляет мощный язык запросов (SQL), позволяя быстро искать, фильтровать и анализировать огромные объёмы данных. Без БД поиск информации в большом количестве файлов занимает много времени.
- **Поддержка высокой производительности и параллельного доступа**: Через индексацию, кеширование, пулы соединений и распределённые архитектуры БД может обработать тысячи одновременных запросов за миллисекунды. Это критично для современных приложений (распродажи, социальные сети). Без этого система замедляется и падает.
- **Гарантирование целостности и консистентности данных**: БД использует механизмы (ограничения, триггеры) для обеспечения корректности данных. Данные должны соответствовать правилам: возраст должен быть числом, ID заказа должен быть уникальным. Это предотвращает некорректные данные.
- **Обеспечение безопасности данных**: БД предоставляет аутентификацию, контроль доступа, шифрование для защиты от несанкционированного доступа, модификации или удаления. Также БД делает резервные копии для восстановления после сбоев, потери данных или атак.

## 1.3 Реляционные и нереляционные базы данных

Мы узнали о ценности БД и способах развёртывания. Теперь нужно разобраться с двумя основными категориями: реляционные БД и нереляционные БД (NoSQL).

**Реляционная БД** как строгая таблица Excel: все данные должны иметь заранее определённый формат (Schema — названия колонок и типы), и разные таблицы связываются через ключи. Плюсы: точность и надёжность, отлично для финансов, инвентаря, заказов. Минусы: изменение структуры сложное, производительность падает с огромными данными.

**Нереляционная БД** (NoSQL) как гибкая папка: можно хранить документы, изображения, ключ-значение пары разных форм, без предопределённой структуры. Плюсы: легко адаптироваться к изменениям, отлично масштабируется для больших данных (социальные сети, логи). Минусы: теряет часть надежности, сложнее связывать данные из разных источников.

**Как выбрать?** Реляционные БД для: финансовых сделок, управления запасами, обработки заказов, бухгалтерских систем — где нужна высокая надежность и сложные связи. Нереляционные БД для: контента соцсетей, логирования, IoT, рекомендаций — где нужна гибкость и масштабируемость.

На начальном этапе компании обычно не тратят время на выбор БД. Современные БД хорошо развиты. Лучший путь — проконсультироваться с облачными провайдерами и подобрать БД под вашу задачу. Часто это самый прямой способ.

Можно посмотреть [рекомендации по выбору БД](https://help.aliyun.com/zh/govcloud/getting-started/select-database-services), где показаны разные типы для разных сценариев.

| Тип БД   | Название            | Цена | Применение                                                                                                                                      |
| -------- | ------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| SQL      | RDS MySQL           | Низ. | Базовая версия: обучение и малые сайты. Высокая доступность: средние нагрузки. Кластер: критичные системы с высоким трафиком               |
|          | RDS SQL Server      | Выс. | Базовая: тестирование и малые коммерческие сайты. HA: корпоративные сайты. Кластер: критичные системы                                        |
|          | RDS PostgreSQL      | Мин. | Базовая: обучение и малые сайты. HA: средние нагрузки. Кластер: высокая производительность выше MySQL                                       |
|          | RDS PPAS            | Выс. | Общее: Oracle-совместимое. Выделенное: требует выделенного железа для высоконагруженных систем                                              |
|          | DRDS                | Сред.| Entry: 4 Core 8 GB, доступная цена. Enterprise: 16 Core 32 GB, хорошая производительность для высоконагруженных. Ultra: 32 Core 64 GB     |
| NoSQL    | Redis               | Сред.| Hot Standby: как БД для повышения доступности. Кластер: как кеш-слой для ускорения                                                         |
|          | MongoDB             | Сред.| Узел: разработка и тестирование. Replica Set: высокие требования к чтению, читаемые сценарии. Sharding: очень высокие требования к чтению  |

Смотреть в таблице легче. Разберём сценарий "платформа блогов" и посмотрим, как одни и те же данные хранятся в SQL и NoSQL:

Нужно хранить:
- Пользователей: ID, имя, почта
- Статьи: ID, название, содержание, автор
- Комментарии: ID, текст, автор комментария, статья
- Теги: ID, название
- Связь статья-теги: одна статья может иметь много тегов

### Реляционная БД (SQL)

В SQL разные типы данных хранятся в отдельных таблицах, связанные внешними ключами. Это чисто и снижает дублирование.

Таблица `users`:

| user_id | username | email             |
| ------- | -------- | ----------------- |
| 101     | Alice    | alice@example.com |
| 102     | Bob      | bob@example.com   |

Таблица `posts`:

| post_id | title      | content                  | author_id |
| ------- | ---------- | ------------------------ | --------- |
| 1       | Intro SQL  | Статья о SQL БД...       | 101       |
| 2       | Intro NoSQL| NoSQL даёт гибкость...  | 102       |

Таблица `comments`:

| comment_id | body        | commenter_id | post_id |
| ---------- | ----------- | ------------ | ------- |
| 1001       | Отлично!    | 102          | 1       |
| 1002       | Понял.      | 101          | 2       |
| 1003       | Примеров?   | 101          | 1       |

Таблица `tags`:

| tag_id | tag_name |
| ------ | -------- |
| 51     | БД       |
| 52     | Tech     |
| 53     | Intro    |

Таблица `post_tags` (связь многие-ко-многим):

| post_id | tag_id |
| ------- | ------ |
| 1       | 51     |
| 1       | 52     |
| 2       | 51     |
| 2       | 52     |
| 2       | 53     |

Чтобы получить полную информацию о статье (содержание, автор, комментарии, теги), нужно соединить 5 таблиц через JOIN:

```sql
SELECT
    p.title,
    p.content,
    u.username AS author,
    c.body AS comment,
    t.tag_name AS tag
FROM
    posts p
JOIN
    users u ON p.author_id = u.user_id
LEFT JOIN
    comments c ON p.post_id = c.post_id
LEFT JOIN
    post_tags pt ON p.post_id = pt.post_id
LEFT JOIN
    tags t ON pt.tag_id = t.tag_id
WHERE
    p.post_id = 1;
```

Такой запрос объединяет 5 таблиц. Это главное преимущество SQL: гибкие сложные запросы с гарантией консистентности.

### Нереляционная БД (NoSQL)

NoSQL работает по-другому — вместо разделения данных на таблицы, он складывает связанные данные в один документ для быстрого чтения.

Пример документа в MongoDB:

```json
{
  "_id": 1,
  "title": "Intro SQL",
  "content": "Статья о SQL БД...",
  "author": {
    "user_id": 101,
    "username": "Alice",
    "email": "alice@example.com"
  },
  "tags": [
    "БД",
    "Tech"
  ],
  "comments": [
    {
      "comment_id": 1001,
      "body": "Отлично!",
      "commenter": {
        "user_id": 102,
        "username": "Bob"
      }
    },
    {
      "comment_id": 1003,
      "body": "Примеров?",
      "commenter": {
        "user_id": 101,
        "username": "Alice"
      }
    }
  ]
}
```

Когда нужна полная информация о статье, нужен один запрос по `_id:1` и вся информация приходит сразу. Нет многотабличных JOIN операций.

**Преимущество**: один запрос вместо 3-4 соединений таблиц, быстрее читаются данные.

**Недостаток**: дублирование данных. Если "Alice" изменит имя, нужно обновить её данные везде, где она упоминается — в каждой статье, комментарии и т.д. Это утомительно и может привести к несоответствиям.

**Но это часто приемлемо**: для сценариев "много читают, мало пишут" (блоги, каталоги товаров) дублирование стоит быстрого чтения. Для сценариев "много пишут" (частые обновления профиля) нужна SQL.

Это была базовая информация. Для углубления можно изучить разные типы БД.

Примеры SQL БД:
[Db2](https://www.ibm.com/products/db2-database), [MySQL](https://cloud.ibm.com/catalog#highlights), [PostgreSQL](https://www.ibm.com/think/topics/postgresql), [YugabyteDB](https://www.yugabyte.com/), [CockroachDB](https://www.cockroachlabs.com/), [Oracle Database](https://www.ibm.com/products/postgres-enterprise), [Azure SQL Database](https://www.ibm.com/consulting/microsoft)

Примеры NoSQL БД:
[Redis](https://www.ibm.com/think/topics/redis), [CouchDB](https://www.ibm.com/think/topics/couchdb), [MongoDB](https://www.ibm.com/think/topics/mongodb), [Cassandra](https://cloud.ibm.com/catalog#highlights), [Elasticsearch](https://www.ibm.com/think/topics/elasticsearch), [BigTable](https://www.techtarget.com/searchdatamanagement/news/252512583/Google-scales-up-Cloud-Bigtable-NoSQL-database), [Neo4j](https://neo4j.com/users/ibm/), [HBase](https://www.ibm.com/think/topics/hbase)

# 2. Supabase

Раньше мы учили основные типы БД и их применение. Но в реальных проектах БД — это только часть бэкенда. Кроме хранения и поиска данных, нужно решить **регистрацию, вход, проверку прав, загрузку файлов, API, задачи, уведомления** и многое другое. Просто выбрать БД — это только начало.

Поэтому нужна более широкая перспектива: **бэкенд-сервис**. Полное приложение = "фронтенд + бэкенд": фронтенд отвечает за интерфейс, бэкенд — за данные, логику, управление пользователями. Раньше разработчики сами настраивали серверы, БД, писали API, управляли безопасностью и масштабированием — утомительно. Чтобы избежать повтора, появился **BaaS (Backend as a Service, бэкенд как сервис)**: облачная платформа, где БД, авторизация, хранилище, realtime и другие функции уже готовы. Разработчики просто вызывают API, не строя инфраструктуру с нуля.

В этом контексте [Supabase](https://supabase.com/) — новое поколение BaaS: использует PostgreSQL, на его основе добавляет Auth, Storage, Realtime, Edge Functions, Vector и другие компоненты. Это "всё-в-одном бэкенд-сервис на основе Postgres". Дальше мы посмотрим, какую работу Supabase нас избавляет, и как он сокращает путь от идеи к готовому продукту.

## 2.1 Пошаговое руководство

Разобравшись с ролью Supabase, посмотрим на консоль и её основные функции.

![консоль Supabase](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image2.png)

Зайдите на сайт Supabase, войдите в свой аккаунт, и нажмите "New project" для создания.

Введите название проекта, пароль БД и выберите регион поближе к целевым пользователям.

![создание проекта](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image3.png)

После создания в левой панели появятся основные функции (Table Editor, SQL Editor, Database, Authentication и т.д.).

![главная консоль](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image4.png)

### Редактор таблиц

Table Editor — визуальный редактор Supabase. Как Excel: смотрите и меняйте данные мышкой без SQL.

![редактор таблиц](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image5.png)

Обратите внимание на Schema. Schema — это "контейнер" в БД для организации таблиц, представлений, функций, индексов. Главные две функции: избежать конфликтов имён (разные Schema могут иметь таблицы с одинаковыми именами) и разделение прав доступа.

На панели сверху можно выбирать Schema:

- `public`: по умолчанию для бизнес-таблиц (статьи, комментарии);
- `auth`: для системы пользователей, таблица `users` хранит зарегистрированных, не меняйте эту схему.

![Schema выбор](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image6.png) ![auth Schema](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image7.png)

### SQL редактор

SQL Editor выполняет SQL команды. Вы можете попросить ИИ создать SQL, вставить в редактор, нажать RUN, и результат видна в Results.

![SQL редактор](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image8.png)

После RUN выполненные команды сохраняются в левой панели PRIVATE, можно добавлять в избранное.

### Центр управления БД

Database — панель для управления таблицами, видно связи между ними (внешние ключи).

![управление БД](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image9.png)

Таблицы создаются здесь визуально, подробнее будет дальше.

![новая таблица](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image10.png)

### Аутентификация

Authentication управляет регистрацией, входом, правами. По умолчанию через почту, но поддерживает OAuth (Google, GitHub и т.д.). Все пользователи автоматически синхронизируются в таблицу `auth.users`.

![аутентификация](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image11.png)

В "Provider" выбираются способы входа, по умолчанию Email.

![провайдеры входа](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image12.png)

В "Sign In / Providers" контролируется поведение регистрации. Если не нужна обязательная подтверждение почты, можно отключить "Confirm email".

![управление почтой](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image13.png)

Если нужен другойAuth сервис, "Third Party Auth" позволяет использовать Clerk или подобное вместо встроенного.

![третий сервис auth](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image14.png)

Если боитесь большого потока новых пользователей, "Rate Limits" помогает ограничить.

![ограничения](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image15.png)

### Хранилище

Storage — система файлов Supabase, как S3 Amazon. Для картин, видео, документов, аудио с контролем доступа и получением URL.

![хранилище](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image16.png)

Подробнее будет в проектах.

![конфигурация хранилища](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image17.png)

Если нужен S3 протокол, есть соответствующие настройки.

![S3 интеграция](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image18.png)

> Amazon Cloud (AWS) — облачная платформа Amazon (как большой интернет-дата-центр, где вы берёте мощность и хранилище по мере необходимости). S3 (Simple Storage Service) — сервис в AWS для хранения файлов (как бесконечный облачный диск для картин, видео, резервных копий и т.д.). Это стандарт хранения файлов в интернете.
>
> **Почему S3-совместимое API?** S3 существует 20 лет, полно инструментов и документации. Совместимость означает, что можно использовать существующие решения вместо создания с нуля — быстрее на рынок.

### Граничные функции

Если не хотите свой сервер, но нужны функции, Edge Functions помогут. Это бессерверные функции Supabase на краю сети. Нет надобности в своём сервере, пишете код и развёртываете в облаке. Функции работают на краевых узлах рядом с пользователями, снижая задержку.

![edge functions](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image19.png)

Главное использование Edge Functions — безопасный посредник для API третьих сторон. Вызов OpenAI из браузера раскрывает ключ — опасно. Edge Function скрывает ключ на сервере Supabase.

![безопасность ключей](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image20.png)

Edge Functions использует secrets (переменные среды) для хранения ключей, загружаемых через `Deno.env.get`.

![secrets](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image21.png)

Вызов Edge Function требует ключа в заголовке:

```javascript
// Основные настройки (замените на свои)
const projectId = "ваш-ID-проекта-Supabase";
const functionName = "целевая-функция";
const supabaseKey = "ваш-anon_key-Supabase";

// Вызов функции
async function callEdgeFunction() {
  const url = `https://${projectId}.supabase.co/functions/v1/${functionName}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${supabaseKey}` // Ключевой момент: ключ в заголовке
      },
      body: JSON.stringify({ order_id: "123", action: "refund" }) // Свои данные
    });

    const result = await response.json();
    console.log("Успех:", result);
  } catch (error) {
    console.error("Ошибка:", error.message);
  }
}

// Выполнение
callEdgeFunction();
```

Edge Functions интегрируется с auth: если вошедший пользователь вызывает функцию, его данные передаются в неё. Функция автоматически соблюдает RLS при доступе к БД, гарантируя, что пользователь видит только свои данные.

Edge Functions применяются широко: Webhook слушатели, отправка писем, создание PDF, кастомные API, тяжелые вычисления — всё можно. Например, Clerk (сервис auth) отправляет Webhook при регистрации, Edge Function ловит и синхронизирует в Supabase БД автоматически, всё без своего сервера.

### Обработчик realtime

Realtime позволяет приложению получать изменения БД в реальном времени без постоянного опроса. Когда данные меняются (INSERT, UPDATE, DELETE), Realtime через WebSocket пушит изменения в фронтенд. Критично для приложений с живым взаимодействием.

Realtime включает три главных блока:

1. **Postgres Changes**: слушать изменения таблиц. Можно подписаться на конкретную таблицу, события (добавление, удаление, изменение), фильтры, с RLS поддержкой — видишь только разрешённые данные.
2. **Broadcast**: клиенты отправляют быстрые временные сообщения через канал. Для чата, следия курсора, синхронизации игровых статусов.
3. **Presence**: отслеживание кто онлайн. Для "X пользователей просматривают" в совместных приложениях.

Подробнее будет в проектах.

### Настройки проекта

Project Settings — расширенная конфигурация ресурсов и параметров.

![параметры проекта](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image22.png)

На начальном этапе главное — Data API для получения URL ("https://xxx.supabase.co"), это адрес всех запросов к БД. Фронтенд через него инициализирует клиент Supabase.

![Data API](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image23.png)

Второе — API Keys. "Legacy anon, service_role API keys": anon public ключ для фронтенда (права по RLS), service_role — мастер-ключ для сервера (обходит RLS). service_role секретен, если утечёт — создайте новый и обновите.

![API ключи](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image24.png)

Остальное на начальном этапе не требуется, изучайте позже при необходимости.

## 2.2 Создание первой SQL таблицы

Выше были интерфейсы Supabase. Теперь главное — операции с БД.

В Supabase создают таблицы двумя способами:

1. **(Рекомендуется)** Попросить ИИ создать SQL для Supabase, вставить в SQL Editor и выполнить. Быстро и удобно. Подробнее дальше.
2. Визуально: Database → Tables → New table.

![новая таблица визуально](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image25.png)

Названия таблиц и типы данных указываются в Columns.

![колонки таблицы](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image26.png)

Важно в реляционных БД — связи между таблицами. Foreign keys определяют одну таблицу ссылается на другую.

![внешние ключи](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image27.png)

Foreign key — поле в текущей таблице, значение которого ссылается на Primary Key другой таблицы.

Пример с классом и студентами:

```sql
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    class_id INT,
    FOREIGN KEY (class_id) REFERENCES classes(class_id)
);
```

Таблица классов (班级表):
Каждый класс имеет уникальный ID.

| class_id | class_name |
| -------- | ---------- |
| 101      | 1класс-1п  |
| 102      | 1класс-2п  |

Таблица студентов (学生表):
Студент принадлежит классу, отслеживаем через `class_id`:

| student_id | student_name | class_id |
| ---------- | ------------ | -------- |
| 2024001    | Чжан Сань    | 101      |
| 2024002    | Ли Сы       | 102      |
| 2024003    | Ван У       | 101      |

`class_id` в студентах — внешний ключ, ссылается на primary key классов.

В Supabase при добавлении Foreign Key можете выбрать целевую таблицу и поле.

![добавление FK](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image28.png)

## 2.3 SQL Editor и базовые операции БД

Теперь выполним SQL операции: CREATE, INSERT, SELECT, UPDATE, DELETE. Копируйте код в SQL Editor и смотрите результаты.

Все примеры: https://github.com/THU-SIGS-AIID/Project5-Supabase-Demos/tree/main/apps/sql-examples

### 2.3.1 `CREATE` — создание таблицы

`CREATE TABLE` определяет структуру новой таблицы (колонки, типы, ограничения).

```sql
-- Шаг 1: Создание таблицы 'orders'
-- Создаёт пример таблицы для дальнейших операций.
CREATE TABLE IF NOT EXISTS orders (
  id serial PRIMARY KEY,
  user_id int NOT NULL,            -- ID пользователя
  status text NOT NULL,            -- Статус заказа (paid, pending и т.д.)
  amount numeric(10, 2) NOT NULL,  -- Сумма заказа
  details jsonb,                   -- Детали товаров в JSON
  placed_at timestamptz DEFAULT now(), -- Время создания заказа
  is_paid boolean DEFAULT false    -- Флаг оплаты
);

-- Результат:
-- Таблица создана, если не существовала.
-- Нет данных пока.
-- Если существует, ошибки не будет.
```

После выполнения таблица появляется в Table Editor.

![созданная таблица](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image29.png)

### 2.3.2 `INSERT` — добавление данных

`INSERT INTO` добавляет строки в таблицу.

```sql
-- Шаг 2: Добавление начальных данных в таблицу orders
INSERT INTO orders (user_id, status, amount, details, placed_at, is_paid) VALUES
  (2001, 'pending', 23.50, '{"items":[{"sku":"BGR001","name":"Beef Burger","qty":1,"price":12.00}]}', now() - interval '2 days', false),
  (2002, 'paid', 50.00, '{"items":[{"sku":"BGR002","name":"Chicken Burger","qty":2,"price":10.00},{"sku":"DRK001","name":"Lemonade","qty":2,"price":5.00}]}', now() - interval '1 day', true),
  (2003, 'cancelled', 15.00, '{"items":[{"sku":"FRY001","name":"French Fries","qty":3,"price":5.00}], "reason":"Not available"}', now() - interval '45 days', false),
  (2004, 'paid', 22.98, '{"items":[{"sku":"BGR003","name":"Veggie Burger","qty":2,"price":9.99}], "promo":"SUMMER22"}', now() - interval '10 days', true),
  (2005, 'pending', 18.75, '{"items":[{"sku":"SAL001","name":"Salad","qty":1,"price":6.75},{"sku":"BGR001","name":"Beef Burger","qty":1,"price":12.00}]}', now() - interval '7 hours', false),
  (2006, 'paid', 8.00, '{"items":[{"sku":"DRK002","name":"Cola","qty":2,"price":4.00}]}', now() - interval '3 hours', true),
  (2007, 'refunded', 14.50, '{"items":[{"sku":"BGR003","name":"Veggie Burger","qty":1,"price":9.99},{"sku":"FRY001","name":"French Fries","qty":1,"price":4.51}], "refund_reason":"Late delivery"}', now() - interval '15 days', false),
  (2008, 'paid', 26.99, '{"items":[{"sku":"BGR002","name":"Chicken Burger","qty":2,"price":10.00},{"sku":"DRK001","name":"Lemonade","qty":1,"price":6.99}]}', now() - interval '12 days', true),
  (2009, 'pending', 9.99, '{"items":[{"sku":"BGR003","name":"Veggie Burger","qty":1,"price":9.99}]}', now() - interval '30 minutes', false),
  (2010, 'paid', 19.89, '{"items":[{"sku":"BGR001","name":"Beef Burger","qty":1,"price":12.00},{"sku":"DRK002","name":"Cola","qty":2,"price":3.95}]}', now() - interval '5 days', true),
  (2011, 'cancelled', 0.00, '{"items":[], "reason":"User cancelled"}', now() - interval '2 days', false);

-- Результат:
-- SELECT * FROM orders вернёт около 11 строк с разными user_id, status, amount, details, placed_at, is_paid.
```

Теперь в таблице 11 строк. Выполните `SELECT * FROM orders;` и посмотрите.

![данные в таблице](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image30.png)

### 2.3.3 `SELECT` — чтение данных

`SELECT` извлекает данные с фильтрацией и сортировкой.

```sql
-- Шаг 3: Примеры SELECT для таблицы orders

-- Пример 1: Все поля всех заказов
SELECT * FROM orders;
-- Результат: все строки и столбцы.

-- Пример 2: Только pending заказы
SELECT id, user_id, amount FROM orders WHERE status = 'pending';
-- Результат: строки с status='pending'; столбцы: id, user_id, amount.

-- Пример 3: Специфичные поля и фильтр по оплате
SELECT id, status, is_paid, amount FROM orders WHERE is_paid = true;
-- Результат: заказы, где is_paid=true; столбцы: id, status, is_paid, amount.

-- Пример 4: Извлечение товаров из details (JSON) каждого заказа
SELECT id, details -> 'items' AS item_list FROM orders;
-- Результат: id и массив товаров из JSON.
```

- **Пример 1**: Все данные из orders.

- **Пример 2**: Только pending заказы с указанными полями:

![pending заказы](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image31.png)

- **Пример 3**: Оплаченные заказы:

| id  | status | is_paid | amount |
| --- | ------ | ------- | ------ |
| 2   | paid   | true    | 50.00  |
| 4   | paid   | true    | 22.98  |
| 6   | paid   | true    | 8.00   |
| 8   | paid   | true    | 26.99  |
| 10  | paid   | true    | 19.89  |

- **Пример 4**: Товары из JSON:

| id  | item_list                                                                                                            |
| --- | -------------------------------------------------------------------------------------------------------------------- |
| 1   | `[{"qty":1,"sku":"BGR001","name":"Beef Burger","price":12}]`                                                         |
| 2   | `[{"qty":2,"sku":"BGR002","name":"Chicken Burger","price":10},{"qty":2,"sku":"DRK001","name":"Lemonade","price":5}]` |
| 3   | `[{"qty":3,"sku":"FRY001","name":"French Fries","price":5}]`                                                         |
| ... | ...                                                                                                                  |

### 2.3.4 `INSERT` — добавление одной записи

Раньше добавляли много строк, теперь одну.

```sql
-- Шаг 4: Добавление одного заказа
INSERT INTO orders (user_id, status, amount, details, is_paid)
VALUES (
  2012, 'paid', 9.99,
  '{"items":[{"sku":"BGR002","name":"AIID Burger","qty":100,"price":1000}]}',
  true
);
-- Результат:
-- Таблица растёт с 11 на 12 строк.
```

Выполните `SELECT * FROM orders;` и увидите 12 строк.

### 2.3.5 `UPDATE` — изменение данных

`UPDATE` меняет существующие записи.

```sql
-- Шаг 5: Обновление заказа
-- Пример: отметить заказ с id=1 как оплаченный
UPDATE orders SET status = 'paid', is_paid = true WHERE id = 1;
-- Результат:
-- До: id=1 имел status='pending', is_paid=false
-- После: id=1 имеет status='paid', is_paid=true
-- Остальные строки не меняются.
```

### 2.3.6 `DELETE` — удаление данных

`DELETE` удаляет записи.

```sql
-- Шаг 6: Удаление старых заказов
-- Пример: удалить заказы старше 2 дней для очистки
DELETE FROM orders WHERE placed_at < now() - interval '2 days';
-- Результат:
-- До: есть строки с placed_at < now()-interval '2 days'
-- После: эти строки удалены.
```

Перед `DELETE` выполните фильтр `SELECT id, status, placed_at FROM orders WHERE placed_at < now() - interval '2 days';` чтобы видеть что удалится. Потом `DELETE`, потом повторите `SELECT` — ноль результатов.

## 2.4 Безопасность на уровне строк

Изучив базовые операции, теперь о безопасности —  RLS (Row Level Security, безопасность на уровне строк).

Критический вопрос: как изолировать доступ к данным? Пользователь А видит только свои данные, не данные пользователя Б. Как заблокировать несанкционированный доступ или случайное изменение?

RLS решает это: определяет политики для таблиц, контролирующие, кто какие строки видит/меняет на основе идентификации пользователя.

Пример: для таблицы заказов политика: "пользователь может видеть только свои заказы (где `user_id` совпадает с его ID)".

Когда RLS включена, все операции (SELECT, INSERT, UPDATE, DELETE) проверяют политики. Если операция не соответствует правилам, БД её отклоняет.

В Supabase RLS связана с Auth, функция `auth.uid()` возвращает ID текущего пользователя (UUID). Легко писать политики вроде "заказ.user_id должен совпадать с auth.uid()".

Включить RLS можно в интерфейсе кнопкой RLS на таблице:

![RLS кнопка](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image32.png)

![RLS список](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image33.png)

![RLS создание](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image34.png)

Но обычно RLS включают в SQL инициализации, проще. Выполните подобное:

![RLS SQL](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image35.png)

# 3. Первое приложение SQL

Усвоив основы БД и RLS, переходим к практике. На примере "Управление заказами бургерной" покажем: как связать приложение с Supabase, как использовать БД и авторизацию.

## 3.1 Клонирование и запуск примера Supabase

Сначала получите код примера. Попросите Claude Code или Trae выполнить: https://github.com/THU-SIGS-AIID/Project5-Supabase-Demos

Если SSH настроен, используйте SSH для безопасности (git@github.com:THU-SIGS-AIID/Project5-Supabase-Demos.git). Если проблемы, скачайте ZIP с сайта, распакуйте.

![после клонирования](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image36.png)

После клонирования попросите ИИ запустить проект: "Запусти проект 1 из Project5-Supabase-Demos" или пропустите абсолютный путь проекта.

## 3.2 Проект 1 — CRUD меню бургерной

Начнём с `project-burger-shop-menu-crud-1`. Научимся инициализировать Supabase через SQL и связать фронтенд с БД.

### Использование скрипта для создания БД

В папке Project 1 есть папка `scripts` с файлом `init.sql`, который автоматически создаёт все таблицы и данные.

```sql
......

-- ============================================================================
-- 2. Создание таблицы меню
-- ============================================================================

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text check (category in ('burger','side','drink')) default 'burger',
  price_cents int not null check (price_cents > 0),
  available boolean default true,
  emoji text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Комментарии для документации
comment on table public.menu_items is 'Товары меню бургерной для CRUD демо';
comment on column public.menu_items.id is 'Уникальный ID товара';
comment on column public.menu_items.name is 'Название товара';
comment on column public.menu_items.description is 'Описание товара';
comment on column public.menu_items.category is 'Категория: burger, side или drink';
comment on column public.menu_items.price_cents is 'Цена в центах (целое число) для точности';
comment on column public.menu_items.available is 'Доступен ли товар для заказа';
comment on column public.menu_items.emoji is 'Опциональный emoji для товара';
comment on column public.menu_items.created_at is 'Когда создан товар';
comment on column public.menu_items.updated_at is 'Когда изменён товар';

......
```

После выполнения скрипта в Supabase появляются таблицы. Инициализация делает:

1. Создание таблицы меню
2. Таблица хранит название, описание, цену, категорию (бургер, гарнир, напиток), доступность.
3. Создание таблицы промокодов
4. Для управления скидками: код, тип скидки, размер.
5. Отключение RLS для удобства разработки
6. Примечание: RLS — критично для безопасности, в production это обязательно включать.
7. Вставка примеров данных
8. Таблицы наполняются примерами бургеров, гарниров, напитков, промокодов.

### Установка соединения с БД

БД готова, теперь связываем приложение. Нужно добавить URL и ключ Supabase. Два способа:

1. Через переменные окружения

Создайте `.env` в корне проекта:

```
NEXT_PUBLIC_SUPABASE_URL=https://ваш-проект.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=ваш-anon-key
```

2. Через интерфейс

На главной странице справа есть кнопка "Settings". Кликните, введите URL и ключ. После "Save" создаётся клиент Supabase:

```JavaScript
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Фабрика для демо: возвращает null если не настроено
export function maybeCreateBrowserClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anon) return null;
  return createClient(url, anon);
}
```

После инициализации БД и настройки Supabase Link видите интерфейс управления меню. Можете добавлять/удалять товары и смотреть изменения в Supabase Table Editor.

![интерфейс меню](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image37.png)

![товары в таблице](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image38.png)

### Домашнее задание

1. Добавьте и удалите несколько товаров, посмотрите в Supabase как меняются данные.

## 3.3 Проект 2 — Авторизация пользователей бургерной

Project 1 делал CRUD. Project 2 добавляет авторизацию и права доступа через Auth и RLS.

Project 2 имеет страницу входа, пользователи логируются через почту и пароль. Вызывает встроенный метод Supabase Auth:

```
const { error: err } = await supabaseClient.auth.signUp({
  email,
  password,
  options: {
    data: {
      full_name: fullName || null,
      birthday: birthday || null,
      avatar_url: avatarUrl || null
    }
  }
});
```

![страница входа](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image39.png)

После входа Supabase создаёт сессию, все запросы автоматически передают auth данные. RLS гарантирует, что каждый видит только свои данные (например, только свои покупки и кошелёк). Разные пользователи видят разное.

Как Project 1, нужно выполнить `init.sql` для инициализации (если ошибка, удалите таблицы в Table Editor или удалите проект и создайте новый).

После регистрации через почту и входа видите Shop:

![магазин](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image40.png)

Но Admin недоступен. Нужно найти в таблице поле роли пользователя и изменить на `admin` для доступа в Admin:

![админ панель](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image41.png)

Когда регистрируетесь, нужно подтвердить почту. Это можно отключить в Supabase Authentication, Sign In / Providers, отключив "Confirm email".

![отключение подтверждения](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image42.png)

### Домашнее задание

1. Получите новичка бонус и сделайте покупки.
2. Найдите в БД таблицу ролей пользователя и измените на `admin`, затем проверьте админ-панель.
3. Найдите таблицу кошелька и увеличьте баланс.

# 4. Разработка вашего первого приложения Supabase

Раньше вы учили основы БД, Supabase и авторизацию. Теперь пора разработать своё приложение с БД и авторизацией!

## 4.1 Стандартизированный процесс подключения Supabase к любому приложению

Есть стандартный процесс подключения Supabase к приложению:

1. Опишите требования ИИ
   1. Расскажите ИИ о вашем приложении и что нужно добавить. Пример: "У меня Todo приложение с локальным хранилищем, нужна синхронизация в облако Supabase. Какие таблицы создать? Какие операции?"
   2. Дополните требования: форматы полей (timestamp как `timestamptz`, деньги как целые числа центов), правила доступа (только свои Todo).
   3. Проверьте ответ ИИ, поправьте если чего упустили.
2. Генерируйте init.sql скрипт
   Попросите ИИ: "Создай init.sql скрипт для инициализации Supabase на основе таблиц выше." Запустите в SQL Editor. Если ошибка, покажите ИИ текст ошибки.
3. Переделайте код приложения
   Попросите: "Переделай код чтобы работал с Supabase БД и обрабатывал операции." ИИ изменит код для синхронизации с Supabase.
4. Настройте Supabase параметры и протестируйте
   1. Добавьте URL и ключ Supabase (обычно в `.env`).
   2. Тестируйте функции БД. Смотрите в Supabase Table Editor что изменяется.
   3. Если проблемы, опишите ИИ что происходит, ИИ найдёт и исправит.

Также можете добавить авторизацию: "Добавь систему авторизации Supabase с почтой и паролем." Укажите логику переходов (после входа куда идти, где кнопка входа). После интеграции протестируйте регистрацию/вход в Authentication разделе.

Если хотите, можете просить ИИ скопировать функции из другого проекта: "Пересели функции Supabase из проекта {путь} на основе того как там сделано."

## 4.2 Кейс: Онлайн змейка с рейтингом

Разберём реальный пример: добавим облачный рейтинг к игре "Змейка" с авторизацией.

![змейка](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image43.png)

### 4.2.1 Анализ требований

Сначала расскажите ИИ о проекте и необходимостях:

> "Есть игра змейка в {путь}. Нужен облачный рейтинг с авторизацией. Рейтинг показывает очки по имени и почте пользователя.
>
> Помоги спланировать: какие таблицы создать? Какие поля?"

Ответ ИИ:

![план таблиц](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image44.png)

### 4.2.2 Генерация init.sql

Попросите: "На основе плана создай init.sql для Supabase":

![init.sql](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image45.png)

### 4.2.3 Переделка кода

Попросите: "На основе плана и таблиц реализуй рейтинг Supabase. Рейтинг на отдельной странице, показывает очки по имени/почте, поддерживает авторизацию (регистрация/вход по почте), без авторизации нельзя играть."

Если диалог длинный, можно перезапустить, добавив init.sql в контекст.

Если логин работает неправильно, покажите ИИ код Project 2 как эталон: "Используй логику из {проект 2}."

Проверьте что правильно настроены Supabase параметры, без ошибок конфигурации. Если данные не сохраняются/не видны, расскажите ИИ что происходит, ИИ найдёт причину.

Успех: пользователь регистрируется, входит, видит свой рейтинг.

![рейтинг игра](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image46.png)

![рейтинг список](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image47.png)

### Домашнее задание

1. Добавьте авторизацию к демо змейки.
2. Добавьте авторизацию к вашему приложению.

# 5. Становимся мастером Supabase

Выше были основы. Дальше более глубокие функции Supabase, чтобы вы поняли почему мы выбрали Supabase и как использовать продвинутые функции для сложного взаимодействия.

Не нужно учить всё сразу. Пролистайте дальше и изучайте когда проект потребует.

## 5.1 Почему Supabase

Думаем: почему из всех бэкенд-решений выбрали Supabase?

Стартапы при выборе технологии стоят перед дилеммой: хочется полного контроля над системой, но нужно быстро выпустить продукт. Самодельный бэкенд требует месяцев разработки БД, realtime синхронизации, авторизации, API, хранилища файлов, задач, мониторинга и т.д. Это требует опыта. С ограниченным бюджетом и сжатыми сроками легко угодить в болото инфраструктуры и опоздать с фичами.

Supabase упаковывает эти функции в готовый облачный сервис (PostgreSQL, realtime, Auth, Storage, Edge Functions, API). Стартапы сосредоточиваются на核心 фичах вместо инфраструктуры — проверенная стратегия выживания.

Можно использовать альтернативы вроде PocketBase (ультралёгкий) или Appwrite (кроссплатформенный), но по полноте функций, зрелости SQL экосистемы и популярности на GitHub Supabase лидирует.

Важно: Supabase открыт с поддержкой приватного развёртывания, что снижает риск привязки к платформе в сравнении с закрытым Firebase.

Итог: выбирайте технологию под размер проекта. Для MVP и ранних пользователей Supabase достаточно и безопасен, он поддерживает интеграцию с Stripe, Resend, Cloudflare и другими сервисами. Даже при расширении можно использовать гибридный подход — разные функции на разных платформах. Supabase открытая архитектура гарантирует гибкость.

## 5.2 Вход через Google и GitHub

Раньше учили почту для входа. Реально мы хотим упростить через социальные сети Google и GitHub. Тут учим как это настроить, плюс сброс пароля.

Project `project-burger-shop-auth-advanced-supabase-6` полностью демонстрирует эти функции.

![продвинутая авторизация](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image48.png)

### 5.2.1 OAuth поток: как работает третий вход

Третий вход использует OAuth 2.0 — протокол "разрешение делегатом": пользователь разрешает приложению доступ к его публичной информации (почта, аватар) на Google/GitHub без раскрытия пароля.

5 шагов, пример с Google:

1. Пользователь нажимает "Sign in with Google", приложение перенаправляет на Google.
2. На Google странице пользователь логируется и разрешает права.
3. Google возвращает код авторизации (не сразу данные для безопасности).
4. Supabase обменивает код на Access Token у Google.
5. Supabase берёт данные пользователя через Token и создаёт аккаунт (или связывает существующий) и сессию.

![OAuth поток](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image49.png)

### 5.2.2 Получение Client ID и Secret от Google

1. **Заходим в Google Cloud Console**: https://console.cloud.google.com/
2. Создаём новый проект или используем существующий.
3. **Настраиваем OAuth consent screen**:
   - APIs & Services → OAuth consent screen
   - Выбираем "External"
   - Заполняем имя приложения, email поддержки
   - В "Authorized domains" добавляем `*.supabase.co`
   - Пропускаем "Scopes" и "Test users"
4. **Создаём Credentials**:
   - APIs & Services → Credentials
   - "+ CREATE CREDENTIALS" → "OAuth client ID"
   - "Web application"
   - Называем (например "Supabase Auth")
   - "Authorized redirect URIs": добавляем URL из Supabase (обычно `https://<project-id>.supabase.co/auth/v1/callback`)
   - Создаём
5. **Копируем Client ID и Client Secret**

### 5.2.3 Получение Client ID и Secret от GitHub

1. **GitHub Developer Settings**:
   - Логируемся, аватар → Settings
   - Developer settings (внизу слева)
2. **Регистрируем приложение**:
   - OAuth Apps → New OAuth App
   - Название: например "My Burger Shop"
   - Homepage URL: ваш сайт или `http://localhost:3000`
   - Authorization callback URL: URL из Supabase (обычно `https://<project-id>.supabase.co/auth/v1/callback`)
   - Register
3. **Копируем Client ID и Secret** (Secret можно сгенерировать при нужде)

### 5.2.4 Настройка в Supabase

1. **Supabase Dashboard**:
   - Authentication → Providers
2. **Google**:
   - Найти Google, включить
   - Вставить Client ID и Secret
   - Save
3. **GitHub**:
   - Найти GitHub, включить
   - Вставить Client ID и Secret
   - Save

![провайдеры включены](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image52.png)

Теперь можно входить через Google и GitHub! Берите Project 2 как пример и добавляйте авторизацию к своему приложению.

### 5.2.5 Сброс пароля

Полная авторизация включает сброс пароля. Project 2 это реализует. Процесс:

1. Пользователь забыл пароль, вводит почту
2. Фронтенд вызывает `supabase.auth.resetPasswordForEmail()`
3. Supabase отправляет письмо со ссылкой (URL на приложение, например /auth/reset)
4. Пользователь нажимает ссылку, видит форму нового пароля
5. Вводит пароль, фронтенд вызывает `supabase.auth.updateUser()` с новым паролем
6. Supabase проверяет ссылку и обновляет пароль

Если письмо слишком простое, кастомизируйте в Supabase Dashboard, Authentication → Email Templates.

![шаблоны писем](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image53.png)

Есть и другие функции (пригласить пользователя и т.д.), учите когда потребуется.

## 5.3 Реальные данные

Realtime — самая мощная фишка Supabase, для协作, чатов, рейтингов в реальном времени.

Project `project-burger-shop-realtime-orders-3` показывает чат и синхронизацию курсора через Realtime.

![realtime демо](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image54.png)

Если код сложный, ИИ поможет по документации.

### 5.3.1 Postgres Changes — мониторинг БД

Самое частое использование Realtime — слушать изменения БД. Когда данные меняются (INSERT, UPDATE, DELETE), Supabase через WebSocket пушит всем подписчикам, без опроса API.

Обычно включается в Table Editor кнопкой "Enable Realtime", но удобнее в SQL:

```sql
-- Включаем realtime репликацию
ALTER TABLE public.chat_messages REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;
END $$;
```

Этот код добавляет `chat_messages` в `supabase_realtime` публикацию, Supabase начинает слушать изменения.

Слушаем через код:

```typescript
    const sub = supabase
      .channel('chat_messages_channel')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'chat_messages'
      }, (payload: any) => {
        console.log('Новое сообщение:', payload.new);
        const newMessage = payload.new as Message;
        // ... //
      .subscribe((status: string) => {
        console.log('Статус подписки:', status);
      });
```

- `.channel('chat_messages_channel')`: отдельный канал для общения
- `.on('postgres_changes', ...)`: подписываемся на INSERT события таблицы chat_messages
- `payload.new`: когда добавляется сообщение, Supabase пушит данные всем подписчикам
- `.subscribe()`: начинает слушать

### 5.3.2 Broadcast & Presence — мгновенный обмен

Для временных данных (курсор мыши, онлайн статус) вместо БД используются Broadcast и Presence.

- **Presence**: отслеживает кто онлайн на канале.
- **Broadcast**: отправляет быстрые временные сообщения между клиентами.

Presence работает так:

1. Создаём канал с Presence
   ```
   const ch = supabase.channel('lobby_presence', {
     config: {
       presence: { key: anonymousUser.id },
     }
   });
   ```

2. При подписке объявляем своё присутствие
   ```
   const me = {
     id: anonymousUser.id,
     name: anonymousUser.name,
     color: anonymousUser.color
   };

   ch.subscribe(async (status) => {
     if (status === 'SUBSCRIBED') {
       await ch.track(me);
     }
   });
   ```

3. Слушаем список онлайн пользователей
   ```
   ch.on('presence', { event: 'sync' }, () => {
     const state = ch.presenceState();
     const flat = {};
     Object.values(state).forEach((arr) => {
       arr.forEach((u) => { flat[u.id] = { ...u }; });
     });
     setOnline(flat);
   });
   ```

4. Слушаем join/leave события
   ```
   ch.on('presence', { event: 'join' }, ({ key, newPresences }) => {
     console.log('Пользователь присоединился:', key, newPresences);
   });

   ch.on('presence', { event: 'leave' }, ({ key, leftPresences }) => {
     console.log('Пользователь ушёл:', key, leftPresences);
   });
   ```

Для эффектов вроде синхронизации курсора используем Broadcast (быстро, без БД):

1. Отправитель: шлёт позицию курсора
   ```typescript
   const handleMouseMove = (e) => {
     const payload = {
       id: anonymousUser.id,
       x: e.clientX,
       y: e.clientY,
       name: anonymousUser.name,
       color: anonymousUser.color
     };

     channelRef.current?.send({
       type: 'broadcast',
       event: 'cursor',
       payload
     });
   };

   document.addEventListener('mousemove', handleMouseMove);
   ```

2. Получатель: слушает и рисует чужие курсоры
   ```typescript
   ch.on('broadcast', { event: 'cursor' }, ({ payload }) => {
     setOnline((prev) => ({
       ...prev,
       [payload.id]: {
         ...(prev[payload.id] || {}),
         x: payload.x,
         y: payload.y
       }
     }));
   });
   ```

Presence управляет списком, Broadcast передаёт временные данные — вместе дают полноценный реал-тайм.

## 5.4 Хранилище

Помимо структурированных данных (профили, заказы), приложения хранят файлы (аватары, картинки товаров, документы). На главном сервере это нагрузка, медленность. Используют специализированное хранилище (Object Storage).

Файлы через URL: каждый файл получает уникальный URL (вроде "https://xxx.oss.com/avatar/user123.jpg"), браузер грузит прямо, не через сервер приложения. Скорость и масштабируемость.

Project `project-burger-shop-storage-uploads-4` показывает загрузку аватара пользователя через Supabase Storage и получение URL.

![загрузка файлов](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image55.png)

![интерфейс загрузки](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image56.png)

### 5.4.1 Хранилище — Buckets

Bucket — папка для файлов. Каждый может иметь свою политику доступа.

Файлы доступны через URL, но кто может загружать/скачивать определяется RLS политикой на `storage.objects` и `storage.buckets` таблицы.

Пример политики: только свои аватары, только jpg/png:

```
CREATE POLICY "Разрешить загрузку в avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid() = (storage.foldername(name))[1]::uuid AND
  (storage.extension(name) IN ('png', 'jpg', 'jpeg'))
);

CREATE POLICY "Публичный доступ к avatars"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );
```

### 5.4.2 Получение URL файла

После загрузки файл имеет путь (например "public/avatar1.png"). Это строка, не URL. Нужно преобразовать в ссылку для браузера.

Два способа:

#### 1. Публичный URL — постоянная ссылка

Если файл в публичном Bucket:

```typescript
const { data } = supabase.storage
  .from('avatars')
  .getPublicUrl('public/avatar1.png');
const publicUrl = data.publicUrl;
```

Плюсы: простой фиксированный URL, легко кешируется CDN. Минусы: рискует hotlink атакой (кто-то встроит ссылку на свой сайт, вы платите трафик).

#### 2. Подписанный URL — временная ссылка

Для безопасности используют временные ссылки:

```typescript
const { data, error } = await supabase.storage
  .from('avatars')
  .createSignedUrl('private/user-invoice.pdf', 3600); // 1 час
const signedUrl = data?.signedUrl;
```

Плюсы: ссылка имеет срок действия, контролируется доступ, нет hotlink атаки. Минусы: нужно генерировать ссылку каждый раз.

**Рекомендуется использовать подписанные URL по умолчанию**, только публичные URL для явно публичных ресурсов (логотип, промо картинки).

## 5.5 Граничные функции

Edge Function — бессерверные функции на краю сети для задач, которые нельзя в браузере: вызовы API с секретом, тяжёлые вычисления, контроль доступа.

Serverless означает "без управления серверами". Вы пишете функцию, облако запускает её по событию и платит за время выполнения.

Есть множество Edge Function сервисов: AWS Lambda@Edge, Cloudflare Workers, Vercel Edge Functions. Supabase Edge Functions на Deno и TypeScript, развёрнутые на краевых узлах.

Project `project-burger-shop-edge-function-5` демонстрирует чат с LLM через Edge Function.

![LLM чат](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image57.png)

### 5.5.1 LLM чат пример

Нужен чат с ChatGPT в приложении. Для OpenAI API нужен ключ — **нельзя в браузере**, утечка! Edge Function служит посредником:

Из `project-burger-shop-edge-function-5/scripts/llm-chat.ts`:

```typescript
// scripts/llm-chat.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { OpenAI } from "npm:openai";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

Deno.serve(async (req) => {
  try {
    const openai = new OpenAI({ apiKey: OPENAI_API_KEY });
    const { prompt } = await req.json();

    const stream = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }],
      stream: true,
    });

    return new Response(stream.toReadableStream(), {
      headers: { "Content-Type": "text/event-stream" },
    });
  } catch (err) {
  }
});
```

OPENAI_API_KEY хранится на сервере как переменная окружения, браузер его не видит. Безопасно.

### 5.5.2 Создание и развёртывание функции

Supabase позволяет создать функцию прямо в интерфейсе без командной строки:

1. **Заходим в Edge Functions панель**:
   - Supabase Dashboard → Edge Functions
2. **Создаём функцию**:
   - "Create a new function"
   ![новая функция](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image58.png)
   - Названием, например `llm-chat`
3. **Вставляем код**:
   ![редактор кода](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image59.png)
   - Удаляем шаблон
   - Копируем код из `llm-chat.ts`
   - Вставляем
4. **Настраиваем Secrets**:
   ![добавление secret](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image60.png)
   - Sidebar → Secrets
   - Name: `OPENAI_API_KEY`
   - Value: ваш OpenAI ключ
   - Save

После Deploy функция доступна онлайн. Несколько минут и готово.

Кроме LLM, Edge Functions делает: Webhook слушатели (Stripe платежи), отправку писем (Resend), генерацию изображений (Stability AI), сжатие картинок — широкий спектр.

Примеры в Project 5: txt2img.ts (генерация картинок), send-email.ts (отправка писем).

## 5.6 Clerk для входа

Clerk — специализированный сервис для управления пользователями (регистрация, вход, MFA, роли, сессии) без строительства своей системы.

Project `project-burger-shop-auth-advanced-clerk-7` показывает интеграцию Clerk и Supabase.

![clerk интеграция](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image61.png)

### 5.6.1 Создание Clerk приложения

1. **Регистрируемся**: https://dashboard.clerk.com/
2. **Создаём приложение**:
   ![создание приложения](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image62.png)
   - "Create application"
   - Имя, например "Burger Shop"
   - Способы входа: Email, Google, GitHub
   - Create
3. **Получаем ключи**:
   ![ключи Clerk](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image63.png)
   ![скопировать ключи](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image64.png)
   - Publishable key (`pk_...`) и Secret key (`sk_...`)
   - Добавляем в `.env.local`:
     ```bash
     NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
     CLERK_SECRET_KEY=sk_test_...
     ```

### 5.6.2 Интеграция Clerk с Supabase

Clerk и Supabase имеют встроенную интеграцию для упрощения авторизации:

1. **В Clerk включаем Supabase интеграцию**:
   - Clerk Dashboard → Integrations
   - Найти Supabase, включить
   - Скопировать Clerk Domain (формат: `https://<id>.clerk.accounts.dev`)
2. **В Supabase добавляем Clerk провайдер**:
   - Supabase Dashboard → Authentication → Providers
   - Add provider → Clerk
   - Вставляем Clerk Domain
   - Save

### 5.6.3 Синхронизация пользователей через Webhook

Clerk управляет авторизацией, но Supabase БД не синхронизируется автоматически. Webhook помогает:

1. Clerk отправляет Webhook при регистрации
2. Edge Function ловит и пишет в Supabase таблицу `users`

Сначала создаём таблицу пользователей:

```sql
-- Таблица для синхронизации пользователей Clerk
CREATE TABLE public.users (
  id TEXT NOT NULL PRIMARY KEY, -- Clerk User ID
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Включаем RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Политика: пользователь видит свой профиль
CREATE POLICY "Authenticated users can view their own user record"
ON public.users FOR SELECT
TO authenticated
USING ( (SELECT auth.jwt()->>'sub') = id );

-- Политика: пользователь меняет свой профиль
CREATE POLICY "Authenticated users can update their own user record"
ON public.users FOR UPDATE
TO authenticated
USING ( (SELECT auth.jwt()->>'sub') = id );
```

И Edge Function который ловит Webhook:

```JavaScript
// supabase/functions/clerk-webhooks/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { Webhook } from 'npm:svix'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Clerk Webhook secret из переменных окружения
const CLERK_WEBHOOK_SECRET = Deno.env.get('CLERK_WEBHOOK_SECRET')

if (!CLERK_WEBHOOK_SECRET) {
  throw new Error('CLERK_WEBHOOK_SECRET not set')
}
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  try {
    // 1. Получаем Svix заголовки
    const headers = Object.fromEntries(req.headers)
    const svix_id = headers['svix-id']
    const svix_timestamp = headers['svix-timestamp']
    const svix_signature = headers['svix-signature']

    if (!svix_id || !svix_timestamp || !svix_signature) {
      return new Response('Missing Svix headers', { status: 400 })
    }

    const payload = await req.json()
    const body = JSON.stringify(payload)

    // 2. Проверяем подпись Webhook
    const wh = new Webhook(CLERK_WEBHOOK_SECRET)
    const evt = wh.verify(body, {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature,
    })

    const { id } = evt.data
    const eventType = evt.type
    console.log(`Webhook: ${eventType} для пользователя: ${id}`)

    // 3. Выполняем операции БД на основе события
    switch (eventType) {
      case 'user.created': {
        const { id, first_name, last_name, image_url, email_addresses } = evt.data
        const { error } = await supabaseAdmin.from('users').insert({
          id,
          first_name,
          last_name,
          image_url,
          email: email_addresses[0]?.email_address,
        })
        if (error) throw error
        console.log(`Пользователь ${id} создан.`)
        break
      }

      case 'user.updated': {
        const { id, first_name, last_name, image_url, email_addresses } = evt.data
        const { error } = await supabaseAdmin
          .from('users')
          .update({
            first_name,
            last_name,
            image_url,
            email: email_addresses[0]?.email_address,
            updated_at: new Date().toISOString(),
          })
          .eq('id', id)
        if (error) throw error
        console.log(`Пользователь ${id} обновлён.`)
        break
      }

      case 'user.deleted': {
        const deletedId = id
        if (!deletedId) {
          return new Response('Deleted user ID not found', { status: 400 })
        }
        const { error } = await supabaseAdmin.from('users').delete().eq('id', deletedId)
        if (error) throw error
        console.log(`Пользователь ${deletedId} удалён.`)
        break
      }
    }

    return new Response('Webhook processed successfully', { status: 200 })
  } catch (err) {
    console.error('Error processing webhook:', err.message)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }
})
```

Затем в Clerk Dashboard → Webhooks добавляем Endpoint URL Edge Function и включаем события `user.created`, `user.updated`, `user.deleted`.

![webhook конфигурация](https://raw.githubusercontent.com/datawhalechina/easy-vibe/main/docs/zh-cn/stage-2/backend/database-supabase/images/image65.png)

### 5.6.4 Социальные входы в Clerk

До настройки соцсетей уточняем два среды: разработку и production.

- **Разработка**: локальный `localhost:3000`, для быстрого тестирования
- **Production**: онлайн сайт, требует реальные учётные данные

Clerk предоставляет общие OAuth ключи для разработки, но production требует собственные (подобие Google/GitHub конфигурации из раздела 5.2).

1. **Разработка** (простая):
   - Clerk Dashboard → SSO connections
   - Add connection → For all users
   - Выбираем GitHub или Google
   - Add connection (Clerk использует встроенные ключи)

2. **Production** (с собственными ключами):
   - Clerk Dashboard → SSO connections → Add connection → For all users → Use custom credentials
   - Копируем Callback URL из Clerk
   - На GitHub/Google регистрируем приложение (как в 5.2)
   - Получаем Client ID и Secret
   - Вставляем в Clerk, Add connection

Полное описание есть в документации.

Тестируем: Clerk Dashboard → Account Portal → Sign-in, нажимаем "посетить страницу входа", тестируем GitHub/Google вход.

# 6. От Supabase к компонентам бэкенда (продвинуто)

Раньше смотрели Supabase как платформу. Но каждый компонент (Auth, Storage, Edge Functions, Realtime, Database) имеет альтернативы в экосистеме.

**Почему учить альтернативы?**
- Проверить нужен ли Supabase полностью или части можно заменить
- При масштабировании понять что можно отделить от Supabase
- Расширить кругозор, знать опции если не используешь Supabase

Раздел сравнивает основные компоненты и альтернативные варианты.

## Сравнимые BaaS платформы

Есть альтернативные платформы "всё-в-одном", если Supabase не подходит:

| Платформа          | Тип                                  | Бесплатно/цена                    | Особенности                                                             |
| ------------------ | ------------------------------------ | --------------------------------- | ----------------------------------------------------------------------- |
| Firebase           | BaaS (Auth + Firestore + Storage)   | Spark: бесплатно; Blaze: по факту | Зрелая, документация, NoSQL, дорого масштабируется                     |
| Supabase           | BaaS (Postgres + Auth + Storage)    | Бесплатно 500MB; Pro: по факту    | SQL, современная, можно самостоятельно развёртывать                   |
| Appwrite Cloud     | BaaS открытого кода                 | Бесплатно базовое; платно расширено | Современная, самостоятельно развёртываемая, API унифицированный       |
| Nhost              | Postgres + GraphQL + Auth + Storage | Бесплатно 1GB; платно больше      | GraphQL для фронтенда, легче интеграция с React                       |
| AWS Amplify        | BaaS AWS                            | Бесплатно частично; платно        | Мощная, для тех кто в AWS, сложная кривая обучения                    |
| Xata               | DB + API + Auth (быстро растёт)    | Бесплатно 250k; платно больше     | Отличный UX, не всё включено, но главное есть                         |
| Convex             | DB + Auth + Functions (front-first) | Бесплатно разработка; платно      | Быстрый старт, привязка к платформе                                    |

## Аутентификация (Auth)

| Сервис              | Особенности                                | Бесплатно              | Применение                                          |
| ------------------- | ------------------------------------------ | ---------------------- | ---------------------------------------------------- |
| Firebase Auth       | Google BaaS Auth, соцсети, простая        | Spark: 50k пользователей| Быстрый старт, простая, Firebase экосистема       |
| Auth0 (Okta)        | Корпоративная Auth, MFA, SAML             | 25k пользователей      | Большие приложения, мощная, дорогая                |
| AWS Cognito         | AWS Auth сервис, SAML, соцсети           | 10k пользователей/мес  | Уже в AWS, интеграция с сервисами                 |
| Logto               | Открытая Auth, самостоятельная           | Облако: 50k пользователей| Auth0 альтернатива, современная, растёт быстро   |
| Keycloak            | Открытая IAM/SSO, LDAP, SAML             | Бесплатно (самостоятельно)| Мощная, сложная в настройке, корпоративная        |

## Файловое хранилище (Storage)

| Сервис               | Тип                 | Бесплатно                        | Применение                                                       |
| -------------------- | ------------------- | -------------------------------- | ---------------------------------------------------------------- |
| Amazon S3            | Облачное хранилище  | 5GB + 20k запросов/мес           | Стандарт индустрии, надёжное, сложное ценообразование          |
| Google Cloud Storage | Облачное хранилище  | 1GB в Firebase; платно после     | Google интеграция, CDN, удобное                                 |
| Tencent COS / Alibaba OSS | Облачное (Китай) | По факту с бонусами             | Для Китая, быстрое, хорошая документация                        |
| MinIO                | Открытое S3-совместимое | Бесплатно (самостоятельно)     | Лёгкое, S3 API, приватное облако                                |
| Cloudinary / Imgix   | Медиа-хранилище+CDN | 25GB/мес бесплатно              | Оптимизация картинок/видео, медиа проекты                       |

## Граничные функции (Edge Functions)

| Сервис                    | Особенности                  | Бесплатно                     | Применение                                            |
| ------------------------- | ----------------------------- | ----------------------------- | ----------------------------------------------------- |
| Cloudflare Workers        | JS на краю Cloudflare         | 100k запросов/день            | Быстро, низкая задержка, простая                     |
| Vercel Edge Functions     | JS/TS с Next.js интеграцией  | 1M запросов/мес               | Для Next.js, удобная, хороший бесплатный лимит     |
| Netlify Edge / Functions  | Node.js функции + маршруты   | 300 токенов/мес              | Простая, Git интеграция, обмен токенами              |
| AWS Lambda@Edge           | AWS функции на CDN            | 1M запросов + 400k GB-s       | AWS мощь, сложно настраивать, дороже                 |

## Realtime / Pub-Sub

| Сервис            | Особенности              | Бесплатно               | Применение                                     |
| ----------------- | ----------------------- | ----------------------- | ---------------------------------------------- |
| Firebase Realtime | Google realtime БД       | 1GB + лимиты в Spark   | Firebase экосистема, простая, слабые запросы |
| Ably              | Realtime сообщения       | 6M сообщений/мес        | Мощная, высокая надёжность, видеочаты         |
| Pusher Channels   | WebSocket события        | 200k сообщений/день     | Простая, документация, чаты                    |
| Самостроительный WebSocket | Node.js/Go/Elixir | Свой сервер            | Гибкость максимальная, сложность высокая      |

## Базы данных

| Сервис                  | Тип              | Бесплатно              | Особенности                                                  |
| ----------------------- | ---------------- | ---------------------- | ------------------------------------------------------------ |
| Neon (PostgreSQL)       | SQL бессерверный | 0.5GB хранилище        | Облачный Postgres, автомасштабирование, ветвления для тестов|
| Aiven PostgreSQL        | SQL托管          | 1GB; платно больше     | Управляемый Postgres, мультиобласть, мониторинг            |
| CockroachDB Cloud       | Распределённый SQL | 10GB                  | Как Google Spanner, горизонтальное масштабирование          |
| TiDB Cloud              | Распределённый SQL | 25GB                  | MySQL-совместимое, отличная производительность              |
| MongoDB Atlas           | NoSQL документы  | 0.5GB M0 кластер       | MongoDB облако, гибкие документы, масштабируется           |

Альтернативы выбираются по проекту. Для MVP и малых проектов Supabase и его компоненты часто достаточны. При масштабировании смешивайте инструменты под задачу.

# Заключение

В этом уроке мы изучили основы БД, Supabase и как строить приложения. Обращайтесь к этому руководству при разработке.

Помните принцип: **сначала готово, потом совершенно!** Не стремитесь к идеалу с первого раза, совершенствуйте итеративно.

# Домашнее задание

1. Разработайте приложение с авторизацией и БД. Включите дополнительные функции Supabase (Realtime / Storage / Edge Functions).
