# Как разработать кроссплатформенное настольное приложение на Electron — преобразование речи в текст

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/electron-voice-to-text.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/electron-voice-to-text.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/electron-voice-to-text/index.md)

Полный цикл создания настольного приложения «речь в текст» на Electron с облачным и локальным распознаванием, сборка под Windows, macOS и Linux.

- Архитектура: Main и Renderer изолированы, связь через IPC и preload-мост.
- Вариант A — OpenAI Whisper API; вариант B — локальный whisper.cpp (приватность, офлайн).
- Web Speech API в Electron не работает — поэтому Whisper.
- Минус Electron — большой размер (упакован Chromium); модель качать при первом запуске.
