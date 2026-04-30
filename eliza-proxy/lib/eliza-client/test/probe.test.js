'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { classifyError, extractResponseText } = require('../probe.js');

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
  it('classifies 412 as non-retryable auth_error', () => {
    const { kind, retryable } = classifyError(412, 'precondition failed');
    assert.equal(kind, 'auth_error');
    assert.equal(retryable, false);
  });
  it('classifies 500 as retryable provider_error', () => {
    const { kind, retryable } = classifyError(500, 'internal server error');
    assert.equal(kind, 'provider_error');
    assert.equal(retryable, true);
  });
  it('classifies 403 nda as non-retryable', () => {
    const { kind, retryable } = classifyError(403, 'nda not accepted');
    assert.equal(kind, 'nda_not_allowed');
    assert.equal(retryable, false);
  });
  it('classifies 403 without nda as forbidden non-retryable', () => {
    const { kind, retryable } = classifyError(403, 'access denied');
    assert.equal(kind, 'forbidden');
    assert.equal(retryable, false);
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
  it('returns empty string for null', () => {
    assert.equal(extractResponseText(null), '');
  });
});
