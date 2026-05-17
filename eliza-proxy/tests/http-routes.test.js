'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');

const { createApp, createUsageStats, renderDashboardHtml, parseProbeMode } = require('../server');
const { createProbeState } = require('../lib/probe-state');

function makeEliza(models) {
  return {
    probeMode: false,
    async getModels() {
      return { models, validated: false, onValidated: () => {} };
    },
    async probe() {
      return { available: true, probe: { ok: true, kind: 'ok' }, realProviderCalls: true };
    },
    onModelUpdate() {},
    async *chat() {
      yield { done: true };
    },
  };
}

function findRouteHandler(app, method, path) {
  const layer = app._router.stack.find((item) => item.route
    && item.route.path === path
    && item.route.methods[method.toLowerCase()]);
  return layer?.route?.stack?.[0]?.handle;
}

function makeRes() {
  return {
    statusCode: 200,
    headers: {},
    body: null,
    writableEnded: false,
    destroyed: false,
    setHeader(name, value) {
      this.headers[name.toLowerCase()] = value;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      this.writableEnded = true;
      return this;
    },
    send(payload) {
      this.body = payload;
      this.writableEnded = true;
      return this;
    },
    flushHeaders() {},
    write() { return true; },
    end() {
      this.writableEnded = true;
    },
    on() {},
  };
}

async function callRoute(app, method, path, reqExtras = {}) {
  const handler = findRouteHandler(app, method, path);
  assert.ok(handler, `missing route ${method} ${path}`);

  const req = {
    method,
    path,
    url: path,
    headers: {},
    body: {},
    ...reqExtras,
  };
  const res = makeRes();

  await handler(req, res);
  return res;
}

test('GET / serves read-only dashboard html', async () => {
  const models = [{ id: 'gpt-4.1', provider: 'openai', title: '', developer: '', prices: {} }];
  const probeState = createProbeState();
  probeState.seedCatalog(models);

  const app = createApp({
    eliza: makeEliza(models),
    probeState,
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const res = await callRoute(app, 'GET', '/');
  assert.equal(res.statusCode, 200);
  assert.match(String(res.body), /Read-only catalog view/);
  assert.match(String(res.body), /\/v1\/probe-status/);
});

test('dashboard inline script is valid JavaScript', () => {
  const html = renderDashboardHtml();
  const match = html.match(/<script>([\s\S]*?)<\/script>/);
  assert.ok(match, 'missing inline script');
  assert.doesNotThrow(() => new vm.Script(match[1]));
});

test('startup probe mode is opt-in by CLI or environment', () => {
  assert.equal(parseProbeMode([], {}), false);
  assert.equal(parseProbeMode(['--probe'], {}), true);
  assert.equal(parseProbeMode([], { ELIZA_STARTUP_PROBE: 'true' }), true);
  assert.equal(parseProbeMode(['--exit-after-probe'], {}), true);
});

test('GET /v1/probe-status returns lifecycle and grouped models', async () => {
  const models = [
    { id: 'gpt-4.1', provider: 'openai', title: '', developer: '', prices: {} },
    { id: 'claude-sonnet-4-6', provider: 'anthropic', title: '', developer: '', prices: {} },
  ];
  const probeState = createProbeState();
  probeState.seedCatalog(models);
  probeState.applyProbeEvent('openai', {
    id: 'gpt-4.1',
    provider: 'openai',
    probe: { status: 'warning', kind: 'timeout_or_abort', latencyMs: 900, checkedAt: '2026-01-01T00:00:00.000Z' },
  });

  const app = createApp({
    eliza: makeEliza(models),
    probeState,
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const res = await callRoute(app, 'GET', '/v1/probe-status');
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.probeStatus, 'complete');
  assert.equal(res.body.catalogReady, true);
  assert.equal(res.body.summary.warning, 1);
  assert.equal(res.body.startupError, null);
  assert.equal(Array.isArray(res.body.providers), true);
});

test('GET /v1/probe-status lazily seeds catalog when startup state is empty', async () => {
  const models = [
    { id: 'gpt-4.1', provider: 'openai', title: '', developer: '', prices: {} },
  ];
  const probeState = createProbeState();

  const app = createApp({
    eliza: makeEliza(models),
    probeState,
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const res = await callRoute(app, 'GET', '/v1/probe-status');
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.probeStatus, 'idle');
  assert.equal(res.body.summary.total, 1);
  assert.equal(res.body.summary.available, 1);
  assert.equal(res.body.providers[0].provider, 'openai');
});

test('GET /v1/probe-status exposes startup error when present', async () => {
  const models = [];
  const probeState = createProbeState();
  probeState.setStartupError('token invalid');

  const app = createApp({
    eliza: makeEliza(models),
    probeState,
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const res = await callRoute(app, 'GET', '/v1/probe-status');
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.startupError, 'token invalid');
  assert.equal(res.body.summary.total, 0);
});

test('GET /v1/health and /v1/models include probe metadata', async () => {
  const models = [{ id: 'gpt-4.1', provider: 'openai', title: '', developer: '', prices: {} }];
  const probeState = createProbeState();
  probeState.seedCatalog(models);
  probeState.applyProbeEvent('openai', {
    id: 'gpt-4.1',
    provider: 'openai',
    probe: { status: 'error', kind: 'auth_error', checkedAt: '2026-01-01T00:00:00.000Z', latencyMs: 10 },
  });

  const app = createApp({
    eliza: makeEliza(models),
    probeState,
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const healthRes = await callRoute(app, 'GET', '/v1/health');
  assert.equal(healthRes.statusCode, 200);
  assert.equal(healthRes.body.probeStatus, 'complete');
  assert.equal(healthRes.body.catalogReady, true);
  assert.equal(healthRes.body.probeSummary.error, 1);

  const modelsRes = await callRoute(app, 'GET', '/v1/models');
  assert.equal(modelsRes.statusCode, 200);
  assert.equal(modelsRes.body.models.length, 1);
  assert.equal(modelsRes.body.models[0].probe.status, 'error');
  assert.equal(modelsRes.body.models[0].probe.kind, 'auth_error');
});

test('POST /v1/probe remains explicit manual diagnostic operation', async () => {
  const app = createApp({
    eliza: makeEliza([]),
    probeState: createProbeState(),
    usageStats: createUsageStats(),
    logUsage: false,
  });

  const res = await callRoute(app, 'POST', '/v1/probe', { body: { model: 'gpt-4.1' } });
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.available, true);
  assert.equal(res.body.realProviderCalls, true);
  assert.equal(typeof res.body.latency, 'number');
});
