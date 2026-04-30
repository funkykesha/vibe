# Eliza API: Подключение к моделям

**Обновлено:** 2026-04-30  
**Источник:** eliza-proxy documentation + Arcadia examples

---

## Доступность моделей с текущим токеном

**Работающие модели (internal/communal):**
- `deepseek-v3-1-terminus` ✅
- `deepseek-v3-2` ✅
- `glm-4-7` ✅

**Недоступные модели (требуют sec-review):**
- Claude (claude-*) ❌ - внешние Anthropic модели
- Google (gemini-*) ❌ - внешние Google модели
- DeepSeek external (deepseek-chat, deepseek-reasoner) ❌ - внешние DeepSeek модели
- OpenAI (gpt-*) ❌ - внешние OpenAI модели
- Другие внешние провайдеры ❌

**Примечание:** Если модель показывает ❌ при probe, проверьте:
1. Имеет ли ваш токен доступ к внешним моделям
2. Пройден ли sec-review для желаемого провайдера
3. Является ли модель внутренней (communal) или внешней

---

## Что такое Eliza

Eliza — общеяндексовая точка входа для работы с LLM. Предоставляет:
- Доступ к внешним моделям (OpenAI, Google, Anthropic, ... и др.)
- Доступ к внутренним LLM-моделям (Yandex GPT, DeepSeek, GLM и др.)
- Единую точку входа для всех моделей
- OAuth-авторизацию через `SOY_TOKEN` или `ELIZA_TOKEN`

---

## Базовый URL API

```
https://api.eliza.yandex.net
```

---

## Типы моделей и эндпоинты

### Внешние модели (External)

Провайдеры: OpenAI, Anthropic, Google, Together, OpenRouter, Alibaba/Qwen, GigaChat

| Эндпоинт | Провайдер | Примеры моделей |
|----------|-----------|-----------------|
| `/raw/openai/v1` | OpenAI | `gpt-4o`, `gpt-4o-mini`, `gpt-5.x` |
| `/raw/anthropic/v1` | Anthropic | `claude-3-opus`, `claude-3-5-sonnet`, `claude-4-sonnet` |
| `/raw/openrouter/v1` | OpenRouter | `openai/*`, `deepseek/*`, `google/*` (external gemini) |
| `/raw/together/v1` | Together | `deepseek/*`, `qwen/qwq-*` |
| `/raw/alibaba/v1` | Alibaba | `qwen3-vl-*` |
| `/raw/gigachat/v1` | GigaChat | `GigaChat-Pro`, `GigaChat-Max` |

**Important:** Для внешних моделей часто требуется прохождение sec-review. См. https://wiki.yandex-team.ru/eliza/api/#dostup-dlya-robotov-i-kpb

**Важно:** Внешние модели (Claude, Google, внешние DeepSeek, GigaChat и др.) требуют специального одобрения (sec-review) и могут быть недоступны с текущим токеном. Если внешние модели показывают ❌ при probe, это означает отсутствие необходимых прав доступа, а не ошибку в маршрутизации.

### Внутренние модели (Internal)

Провайдеры: Yandex (GPT-OSS, YandexGPT), DeepSeek, GLM, Qwen, Zeliboba

| Эндпоинт | Провайдер | Примеры моделей |
|----------|-----------|-----------------|
| `/raw/internal/gpt-oss-20b/v1` | Yandex GPT-OSS | `gpt-oss-20b` |
| `/raw/internal/gpt-oss-120b/v1` | Yandex GPT-OSS | `gpt-oss-120b` |
| `/raw/internal/deepseek-r1-runtime/v1` | DeepSeek R1 | `deepseek-r1-runtime`, `internal-deepseek-r1` |
| `/raw/internal/glm-45-runtime/v1` | GLM 45B | `glm-45-runtime` |
| `/raw/internal/glm-4-7/v1` | GLM 4 7B | `glm-4-7` |
| `/raw/internal/qwen3-235b/v1` | Qwen 235B | `qwen3-235b`, `qwen/qwen3-235b-a22b-2507` |
| `/raw/internal/qwen3-coder-480b-a35b-runtime/v1` | Qwen Coder | `qwen3-coder-480b-a35b-runtime` |
| `/raw/internal/qwen3_235b_a22b_2507_fp8/v1` | Qwen 235B FP8 | `qwen3_235b_a22b_2507_fp8` |
| `/raw/internal/deepseek-v3-1-terminus/v1` | DeepSeek Terminus | `deepseek-v3-1-terminus` |
| `/internal/zeliboba/{model}/generative/v1/chat` | Zeliboba | `32b_aligned_quantized_202506`, `32b_aligned_quantized_202506_reasoner` |

### Получение списка моделей

```python
def get_models(internal: bool = False) -> dict:
    url = "https://api.eliza.yandex.net/models"
    if internal:
        url = "https://api.eliza.yandex.net/internal/v1/models"

    headers = {
        "authorization": f"OAuth {os.getenv('SOY_TOKEN')}"
    }

    response = requests.get(url, headers=headers).json()
    return response
```

---

## Примеры подключения

### Пример 1: OpenAI SDK (Python)

```python
import os
from openai import OpenAI
import httpx

# Метод 1: Прямой вызов через raw endpoint
client = OpenAI(
    base_url="https://api.eliza.yandex.net/raw/internal/gpt-oss-120b/v1",
    api_key=os.getenv("SOY_TOKEN"),
    http_client=httpx.Client(verify=False)
)

response = client.chat.completions.create(
    model="gpt-oss-120b",
    messages=[{"role": "user", "content": "Hello!"}],
    max_tokens=1000
)
```

```python
# Метод 2: Через OpenAI-compatible endpoint
client = OpenAI(
    base_url="https://api.eliza.yandex.net/openai/v1",
    api_key=os.getenv("SOY_TOKEN"),
    default_headers={
        "authorization": f"OAuth {os.getenv('SOY_TOKEN')}",
        "content-type": "application/json"
    },
    http_client=httpx.AsyncClient(verify=False, timeout=10.0)
)

response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

```python
# Метод 3: Через Anthropic endpoint
from anthropic import Anthropic

client = Anthropic(
    api_key=os.getenv("SOY_TOKEN"),
    baseURL="https://api.eliza.yandex.net/anthropic",
    timeout=120000
)

response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}]
)
```

### Пример 2: Go (library/go/yandex/eliza)

```go
package main

import (
    "context"
    "log/slog"

    "go.yandex-team.ru/library/go/yandex/eliza"
)

func main() {
    ctx := context.Background()
    client := eliza.New(eliza.WithLogger(slog.Default()))

    model := "internal-deepseek" // или "claude-sonnet-4-0", "gpt-4o-mini"

    response, err := client.Chat(ctx, model, []eliza.Message{
        eliza.UserMessage("Что такое Яндекс?"),
    })

    if err != nil {
        slog.Error("error occurred", "err", err)
        return
    }

    slog.Info("response received",
        "message", response.Message,
        "cost", response.Cost,
        "reasoning", response.Reasoning, // Для моделей с thinking
    )
}
```

### Пример 3: JavaScript/TypeScript

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://api.eliza.yandex.net/raw/internal/glm-45-runtime/v1',
  apiKey: process.env.ELIZA_TOKEN,
});

const response = await client.chat.completions.create({
  model: 'glm-45',
  messages: [{ role: 'user', content: 'Hello!' }],
  max_tokens: 1000,
});

console.log(response.choices[0].message.content);
```

### Пример 4: HTTP Requests (без SDK)

```python
import requests
import os

def call_completion(model: str, content: str):
    main_url = "https://api.eliza.yandex.net/"

    model_dict = {
        "gpt": ["gpt-4o-2024-11-20", "/openai/v1/chat/completions"],
        "deepseek-v3": ["deepseek", "/internal/deepseek/v1/chat/completions"],
        "deepseek-r1": ["deepseek-r1-runtime", "/internal/deepseek-r1-runtime/v1/chat/completions"],
        "glm45": ["glm-45-runtime", "/raw/internal/glm-45-runtime/v1/chat/completions"],
        "qwen-235b": ["qwen/qwen3-235b-a22b-2507", "/openrouter/v1/chat/completions"],
    }

    if model not in model_dict:
        raise RuntimeError(f"Model {model} not supported")

    model_name, path = model_dict[model]
    url = main_url + path

    payload = {
        "model": model_name,
        "messages": [{"role": "user", "content": content}]
    }

    headers = {
        "authorization": f"OAuth {os.getenv('SOY_TOKEN')}",
        "content-type": "application/json"
    }

    response = requests.post(url, json=payload, headers=headers).json()
    return response
```

---

## Авторизация

### Требуемые токены

- **SOY_TOKEN** — OAuth токен для сервисов Яндекса
- **ELIZA_TOKEN** — альтернативное имя для того же токена

### Получение токена

```
https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80
```

### Формат авторизации

```python
# Метод 1: Через header
headers = {
    "authorization": f"OAuth {os.getenv('SOY_TOKEN')}",
    "content-type": "application/json"
}

# Метод 2: Через api_key (для OpenAI SDK)
client = OpenAI(
    api_key=os.getenv("SOY_TOKEN"),  # Eliza использует значение как токен
    base_url="https://api.eliza.yandex.net/openai/v1"
)

# Метод 3: Через X-Custom-API-Key (для внешних моделей с собственными ключами)
headers = {
    "authorization": f"OAuth {os.getenv('SOY_TOKEN')}",
    "X-Custom-API-Key": "your_external_api_key"
}
```

---

## Пулы (Quota Pools)

Для управления и статистики использования можно указывать пул:

```python
# Через header
headers = {
    "authorization": f"OAuth {os.getenv('SOY_TOKEN')}",
    "Ya-Pool": "my_project_pool"
}

# Для OpenAI SDK
import openai
openai.api_key = os.getenv("SOY_TOKEN")
openai.base_url = "https://api.eliza.yandex.net/openai/v1"

response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[...],
    extra_headers={"Ya-Pool": "my_project_pool"}
)
```

---

## Особенности ответов

### Стандартный формат (OpenAI-compatible)

```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o-mini",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Ответ модели"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30,
    "cost_usd": 0.0015
  }
}
```

### Модели с reasoning (DeepSeek R1, Qwen3 Thinking)

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Финальный ответ",
        "reasoning_content": "Мысли модели перед ответом..."
      },
      "finish_reason": "stop"
    }
  ],
  "reasoning": {
    "content": "Расширенная информация о рассуждениях",
    "tokens": 500
  },
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "reasoning_tokens": 500,  // Отдельный счетчик для reasoning
    "total_tokens": 530
  }
}
```

**Обработка reasoning в коде:**

```python
# Вариант 1: Через reasoning_content
thought = response.choices[0].message.get("reasoning_content", None)
content = response.choices[0].message.get("content", None)

# Вариант 2: Парсинг тегов <thinking>
if content and "<thinking>" in content:
    thought, content = content.split("</thinking>", 1)
    thought = thought.replace("<thinking>", "").strip()
```

---

## Streaming (SSE)

Eliza поддерживает SSE streaming для всех моделей:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.eliza.yandex.net/openai/v1",
    api_key=os.getenv("SOY_TOKEN")
)

stream = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

Формат SSE в eliza-proxy (нормализованный):

```
data: {"delta":"Hello"}
data: {"delta":" world"}
data: {"usage":{"input":5,"output":10,"cost_usd":0.002}}
data: [DONE]
```

---

## Tool Calling / Function Calling

Поддерживается для OpenAI и Anthropic моделей:

```python
client = OpenAI(
    base_url="https://api.eliza.yandex.net/openai/v1",
    api_key=os.getenv("SOY_TOKEN")
)

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather for a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                }
            }
        }
    }
]

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "What's the weather in Moscow?"}],
    tools=tools
)

tool_calls = response.choices[0].message.tool_calls
```

---

## JSON Schema / Structured Output

```python
from pydantic import BaseModel

class Answer(BaseModel):
    name: str
    count: int

client = OpenAI(
    base_url="https://api.eliza.yandex.net/raw/internal/gpt-oss-120b/v1",
    api_key=os.getenv("SOY_TOKEN")
)

response = client.chat.completions.create(
    model="gpt-oss-120b",
    messages=[{"role": "user", "content": "Name 3 cities"}],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "answer",
            "schema": Answer.model_json_schema(),
        }
    }
)

answer = Answer.model_validate_json(response.choices[0].message.content)
```

---

## Кэширование и quota

- Raw models кешируются на срок жизни процесса
- Валидированные модели обновляются асинхронно через probe
- Кеш валидированных моделей: 30 секунд
- Ответ включает поле `cost_usd` для отслеживания затрат

---

## Дополнительные параметры

### Reasoning effort (для моделей с thinking)

```python
response = client.chat.completions.create(
    model="claude-3-7-sonnet-20250219",
    messages=[...],
    reasoning_effort="high",  # "low", "medium", "high"
    max_tokens=16384
)
```

### Temperature и другие параметры

```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[...],
    temperature=1.0,      # 0.0 - 2.0
    max_tokens=10000,
    top_p=1.0,
    n=1
)
```

---

## Ошибки и обработка

### Типичные ошибки

- **429** — Rate limit / quota exceeded
- **401** — Неверный токен авторизации
- **501** — Streaming не поддерживается моделью
- **500** — Внутренняя ошибка Eliza

### Обработка в Python

```python
from openai import OpenAI, APIError, RateLimitError, APITimeoutError

try:
    response = client.chat.completions.create(...)
except RateLimitError as e:
    # Retry with backoff
    print(f"Rate limited: {e}")
except APITimeoutError as e:
    print(f"Timeout: {e}")
except APIError as e:
    print(f"API error: {e}")
```

---

## Полезные ссылки

- **Wiki:** https://wiki.yandex-team.ru/eliza/api/
- **Документация:** https://docs.yandex-team.ru/eliza/
- **Tracker:** ELIZASUPPORT компонент
- **Go библиотека:** `library/go/yandex/eliza`

---

## Best Practices

1. **Используйте стандартные SDK** (OpenAI, Anthropic) — совместимость 100%
2. **Кешируйте `get_models()`** ответ на уровне процесса
3. **Указывайте pool** для статистики и контроля квот
4. **Обрабатывайте `reasoning_tokens`** отдельно для моделей с thinking
5. **Проверяйте `finish_reason`** при обработке ответов
6. **Используйте `probe()`** для проверки доступности моделей при старте
7. **Логируйте `cost_usd`** для трекинга расходов
