require('dotenv').config();

const express = require('express');
const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
const os = require('os');

const ELIZA_TOKEN = process.env.ELIZA_TOKEN;

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const KNOWLEDGE_DIR = path.join(__dirname, 'knowledge');
const RULES_FILE = path.join(__dirname, 'rules.json');
const MODELS_FILE = path.join(__dirname, 'models.json');
const MODEL_TEST_SCRIPT = path.join(__dirname, 'scripts', 'test-models.js');

// Ensure dirs exist
if (!fs.existsSync(KNOWLEDGE_DIR)) fs.mkdirSync(KNOWLEDGE_DIR, { recursive: true });
if (!fs.existsSync(RULES_FILE)) fs.writeFileSync(RULES_FILE, JSON.stringify({ rules: [] }, null, 2));

// ── Models — fetch from Eliza, cache to models.json ─────────────────────────

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
      // Exclude test/internal namespaces
      if (EXCLUDED_NAMESPACES.has(ns)) return false;
      // Exclude internal vendor with no namespace
      if (!ns && m.vendor === 'internal') return false;
      // Exclude non-chat models (embeddings, TTS, image-gen, etc.)
      if (NON_CHAT_PATTERNS.some((p) => p.test(m.id))) return false;
      // Exclude date-versioned old models (YYYY-MM-DD in id)
      if (/\d{4}-\d{2}-\d{2}/.test(m.id)) return false;
      // Exclude known old model families
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

async function prefetchModels() {
  if (!ELIZA_TOKEN) return;
  if (!fs.existsSync(MODEL_TEST_SCRIPT)) {
    console.warn(`  ⚠ Не найден скрипт проверки моделей: ${MODEL_TEST_SCRIPT}`);
    return;
  }

  console.log('  → Запускаю фоновую проверку доступных моделей...');
  const child = spawn(process.execPath, [MODEL_TEST_SCRIPT], {
    cwd: __dirname,
    env: process.env,
    stdio: 'inherit',
  });

  child.on('error', (err) => {
    console.warn(`  ⚠ Не удалось запустить проверку моделей: ${err.message}`);
  });

  child.on('exit', (code) => {
    if (code === 0) {
      console.log('  ✓ Проверка моделей завершена');
      return;
    }
    console.warn(`  ⚠ Проверка моделей завершилась с кодом ${code}`);
  });
}

app.get('/api/models', async (req, res) => {
  if (!ELIZA_TOKEN) {
    res.status(500).json({ error: 'ELIZA_TOKEN не задан в .env' });
    return;
  }

  if (fs.existsSync(MODELS_FILE)) {
    try {
      const cached = JSON.parse(fs.readFileSync(MODELS_FILE, 'utf8'));
      if (cached.validated === true && Array.isArray(cached.models) && (cached.models.length === 0 || typeof cached.models[0] === 'object')) {
        res.json(cached);
        return;
      }
    } catch { /* fall through */ }
  }

  res.json({
    models: [],
    updatedAt: null,
    pending: true,
    error: 'Список моделей еще не проверен. Дождитесь завершения scripts/test-models.js',
  });
});

// ── Model family detection ───────────────────────────────────────────────────
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
  return /^(gpt-5|o[134]|grok-3|grok-4)/.test(m) || supportsReasoningEffort(m);
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
      model: model,
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
      model: model,
    };
  }

  return {
    url: 'https://api.eliza.yandex.net/raw/openai/v1/chat/completions',
    format: 'openai',
    model: getInternalModelId(model) || model,
  };
}

function buildOpenAIProbeBody(model, tokenLimit, extra = {}) {
  const config = elizaConfig(model);
  return {
    model: config.model || model,
    messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
    stream: false,
    ...extra,
    ...(extra.max_completion_tokens ? {} : { max_tokens: tokenLimit }),
  };
}

function buildModelTestVariants(model) {
  const config = elizaConfig(model);
  const { format } = config;
  const tokenLimit = usesReasoningTokens(model) ? 32 : 16;

  if (format === 'anthropic') {
    const variants = [
      {
        name: 'anthropic-blocks-max_tokens',
        body: {
          model: config.model || model,
          messages: [{ role: 'user', content: [{ type: 'text', text: 'Reply with exactly OK.' }] }],
          max_tokens: tokenLimit,
          stream: false,
        },
      },
      {
        name: 'anthropic-string-max_tokens',
        body: {
          model: config.model || model,
          messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
          max_tokens: tokenLimit,
          stream: false,
        },
      },
    ];

    if (config.supportsThinking) {
      variants.push({
        name: 'anthropic-thinking-enabled',
        body: {
          model: config.model || model,
          messages: [{ role: 'user', content: 'Reply with exactly OK.' }],
          max_tokens: Math.max(tokenLimit, 64),
          thinking: {
            budget_tokens: 32,
            type: 'enabled',
          },
          stream: false,
        },
      });
    }

    return variants;
  }

  const variants = [
    { name: 'openai-string-max_tokens', body: buildOpenAIProbeBody(model, tokenLimit, { temperature: 0 }) },
    { name: 'openai-string-max_tokens-no-temp', body: buildOpenAIProbeBody(model, tokenLimit) },
  ];

  const resolvedProvider = inferProviderFromModel(model);
  if (['google', 'deepseek', 'mistral', 'xai', 'alibaba', 'moonshotai', 'zhipu', 'meta', 'sber'].includes(resolvedProvider || '')) {
    variants.push({
      name: 'openai-blocks-max_tokens',
      body: {
        model: config.model || model,
        messages: [{ role: 'user', content: [{ type: 'text', text: 'Reply with exactly OK.' }] }],
        max_tokens: tokenLimit,
        stream: false,
      },
    });
    variants.push({
      name: 'openai-prompt-max_tokens',
      body: {
        model: config.model || model,
        prompt: 'Reply with exactly OK.',
        max_tokens: tokenLimit,
        stream: false,
      },
    });
  }

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

  if (supportsReasoningEffort(model)) {
    for (const effort of ['low', 'medium', 'high']) {
      variants.push({
        name: `openai-string-reasoning_effort-${effort}`,
        body: buildOpenAIProbeBody(model, tokenLimit, { reasoning_effort: effort }),
      });
    }
  }

  return variants;
}

// ── Model availability test ──────────────────────────────────────────────────
app.post('/api/models/test', async (req, res) => {
  const { model } = req.body;
  if (!model) { res.status(400).json({ error: 'model required' }); return; }
  if (!ELIZA_TOKEN) { res.status(500).json({ error: 'ELIZA_TOKEN не задан' }); return; }

  const { url } = elizaConfig(model);

  try {
    const t0 = Date.now();
    for (const variant of buildModelTestVariants(model)) {
      const r = await fetch(url, {
        method: 'POST',
        headers: { Authorization: `OAuth ${ELIZA_TOKEN}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(variant.body),
        signal: AbortSignal.timeout(10000),
      });

      if (r.ok) {
        const latency = Date.now() - t0;
        res.json({ available: true, latency, variant: variant.name });
        return;
      }

      const text = await r.text().catch(() => '');
      if (![400, 422, 500].includes(r.status)) {
        res.json({ available: false, status: r.status, error: text.slice(0, 300), variant: variant.name });
        return;
      }
    }

    const latency = Date.now() - t0;
    res.json({ available: false, latency, error: 'all probe variants failed' });
  } catch (err) {
    res.json({ available: false, error: err.message });
  }
});

// ── Chat — streaming proxy to Eliza ─────────────────────────────────────────
// Server always normalises SSE to: data: {"text":"..."}\n\n  or  data: [DONE]\n\n
app.post('/api/chat', async (req, res) => {
  const { messages, currentCode, inputData, model } = req.body;

  if (!ELIZA_TOKEN) {
    res.status(500).json({ error: 'ELIZA_TOKEN не задан в .env' });
    return;
  }

  const knowledge = loadKnowledge();
  const rules = loadRules();
  const systemPrompt = buildSystemPrompt(knowledge, rules, currentCode, inputData);

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  // Guard against writing to a closed/destroyed response (EPIPE)
  // Use res.on('close') — in Node.js v17+ req 'close' fires when request body
  // is consumed (not when the client disconnects), so res is the right target.
  let clientConnected = true;
  res.on('close', () => { clientConnected = false; });
  res.on('error', () => { clientConnected = false; });

  function safeWrite(data) {
    if (!clientConnected || res.destroyed || res.writableEnded) return false;
    try { res.write(data); return true; } catch { clientConnected = false; return false; }
  }

  const config = elizaConfig(model);
  const { url, format } = config;

  // Build request body per provider
  const body = format === 'anthropic'
    ? {
        model: config.model || model || 'claude-sonnet-4-6',
        system: systemPrompt,
        messages,                  // no system role in messages
        max_tokens: 8096,
        ...(config.supportsThinking ? { thinking: { budget_tokens: 1024, type: 'enabled' } } : {}),
        stream: true,
      }
    : {
        model: config.model || model || 'gpt-4.1',
        messages: [{ role: 'system', content: systemPrompt }, ...messages],
        ...(config.supportsReasoningEffort ? { reasoning_effort: 'medium' } : {}),
        stream: true,
      };

  let reader;
  try {
    const elizaRes = await fetch(url, {
      method: 'POST',
      headers: { Authorization: `OAuth ${ELIZA_TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!elizaRes.ok) {
      const errText = await elizaRes.text();
      safeWrite(`data: ${JSON.stringify({ error: `Eliza error ${elizaRes.status}: ${errText}` })}\n\n`);
      res.end();
      return;
    }

    reader = elizaRes.body.getReader();
    res.on('close', () => reader.cancel().catch(() => {}));

    const decoder = new TextDecoder();
    let buf = '';
    while (true) {
      if (!clientConnected) { reader.cancel().catch(() => {}); break; }
      const { done, value } = await reader.read();
      if (done) break;

      buf += decoder.decode(value, { stream: true });
      const lines = buf.split('\n');
      buf = lines.pop(); // keep incomplete last line

      for (const line of lines) {
        if (!clientConnected) break;
        if (!line.startsWith('data:')) continue;
        const raw = line.slice(5).trim();
        if (raw === '[DONE]') { safeWrite('data: [DONE]\n\n'); continue; }

        try {
          const parsed = JSON.parse(raw);
          let text = '';

          if (format === 'anthropic') {
            if (parsed.type === 'content_block_delta') {
              text = parsed.delta?.text || '';
            } else if (parsed.type === 'message_stop') {
              safeWrite('data: [DONE]\n\n');
            } else if (parsed.type === 'error') {
              safeWrite(`data: ${JSON.stringify({ error: parsed.error?.message || 'Anthropic error' })}\n\n`);
            }
          } else {
            text = parsed.choices?.[0]?.delta?.content || '';
            if (parsed.choices?.[0]?.finish_reason) safeWrite('data: [DONE]\n\n');
          }

          if (text) safeWrite(`data: ${JSON.stringify({ text })}\n\n`);
        } catch { /* skip malformed lines */ }
      }
    }
  } catch (err) {
    if (clientConnected) safeWrite(`data: ${JSON.stringify({ error: err.message })}\n\n`);
  } finally {
    if (!res.writableEnded) {
      try { res.end(); } catch { /* already closed */ }
    }
  }
});

// ── Execute Groovy script ────────────────────────────────────────────────────
app.post('/api/execute', async (req, res) => {
  const { code, inputData } = req.body;

  // Check groovy is available
  let groovyCmd = 'groovy';
  try {
    execSync('which groovy || groovy --version', { stdio: 'ignore' });
  } catch {
    // Try common installation paths
    const candidates = [
      '/usr/local/bin/groovy',
      '/opt/homebrew/bin/groovy',
      `${os.homedir()}/.sdkman/candidates/groovy/current/bin/groovy`,
    ];
    const found = candidates.find((p) => fs.existsSync(p));
    if (found) {
      groovyCmd = found;
    } else {
      res.json({
        output: null,
        error:
          'Groovy не установлен.\n\nУстановите через Homebrew:\n  brew install groovy\n\nИли через SDKMAN:\n  sdk install groovy',
      });
      return;
    }
  }

  const tmpDir = os.tmpdir();
  const scriptFile = path.join(tmpDir, `groovy_agent_${Date.now()}.groovy`);

  fs.writeFileSync(scriptFile, code);

  try {
    const result = await runProcess(groovyCmd, [scriptFile], inputData || '{}', 30000);
    res.json(result);
  } finally {
    try { fs.unlinkSync(scriptFile); } catch { /* ignore */ }
  }
});

function runProcess(cmd, args, stdin, timeout) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args);
    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (d) => { stdout += d; });
    proc.stderr.on('data', (d) => { stderr += d; });

    // Suppress EPIPE if child process exits before stdin is fully written
    proc.stdin.on('error', () => {});
    proc.stdin.write(stdin);
    proc.stdin.end();

    const timer = setTimeout(() => {
      proc.kill();
      resolve({ output: null, error: 'Timeout: выполнение превысило 30 секунд' });
    }, timeout);

    proc.on('close', (code) => {
      clearTimeout(timer);
      if (code === 0) {
        resolve({ output: stdout, error: stderr || null });
      } else {
        resolve({ output: stdout || null, error: stderr || `Exit code: ${code}` });
      }
    });

    proc.on('error', (err) => {
      clearTimeout(timer);
      resolve({ output: null, error: err.message });
    });
  });
}

// ── Knowledge base ───────────────────────────────────────────────────────────
app.get('/api/knowledge', (req, res) => {
  res.json(loadKnowledge());
});

app.post('/api/knowledge', (req, res) => {
  const { name, content } = req.body;
  if (!name || !content) { res.status(400).json({ error: 'name and content required' }); return; }
  const safe = name.replace(/[^a-zA-Z0-9_-]/g, '_');
  fs.writeFileSync(path.join(KNOWLEDGE_DIR, `${safe}.md`), content);
  res.json({ success: true, name: safe });
});

app.delete('/api/knowledge/:name', (req, res) => {
  const filePath = path.join(KNOWLEDGE_DIR, `${req.params.name}.md`);
  if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  res.json({ success: true });
});

// ── Rules ────────────────────────────────────────────────────────────────────
app.get('/api/rules', (req, res) => {
  res.json({ rules: loadRules() });
});

app.post('/api/rules', (req, res) => {
  const { rules } = req.body;
  fs.writeFileSync(RULES_FILE, JSON.stringify({ rules: rules || [] }, null, 2));
  res.json({ success: true });
});

// ── Helpers ──────────────────────────────────────────────────────────────────
function loadKnowledge() {
  if (!fs.existsSync(KNOWLEDGE_DIR)) return [];
  return fs
    .readdirSync(KNOWLEDGE_DIR)
    .filter((f) => f.endsWith('.md'))
    .map((file) => ({
      name: file.replace('.md', ''),
      content: fs.readFileSync(path.join(KNOWLEDGE_DIR, file), 'utf8'),
    }));
}

function loadRules() {
  try {
    return JSON.parse(fs.readFileSync(RULES_FILE, 'utf8')).rules || [];
  } catch {
    return [];
  }
}

function trimInputForPrompt(inputData) {
  const raw = (inputData || '').trim();
  if (!raw || raw === '{}') return raw;

  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) {
      return JSON.stringify(parsed.slice(0, 5), null, 2);
    }

    if (parsed && typeof parsed === 'object') {
      const trimmed = {};
      for (const [key, value] of Object.entries(parsed)) {
        trimmed[key] = Array.isArray(value) ? value.slice(0, 5) : value;
      }
      return JSON.stringify(trimmed, null, 2);
    }
  } catch {
    return raw;
  }

  return raw;
}

function buildSystemPrompt(knowledge, rules, currentCode, inputData) {
  let prompt = `Ты эксперт по Groovy, специализирующийся на трансформации JSON-данных.
Твоя задача — писать и изменять Groovy-скрипты для преобразования JSON.

## Требования к скриптам

- Импортируй JsonSlurper и JsonOutput в начале
- Читай входные данные через System.in:
  \`def input = new JsonSlurper().parseText(System.in.text ?: '{}')\`
- Выводи результат через:
  \`println JsonOutput.prettyPrint(JsonOutput.toJson(result))\`
- Всегда предоставляй ПОЛНЫЙ, рабочий скрипт — не фрагменты

## Формат ответа

Когда пишешь или изменяешь код:
1. Кратко объясни что делаешь (1–3 предложения)
2. Дай полный код в блоке \`\`\`groovy

Если пользователь задаёт вопрос без запроса кода — отвечай обычным текстом без блока кода.

## Ключевые паттерны Groovy

\`\`\`groovy
// Трансформация массива
input.items.collect { item -> [newField: item.oldField] }

// Фильтрация
.findAll { it.active }

// Группировка
.groupBy { it.category }

// Безопасная навигация и дефолт
record?.field?.nested ?: 'default'

// Добавление поля в map
record + [newKey: value]

// Сортировка
.sort { a, b -> a.name <=> b.name }

// Уникальные значения
.unique { it.id }
\`\`\`
`;

  if (knowledge.length > 0) {
    prompt += '\n\n## База знаний Groovy\n';
    knowledge.forEach((k) => {
      prompt += `\n### ${k.name}\n${k.content}\n`;
    });
  }

  if (rules.length > 0) {
    prompt += '\n\n## Правила пользователя (выполняй строго)\n';
    rules.forEach((r, i) => { prompt += `${i + 1}. ${r}\n`; });
  }

  if (currentCode && currentCode.trim()) {
    prompt += `\n\n## Текущий код в редакторе\n\`\`\`groovy\n${currentCode}\n\`\`\``;
  }

  const promptInputData = trimInputForPrompt(inputData);
  if (promptInputData && promptInputData !== '{}' && promptInputData !== '') {
    prompt += `\n\n## Входные данные\n\`\`\`json\n${promptInputData}\n\`\`\``;
  }

  return prompt;
}

// ── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\nGroovy AI Agent запущен: http://localhost:${PORT}\n`);
  console.log('Требования:');
  if (!ELIZA_TOKEN) {
    console.warn('  ⚠ ELIZA_TOKEN не задан! Создайте файл .env с ELIZA_TOKEN=<токен>');
    console.warn('    Токен: https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80');
  } else {
    console.log('  ✓ ELIZA_TOKEN загружен из .env');
    prefetchModels();
  }
  console.log('  - Groovy (brew install groovy) — для выполнения скриптов\n');
});
