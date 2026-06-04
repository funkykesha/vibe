# Как разработать браузерное AI-расширение — суммаризация любой веб-страницы в один клик

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/browser-ai-extension.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/browser-ai-extension.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/index.md)


Полный цикл создания Chrome-расширения «AI Page Summarizer», которое читает страницу и генерирует резюме через AI.

- Архитектура Manifest V3: Service Worker, Content Script, Side Panel, Options Page.
- Два источника AI: облачный API (OpenAI/Claude) и встроенный Summarizer API (Gemini Nano, Chrome 138+).
- Минимальные права ускоряют ревью; при публикации лучше проксировать ключ через бэкенд.
- Та же архитектура годится для переводчиков, аннотаторов и трекеров цен.
