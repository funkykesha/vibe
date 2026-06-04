# От NanoBanana к собственному Agent для производства ассетов

> Этап 2 · Фронтенд

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-2/frontend/lovart-assets.md) · [Полный перевод](../../../lesson-originals-ru/stage-2/frontend/lovart-assets.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/frontend/lovart-assets/index.md)


Путь от генерации первой картинки через API NanoBanana и инструмент Lovart до сборки своего агента автоиллюстрации статей.

- Сырой API исполняет команду, но не дробит цель на шаги — нужен агент
- Lovart добавляет слой понимания и планирования поверх базовой модели
- Ключ: разделить «понимание» (LLM) и «исполнение» (модель изображений)
- Ценность — production-уровень ассетов и своя система-помощник
