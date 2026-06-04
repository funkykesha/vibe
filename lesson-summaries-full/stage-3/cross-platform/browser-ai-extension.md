# Как разработать браузерное AI-расширение — суммаризация любой веб-страницы в один клик

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/browser-ai-extension.md) · **Расширенно** · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/browser-ai-extension.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/browser-ai-extension/index.md)


## О чём урок
Урок проводит полный цикл создания AI-расширения для Chrome под названием «AI Page Summarizer»: оно читает содержимое любой открытой страницы и генерирует краткое резюме с помощью AI. Показаны разработка, отладка и публикация в Chrome Web Store. Большая часть кода пишется в стиле vibecoding через AI-ассистента (Cursor / Trae / Claude Code).

## Ключевые темы
- Архитектура расширения на Manifest V3: manifest.json (права доступа), Service Worker (фоновая логика), Content Script (чтение DOM), Side Panel (интерфейс), Options Page (настройки).
- Поток сообщений: клик по иконке → боковая панель → Service Worker → Content Script читает текст страницы → вызов AI API → отображение резюме.
- Два способа получить AI: облачный API (OpenAI / Claude) и встроенный в Chrome AI (Summarizer API на Gemini Nano) — локальный, бесплатный, без API-ключа, начиная с Chrome 138.
- Загрузка распакованного расширения, отладка Service Worker / боковой панели / Content Script через разные контексты DevTools.
- Публикация: упаковка в .zip, регистрация разработчика ($5), заполнение информации и privacy-практик, отправка на ревью.

## Главные выводы
- Manifest V3 разделяет ответственность между компонентами; минимальные права (activeTab, storage, scripting, sidePanel) ускоряют прохождение ревью.
- Встроенный AI Chrome снижает порог входа: можно строить AI-расширения вообще без API-ключа, но он требует Chrome 138+ и достаточного железа.
- Хранить API-ключ в chrome.storage.local допустимо для себя; при публикации безопаснее проксировать запросы через свой бэкенд.
- Та же архитектура подходит для расширений-переводчиков, аннотаторов, трекеров цен и объяснителей кода.

## Инструменты и технологии
- Chrome Extensions (Manifest V3), Service Worker, Content Script, Side Panel API, chrome.storage.
- Chrome встроенный AI — Summarizer API (Gemini Nano), OpenAI API (gpt-4o-mini), Claude API.
- AI-ассистенты: Cursor / Trae / Claude Code; Chrome Web Store Developer Dashboard.
