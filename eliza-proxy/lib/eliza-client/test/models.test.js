'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { parseModels, inferProvider, inferFamily } = require('../models.js');

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
