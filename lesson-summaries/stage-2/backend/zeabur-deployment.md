# Как развернуть веб-приложение

> Этап 2 · Бэкенд

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-2/backend/zeabur-deployment.md) · [Полный перевод](../../../lesson-originals-ru/stage-2/backend/zeabur-deployment.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/zeabur-deployment/index.md)

Развёртывание публикует приложение в интернете. Low-code-платформы (CloudBase, Vercel, Netlify, Zeabur) автоматизируют сервер и запуск; Zeabur гибок для сложных проектов.

- Выбор платформы по задаче: Vercel/Netlify — фронтенд, Zeabur — Dify, n8n.
- Zeabur слушает только порт 8080 (React по умолчанию 3000 — поменять).
- Развёртывание через GitHub-репозиторий или Docker-образ; nginx как точка входа.
- Бесплатный лимит ~5 USD/мес — неиспользуемые сервисы останавливать (Suspend).
