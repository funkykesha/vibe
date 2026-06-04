# От базы данных к Supabase

> Этап 2 · Бэкенд

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-2/backend/database-supabase.md) · **Расширенно** · [Полный перевод](../../../lesson-originals-ru/stage-2/backend/database-supabase.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/database-supabase/index.md)

## О чём урок
Урок объясняет, что такое данные и базы данных, в чём разница между реляционными (SQL) и нереляционными (NoSQL) хранилищами, а затем переходит к Supabase — современной BaaS-платформе (Backend as a Service) на базе PostgreSQL. Цель — превратить работающее приложение в полноценный онлайн-продукт с базой данных и системой пользователей, не строя бэкенд-инфраструктуру с нуля.

## Ключевые темы
- Формы представления данных: переменные, таблицы, JSON, векторы (embedding); зачем нужна база данных (персистентность, запросы, производительность, целостность, безопасность).
- Реляционные БД (строгая схема, внешние ключи, JOIN) против NoSQL (документная модель, агрегация данных, гибкость, компромисс с избыточностью).
- Supabase как BaaS: PostgreSQL плюс Auth, Storage, Realtime, Edge Functions, Vector.
- Модули консоли Supabase: Table Editor, SQL Editor, Database, Authentication, Storage (совместимость с S3), Edge Functions, Realtime, Project Settings (URL и API-ключи).
- Базовые SQL-операции: `CREATE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE` на примере таблицы заказов; внешние ключи.
- Row Level Security (RLS) — построчная защита доступа через `auth.uid()`.

## Главные выводы
- База данных решает проблему персистентного хранения, эффективных запросов и безопасности данных, которых не было бы при хранении в памяти приложения.
- Выбор типа БД зависит от сценария: реляционные — для строгой согласованности (финансы, заказы), NoSQL — для гибких и высоконагруженных read-heavy сценариев.
- Supabase сокращает путь от прототипа до готового продукта, предоставляя БД и пользовательскую систему «из коробки».
- Edge Functions служат безопасным промежуточным слоем: секретные ключи (OpenAI, Stripe) хранятся на сервере через secrets и `Deno.env.get`, а не во фронтенде.
- service_role-ключ обходит RLS и никогда не должен попадать на клиент; anon public-ключ ограничен политиками RLS.

## Инструменты и технологии
- Supabase, PostgreSQL, SQL
- Auth, Storage (S3-совместимый), Realtime (WebSocket), Edge Functions (Deno)
- RLS, JSON/JSONB, Clerk (сторонний Auth), Trae / Claude Code для клонирования демо-репозитория
