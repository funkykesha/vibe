# От базы данных к Supabase

> Этап 2 · Бэкенд

Supabase — это BaaS на PostgreSQL с Auth, Storage, Realtime и Edge Functions, дающий БД и систему пользователей «из коробки».

- Реляционные БД (SQL) — для строгой согласованности, NoSQL — для гибкости.
- SQL-операции: `CREATE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`; внешние ключи.
- RLS защищает данные построчно через `auth.uid()`.
- Секретные ключи держать в Edge Functions; service_role обходит RLS и не идёт на клиент.
