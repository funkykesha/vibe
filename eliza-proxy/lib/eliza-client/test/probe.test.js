'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  classifyError,
  extractResponseText,
  classifyProbeResult,
  resolveProbeTimeoutMs,
  runProbe,
  resolveConcurrency,
} = require('../probe.js');

describe('classifyError', () => {
  it('classifies 404 model not found as non-retryable', () => {
    const { kind, retryable } = classifyError(404, 'model not found');
    assert.equal(kind, 'model_not_found');
    assert.equal(retryable, false);
  });

  it('classifies 429 as retryable', () => {
    const { retryable } = classifyError(429, '');
    assert.equal(retryable, true);
  });

  it('classifies 400 invalid_request_shape as retryable', () => {
    const { kind, retryable } = classifyError(400, 'invalid max_tokens parameter');
    assert.equal(kind, 'invalid_request_shape');
    assert.equal(retryable, true);
  });

  it('classifies 401 as non-retryable auth_error', () => {
    const { kind, retryable } = classifyError(401, 'unauthorized');
    assert.equal(kind, 'auth_error');
    assert.equal(retryable, false);
  });

  it('classifies 500 as retryable provider_error', () => {
    const { kind, retryable } = classifyError(500, 'internal server error');
    assert.equal(kind, 'provider_error');
    assert.equal(retryable, true);
  });
});

describe('extractResponseText', () => {
  it('extracts from openai choices', () => {
    const data = { choices: [{ message: { content: 'OK' } }] };
    assert.equal(extractResponseText(data), 'OK');
  });

  it('extracts from anthropic content array', () => {
    const data = { content: [{ type: 'text', text: 'OK' }] };
    assert.equal(extractResponseText(data), 'OK');
  });

  it('returns empty string for unknown shape', () => {
    assert.equal(extractResponseText({ unknown: true }), '');
  });
});

describe('probe result classification', () => {
  it('maps retryable failures to warning', () => {
    const status = classifyProbeResult({ ok: false, kind: 'quota_exceeded' });
    assert.equal(status, 'warning');
  });

  it('maps non-retryable failures to error', () => {
    const status = classifyProbeResult({ ok: false, kind: 'auth_error' });
    assert.equal(status, 'error');
  });

  it('maps success to success', () => {
    const status = classifyProbeResult({ ok: true, kind: 'ok' });
    assert.equal(status, 'success');
  });
});

describe('timeout policy', () => {
  it('uses provider override for anthropic', () => {
    const timeout = resolveProbeTimeoutMs({ id: 'claude-sonnet-4-6', provider: 'anthropic' });
    assert.equal(timeout, 1900);
  });

  it('uses model override for claude-opus', () => {
    const timeout = resolveProbeTimeoutMs({ id: 'claude-opus-4-1', provider: 'anthropic' });
    assert.equal(timeout, 2200);
  });
});

describe('concurrency controls', () => {
  it('bounds concurrency to default range', () => {
    assert.equal(resolveConcurrency(0), 1);
    assert.equal(resolveConcurrency(100), 8);
  });

  it('runProbe respects concurrency limit', async () => {
    const models = Array.from({ length: 6 }, (_, i) => ({ id: `m-${i}`, provider: 'openai' }));

    let active = 0;
    let maxActive = 0;

    async function fakeProbeModel(model) {
      active += 1;
      maxActive = Math.max(maxActive, active);
      await new Promise((resolve) => setTimeout(resolve, 15));
      active -= 1;
      return {
        ok: true,
        status: 200,
        kind: 'ok',
        variant: 'fake',
        latencyMs: 1,
        checkedAt: new Date().toISOString(),
        sample: 'OK',
      };
    }

    const results = await runProbe(models, 't', 'https://api.example.test', null, null, {
      concurrency: 2,
      probeModelFn: fakeProbeModel,
    });

    assert.equal(results.length, 6);
    assert.equal(maxActive <= 2, true);
  });
});
