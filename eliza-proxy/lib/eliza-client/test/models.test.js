'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { parseModels, inferProvider, inferFamily, inferCapabilities, inferStability } = require('../models.js');
const { parseObservedFacts, planMoniumQueries, findObservedMissingFromCatalog } = require('../observed-facts.js');

describe('inferProvider', () => {
  it('recognizes claude as anthropic', () => {
    assert.equal(inferProvider({ id: 'claude-sonnet-4-6', title: '', developer: 'Anthropic' }), 'anthropic');
  });
  it('recognizes gpt as openai', () => {
    assert.equal(inferProvider({ id: 'gpt-4.1', title: '', developer: 'OpenAI' }), 'openai');
  });
  it('recognizes gemini as google', () => {
    assert.equal(inferProvider({ id: 'gemini-2.0-flash', title: '', developer: 'Google' }), 'google');
  });
});

describe('parseModels', () => {
  it('filters excluded namespaces', () => {
    const raw = [
      { id: 'claude-sonnet', title: 'Claude Sonnet', developer: 'Anthropic', namespace: 'eliza_test', prices: {} },
      { id: 'gpt-4', title: 'GPT-4', developer: 'OpenAI', namespace: '', prices: {} },
    ];
    const result = parseModels({ data: raw });
    assert.equal(result.length, 0); // both filtered: claude-sonnet by namespace, gpt-4 by OLD_MODEL_PATTERNS
  });

  it('filters non-chat models', () => {
    const raw = [{ id: 'text-embedding-ada-002', namespace: '' }];
    assert.equal(parseModels({ data: raw }).length, 0);
  });

  it('filters date-versioned ids', () => {
    const raw = [{ id: 'gpt-4o-2024-05-13', namespace: '' }];
    assert.equal(parseModels({ data: raw }).length, 0);
  });

  it('deduplicates by provider:family keeping preferred', () => {
    const raw = [
      { id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } },
      { id: 'anthropic/claude-sonnet-4-6', title: '', developer: '', namespace: '', prices: {} },
    ];
    const result = parseModels({ data: raw });
    // Both resolve to anthropic:claude-sonnet — only one survives, the one with better score (title + prices)
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 'claude-sonnet-4-6');
  });

  it('filters transient/preview models', () => {
    const raw = [
      { id: 'claude-sonnet-preview', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: {} },
      { id: 'gpt-4o-audio-preview', title: '', developer: 'OpenAI', namespace: '', prices: {} },
    ];
    assert.equal(parseModels({ data: raw }).length, 0);
  });

  it('excludes non-streaming GPT models from selectable catalog', () => {
    const raw = [
      { id: 'gpt-5.4-pro', title: 'GPT 5.4 Pro', developer: 'OpenAI', namespace: '', prices: {} },
      { id: 'gpt-4.1', title: 'GPT 4.1', developer: 'OpenAI', namespace: '', prices: {} },
    ];
    const result = parseModels({ data: raw });
    assert.deepEqual(result.map((m) => m.id), ['gpt-4.1']);
  });

  it('keeps compatible streaming chat models with metadata', () => {
    const result = parseModels({ data: [
      { id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } },
    ] });
    assert.equal(result.length, 1);
    assert.equal(result[0].provider, 'anthropic');
    assert.equal(result[0].family, 'claude-sonnet');
    assert.equal(result[0].stability, 'stable');
    assert.equal(result[0].capabilities.chat, true);
    assert.equal(result[0].capabilities.streaming, true);
  });

  it('includes observed compatible preview models with preview metadata', () => {
    const facts = parseObservedFacts(
      'chat.status{model="gemini-3-pro-preview",vendor="google",provider="google",status="200",stream="true"} 12',
      { from: '2026-05-01T00:00:00Z', to: '2026-05-02T00:00:00Z' },
    );
    const result = parseModels({
      data: [{ id: 'gemini-3-pro-preview', title: 'Gemini 3 Pro Preview', developer: 'Google', namespace: '', prices: {} }],
    }, { observedFacts: facts });
    assert.equal(result.length, 1);
    assert.equal(result[0].stability, 'preview');
    assert.equal(result[0].observed.observedStatus200, true);
    assert.equal(result[0].observed.observedStreamTrue, true);
  });

  it('deduplicates -latest variant with bare id', () => {
    const raw = [
      { id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } },
      { id: 'claude-sonnet-4-6-latest', title: 'Claude Sonnet Latest', developer: 'Anthropic', namespace: '', prices: {} },
    ];
    const result = parseModels({ data: raw });
    assert.equal(result.length, 1);
  });

  it('accepts array input', () => {
    const raw = [{ id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } }];
    const result = parseModels(raw);
    assert.equal(result.length, 1);
  });
});

describe('capability helpers', () => {
  it('classifies chat, streaming, non-chat, stable, and preview models', () => {
    assert.deepEqual(inferCapabilities({ id: 'gpt-4.1' }), { chat: true, streaming: true, selectable: true });
    assert.equal(inferCapabilities({ id: 'gpt-5.4-pro' }).streaming, false);
    assert.equal(inferCapabilities({ id: 'text-embedding-3-large' }).chat, false);
    assert.equal(inferStability({ id: 'gpt-4.1' }), 'stable');
    assert.equal(inferStability({ id: 'gemini-3-pro-preview' }), 'preview');
  });
});

describe('observed Monium facts', () => {
  it('parses fixture text into observed model facts and ignores zero traffic', () => {
    const facts = parseObservedFacts([
      'chat.status{model="gemini-3-pro-preview",vendor="google",provider="google",status="200",stream="true"} 5',
      'chat.status{model="gpt-4.1",vendor="openai",provider="openai",status="500",stream="true"} 0',
    ].join('\n'), { from: '2026-05-01T00:00:00Z', to: '2026-05-02T00:00:00Z' });

    assert.equal(facts.size, 1);
    assert.equal(facts.get('gemini-3-pro-preview').observedStatus200, true);
    assert.equal(facts.get('gemini-3-pro-preview').observedStreamTrue, true);
    assert.equal(facts.get('gemini-3-pro-preview').requestScore, 5);
  });

  it('plans bounded absolute-window Monium queries', () => {
    const queries = planMoniumQueries({
      from: '2026-05-01T00:00:00Z',
      to: '2026-05-02T00:00:00Z',
      vendors: ['google'],
      statuses: ['200'],
      streams: ['true', 'false'],
    });
    assert.equal(queries.length, 2);
    assert.deepEqual(queries[0].selectors, { vendor: 'google', status: '200', stream: 'true' });
    assert.throws(() => planMoniumQueries({ from: 'now-1d', vendors: ['google'] }), /from\/to/);
  });

  it('reports observed models missing from catalog as diagnostics', () => {
    const facts = parseObservedFacts('chat.status{model="missing-model",vendor="google",status="200",stream="true"} 1');
    const missing = findObservedMissingFromCatalog(facts, [{ id: 'gpt-4.1' }]);
    assert.equal(missing.length, 1);
    assert.equal(missing[0].model, 'missing-model');
  });
});

describe('inferFamily', () => {
  it('returns claude-sonnet for sonnet models', () => {
    assert.equal(inferFamily({ id: 'claude-sonnet-4-6', title: 'Claude Sonnet' }, 'anthropic'), 'claude-sonnet');
  });
  it('returns claude-haiku for haiku models', () => {
    assert.equal(inferFamily({ id: 'claude-haiku-3-5', title: 'Claude Haiku' }, 'anthropic'), 'claude-haiku');
  });
  it('returns gpt-4.1 for gpt-4.1 openai models', () => {
    assert.equal(inferFamily({ id: 'gpt-4.1', title: 'GPT-4.1' }, 'openai'), 'gpt-4.1');
  });
  it('returns empty string for anthropic model without known subfamily', () => {
    assert.equal(inferFamily({ id: 'claude-unknown-model', title: 'Claude Unknown' }, 'anthropic'), '');
  });
});
