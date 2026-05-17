'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { createProbeState } = require('../lib/probe-state');

test('probe state buffers fast probe events before catalog seed', () => {
  const state = createProbeState();

  state.applyProbeEvent('openai', {
    id: 'gpt-4.1',
    provider: 'openai',
    probe: {
      status: 'success',
      kind: 'ok',
      latencyMs: 12,
      checkedAt: '2026-05-01T00:00:00.000Z',
      httpStatus: 200,
    },
  });

  assert.equal(state.getSnapshot().seeded, false);
  assert.equal(state.getSnapshot().summary.total, 0);

  state.seedCatalog([
    { id: 'gpt-4.1', provider: 'openai', title: 'GPT 4.1' },
  ], { probeMode: true });

  const snapshot = state.getSnapshot();
  assert.equal(snapshot.seeded, true);
  assert.equal(snapshot.catalogReady, true);
  assert.equal(snapshot.probeStatus, 'complete');
  assert.equal(snapshot.summary.total, 1);
  assert.equal(snapshot.summary.success, 1);
  assert.equal(snapshot.providers.length, 1);
  assert.equal(snapshot.providers[0].models.length, 1);
  assert.equal(snapshot.providers[0].models[0].kind, 'ok');
});

test('probe state marks explicit probe mode complete for zero catalog models', () => {
  const state = createProbeState();

  state.seedCatalog([], { probeMode: true });

  const snapshot = state.getSnapshot();
  assert.equal(snapshot.seeded, true);
  assert.equal(snapshot.catalogReady, true);
  assert.equal(snapshot.probeStatus, 'complete');
  assert.equal(snapshot.summary.total, 0);
  assert.equal(snapshot.summary.pending, 0);
});
