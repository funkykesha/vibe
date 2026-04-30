'use strict';

const { elizaConfig, supportsThinking, usesReasoningTokens, supportsReasoningEffort } = require('./routing.js');

const CONCURRENCY = 15;
const REQUEST_TIMEOUT_MS = 200;
const MAX_TOKENS = 16;
const REASONING_MAX_TOKENS = 32;
const TEST_PROMPT = 'Reply with exactly OK.';

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
  // 401/412: auth/precondition failures — non-retryable (Rev 2)
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
      const c = choice?.message?.content ?? choice?.delta?.content ?? '';
      if (typeof c === 'string') return c;
      if (Array.isArray(c)) return c.map((i) => (typeof i?.text === 'string' ? i.text : '')).join('');
      return '';
    }).join('').trim();
  }
  if (Array.isArray(data.output)) {
    return data.output.map((item) => {
      if (typeof item?.content === 'string') return item.content;
      if (Array.isArray(item?.content)) return item.content.map((p) => (typeof p?.text === 'string' ? p.text : '')).join('');
      if (typeof item?.text === 'string') return item.text;
      return '';
    }).join('').trim();
  }
  if (Array.isArray(data.candidates)) {
    return data.candidates.map((c) => c?.content?.parts || []).flat().map((p) => p?.text || '').join('').trim();
  }
  return '';
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

  // Rev 2: reasoning models must NOT receive temperature (causes 400 errors)
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

  // zhipu (GLM) uses an internal endpoint — prompt-style and max_completion_tokens variants don't apply
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
  
  // Set status to pending if updateModelStatus function is provided
  if (updateModelStatus) {
    updateModelStatus(model.provider, model.id, 'pending');
  }

  const doFetch = (body) => fetch(config.url, {
    method: 'POST',
    headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });

  for (const variant of buildProbeVariants(model, baseUrl)) {
    let response;
    try {
      response = await doFetch(variant.body);
    } catch (err) {
      // Rev 2: one retry on TypeError (network error — DNS failure, ECONNREFUSED, etc.)
      if (err instanceof TypeError) {
        try {
          response = await doFetch(variant.body);
        } catch {
          lastFailure = { ok: false, status: 0, error: err.message, kind: 'network_error', variant: variant.name };
          continue;
        }
      } else {
        lastFailure = { ok: false, status: 0, error: String(err), kind: 'timeout_or_abort', variant: variant.name };
        continue;
      }
    }

    if (!response.ok) {
      const rawText = await response.text().catch(() => '');
      const parsed = safeJsonParse(rawText || 'null');
      const error = extractErrorMessage(parsed, rawText).slice(0, 300);
      const classification = classifyError(response.status, error);
      lastFailure = { ok: false, status: response.status, error, kind: classification.kind, variant: variant.name };
      if (!classification.retryable) {
        // Set status to error if updateModelStatus function is provided
        if (updateModelStatus) {
          updateModelStatus(model.provider, model.id, 'error');
        }
        return lastFailure;
      }
      continue;
    }

    const data = await response.json().catch(() => null);
    const text = extractResponseText(data);
    if (!text) {
      lastFailure = { ok: false, status: response.status, error: 'empty response', kind: 'empty_response', variant: variant.name };
      continue;
    }
    
    // Set status to success if updateModelStatus function is provided
    if (updateModelStatus) {
      updateModelStatus(model.provider, model.id, 'success');
    }

    return { ok: true, status: response.status, sample: text.slice(0, 80), variant: variant.name };
  }
  
  // Set status to error if updateModelStatus function is provided
  if (updateModelStatus) {
    updateModelStatus(model.provider, model.id, 'error');
  }

  return lastFailure || { ok: false, status: 0, error: 'probe failed without response', kind: 'probe_failed', variant: 'none' };
}

async function runProbe(models, token, baseUrl, onModelProbed, updateModelStatus = null) {
  const results = [];
  for (const model of models) {
    try {
      const result = await probeModel(model, token, baseUrl, updateModelStatus);
      if (result.ok) {
        const withProbe = { ...model, probe: { checkedAt: new Date().toISOString(), status: result.status, sample: result.sample, variant: result.variant } };
        if (onModelProbed) onModelProbed(withProbe.provider, withProbe);
        results.push(withProbe);
      } else {
        const failed = { ...model, probe: { status: 0 } };
        if (onModelProbed) onModelProbed(failed.provider, failed);
        results.push(failed);
      }
    } catch (err) {
      console.error(`[eliza-client] probe error for ${model.id}:`, err.message);
      const failed = { ...model, probe: { status: 0 } };
      if (onModelProbed) onModelProbed(failed.provider, failed);
      results.push(failed);
    }
  }
  return results.sort((a, b) => a.id.localeCompare(b.id));
}

module.exports = { runProbe, probeModel, buildProbeVariants, classifyError, extractResponseText, extractErrorMessage };
