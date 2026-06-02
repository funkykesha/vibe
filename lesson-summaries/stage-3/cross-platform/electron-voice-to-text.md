# Как разработать кроссплатформенное настольное приложение на Electron — преобразование речи в текст

> Этап 3 · Кроссплатформенная разработка

## О чём урок
Урок проводит полный цикл создания настольного приложения «речь в текст» на Electron с поддержкой двух режимов распознавания — облачного API и локальной модели — и итоговой сборкой под Windows, macOS и Linux. Показаны архитектура процессов Electron, запись с микрофона и интеграция Whisper.

## Ключевые темы
- Что такое Electron: HTML/CSS/JS + Chromium + Node.js для настольных приложений на трёх платформах.
- Архитектура: главный процесс (Main), процесс рендеринга (Renderer), preload-скрипт как мост, IPC-коммуникация через contextBridge.
- Создание проекта через Electron Forge (шаблон Vite), структура файлов.
- Запись звука: navigator.mediaDevices.getUserMedia, MediaRecorder (webm), передача ArrayBuffer в главный процесс; обработка разрешения на микрофон.
- Вариант A — облачный: OpenAI Whisper API ($0.006/мин), вызов в главном процессе, панель настроек с API Key.
- Вариант B — локальный: whisper.cpp через nodejs-whisper, выбор модели (tiny → large-v3), ускорение на Apple Silicon (Metal/Neural Engine) и CUDA.
- Сборка и распространение через electron-forge make (.dmg/.zip, .exe, .deb/.rpm), оптимизация размера, подпись кода.

## Главные выводы
- Renderer и Main изолированы — взаимодействие только через IPC и безопасный preload-мост.
- Web Speech API в Electron не работает (Google закрыл поддержку для не-Chrome оболочек), поэтому нужны Whisper API или whisper.cpp.
- Локальная модель даёт приватность и офлайн; на Apple Silicon распознавание быстрее реального времени.
- Минус Electron — большой размер (упакован весь Chromium); локальную модель лучше скачивать при первом запуске.

## Инструменты и технологии
- Electron, Electron Forge, Vite, IPC, contextBridge.
- MediaRecorder, getUserMedia, OpenAI Whisper API, whisper.cpp / nodejs-whisper.
- AI-ассистент (Cursor/Trae/Claude Code), windeployqt-аналоги (electron-forge make).
