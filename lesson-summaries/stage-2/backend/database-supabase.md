# От базы данных к Supabase

> Этап 2 · Бэкенд

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-2/backend/database-supabase.md) · [Полный перевод](../../../lesson-originals-ru/stage-2/backend/database-supabase.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/database-supabase/index.md)

Supabase — это BaaS на PostgreSQL с Auth, Storage, Realtime и Edge Functions, дающий БД и систему пользователей «из коробки».

- Реляционные БД (SQL) — для строгой согласованности, NoSQL — для гибкости.
- SQL-операции: `CREATE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`; внешние ключи.
- RLS защищает данные построчно через `auth.uid()`.
- Секретные ключи держать в Edge Functions; service_role обходит RLS и не идёт на клиент.
