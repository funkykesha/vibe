#!/usr/bin/env node

require('dotenv').config();

const fs = require('fs');
const path = require('path');

const ELIZA_TOKEN = process.env.ELIZA_TOKEN;
const MODELS_FILE = path.join(__dirname, '..', 'models.json');

const EXCLUDED_NAMESPACES = new Set(['eliza_test', 'alice', 'gena_offline_batch_inference', 'internal']);

const NON_CHAT_PATTERNS = [
  /^tts-/, /^whisper-/, /^dall-e-/, /^text-embedding-/, /^gemini-embedding-/,
  /^gpt-image-/, /^chatgpt-image-/, /^sora-/, /recraftv3/, /midjourney/,
  /^eleven_/, /realtime/, /transcribe/, /^gpt-4o-audio-/, /^gpt-4o-mini-audio-/,
  /^gpt-realtime/, /^gpt-4o-mini-tts/, /embedding/, /^serpapi$/, /^fulltext$/,
  /^V_[0-9]/, /^gpt-oss-/, /^qodo-embed-/, /^embedder-/,
];

const OLD_MODEL_PATTERNS = [
  /^gpt-3\.5-/, /^gpt-4-turbo$/, /^gpt-4$/, /^gpt-4o-2024-/,
  /^open-mistral-/, /^open-mixtral-/, /^gemini-1\.5-/, /^gemini-2\.0-flash-lite$/,
  /^command-r-08-2024$/, /^command-r-plus-08-2024$/,
];

const TRANSIENT_MODEL_PATTERNS = [
  /(^|[-/])(preview|exp|experimental|beta|alpha|rc)([-/]|$)/,
  /(^|[-/])search-preview([-/]|$)/,
  /(^|[-/])deep-research([-/]|$)/,
  /(^|[-/])(vision|image|ocr|vl|audio|omni)([-/]|$)/,
  /nan[ -]?banana/,
  /containers?$/,
  /batch$/,
];

const TEST_PROMPT = 'Reply with exactly OK.';
const MAX_TOKENS = 16;
const REASONING_MAX_TOKENS = 32;
const REQUEST_TIMEOUT_MS = 10000;
const CONCURRENCY = 3;

function safeJsonParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function extractErrorMessage(payload, fallbackText = '') {
  if (!payload || typeof payload !== 'object') return fallbackText.trim();
  if (typeof payload.error === 'string') return payload.error;
  if (payload.error && typeof payload.error.message === 'string') return payload.error.message;
  if (payload.stats && typeof payload.stats.message === 'string') return payload.stats.message;
  if (typeof payload.message === 'string') return payload.message;
  return fallbackText.trim();
}

function classifyError(status, message) {
  const text = (message || '').toLowerCase();

  if (status === 429) return { kind: 'quota_exceeded', retryable: true };
  if (status === 404) {
    if (text.includes('internal')) return { kind: 'internal_model_not_found', retryable: false };
    if (text.includes('model') || text.includes('not found') || text.includes('unknown')) {
      return { kind: 'model_not_found', retryable: false };
    }
    return { kind: 'wrong_endpoint_or_alias', retryable: false };
  }
  if (status === 403 && text.includes('nda')) return { kind: 'nda_not_allowed', retryable: false };
  if (status === 400 || status === 422) {
    if (
      text.includes('max_tokens') ||
      text.includes('max_completion_tokens') ||
      text.includes('unsupported parameter') ||
      text.includes('invalid request') ||
      text.includes('messages') ||
      text.includes('reasoning') ||
      text.includes('content')
    ) {
      return { kind: 'invalid_request_shape', retryable: true };
    }
    return { kind: 'invalid_request', retryable: true };
  }
  if (status >= 500) return { kind: 'provider_error', retryable: true };
  return { kind: 'unknown_error', retryable: false };
}

function usesReasoningTokens(model) {
  return /^(gpt-5|o[134]|grok-3|grok-4)/.test(model.family || '') || supportsReasoningEffort(model.id);
}

function textMessage(text) {
  return [{ role: 'user', content: text }];
}

function blockMessage(text) {
  return [{ role: 'user', content: [{ type: 'text', text }] }];
}

function normalizeModelText(...parts) {
  return parts
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
}

function stripProviderPrefix(id) {
  return (id || '').toLowerCase().replace(/^[a-z0-9._-]+\//, '');
}

function inferProvider(model) {
  const text = normalizeModelText(model.id, model.title, model.developer);
  const developer = (model.developer || '').toLowerCase();

  if (developer === 'openai' || /(^|\W)(gpt|chatgpt|codex|o1|o3|o4)(\W|$)/.test(text)) return 'openai';
  if (developer === 'anthropic' || text.includes('claude')) return 'anthropic';
  if (developer === 'google' || text.includes('gemini') || text.includes('nano banana')) return 'google';
  if (developer === 'deepseek' || text.includes('deepseek')) return 'deepseek';
  if (developer === 'mistral' || text.includes('mistral')) return 'mistral';
  if (developer === 'xai' || text.includes('grok') || text.includes('xai')) return 'xai';
  if (developer === 'alibaba' || developer === 'qwen' || text.includes('qwen') || text.includes('qwq')) return 'alibaba';
  if (developer === 'moonshotai' || text.includes('kimi') || text.includes('moonshot')) return 'moonshotai';
  if (developer === 'zhipu' || text.includes('glm')) return 'zhipu';
  if (developer === 'meta' || text.includes('llama')) return 'meta';
  if (developer === 'yandex' || text.includes('alice ai')) return 'yandex';
  if (developer === 'sber' || text.includes('gigachat')) return 'sber';

  return developer || '';
}

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

function inferFamily(model, provider) {
  const id = stripProviderPrefix(model.id);
  const text = normalizeModelText(id, model.title);

  if (provider === 'openai') {
    const match = text.match(/\b(gpt-4\.1(?:-(?:mini|nano))?|gpt-4o(?:-mini)?|gpt-5(?:\.\d+)?(?:-(?:mini|nano|pro|codex))?|o[134](?:-(?:mini|pro))?)\b/);
    return match ? match[1] : '';
  }
  if (provider === 'anthropic') {
    if (text.includes('haiku')) return 'claude-haiku';
    if (text.includes('sonnet')) return 'claude-sonnet';
    if (text.includes('opus')) return 'claude-opus';
  }
  if (provider === 'google') {
    const match = text.match(/\b(gemini-[0-9.]+-(?:flash(?:-lite)?|pro))\b/);
    return match ? match[1] : '';
  }
  if (provider === 'deepseek') {
    const match = text.match(/\b(deepseek-(?:r1|v3(?:-[0-9]+)?|chat|reasoner))\b/);
    return match ? match[1].replace(/-([0-9]+)/, '.$1') : '';
  }
  if (provider === 'mistral') {
    const match = text.match(/\b(mistral-(?:large|medium|small))(?:-latest)?\b/);
    return match ? match[1] : '';
  }
  if (provider === 'xai') {
    const match = text.match(/\b(grok-(?:3(?:-mini)?|4))(?:-fast)?\b/);
    return match ? match[1] : '';
  }
  if (provider === 'alibaba') {
    const match = text.match(/\b(qwen(?:[0-9.]+)?(?:-(?:coder|vl|plus|max|mt-plus|mt-turbo|omni-flash))?|qwq-32b)\b/);
    return match ? match[1] : '';
  }
  if (provider === 'moonshotai') {
    const match = text.match(/\b(kimi-k2(?:\.5)?)\b/);
    return match ? match[1] : '';
  }
  if (provider === 'zhipu') {
    const match = text.match(/\b(glm-[0-9.]+)\b/);
    return match ? match[1] : '';
  }

  return '';
}

function isCurrentModel(model, provider, family) {
  const id = (model.id || '').toLowerCase();
  const text = normalizeModelText(id, model.title);

  if (!provider || !family) return false;
  if (TRANSIENT_MODEL_PATTERNS.some((pattern) => pattern.test(id) || pattern.test(text))) return false;
  if (/\d{4}-\d{2}-\d{2}/.test(id)) return false;

  return true;
}

function aliasKey(model, provider, family) {
  const id = stripProviderPrefix(model.id)
    .replace(/-latest$/g, '')
    .replace(/[-_](preview|exp|experimental|beta|alpha|rc)(?:[-_].*)?$/g, '');
  return `${provider}:${family || id}`;
}

function preferredModel(a, b) {
  const score = (model) => {
    let points = 0;
    if (!model.id.includes('/')) points += 4;
    if (model.title) points += 2;
    if (model.developer) points += 1;
    if (model.prices && Object.keys(model.prices).length > 0) points += 2;
    if (/-latest$/.test(model.id)) points += 1;
    return points;
  };

  return score(a) >= score(b) ? a : b;
}

function parseModels(raw) {
  const list = Array.isArray(raw) ? raw : (raw.data || []);
  const parsed = list
    .filter((m) => m && m.id)
    .filter((m) => {
      const ns = m.namespace || '';
      if (EXCLUDED_NAMESPACES.has(ns)) return false;
      if (!ns && m.vendor === 'internal') return false;
      if (NON_CHAT_PATTERNS.some((p) => p.test(m.id))) return false;
      if (/\d{4}-\d{2}-\d{2}/.test(m.id)) return false;
      if (OLD_MODEL_PATTERNS.some((p) => p.test(m.id))) return false;
      return true;
    })
    .map((m) => {
      const normalized = {
        id: m.id,
        title: m.title || '',
        developer: m.developer || '',
        namespace: m.namespace || '',
        prices: m.prices || {},
      };
      const provider = inferProvider(normalized);
      const family = inferFamily(normalized, provider);
      return { ...normalized, provider, family };
    })
    .filter((m) => isCurrentModel(m, m.provider, m.family));

  const deduped = new Map();
  for (const model of parsed) {
    const key = aliasKey(model, model.provider, model.family);
    const existing = deduped.get(key);
    deduped.set(key, existing ? preferredModel(existing, model) : model);
  }

  return [...deduped.values()].sort((a, b) => a.id.localeCompare(b.id));
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

function elizaConfig(model, provider = null) {
  const m = (model || '').toLowerCase();
  const resolvedProvider = provider || inferProviderFromModel(model);

  if (m.startsWith('claude')) {
    return {
      url: 'https://api.eliza.yandex.net/raw/anthropic/v1/messages',
      format: 'anthropic',
      model,
      supportsThinking: supportsThinking(model),
    };
  }

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

  if (resolvedProvider && ['google', 'deepseek', 'mistral', 'xai', 'alibaba', 'moonshotai', 'zhipu', 'meta', 'sber'].includes(resolvedProvider)) {
    return {
      url: 'https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions',
      format: 'openai',
      model,
    };
  }

  return {
    url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
    format: 'openai',
    model: getInternalModelId(model) || model,
  };
}

function buildProbeBody(model) {
  const config = elizaConfig(model.id, model.provider);
  const tokenLimit = usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS;
  if (config.format === 'anthropic') {
    return {
      model: config.model || model.id,
      messages: blockMessage(TEST_PROMPT),
      max_tokens: tokenLimit,
      stream: false,
    };
  }

  return {
    model: config.model || model.id,
    messages: textMessage(TEST_PROMPT),
    max_tokens: tokenLimit,
    stream: false,
    temperature: 0,
  };
}

function buildOpenAIProbeBody(model, tokenLimit, extra = {}) {
  const config = elizaConfig(model.id, model.provider);
  return {
    model: config.model || model.id,
    messages: textMessage(TEST_PROMPT),
    stream: false,
    ...extra,
    ...(extra.max_completion_tokens ? {} : { max_tokens: tokenLimit }),
  };
}

function buildAnthropicProbeBody(model, extra = {}) {
  const config = elizaConfig(model.id, model.provider);
  const tokenLimit = usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS;
  return {
    model: config.model || model.id,
    messages: textMessage(TEST_PROMPT),
    max_tokens: tokenLimit,
    stream: false,
    ...extra,
  };
}

function buildProbeVariants(model) {
  const config = elizaConfig(model.id, model.provider);
  if (config.format === 'anthropic') {
    const variants = [
      { name: 'anthropic-blocks-max_tokens', body: buildProbeBody(model) },
      {
        name: 'anthropic-string-max_tokens',
        body: buildAnthropicProbeBody(model),
      },
    ];

    if (config.supportsThinking) {
      variants.push({
        name: 'anthropic-thinking-enabled',
        body: buildAnthropicProbeBody(model, {
          max_tokens: Math.max(REASONING_MAX_TOKENS, 64),
          thinking: {
            budget_tokens: 32,
            type: 'enabled',
          },
        }),
      });
    }

    return variants;
  }

  const tokenLimit = usesReasoningTokens(model) ? REASONING_MAX_TOKENS : MAX_TOKENS;
  const variants = [];

  variants.push({ name: 'openai-string-max_tokens', body: buildProbeBody(model) });
  variants.push({ name: 'openai-string-max_tokens-no-temp', body: buildOpenAIProbeBody(model, tokenLimit) });

  if (usesReasoningTokens(model)) {
    variants.push({
      name: 'openai-string-max_completion_tokens',
      body: buildOpenAIProbeBody(model, tokenLimit, {
        max_completion_tokens: tokenLimit,
        temperature: 0,
        reasoning_effort: 'low',
      }),
    });
  }

  if (/^(google|zhipu|alibaba|moonshotai|mistral|deepseek|xai|meta|sber)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-blocks-max_tokens',
      body: {
        model: config.model || model.id,
        messages: blockMessage(TEST_PROMPT),
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  if (/^(google|alibaba|moonshotai|mistral|deepseek|xai|meta|sber)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-prompt-max_tokens',
      body: {
        model: config.model || model.id,
        prompt: TEST_PROMPT,
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

  if (/^(google|alibaba)$/.test(model.provider || '')) {
    variants.push({
      name: 'openai-string-max_completion_tokens-no-temp',
      body: buildOpenAIProbeBody(model, tokenLimit, { max_completion_tokens: tokenLimit }),
    });
  }

  if (/^o[134]/.test(model.family || '')) {
    variants.push({
      name: 'openai-string-max_completion_tokens-no-reasoning',
      body: buildOpenAIProbeBody(model, tokenLimit, { max_completion_tokens: tokenLimit }),
    });
  }

  if (supportsReasoningEffort(model.id)) {
    for (const effort of ['low', 'medium', 'high']) {
      variants.push({
        name: `openai-string-reasoning_effort-${effort}`,
        body: buildOpenAIProbeBody(model, tokenLimit, { reasoning_effort: effort }),
      });
    }
  }

  return variants;
}

async function probeModel(model) {
  const { url } = elizaConfig(model.id, model.provider);
  let lastFailure = null;

  for (const variant of buildProbeVariants(model)) {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `OAuth ${ELIZA_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(variant.body),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });

    if (!response.ok) {
      const rawText = await response.text().catch(() => '');
      const parsed = safeJsonParse(rawText || 'null');
      const error = extractErrorMessage(parsed, rawText).slice(0, 300);
      const classification = classifyError(response.status, error);
      lastFailure = {
        ok: false,
        status: response.status,
        error,
        kind: classification.kind,
        variant: variant.name,
      };

      if (!classification.retryable) return lastFailure;
      continue;
    }

    const data = await response.json().catch(() => null);
    const text = extractResponseText(data);
    if (!text) {
      lastFailure = {
        ok: false,
        status: response.status,
        error: 'empty response',
        kind: 'empty_response',
        variant: variant.name,
      };
      continue;
    }

    return {
      ok: true,
      status: response.status,
      sample: text.slice(0, 80),
      variant: variant.name,
    };
  }

  return lastFailure || {
    ok: false,
    status: 0,
    error: 'probe failed without response',
    kind: 'probe_failed',
    variant: 'none',
  };
}

function extractResponseText(data) {
  if (!data || typeof data !== 'object') return '';

  if (typeof data.text === 'string') return data.text.trim();
  if (typeof data.output_text === 'string') return data.output_text.trim();
  if (typeof data.response?.output_text === 'string') return data.response.output_text.trim();

  if (Array.isArray(data.content)) {
    return data.content
      .map((item) => {
        if (typeof item === 'string') return item;
        if (typeof item?.text === 'string') return item.text;
        if (typeof item?.text?.value === 'string') return item.text.value;
        return '';
      })
      .join('')
      .trim();
  }

  if (Array.isArray(data.choices)) {
    return data.choices
      .map((choice) => {
        const messageContent = choice?.message?.content;
        const deltaContent = choice?.delta?.content;
        if (typeof messageContent === 'string') return messageContent;
        if (typeof deltaContent === 'string') return deltaContent;
        if (Array.isArray(messageContent)) {
          return messageContent
            .map((item) => {
              if (typeof item === 'string') return item;
              if (typeof item?.text === 'string') return item.text;
              if (typeof item?.text?.value === 'string') return item.text.value;
              return '';
            })
            .join('');
        }
        if (Array.isArray(deltaContent)) {
          return deltaContent
            .map((item) => {
              if (typeof item === 'string') return item;
              if (typeof item?.text === 'string') return item.text;
              if (typeof item?.text?.value === 'string') return item.text.value;
              return '';
            })
            .join('');
        }
        return '';
      })
      .join('')
      .trim();
  }

  if (Array.isArray(data.output)) {
    return data.output
      .map((item) => {
        if (typeof item?.content === 'string') return item.content;
        if (Array.isArray(item?.content)) {
          return item.content
            .map((part) => {
              if (typeof part === 'string') return part;
              if (typeof part?.text === 'string') return part.text;
              if (typeof part?.text?.value === 'string') return part.text.value;
              return '';
            })
            .join('');
        }
        if (typeof item?.text === 'string') return item.text;
        return '';
      })
      .join('')
      .trim();
  }

  if (Array.isArray(data.candidates)) {
    return data.candidates
      .map((candidate) => candidate?.content?.parts || [])
      .flat()
      .map((part) => part?.text || '')
      .join('')
      .trim();
  }

  return '';
}

async function mapWithConcurrency(items, limit, worker) {
  const results = new Array(items.length);
  let cursor = 0;

  async function runWorker() {
    while (cursor < items.length) {
      const index = cursor;
      cursor += 1;
      results[index] = await worker(items[index], index);
    }
  }

  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, runWorker));
  return results;
}

async function main() {
  if (!ELIZA_TOKEN) {
    console.error('ELIZA_TOKEN не задан');
    process.exitCode = 1;
    return;
  }

  console.log('→ Загружаю список моделей для локальной проверки');
  const response = await fetch('https://api.eliza.yandex.net/v1/models', {
    headers: { Authorization: `OAuth ${ELIZA_TOKEN}` },
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });

  if (!response.ok) {
    throw new Error(`Eliza error ${response.status} при загрузке моделей`);
  }

  const raw = await response.json();
  const candidates = parseModels(raw);
  console.log(`→ Кандидатов после локальной фильтрации: ${candidates.length}`);

  const checkedAt = new Date().toISOString();
  const rejected = [];
  const results = await mapWithConcurrency(candidates, CONCURRENCY, async (model, index) => {
    process.stdout.write(`[${index + 1}/${candidates.length}] ${model.id} ... `);
    try {
      const result = await probeModel(model);
      if (result.ok) {
        process.stdout.write(`ok [${result.variant}]\n`);
        return { ...model, probe: { checkedAt, status: result.status, sample: result.sample, variant: result.variant } };
      }

      rejected.push({
        id: model.id,
        provider: model.provider,
        family: model.family,
        status: result.status,
        kind: result.kind,
        variant: result.variant,
        error: result.error,
      });
      process.stdout.write(`skip (${result.status || 'ERR'} ${result.kind}${result.variant ? `, ${result.variant}` : ''})\n`);
      return null;
    } catch (error) {
      rejected.push({
        id: model.id,
        provider: model.provider,
        family: model.family,
        status: 0,
        kind: error.name === 'TimeoutError' ? 'timeout' : 'probe_exception',
        variant: 'runtime',
        error: error.message,
      });
      process.stdout.write(`skip (${error.message})\n`);
      return null;
    }
  });

  const models = results.filter(Boolean).sort((a, b) => a.id.localeCompare(b.id));
  const payload = {
    validated: true,
    checkedAt,
    prompt: TEST_PROMPT,
    maxTokens: MAX_TOKENS,
    models,
    rejected,
    totalCandidates: candidates.length,
    totalValidated: models.length,
  };

  fs.writeFileSync(MODELS_FILE, JSON.stringify(payload, null, 2));
  console.log(`✓ Валидных моделей: ${models.length}/${candidates.length}`);
}

main().catch((error) => {
  console.error(`✗ Проверка моделей завершилась ошибкой: ${error.message}`);
  process.exitCode = 1;
});
