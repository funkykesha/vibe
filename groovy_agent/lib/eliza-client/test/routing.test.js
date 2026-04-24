'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { elizaConfig, supportsThinking, usesReasoningTokens, getInternalModelId } = require('../routing.js');

describe('elizaConfig', () => {
  it('routes claude to anthropic endpoint', () => {
    const cfg = elizaConfig('claude-sonnet-4-6');
    assert.equal(cfg.format, 'anthropic');
    assert.match(cfg.url, /\/raw\/anthropic\//);
    assert.equal(cfg.model, 'claude-sonnet-4-6');
  });

  it('routes gpt-4.1 to openai endpoint', () => {
    const cfg = elizaConfig('gpt-4.1');
    assert.equal(cfg.format, 'openai');
    assert.match(cfg.url, /\/raw\/openai\//);
  });

  it('routes gemini to openrouter endpoint', () => {
    const cfg = elizaConfig('gemini-2.0-flash');
    assert.equal(cfg.format, 'openai');
    assert.match(cfg.url, /\/raw\/openrouter\//);
  });

  it('routes glm to internal glm endpoint', () => {
    const cfg = elizaConfig('glm-4.7');
    assert.match(cfg.url, /\/raw\/internal\/glm-latest\//);
    assert.equal(cfg.model, 'internal/glm-latest');
  });

  it('routes qwen3-coder to internal qwen endpoint', () => {
    const cfg = elizaConfig('qwen3-coder-480b');
    assert.match(cfg.url, /qwen3-coder-480b-a35b-runtime/);
  });

  it('routes gpt-5 with supportsStreaming: false', () => {
    const cfg = elizaConfig('gpt-5');
    assert.equal(cfg.supportsStreaming, false);
  });

  it('routes gpt-5.1 with supportsStreaming: false', () => {
    const cfg = elizaConfig('gpt-5.1-mini');
    assert.equal(cfg.supportsStreaming, false);
  });

  it('respects custom baseUrl', () => {
    const cfg = elizaConfig('claude-sonnet-4-6', 'https://custom.example.com');
    assert.match(cfg.url, /https:\/\/custom\.example\.com/);
  });

  it('routes gpt-oss to internal gpt-oss endpoint with supportsReasoningEffort', () => {
    const cfg = elizaConfig('gpt-oss-120b');
    assert.match(cfg.url, /\/raw\/internal\/gpt-oss-120b\//);
    assert.equal(cfg.supportsReasoningEffort, true);
  });

  it('routes alice-ai-llm-32b-reasoner to reasoner endpoint', () => {
    const cfg = elizaConfig('alice-ai-llm-32b-reasoner');
    assert.match(cfg.url, /alice-ai-llm-32b-reasoner-latest/);
  });

  it('routes minimax to internal minimax endpoint', () => {
    const cfg = elizaConfig('minimax');
    assert.match(cfg.url, /\/raw\/internal\/minimax-latest\//);
  });
});

describe('supportsThinking', () => {
  it('returns true for claude-3.7', () => {
    assert.equal(supportsThinking('claude-3-7-sonnet'), true);
  });
  it('returns false for claude-sonnet-4-6', () => {
    assert.equal(supportsThinking('claude-sonnet-4-6'), false);
  });
});

describe('usesReasoningTokens', () => {
  it('returns true for o1', () => {
    assert.equal(usesReasoningTokens('o1'), true);
  });
  it('returns true for o3', () => {
    assert.equal(usesReasoningTokens('o3'), true);
  });
  it('returns true for grok-3', () => {
    assert.equal(usesReasoningTokens('grok-3'), true);
  });
  it('returns true for grok-4', () => {
    assert.equal(usesReasoningTokens('grok-4'), true);
  });
  it('returns true for gpt-5', () => {
    assert.equal(usesReasoningTokens('gpt-5'), true);
  });
  it('returns true for gpt5 (no-dash variant)', () => {
    assert.equal(usesReasoningTokens('gpt5'), true);
  });
  it('returns false for gpt-4.1', () => {
    assert.equal(usesReasoningTokens('gpt-4.1'), false);
  });
  it('returns false for claude-sonnet', () => {
    assert.equal(usesReasoningTokens('claude-sonnet-4-6'), false);
  });
});

describe('getInternalModelId', () => {
  it('returns internal glm id for glm models', () => {
    assert.equal(getInternalModelId('glm-4.7'), 'internal/glm-latest');
    assert.equal(getInternalModelId('glm'), 'internal/glm-latest');
  });
  it('returns internal qwen3-coder id', () => {
    assert.equal(getInternalModelId('qwen3-coder-480b'), 'internal/qwen3-coder-480b-a35b-runtime');
  });
  it('returns null for unknown models', () => {
    assert.equal(getInternalModelId('gpt-4.1'), null);
    assert.equal(getInternalModelId('claude-sonnet'), null);
  });
});
