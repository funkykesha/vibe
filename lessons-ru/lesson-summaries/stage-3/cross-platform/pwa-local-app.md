# Как разработать локальное PWA-приложение — превратить веб-страницу в «настоящее приложение»

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/pwa-local-app.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/pwa-local-app.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/pwa-local-app/index.md)


Превращение React-проекта «Помидорная ферма» в PWA — устанавливаемое, работающее офлайн приложение.

- Инструменты: React, TypeScript, Vite, vite-plugin-pwa, Service Worker, Workbox.
- Service Worker работает только в продакшен-сборке — офлайн тестируют через build/preview.
- Деплой на Vercel (HTTPS обязателен), установка на Android (Chrome) и iPhone (Safari).
- iOS ограничен: установка только через Safari, push с 16.4+, нет Background Sync.
