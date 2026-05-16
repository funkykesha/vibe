'use strict';

const { elizaConfig, supportsReasoningEffort, usesReasoningTokens } = require('./routing.js');

const DEFAULT_CONCURRENCY = Number.parseInt(process.env.PROBE_CONCURRENCY || '4', 10);
const REQUEST_TIMEOUT_MS = Number.parseInt(process.env.PROBE_TIMEOUT_MS || '800', 10);
const MAX_TOKENS = 16;
const REASONING_MAX_TOKENS = 32;
const TEST_PROMPT = 'Reply with exactly OK.';

const PROVIDER_TIMEOUT_OVERRIDES_MS = {
  openai: 1200,
  google: 1400,
  anthropic: 1900,
  xai: 1800,
  moonshotai: 1600,
  mistral: 1400,
  deepseek: 1300,
};

const MODEL_TIMEOUT_OVERRIDES_MS = [
  { pattern: /claude-opus/i, timeoutMs: 2200 },
  { pattern: /grok-4/i, timeoutMs: 2200 },
  { pattern: /kimi-k2/i, timeoutMs: 1800 },
];

const WARNING_KINDS = new Set([
  'quota_exceeded',
  'invalid_request_shape',
  'invalid_request',
  'provider_error',
  'timeout_or_abort',
  'network_error',
  'empty_response',
  'unknown_error',
  'probe_failed',
]);

function safeJsonParse(text) {
  try { return JSON.parse(text); } catch { return null; }
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
  if (status === 401 || status === 412) return { kind: 'auth_error', retryable: false };
  if (status === 404) {
    if (text.includes('internal')) return { kind: 'internal_model_not_found', retryable: false };
    if (text.includes('model') || text.includes('not found') || text.includes('unknown')) return { kind: 'model_not_found', retryable: false };
    return { kind: 'wrong_endpoint_or_alias', retryable: false };
  }
  if (status === 403 && text.includes('nda')) return { kind: 'nda_not_allowed', retryable: false };
  if (status === 403) return { kind: 'forbidden', retryable: false };
  if (status === 400 || status === 422) {
    if (text.includes('max_tokens') || text.includes('max_completion_tokens') || text.includes('unsupported parameter') || text.includes('invalid request') || text.includes('messages') || text.includes('reasoning') || text.includes('content')) {
      return { kind: 'invalid_request_shape', retryable: true };
    }
    return { kind: 'invalid_request', retryable: true };
  }
  if (status >= 500) return { kind: 'provider_error', retryable: true };
  return { kind: 'unknown_error', retryable: false };
}

function extractResponseText(data) {
  if (!data || typeof data !== 'object') return '';
  if (typeof data.text === 'string') return data.text.trim();
  if (typeof data.output_text === 'string') return data.output_text.trim();
  if (typeof data.response?.output_text === 'string') return data.response.output_text.trim();
  if (Array.isArray(data.content)) {
    return data.content.map((item) => {
      if (typeof item === 'string') return item;
      if (typeof item?.text === 'string') return item.text;
      if (typeof item?.text?.value === 'string') return item.text.value;
      return '';
    }).join('').trim();
  }
  if (Array.isArray(data.choices)) {
    return data.choices.map((choice) => {
      const content = choice?.message?.content ?? choice?.delta?.content ?? '';
      if (typeof content === 'string') return content;
      if (Array.isArray(content)) return content.map((item) => (typeof item?.text === 'string' ? item.text : '')).join('');
      return '';
    }).join('').trim();
  }
  if (Array.isArray(data.output)) {
    return data.output.map((item) => {
      if (typeof item?.content === 'string') return item.content;
      if (Array.isArray(item?.content)) return item.content.map((part) => (typeof part?.text === 'string' ? part.text : '')).join('');
      if (typeof item?.text === 'string') return item.text;
      return '';
    }).join('').trim();
  }
  if (Array.isArray(data.candidates)) {
    return data.candidates.map((candidate) => candidate?.content?.parts || []).flat().map((part) => part?.text || '').join('').trim();
  }
  return '';
}

function resolveProbeTimeoutMs(model) {
  const byModel = MODEL_TIMEOUT_OVERRIDES_MS.find(({ pattern }) => pattern.test(model.id || ''));
  if (byModel) return byModel.timeoutMs;

  const provider = (model.provider || '').toLowerCase();
  if (PROVIDER_TIMEOUT_OVERRIDES_MS[provider]) {
    return PROVIDER_TIMEOUT_OVERRIDES_MS[provider];
  }

  return REQUEST_TIMEOUT_MS;
}

function classifyProbeResult(result) {
  if (result.ok) return 'success';
  return WARNING_KINDS.has(result.kind) ? 'warning' : 'error';
}

function buildProbeVariants(model, baseUrl) {
  const config = elizaConfig(model.id, baseUrl);
  const isReasoning = usesReasoningTokens(model.id);
  const tokenLimit = isReasoning ? REASONING_MAX_TOKENS : MAX_TOKENS;
  const textMsg = [{ role: 'user', content: TEST_PROMPT }];
  const blockMsg = [{ role: 'user', content: [{ type: 'text', text: TEST_PROMPT }] }];

  if (config.format === 'anthropic') {
    const variants = [
      { name: 'anthropic-blocks-max_tokens', body: { model: config.model || model.id, messages: blockMsg, max_tokens: tokenLimit, stream: false } },
      { name: 'anthropic-string-max_tokens', body: { model: config.model || model.id, messages: textMsg, max_tokens: tokenLimit, stream: false } },
    ];
    if (config.supportsThinking) {
      variants.push({ name: 'anthropic-thinking-enabled', body: { model: config.model || model.id, messages: textMsg, max_tokens: Math.max(tokenLimit, 64), thinking: { budget_tokens: 32, type: 'enabled' }, stream: false } });
    }
    return variants;
  }

  const variants = isReasoning
    ? [
        { name: 'openai-string-max_tokens', body: { model: config.model || model.id, messages: textMsg, max_tokens: tokenLimit, stream: false } },
        { name: 'openai-string-max_completion_tokens', body: { model: config.model || model.id, messages: textMsg, max_completion_tokens: tokenLimit, stream: false, reasoning_effort: 'low' } },
      ]
    : [
        { name: 'openai-string-max_tokens', body: { model: config.model || model.id, messages: textMsg, max_tokens: tokenLimit, stream: false, temperature: 0 } },
        { name: 'openai-string-max_tokens-no-temp', body: { model: config.model || model.id, messages: textMsg, max_tokens: tokenLimit, stream: false } },
      ];

  if (/^(google|zhipu|alibaba|moonshotai|mistral|deepseek|xai|meta|sber)$/.test(model.provider || '')) {
    variants.push({ name: 'openai-blocks-max_tokens', body: { model: config.model || model.id, messages: blockMsg, max_tokens: tokenLimit, stream: false } });
  }

  if (/^(google|alibaba|moonshotai|mistral|deepseek|xai|meta|sber)$/.test(model.provider || '')) {
    variants.push({ name: 'openai-prompt-max_tokens', body: { model: config.model || model.id, prompt: TEST_PROMPT, max_tokens: tokenLimit, stream: false } });
  }

  if (/^(google|alibaba)$/.test(model.provider || '')) {
    variants.push({ name: 'openai-string-max_completion_tokens-no-temp', body: { model: config.model || model.id, messages: textMsg, max_completion_tokens: tokenLimit, stream: false } });
  }

  if (supportsReasoningEffort(model.id)) {
    for (const effort of ['low', 'medium', 'high']) {
      variants.push({ name: `openai-string-reasoning_effort-${effort}`, body: { model: config.model || model.id, messages: textMsg, max_tokens: tokenLimit, stream: false, reasoning_effort: effort } });
    }
  }

  return variants;
}

async function probeModel(model, token, baseUrl, updateModelStatus = null) {
  const config = elizaConfig(model.id, baseUrl);
  let lastFailure = null;

  if (updateModelStatus) {
    updateModelStatus(model.provider, model.id, 'pending', { status: 'pending' });
  }

  const timeoutMs = resolveProbeTimeoutMs(model);

  const doFetch = (body) => fetch(config.url, {
    method: 'POST',
    headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });

  for (const variant of buildProbeVariants(model, baseUrl)) {
    let response;
    const startedAt = Date.now();

    try {
      response = await doFetch(variant.body);
    } catch (err) {
      const latencyMs = Date.now() - startedAt;
      if (err instanceof TypeError) {
        try {
          response = await doFetch(variant.body);
        } catch (retryErr) {
          lastFailure = {
            ok: false,
            status: 0,
            kind: 'network_error',
            error: retryErr?.message || err.message,
            variant: variant.name,
            latencyMs,
            checkedAt: new Date().toISOString(),
          };
          continue;
        }
      } else {
        lastFailure = {
          ok: false,
          status: 0,
          kind: 'timeout_or_abort',
          error: String(err),
          variant: variant.name,
          latencyMs,
          checkedAt: new Date().toISOString(),
        };
        continue;
      }
    }

    const latencyMs = Date.now() - startedAt;

    if (!response.ok) {
      const rawText = await response.text().catch(() => '');
      const parsed = safeJsonParse(rawText || 'null');
      const error = extractErrorMessage(parsed, rawText).slice(0, 300);
      const classification = classifyError(response.status, error);
      lastFailure = {
        ok: false,
        status: response.status,
        kind: classification.kind,
        error,
        variant: variant.name,
        latencyMs,
        checkedAt: new Date().toISOString(),
      };
      if (!classification.retryable) {
        const finalStatus = classifyProbeResult(lastFailure);
        if (updateModelStatus) {
          updateModelStatus(model.provider, model.id, finalStatus, {
            status: finalStatus,
            kind: lastFailure.kind,
            variant: lastFailure.variant,
            latencyMs: lastFailure.latencyMs,
            checkedAt: lastFailure.checkedAt,
            httpStatus: lastFailure.status,
            error: lastFailure.error,
          });
        }
        return lastFailure;
      }
      continue;
    }

    const data = await response.json().catch(() => null);
    const text = extractResponseText(data);
    if (!text) {
      lastFailure = {
        ok: false,
        status: response.status,
        kind: 'empty_response',
        error: 'empty response',
        variant: variant.name,
        latencyMs,
        checkedAt: new Date().toISOString(),
      };
      continue;
    }

    const success = {
      ok: true,
      status: response.status,
      kind: 'ok',
      sample: text.slice(0, 80),
      variant: variant.name,
      latencyMs,
      checkedAt: new Date().toISOString(),
    };

    if (updateModelStatus) {
      updateModelStatus(model.provider, model.id, 'success', {
        status: 'success',
        kind: 'ok',
        variant: success.variant,
        latencyMs: success.latencyMs,
        checkedAt: success.checkedAt,
        httpStatus: success.status,
      });
    }

    return success;
  }

  const failed = lastFailure || {
    ok: false,
    status: 0,
    kind: 'probe_failed',
    error: 'probe failed without response',
    variant: 'none',
    latencyMs: null,
    checkedAt: new Date().toISOString(),
  };

  const finalStatus = classifyProbeResult(failed);
  if (updateModelStatus) {
    updateModelStatus(model.provider, model.id, finalStatus, {
      status: finalStatus,
      kind: failed.kind,
      variant: failed.variant,
      latencyMs: failed.latencyMs,
      checkedAt: failed.checkedAt,
      httpStatus: failed.status,
      error: failed.error,
    });
  }

  return failed;
}

function toProbeMetadata(result) {
  const finalStatus = classifyProbeResult(result);
  return {
    status: finalStatus,
    kind: result.kind,
    variant: result.variant,
    latencyMs: Number.isFinite(result.latencyMs) ? result.latencyMs : null,
    checkedAt: result.checkedAt || new Date().toISOString(),
    httpStatus: Number.isFinite(result.status) ? result.status : 0,
    ...(result.error ? { error: result.error } : {}),
    ...(result.sample ? { sample: result.sample } : {}),
  };
}

function resolveConcurrency(override) {
  const candidate = Number.parseInt(String(override ?? DEFAULT_CONCURRENCY), 10);
  if (!Number.isFinite(candidate) || candidate < 1) return 1;
  return Math.min(candidate, 8);
}

async function runProbe(models, token, baseUrl, onModelProbed, updateModelStatus = null, options = {}) {
  const probeModelFn = options.probeModelFn || probeModel;
  const concurrency = resolveConcurrency(options.concurrency);
  const list = Array.isArray(models) ? models : [];
  const results = new Array(list.length);
  let cursor = 0;

  async function worker() {
    while (true) {
      const index = cursor;
      cursor += 1;
      if (index >= list.length) return;

      const model = list[index];
      try {
        const result = await probeModelFn(model, token, baseUrl, updateModelStatus);
        const withProbe = { ...model, probe: toProbeMetadata(result) };
        if (onModelProbed) onModelProbed(withProbe.provider, withProbe);
        results[index] = withProbe;
      } catch (err) {
        console.error(`[eliza-client] probe error for ${model.id}:`, err.message);
        const failedProbe = {
          status: 'error',
          kind: 'probe_failed',
          variant: 'none',
          latencyMs: null,
          checkedAt: new Date().toISOString(),
          httpStatus: 0,
          error: err.message,
        };
        if (updateModelStatus) {
          updateModelStatus(model.provider, model.id, 'error', failedProbe);
        }
        const failed = { ...model, probe: failedProbe };
        if (onModelProbed) onModelProbed(failed.provider, failed);
        results[index] = failed;
      }
    }
  }

  const workers = [];
  const workerCount = Math.min(concurrency, Math.max(list.length, 1));
  for (let i = 0; i < workerCount; i += 1) {
    workers.push(worker());
  }

  await Promise.all(workers);
  return results.sort((a, b) => a.id.localeCompare(b.id));
}

module.exports = {
  runProbe,
  probeModel,
  buildProbeVariants,
  classifyError,
  extractResponseText,
  extractErrorMessage,
  classifyProbeResult,
  resolveProbeTimeoutMs,
  resolveConcurrency,
};
