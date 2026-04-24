# Plan: Поддержка разных форматов запросов в Eliza API

## Цель
Обновить логику работы с Eliza API для поддержки различных форматов запросов к разным моделям и провайдерам.

## Анализ текущего состояния

### Существующая функция `elizaConfig()` (server.js:254-266, scripts/test-models.js:245-257)

Текущая реализация:
```javascript
function elizaConfig(model) {
  const m = (model || '').toLowerCase();
  if (m.startsWith('claude')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/anthropic/v1/messages',
      format: 'anthropic',
    };
  }
  return {
    url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
    format: 'openai',
  };
}
```

**Проблемы:**
1. Только 2 формата: Anthropic и OpenAI
2. Нет поддержки внутренних моделей (GLM, Qwen, DeepSeek, Alice AI)
3. Нет поддержки Gemini original API
4. Нет URL для специфичных моделей

---

## Требуемые изменения

### 1. Расширение `elizaConfig()` для всех провайдеров

#### Текущие провайдеры и их URL:
| Провайдер | URL | Формат |
|-----------|-----|--------|
| openai | `/raw/openai/v1/chat/completions` | OpenAI |
| anthropic | `/raw/anthropic/v1/messages` | Anthropic |
| google | `/raw/openrouter/v1/chat/completions` (или `/raw/google/...`) | OpenAI/Gemini |
| deepseek | `/raw/openrouter/v1/chat/completions` (или `/raw/together/...`) | OpenAI |
| mistral | `/raw/openrouter/v1/chat/completions` | OpenAI |
| xai | `/raw/openrouter/v1/chat/completions` | OpenAI |
| alibaba (qwen) | `/raw/openrouter/v1/chat/completions` | OpenAI |
| moonshotai (kimi) | `/raw/openrouter/v1/chat/completions` | OpenAI |
| zhipu (glm) | `/raw/openrouter/v1/chat/completions` | OpenAI |
| meta (llama) | `/raw/openrouter/v1/chat/completions` | OpenAI |
| yandex (alice) | `/raw/openai/v1/chat/completions` | OpenAI |
| sber (gigachat) | `/raw/openrouter/v1/chat/completions` | OpenAI |

#### Внутренние модели (Коммуналка):
| Модель | URL |
|--------|-----|
| GLM 4.7 | `/raw/internal/glm-latest/v1/chat/completions` |
| GPT-OSS-120B | `/raw/internal/gpt-oss-120b/v1/chat/completions` |
| DeepSeek V3.1-Terminus | `/raw/internal/deepseek-v3-1-terminus/v1/chat/completions` |
| Qwen3 Coder (480B) | `/raw/internal/qwen3-coder-480b-a35b-runtime/v1/chat/completions` |
| Alice AI 235B | `/raw/internal/alice-ai-llm-235b-latest/generative/v1/chat/completions` |
| Alice-ai-llm-32b | `/raw/internal/alice-ai-llm-32b-latest/generative/v1/chat/completions` |
| Alice-ai-llm-32b Reasoner | `/raw/internal/alice-ai-llm-32b-reasoner-latest/generative/v1/chat/completions` |
| MiniMax-M2.5 | `/raw/internal/minimax-latest/v1/chat/completions` |
| DeepSeek V3.2 | `/raw/internal/deepseek-v3-2/v1/chat/completions` |

---

### 2. Новая структура `elizaConfig()`

```javascript
function elizaConfig(model, provider = null) {
  const m = (model || '').toLowerCase();
  
  // Anthropic (Claude)
  if (m.startsWith('claude')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/anthropic/v1/messages',
      format: 'anthropic',
      supportsThinking: true,
    };
  }
  
  // Внутренние модели (Коммуналка)
  if (m.includes('glm-') || m.includes('glm4') || m === 'glm') {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/glm-latest/v1/chat/completions',
      format: 'openai',
      model: 'internal/glm-latest',
    };
  }
  
  if (m.includes('gpt-oss') || m.includes('gpt_oss')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/gpt-oss-120b/v1/chat/completions',
      format: 'openai',
      model: 'internal/gpt-oss-120b',
      supportsReasoningEffort: true,
    };
  }
  
  if (m.includes('deepseek-v3-1-terminus') || m.includes('deepseek-v3.1-terminus')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-1-terminus/v1/chat/completions',
      format: 'openai',
      model: 'default',
    };
  }
  
  if (m.includes('deepseek-v3-2') || m.includes('deepseek-v3.2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-2/v1/chat/completions',
      format: 'openai',
      model: 'default',
    };
  }
  
  if (m.includes('qwen3-coder') || m.includes('qwen3coder')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/qwen3-coder-480b-a35b-runtime/v1/chat/completions',
      format: 'openai',
      model: 'internal/qwen3-coder-480b-a35b-runtime',
    };
  }
  
  if (m.includes('alice-ai-llm-235b') || m.includes('alice ai 235b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-235b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: 'internal/alice-ai-llm-235b-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b-reasoner')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-reasoner-latest/generative/v1/chat/completions',
      format: 'openai',
      model: 'internal/alice-ai-llm-32b-reasoner-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b') || m.includes('alice ai 32b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: 'internal/alice-ai-llm-32b-latest',
    };
  }
  
  if (m.includes('minimax') || m.includes('minimax-m2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/minimax-latest/v1/chat/completions',
      format: 'openai',
      model: 'internal/minimax-latest',
    };
  }
  
  // Внешние модели - по провайдеру
  if (provider === 'google' || m.includes('gemini')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai', // OpenRouter использует OpenAI-совместимый формат
    };
  }
  
  if (provider === 'deepseek' || m.includes('deepseek')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  // По умолчанию - OpenAI совместимый формат
  return {
    url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
    format: 'openai',
  };
}
```

---

### 3. Обновление `buildModelTestVariants()`

#### Новые тестовые варианты:

**Для Anthropic:**
- `anthropic-blocks-max_tokens` - с blocks format
- `anthropic-string-max_tokens` - со string format

**Для OpenAI совместимых:**
- `openai-string-max_tokens` - базовый вариант
- `openai-string-max_tokens-no-temp` - без temperature
- `openai-blocks-max_tokens` - для некоторых провайдеров
- `openai-prompt-max_tokens` - для некоторых провайдеров

**Для моделей с reasoning (GPT-OSS-120B):**
- `openai-string-reasoning_effort-low`
- `openai-string-reasoning_effort-medium`
- `openai-string-reasoning_effort-high`

**Для Claude 3.7+ с thinking:**
- `anthropic-thinking-enabled`

---

### 4. Добавление новых функций

#### Функция определения поддержки reasoning:
```javascript
function supportsReasoningEffort(model) {
  const m = (model || '').toLowerCase();
  // GPT-OSS-120B
  return m.includes('gpt-oss') || m.includes('gpt_oss');
}
```

#### Функция определения поддержки thinking (Anthropic):
```javascript
function supportsThinking(model) {
  const m = (model || '').toLowerCase();
  // Claude 3.7+ с thinking
  return /^claude-3-7/.test(m) || m.includes('claude-3.7');
}
```

#### Функция для получения внутренней модели:
```javascript
function getInternalModelId(model) {
  const m = (model || '').toLowerCase();
  
  const internalModels = {
    'glm-4.7': 'internal/glm-latest',
    'glm-4': 'internal/glm-latest',
    'glm': 'internal/glm-latest',
    'gpt-oss-120b': 'internal/gpt-oss-120b',
    'gpt_oss_120b': 'internal/gpt-oss-120b',
    'deepseek-v3.1-terminus': 'default',
    'deepseek-v3-1-terminus': 'default',
    'deepseek-v3.2': 'default',
    'deepseek-v3-2': 'default',
    'qwen3-coder-480b': 'internal/qwen3-coder-480b-a35b-runtime',
    'qwen3coder': 'internal/qwen3-coder-480b-a35b-runtime',
    'alice-ai-llm-235b': 'internal/alice-ai-llm-235b-latest',
    'alice-ai-llm-32b': 'internal/alice-ai-llm-32b-latest',
    'alice-ai-llm-32b-reasoner': 'internal/alice-ai-llm-32b-reasoner-latest',
    'minimax-m2.5': 'internal/minimax-latest',
    'minimax': 'internal/minimax-latest',
  };
  
  for (const [key, value] of Object.entries(internalModels)) {
    if (m.includes(key)) return value;
  }
  
  return null;
}
```

---

### 5. Обновление классификации ошибок

Добавить новые виды ошибок для внутренних моделей:
- `internal_model_not_found` - для внутренних моделей
- `nda_not_allowed` - для внешних моделей с NDA

---

### 6. Файлы для изменения

1. **server.js**
   - Функция `elizaConfig()` (строки 254-266)
   - Функция `buildModelTestVariants()` (строки 272-337)

2. **scripts/test-models.js**
   - Функция `elizaConfig()` (строки 245-257)
   - Функция `buildProbeBody()` (строки 259-278)
   - Функция `buildProbeVariants()` (строки 280-343+)

---

### 7. Примеры запросов для разных моделей

#### GPT-OSS-120B (с reasoning_effort):
```javascript
{
  model: "internal/gpt-oss-120b",
  messages: [{ role: "user", content: "Solve the bridge and flashlight problem." }],
  reasoning_effort: "high"
}
```

#### Claude 3.7 Sonnet (с thinking):
```javascript
{
  model: "claude-3-7-sonnet-latest",
  max_tokens: 12000,
  messages: [{ role: "user", content: "Hello, world!" }],
  thinking: {
    budget_tokens: 8192,
    type: "enabled"
  }
}
```

#### DeepSeek V3.1-Terminus (внутренний):
```javascript
{
  model: "default",
  messages: [{ role: "user", content: "Hello, world!" }],
  temperature: 0.7
}
```

---

## Результат

После реализации плана система будет поддерживать:
1. Все внешние модели через OpenAI и Anthropic совместимые форматы
2. Все внутренние модели (Коммуналка) с правильными URL
3. Специальные параметры: `reasoning_effort`, `thinking`
4. Корректную обработку ошибок для разных типов моделей
