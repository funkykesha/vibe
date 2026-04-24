'use strict';

const BASE_URL = 'https://api.eliza.yandex.net';

function inferProviderFromModel(model) {
  const m = (model || '').toLowerCase();
  if (m.startsWith('claude')) return 'anthropic';
  if (m.includes('gemini')) return 'google';
  if (m.includes('deepseek')) return 'deepseek';
  if (m.includes('mistral')) return 'mistral';
  if (m.includes('grok')) return 'xai';
  if (m.includes('qwen')) return 'alibaba';
  if (m.includes('kimi') || m.includes('moonshot')) return 'moonshotai';
  if (m.includes('glm')) return 'zhipu';
  if (m.includes('llama')) return 'meta';
  if (m.includes('alice')) return 'yandex';
  if (m.includes('gigachat')) return 'sber';
  return null;
}

function supportsReasoningEffort(model) {
  const m = (model || '').toLowerCase();
  return m.includes('gpt-oss') || m.includes('gpt_oss');
}

function supportsThinking(model) {
  const m = (model || '').toLowerCase();
  return /^claude-3-7/.test(m) || m.includes('claude-3.7');
}

function usesReasoningTokens(model) {
  const m = (model || '').toLowerCase();
  return /^(gpt-?5(?![0-9])|o[134]|grok-3|grok-4)/.test(m) || supportsReasoningEffort(m);
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
    'alice ai 235b': 'internal/alice-ai-llm-235b-latest',
    'alice-ai-llm-32b-reasoner': 'internal/alice-ai-llm-32b-reasoner-latest',
    'alice-ai-llm-32b': 'internal/alice-ai-llm-32b-latest',
    'alice ai 32b': 'internal/alice-ai-llm-32b-latest',
    'minimax-m2.5': 'internal/minimax-latest',
    'minimax': 'internal/minimax-latest',
  };
  for (const [key, value] of Object.entries(internalModels)) {
    if (m.includes(key)) return value;
  }
  return null;
}

// Note: server.js had elizaConfig(model, provider=null). The provider param is dropped here
// because this module always infers provider from the model ID via inferProviderFromModel().
// The second param is now baseUrl for testability.
function elizaConfig(model, baseUrl = BASE_URL) {
  const m = (model || '').toLowerCase();
  const resolvedProvider = inferProviderFromModel(model);

  // GPT-5 requires /v1/responses API — not supported by Eliza SSE proxy yet
  // See: INFRAMLPLUGINS-1617
  // Note: matches gpt-5, gpt5, gpt-5.1-mini but not gpt-50, gpt-500
  if (/^gpt-?5(?![0-9])/.test(m)) {
    return {
      url: `${baseUrl}/raw/openai/v1/chat/completions`,
      format: 'openai',
      model,
      supportsStreaming: false,
    };
  }

  if (m.startsWith('claude')) {
    return {
      url: `${baseUrl}/raw/anthropic/v1/messages`,
      format: 'anthropic',
      model,
      supportsThinking: supportsThinking(model),
    };
  }
  if (m.includes('glm-') || m.includes('glm4') || m === 'glm') {
    return { url: `${baseUrl}/raw/internal/glm-latest/v1/chat/completions`, format: 'openai', model: 'internal/glm-latest' };
  }
  if (m.includes('gpt-oss') || m.includes('gpt_oss')) {
    return { url: `${baseUrl}/raw/internal/gpt-oss-120b/v1/chat/completions`, format: 'openai', model: 'internal/gpt-oss-120b', supportsReasoningEffort: true };
  }
  if (m.includes('deepseek-v3-1-terminus') || m.includes('deepseek-v3.1-terminus')) {
    return { url: `${baseUrl}/raw/internal/deepseek-v3-1-terminus/v1/chat/completions`, format: 'openai', model: 'default' };
  }
  if (m.includes('deepseek-v3-2') || m.includes('deepseek-v3.2')) {
    return { url: `${baseUrl}/raw/internal/deepseek-v3-2/v1/chat/completions`, format: 'openai', model: 'default' };
  }
  if (m.includes('qwen3-coder') || m.includes('qwen3coder')) {
    return { url: `${baseUrl}/raw/internal/qwen3-coder-480b-a35b-runtime/v1/chat/completions`, format: 'openai', model: 'internal/qwen3-coder-480b-a35b-runtime' };
  }
  if (m.includes('alice-ai-llm-235b') || m.includes('alice ai 235b')) {
    return { url: `${baseUrl}/raw/internal/alice-ai-llm-235b-latest/generative/v1/chat/completions`, format: 'openai', model: 'internal/alice-ai-llm-235b-latest' };
  }
  if (m.includes('alice-ai-llm-32b-reasoner')) {
    return { url: `${baseUrl}/raw/internal/alice-ai-llm-32b-reasoner-latest/generative/v1/chat/completions`, format: 'openai', model: 'internal/alice-ai-llm-32b-reasoner-latest' };
  }
  if (m.includes('alice-ai-llm-32b') || m.includes('alice ai 32b')) {
    return { url: `${baseUrl}/raw/internal/alice-ai-llm-32b-latest/generative/v1/chat/completions`, format: 'openai', model: 'internal/alice-ai-llm-32b-latest' };
  }
  if (m.includes('minimax')) {
    return { url: `${baseUrl}/raw/internal/minimax-latest/v1/chat/completions`, format: 'openai', model: 'internal/minimax-latest' };
  }
  if (resolvedProvider && ['google', 'deepseek', 'mistral', 'xai', 'alibaba', 'moonshotai', 'zhipu', 'meta', 'sber'].includes(resolvedProvider)) {
    return { url: `${baseUrl}/raw/openrouter/v1/chat/completions`, format: 'openai', model };
  }
  return { url: `${baseUrl}/raw/openai/v1/chat/completions`, format: 'openai', model: getInternalModelId(model) || model };
}

module.exports = { elizaConfig, supportsThinking, supportsReasoningEffort, usesReasoningTokens, getInternalModelId };
