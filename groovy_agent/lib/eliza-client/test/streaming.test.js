'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeStream } = require('../streaming.js');

function makeStream(chunks) {
  const encoder = new TextEncoder();
  return new ReadableStream({
    start(controller) {
      for (const chunk of chunks) controller.enqueue(encoder.encode(chunk));
      controller.close();
    },
  });
}

async function collect(gen) {
  const results = [];
  for await (const item of gen) results.push(item);
  return results;
}

// ── OpenAI format ──────────────────────────────────────────────────────────

test('openai: basic hello + world + [DONE]', async () => {
  const stream = makeStream([
    'data: {"choices":[{"delta":{"content":"hello"}}]}\n\n',
    'data: {"choices":[{"delta":{"content":" world"}}]}\n\n',
    'data: [DONE]\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'hello', done: false },
    { delta: ' world', done: false },
    { delta: '', done: true },
  ]);
});

test('openai: finish_reason stop without [DONE]', async () => {
  const stream = makeStream([
    'data: {"choices":[{"delta":{"content":"hi"},"finish_reason":"stop"}]}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'hi', done: false },
    { delta: '', done: true },
  ]);
});

test('openai: usage capture before done', async () => {
  const stream = makeStream([
    'data: {"choices":[{"delta":{"content":"hi"}}]}\n\n',
    'data: {"choices":[{"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5}}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'hi', done: false },
    { delta: '', done: false, usage: { input: 10, output: 5 } },
    { delta: '', done: true },
  ]);
});

test('openai: [DONE] terminates stream', async () => {
  const stream = makeStream([
    'data: {"choices":[{"delta":{"content":"a"}}]}\n\n',
    'data: [DONE]\n\n',
    'data: {"choices":[{"delta":{"content":"should not appear"}}]}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.equal(items.length, 2);
  assert.equal(items[0].delta, 'a');
  assert.equal(items[1].done, true);
});

test('openai: empty content delta is skipped', async () => {
  const stream = makeStream([
    'data: {"choices":[{"delta":{}}]}\n\n',
    'data: {"choices":[{"delta":{"content":""}}]}\n\n',
    'data: [DONE]\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [{ delta: '', done: true }]);
});

// ── Anthropic format ───────────────────────────────────────────────────────

test('anthropic: basic content_block_delta + message_stop', async () => {
  const stream = makeStream([
    'data: {"type":"content_block_delta","delta":{"text":"hi"}}\n\n',
    'data: {"type":"message_stop"}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'anthropic'));
  assert.deepEqual(items, [
    { delta: 'hi', done: false },
    { delta: '', done: true },
  ]);
});

test('anthropic: error event', async () => {
  const stream = makeStream([
    'data: {"type":"error","error":{"message":"quota exceeded"}}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'anthropic'));
  assert.deepEqual(items, [
    { delta: '', done: true, error: 'quota exceeded' },
  ]);
});

test('anthropic: usage capture from message_delta — output_tokens only', async () => {
  const stream = makeStream([
    'data: {"type":"content_block_delta","delta":{"text":"hello"}}\n\n',
    'data: {"type":"message_delta","usage":{"output_tokens":8}}\n\n',
    'data: {"type":"message_stop"}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'anthropic'));
  assert.deepEqual(items, [
    { delta: 'hello', done: false },
    { delta: '', done: false, usage: { input: 0, output: 8 } },
    { delta: '', done: true },
  ]);
});

test('anthropic: unknown event types are skipped', async () => {
  const stream = makeStream([
    'data: {"type":"message_start","message":{"id":"msg_123"}}\n\n',
    'data: {"type":"content_block_start","index":0}\n\n',
    'data: {"type":"content_block_delta","delta":{"text":"hi"}}\n\n',
    'data: {"type":"message_stop"}\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'anthropic'));
  assert.deepEqual(items, [
    { delta: 'hi', done: false },
    { delta: '', done: true },
  ]);
});

// ── Both formats: chunked delivery ────────────────────────────────────────

test('openai: SSE event split across multiple ReadableStream chunks', async () => {
  // Split "data: {...}\n\n" in the middle of the JSON
  const full = 'data: {"choices":[{"delta":{"content":"split"}}]}\n\ndata: [DONE]\n\n';
  const mid = Math.floor(full.length / 2);
  const stream = makeStream([full.slice(0, mid), full.slice(mid)]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'split', done: false },
    { delta: '', done: true },
  ]);
});

test('anthropic: SSE event split across multiple ReadableStream chunks', async () => {
  const full = 'data: {"type":"content_block_delta","delta":{"text":"chunked"}}\n\ndata: {"type":"message_stop"}\n\n';
  const mid = Math.floor(full.length / 2);
  const stream = makeStream([full.slice(0, mid), full.slice(mid)]);
  const items = await collect(normalizeStream(stream, 'anthropic'));
  assert.deepEqual(items, [
    { delta: 'chunked', done: false },
    { delta: '', done: true },
  ]);
});

// ── Edge cases ─────────────────────────────────────────────────────────────

test('openai: malformed JSON is silently skipped', async () => {
  const stream = makeStream([
    'data: {not valid json}\n\n',
    'data: {"choices":[{"delta":{"content":"ok"}}]}\n\n',
    'data: [DONE]\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'ok', done: false },
    { delta: '', done: true },
  ]);
});

test('both: non-data lines (comments, event:) are skipped', async () => {
  const stream = makeStream([
    ': this is a comment\n',
    'event: message\n',
    'data: {"choices":[{"delta":{"content":"yes"}}]}\n\n',
    'data: [DONE]\n\n',
  ]);
  const items = await collect(normalizeStream(stream, 'openai'));
  assert.deepEqual(items, [
    { delta: 'yes', done: false },
    { delta: '', done: true },
  ]);
});
