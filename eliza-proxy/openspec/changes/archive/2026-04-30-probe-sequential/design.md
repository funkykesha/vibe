## Context

Текущий probe.js использует `mapWithConcurrency(models, CONCURRENCY=15, probeModel)` для параллельной проверки моделей. Это быстро (16 сек для 58 моделей), но весь результат приходит пакетом в конце — `onModelProbed` вызывается 58 раз подряд.

Нужно изменить на последовательный вызов: проверяем модели по одной, `onModelProbed` вызывается после каждой модели.

## Goals / Non-Goals

**Goals:**
- Убрать параллельность из probe, использовать последовательный loop
- Каждая модель имеет свой try-catch
- `onModelProbed` вызывается для каждой модели по мере завершения

**Non-Goals:**
- Оптимизировать скорость (последовательный медленнее)
- Менять интерфейс callback или API

## Decisions

**Решение: `for await...of` loop вместо `mapWithConcurrency`**

```javascript
async function runProbe(models, token, baseUrl) {
  const results = [];
  for (const model of models) {
    try {
      const result = await probeModel(model, token, baseUrl);
      if (result.ok) {
        const withProbe = { ...model, probe: { ... } };
        if (onModelProbed) onModelProbed(withProbe.provider, withProbe);
        results.push(withProbe);
      } else {
        const failed = { ...model, probe: { status: 0 } };
        if (onModelProbed) onModelProbed(failed.provider, failed);
      }
    } catch (err) {
      const failed = { ...model, probe: { status: 0 } };
      if (onModelProbed) onModelProbed(failed.provider, failed);
    }
  }
  return results;
}
```

Это выполняет probeModel для каждой модели последовательно и сразу вызывает callback.

## Risks / Trade-offs

- [Performance] Время probe вырастет до 2-4 минут (vs 16 сек сейчас)
- [UX] Пользователь видит медленный прогресс, но видит в реальном времени
- [Simplicity] Код проще (нет mapWithConcurrency logic)
