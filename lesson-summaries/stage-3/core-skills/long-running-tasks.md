# Как заставить Claude Code работать долго

> Этап 3 · Ключевые навыки

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/long-running-tasks.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/core-skills/long-running-tasks.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/long-running-tasks/index.md)


AI часто останавливается «слишком рано», решив, что готово. Урок объясняет, как заставить Claude Code работать в цикле, пока задача действительно не выполнена (техника Ralph Wiggum и др.).

- LLM не оценивает завершённость объективно — нужен внешний контур проверки.
- Методы: While True Bash Loop, Ralph Wiggum (Stop Hook), Agent Teams, фоновые задачи.
- Качество промпта решает всё: критерии приёмки и маркер завершения.
- Обязательна защита от бесконечной работы и неконтролируемых расходов API.
