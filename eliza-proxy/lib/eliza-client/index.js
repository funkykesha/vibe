'use strict';

const { parseModels } = require('./models.js');
const { runProbe, probeModel } = require('./probe.js');
const { elizaConfig, usesReasoningTokens } = require('./routing.js');
const { normalizeStream } = require('./streaming.js');

class ElizaError extends Error {
  constructor(status, body) {
    super(`Eliza ${status}: ${String(body).slice(0, 200)}`);
    this.name = 'ElizaError';
    this.status = status;
    this.body = body;
  }
}

/** Retriable between fetch attempts (GET never returned a parsed response). */
function isRetriableNetworkError(err) {
  if (!err || typeof err !== 'object') return false;
  if (err instanceof ElizaError) return false;
  if (err.name === 'AbortError') return true;
  const code = err.code || err.cause?.code;
  if (code === 'ECONNRESET' || code === 'ETIMEDOUT' || code === 'ENOTFOUND' || code === 'ENETUNREACH' || code === 'ECONNREFUSED') {
    return true;
  }
  if (err instanceof TypeError) return true;
  return false;
}

function createElizaClient({
  token,
  baseUrl = 'https://api.eliza.yandex.net',
  _skipProbe = false,
  _runProbe = runProbe,
  _sleep = (ms) => new Promise((r) => setTimeout(r, ms)),
  onModelProbed = null,
} = {}) {
  let rawCache = null;
  let validatedCache = null;
  let fetchPromise = null;
  let probePromise = null;
  const callbacks = [];

  async function fetchAndParse() {
    const backoffMs = [500, 1000];
    let attempt = 0;
    while (true) {
      try {
        const res = await fetch(`${baseUrl}/v1/models`, {
          headers: { Authorization: `OAuth ${token}` },
          signal: AbortSignal.timeout(15000),
        });
        if (!res.ok) {
          throw new ElizaError(res.status, await res.text().catch(() => ''));
        }
        const rawJson = await res.json();
        return parseModels(rawJson);
      } catch (err) {
        if (err instanceof ElizaError) throw err;
        if (!isRetriableNetworkError(err) || attempt >= 2) throw err;
        await _sleep(backoffMs[attempt]);
        attempt += 1;
      }
    }
  }

  function startProbeIfNeeded() {
    if (_skipProbe || probePromise) return;

    probePromise = _runProbe(rawCache.models, token, baseUrl, onModelProbed)
      .then((validated) => {
        validatedCache = { models: validated, validated: true };
        callbacks.splice(0).forEach((cb) => cb(validated));
      })
      .catch(() => {
        const fallback = rawCache?.models;
        if (fallback) callbacks.splice(0).forEach((cb) => cb(fallback));
        else callbacks.length = 0;
      })
      .finally(() => {
        setTimeout(() => {
          probePromise = null;
        }, 30_000).unref();
      });
  }

  async function getModels() {
    if (validatedCache) {
      return {
        ...validatedCache,
        onValidated: (cb) => {
          cb(validatedCache.models);
        },
      };
    }

    if (!rawCache) {
      if (!fetchPromise) {
        fetchPromise = fetchAndParse()
          .then((models) => {
            rawCache = { models, validated: false };
          })
          .finally(() => {
            fetchPromise = null;
          });
      }
      await fetchPromise;
    }

    startProbeIfNeeded();

    const onValidated = (cb) => {
      if (validatedCache) cb(validatedCache.models);
      else callbacks.push(cb);
    };
    return { ...rawCache, onValidated };
  }

  function _forceValidated(models) {
    validatedCache = { models, validated: true };
  }

  async function* chat(model, messages, { system } = {}) {
    const config = elizaConfig(model, baseUrl);

    // GPT-5 requires /v1/responses API — not supported by Eliza SSE proxy
    if (config.supportsStreaming === false) {
      throw new ElizaError(501, `Streaming not supported for model: ${model}`);
    }

    const isReasoning = usesReasoningTokens(model);

    const body = config.format === 'anthropic'
      ? {
          model: config.model || model,
          system,
          messages,
          max_tokens: 8096,
          ...(config.supportsThinking ? { thinking: { budget_tokens: 1024, type: 'enabled' } } : {}),
          stream: true,
        }
      : {
          model: config.model || model,
          messages: system
            ? [{ role: isReasoning ? 'developer' : 'system', content: system }, ...messages]
            : messages,
          ...(!isReasoning ? { temperature: 0 } : {}),
          ...(config.supportsReasoningEffort ? { reasoning_effort: 'medium' } : {}),
          stream: true,
        };

    const res = await fetch(config.url, {
      method: 'POST',
      headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!res.ok) throw new ElizaError(res.status, await res.text().catch(() => ''));

    for await (const chunk of normalizeStream(res.body, config.format)) {
      if (chunk.usage) {
        console.log(`[eliza-client] usage model=${model} input=${chunk.usage.input} output=${chunk.usage.output}`);
      }
      yield chunk;
    }
  }

  async function chatOnce(model, messages, opts = {}) {
    let content = '';
    for await (const { delta, done } of chat(model, messages, opts)) {
      if (done) break;
      content += delta;
    }
    return { content };
  }

  async function probe(model) {
    const modelObj = { id: model, provider: null, family: null };
    try {
      const result = await probeModel(modelObj, token, baseUrl);
      return result.ok;
    } catch {
      return false;
    }
  }

  return { chat, chatOnce, probe, getModels, _forceValidated };
}

module.exports = { createElizaClient, ElizaError };
