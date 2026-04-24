# Реализация: Поддержка разных форматов запросов в Eliza API

## Обзор изменений

Этот документ содержит полный код изменений для поддержки различных форматов запросов к моделям в Eliza API.

---

## 1. Изменения в `server.js`

### 1.1. Новые вспомогательные функции

Добавить после функции `usesReasoningTokens()` (строка 270):

```javascript
// ── Helper functions for model detection ─────────────────────────────────────

function supportsReasoningEffort(model) {
  const m = (model || '').toLowerCase();
  // GPT-OSS-120B поддерживает reasoning_effort
  return m.includes('gpt-oss') || m.includes('gpt_oss');
}

function supportsThinking(model) {
  const m = (model || '').toLowerCase();
  // Claude 3.7+ поддерживает thinking mode
  return /^claude-3-7/.test(m) || m.includes('claude-3.7');
}

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

### 1.2. Обновленная функция `elizaConfig()`

Заменить существующую функцию (строки 254-266):

```javascript
// ── Model family detection ───────────────────────────────────────────────────
function elizaConfig(model, provider = null) {
  const m = (model || '').toLowerCase();
  
  // Anthropic (Claude)
  if (m.startsWith('claude')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/anthropic/v1/messages',
      format: 'anthropic',
      supportsThinking: supportsThinking(model),
    };
  }
  
  // Внутренние модели (Коммуналка)
  if (m.includes('glm-') || m.includes('glm4') || m === 'glm') {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/glm-latest/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/glm-latest',
    };
  }
  
  if (m.includes('gpt-oss') || m.includes('gpt_oss')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/gpt-oss-120b/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/gpt-oss-120b',
      supportsReasoningEffort: true,
    };
  }
  
  if (m.includes('deepseek-v3-1-terminus') || m.includes('deepseek-v3.1-terminus')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-1-terminus/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'default',
    };
  }
  
  if (m.includes('deepseek-v3-2') || m.includes('deepseek-v3.2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-2/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'default',
    };
  }
  
  if (m.includes('qwen3-coder') || m.includes('qwen3coder')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/qwen3-coder-480b-a35b-runtime/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/qwen3-coder-480b-a35b-runtime',
    };
  }
  
  if (m.includes('alice-ai-llm-235b') || m.includes('alice ai 235b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-235b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-235b-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b-reasoner')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-reasoner-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-32b-reasoner-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b') || m.includes('alice ai 32b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-32b-latest',
    };
  }
  
  if (m.includes('minimax') || m.includes('minimax-m2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/minimax-latest/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/minimax-latest',
    };
  }
  
  // Внешние модели - по провайдеру
  if (provider === 'google' || m.includes('gemini')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'deepseek' || m.includes('deepseek')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'mistral' || m.includes('mistral')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'xai' || m.includes('grok')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'alibaba' || m.includes('qwen') || m.includes('qwq')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'moonshotai' || m.includes('kimi')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'zhipu' || m.includes('glm')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'meta' || m.includes('llama')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'yandex' || m.includes('alice ai')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'sber' || m.includes('gigachat')) {
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

### 1.3. Обновленная функция `buildModelTestVariants()`

Заменить существующую функцию (строки 272-337):

```javascript
function buildModelTestVariants(model) {
  const config = elizaConfig(model);
  const { format, supportsReasoningEffort, supportsThinking } = config;
  const tokenLimit = usesReasoningTokens(model) ? 32 : 16;

  if (format === 'anthropic') {
    const variants = [
      {
        name: 'anthropic-blocks-max_tokens',
        body: {
          model,
          messages: [{ role: 'user', content: [{ type: 'text', text: 'Reply with exactly OK.' }] }],
          max_tokens: tokenLimit,
          stream: false,
        },
      },
      {
        name: 'anthropic-string-max_tokens',
        body: {
          model,
          messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
          max_tokens: tokenLimit,
          stream: false,
        },
      },
    ];

    // Добавить thinking variant для Claude 3.7+
    if (supportsThinking) {
      variants.push({
        name: 'anthropic-thinking-enabled',
        body: {
          model,
          max_tokens: tokenLimit,
          messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
          thinking: {
            budget_tokens: 8192,
            type: 'enabled',
          },
          stream: false,
        },
      });
    }

    return variants;
  }

  // OpenAI compatible format
  const variants = [
    {
      name: 'openai-string-max_tokens',
      body: {
        model,
        messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
        max_tokens: tokenLimit,
        stream: false,
        temperature: 0,
      },
    },
  ];

  // Для моделей с reasoning tokens (GPT-5, o1, o3, o4, grok-3, grok-4)
  if (usesReasoningTokens(model)) {
    variants.push({
      name: 'openai-string-max_completion_tokens',
      body: {
        model,
        messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
        max_completion_tokens: tokenLimit,
        stream: false,
        temperature: 0,
        reasoning_effort: 'low',
      },
    });
  }

  // Для GPT-OSS-120B с reasoning_effort
  if (supportsReasoningEffort) {
    variants.push({
      name: 'openai-string-reasoning_effort-low',
      body: {
        model,
        messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'low',
      },
    });
    variants.push({
      name: 'openai-string-reasoning_effort-medium',
      body: {
        model,
        messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'medium',
      },
    });
    variants.push({
      name: 'openai-string-reasoning_effort-high',
      body: {
        model,
        messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'high',
      },
    });
  }

  // Вариант без temperature
  variants.push({
    name: 'openai-string-max_tokens-no-temp',
    body: {
      model,
      messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
      max_tokens: tokenLimit,
      stream: false,
    },
  });

  // Для некоторых провайдеров - blocks format
  if (/^(google|zhipu|alibaba|moonshotai|mistral|deepseek|xai)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-blocks-max_tokens',
      body: {
        model,
        messages: [{ role: 'user', content: [{ type: 'text', text: 'Reply with exactly OK.' }] }],
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  // Для некоторых провайдеров - prompt format
  if (/^(google|alibaba|moonshotai|mistral|deepseek|xai)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-prompt-max_tokens',
      body: {
        model,
        prompt: 'Reply with exactly OK.',
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  return variants;
}
```

---

## 2. Изменения в `scripts/test-models.js`

### 2.1. Новые вспомогательные функции

Добавить после функции `usesReasoningTokens()` (строка 90):

```javascript
// ── Helper functions for model detection ─────────────────────────────────────

function supportsReasoningEffort(model) {
  const m = (model || '').toLowerCase();
  // GPT-OSS-120B поддерживает reasoning_effort
  return m.includes('gpt-oss') || m.includes('gpt_oss');
}

function supportsThinking(model) {
  const m = (model || '').toLowerCase();
  // Claude 3.7+ поддерживает thinking mode
  return /^claude-3-7/.test(m) || m.includes('claude-3.7');
}

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

### 2.2. Обновленная функция `elizaConfig()`

Заменить существующую функцию (строки 245-257):

```javascript
function elizaConfig(model, provider = null) {
  const m = (model || '').toLowerCase();
  
  // Anthropic (Claude)
  if (m.startsWith('claude')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/anthropic/v1/messages',
      format: 'anthropic',
      supportsThinking: supportsThinking(model),
    };
  }
  
  // Внутренние модели (Коммуналка)
  if (m.includes('glm-') || m.includes('glm4') || m === 'glm') {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/glm-latest/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/glm-latest',
    };
  }
  
  if (m.includes('gpt-oss') || m.includes('gpt_oss')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/gpt-oss-120b/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/gpt-oss-120b',
      supportsReasoningEffort: true,
    };
  }
  
  if (m.includes('deepseek-v3-1-terminus') || m.includes('deepseek-v3.1-terminus')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-1-terminus/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'default',
    };
  }
  
  if (m.includes('deepseek-v3-2') || m.includes('deepseek-v3.2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/deepseek-v3-2/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'default',
    };
  }
  
  if (m.includes('qwen3-coder') || m.includes('qwen3coder')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/qwen3-coder-480b-a35b-runtime/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/qwen3-coder-480b-a35b-runtime',
    };
  }
  
  if (m.includes('alice-ai-llm-235b') || m.includes('alice ai 235b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-235b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-235b-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b-reasoner')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-reasoner-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-32b-reasoner-latest',
    };
  }
  
  if (m.includes('alice-ai-llm-32b') || m.includes('alice ai 32b')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/alice-ai-llm-32b-latest/generative/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/alice-ai-llm-32b-latest',
    };
  }
  
  if (m.includes('minimax') || m.includes('minimax-m2')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/internal/minimax-latest/v1/chat/completions',
      format: 'openai',
      model: getInternalModelId(model) || 'internal/minimax-latest',
    };
  }
  
  // Внешние модели - по провайдеру
  if (provider === 'google' || m.includes('gemini')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'deepseek' || m.includes('deepseek')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'mistral' || m.includes('mistral')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'xai' || m.includes('grok')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'alibaba' || m.includes('qwen') || m.includes('qwq')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'moonshotai' || m.includes('kimi')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'zhipu' || m.includes('glm')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'meta' || m.includes('llama')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'yandex' || m.includes('alice ai')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
      format: 'openai',
    };
  }
  
  if (provider === 'sber' || m.includes('gigachat')) {
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

### 2.3. Обновленная функция `buildProbeBody()`

Заменить существующую функцию (строки 259-278):

```javascript
function buildProbeBody(model) {
  const config = elizaConfig(model.id, model.provider);
  const { format, model: internalModel } = config;
  const tokenLimit = usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS;
  
  if (format === 'anthropic') {
    return {
      model: model.id,
      messages: blockMessage(TEST_PROMPT),
      max_tokens: tokenLimit,
      stream: false,
    };
  }

  return {
    model: internalModel || model.id,
    messages: textMessage(TEST_PROMPT),
    max_tokens: tokenLimit,
    stream: false,
    temperature: 0,
  };
}
```

### 2.4. Обновленная функция `buildProbeVariants()`

Заменить существующую функцию (строки 280-343+):

```javascript
function buildProbeVariants(model) {
  const config = elizaConfig(model.id, model.provider);
  const { format, supportsReasoningEffort, supportsThinking, model: internalModel } = config;
  
  if (format === 'anthropic') {
    const variants = [
      { name: 'anthropic-blocks-max_tokens', body: buildProbeBody(model) },
      {
        name: 'anthropic-string-max_tokens',
        body: {
          model: model.id,
          messages: textMessage(TEST_PROMPT),
          max_tokens: usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS,
          stream: false,
        },
      },
    ];

    // Добавить thinking variant для Claude 3.7+
    if (supportsThinking) {
      variants.push({
        name: 'anthropic-thinking-enabled',
        body: {
          model: model.id,
          max_tokens: usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS,
          messages: textMessage(TEST_PROMPT),
          thinking: {
            budget_tokens: 8192,
            type: 'enabled',
          },
          stream: false,
        },
      });
    }

    return variants;
  }

  const tokenLimit = usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS;
  const variants = [];

  variants.push({ name: 'openai-string-max_tokens', body: buildProbeBody(model) });

  // Для моделей с reasoning tokens (GPT-5, o1, o3, o4, grok-3, grok-4)
  if (usesReasoningTokens(model)) {
    variants.push({
      name: 'openai-string-max_completion_tokens',
      body: {
        model: internalModel || model.id,
        messages: textMessage(TEST_PROMPT),
        max_completion_tokens: tokenLimit,
        stream: false,
        temperature: 0,
        reasoning_effort: 'low',
      },
    });
  }

  // Для GPT-OSS-120B с reasoning_effort
  if (supportsReasoningEffort) {
    variants.push({
      name: 'openai-string-reasoning_effort-low',
      body: {
        model: internalModel || model.id,
        messages: textMessage(TEST_PROMPT),
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'low',
      },
    });
    variants.push({
      name: 'openai-string-reasoning_effort-medium',
      body: {
        model: internalModel || model.id,
        messages: textMessage(TEST_PROMPT),
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'medium',
      },
    });
    variants.push({
      name: 'openai-string-reasoning_effort-high',
      body: {
        model: internalModel || model.id,
        messages: textMessage(TEST_PROMPT),
        max_tokens: tokenLimit,
        stream: false,
        reasoning_effort: 'high',
      },
    });
  }

  // Вариант без temperature
  variants.push({
    name: 'openai-string-max_tokens-no-temp',
    body: {
      model: internalModel || model.id,
      messages: textMessage(TEST_PROMPT),
      max_tokens: tokenLimit,
      stream: false,
    },
  });

  // Для некоторых провайдеров - blocks format
  if (/^(google|zhipu|alibaba|moonshotai|mistral|deepseek|xai)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-blocks-max_tokens',
      body: {
        model: internalModel || model.id,
        messages: blockMessage(TEST_PROMPT),
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  // Для некоторых провайдеров - prompt format
  if (/^(google|alibaba|moonshotai|mistral|deepseek|xai)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-prompt-max_tokens',
      body: {
        model: internalModel || model.id,
        prompt: TEST_PROMPT,
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  return variants;
}
```

---

## 3. Сводка изменений

### Новые функции:
- `supportsReasoningEffort(model)` - проверяет поддержку reasoning_effort
- `supportsThinking(model)` - проверяет поддержку thinking mode
- `getInternalModelId(model)` - возвращает ID внутренней модели

### Обновленные функции:
- `elizaConfig(model, provider)` - теперь поддерживает все провайдеры и внутренние модели
- `buildModelTestVariants(model)` - генерирует тестовые варианты для всех форматов
- `buildProbeBody(model)` - использует внутренний ID модели
- `buildProbeVariants(model)` - генерирует все тестовые варианты

### Поддерживаемые форматы:
1. **Anthropic** - `/raw/anthropic/v1/messages`
2. **OpenAI** - `/raw/openai/v1/chat/completions`
3. **OpenRouter** - `/raw/openrouter/v1/chat/completions` (для внешних моделей)
4. **Внутренние модели** - `/raw/internal/{model}/v1/chat/completions`

### Специальные параметры:
- `reasoning_effort` (low/medium/high) для GPT-OSS-120B
- `thinking` с `budget_tokens` для Claude 3.7+
- `max_completion_tokens` для моделей с reasoning tokens

---

## 4. Тестирование

После внедрения изменений необходимо протестировать:

1. Внешние модели (OpenAI, Anthropic, Google, DeepSeek)
2. Внутренние модели (GLM, GPT-OSS-120B, Qwen, Alice AI, MiniMax)
3. Специальные параметры (reasoning_effort, thinking)
4. Разные форматы запросов (string, blocks, prompt)
