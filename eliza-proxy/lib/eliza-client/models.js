'use strict';

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
  return parts.filter(Boolean).join(' ').toLowerCase();
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
  if (TRANSIENT_MODEL_PATTERNS.some((p) => p.test(id) || p.test(text))) return false;
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
  const score = (m) => {
    let pts = 0;
    if (!m.id.includes('/')) pts += 4;
    if (m.title) pts += 2;
    if (m.developer) pts += 1;
    if (m.prices && Object.keys(m.prices).length > 0) pts += 2;
    if (/-latest$/.test(m.id)) pts += 1;
    return pts;
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

module.exports = {
  parseModels,
  inferProvider,
  inferFamily,
  normalizeModelText,
  stripProviderPrefix,
};
