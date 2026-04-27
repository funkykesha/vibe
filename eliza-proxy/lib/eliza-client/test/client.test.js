'use strict';

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { parseModels } = require('../models.js');
const { createElizaClient, ElizaError } = require('../index.js');

function makeStream(text) {
  const encoded = new TextEncoder().encode(text);
  return new ReadableStream({
    start(controller) {
      controller.enqueue(encoded);
      controller.close();
    },
  });
}

async function collect(gen) {
  const chunks = [];
  for await (const chunk of gen) chunks.push(chunk);
  return chunks;
}

let originalFetch;

beforeEach(() => {
  originalFetch = globalThis.fetch;
});

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function makeModelResponse(models = []) {
  return { data: models };
}

describe('getModels — caching', () => {
  it('returns raw models immediately (validated: false)', async () => {
    let fetchCount = 0;
    globalThis.fetch = async () => {
      fetchCount += 1;
      return {
        ok: true,
        json: async () => makeModelResponse([
          { id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } },
        ]),
      };
    };

    const eliza = createElizaClient({ token: 'test', _skipProbe: true, _sleep: async () => {} });
    const { models, validated } = await eliza.getModels();
    assert.equal(validated, false);
    assert.equal(models.length, 1);
    assert.equal(fetchCount, 1);
  });

  it('concurrent calls share one fetch', async () => {
    let fetchCount = 0;
    globalThis.fetch = async () => {
      fetchCount += 1;
      await new Promise((r) => setTimeout(r, 20));
      return { ok: true, json: async () => makeModelResponse([]) };
    };

    const eliza = createElizaClient({ token: 'test', _skipProbe: true, _sleep: async () => {} });
    await Promise.all([eliza.getModels(), eliza.getModels(), eliza.getModels()]);
    assert.equal(fetchCount, 1, `Expected 1 fetch, got ${fetchCount}`);
  });

  it('second call returns cached result without fetching again', async () => {
    let fetchCount = 0;
    globalThis.fetch = async () => {
      fetchCount += 1;
      return { ok: true, json: async () => makeModelResponse([]) };
    };

    const eliza = createElizaClient({ token: 'test', _skipProbe: true, _sleep: async () => {} });
    await eliza.getModels();
    await eliza.getModels();
    assert.equal(fetchCount, 1);
  });

  it('onValidated called immediately if validatedCache exists', async () => {
    globalThis.fetch = async () => ({ ok: true, json: async () => makeModelResponse([]) });
    const eliza = createElizaClient({ token: 'test', _skipProbe: true, _sleep: async () => {} });

    eliza._forceValidated([]);

    let called = false;
    const { onValidated } = await eliza.getModels();
    onValidated(() => {
      called = true;
    });
    assert.equal(called, true);
  });
});

describe('fetchAndParse — retries', () => {
  it('retries on network error up to 3 times then succeeds', async () => {
    let fetchCount = 0;
    globalThis.fetch = async () => {
      fetchCount += 1;
      if (fetchCount < 3) throw new TypeError('fetch failed');
      return { ok: true, json: async () => makeModelResponse([]) };
    };

    const eliza = createElizaClient({ token: 't', _skipProbe: true, _sleep: async () => {} });
    await eliza.getModels();
    assert.equal(fetchCount, 3);
  });

  it('does not retry on ElizaError (HTTP error)', async () => {
    let fetchCount = 0;
    globalThis.fetch = async () => {
      fetchCount += 1;
      return { ok: false, status: 401, text: async () => 'unauthorized' };
    };

    const eliza = createElizaClient({ token: 't', _skipProbe: true, _sleep: async () => {} });
    await assert.rejects(() => eliza.getModels(), (e) => e.name === 'ElizaError' && e.status === 401);
    assert.equal(fetchCount, 1);
  });
});

describe('chat()', () => {
  it('throws ElizaError 501 for GPT-5 (supportsStreaming: false)', async () => {
    const eliza = createElizaClient({ token: 't', _skipProbe: true });
    await assert.rejects(
      async () => { for await (const _ of eliza.chat('gpt-5', [])) {} },
      (e) => e instanceof ElizaError && e.status === 501,
    );
  });

  it('uses developer role for reasoning model (o4-mini)', async () => {
    let sentBody;
    globalThis.fetch = async (url, opts) => {
      sentBody = JSON.parse(opts.body);
      return { ok: false, status: 400, text: async () => 'bad' };
    };
    const eliza = createElizaClient({ token: 't', _skipProbe: true });
    await assert.rejects(async () => { for await (const _ of eliza.chat('o4-mini', [], { system: 'sys' })) {} });
    assert.equal(sentBody.messages[0].role, 'developer');
  });

  it('uses system role and temperature:0 for non-reasoning model (gpt-4.1)', async () => {
    let sentBody;
    globalThis.fetch = async (url, opts) => {
      sentBody = JSON.parse(opts.body);
      return { ok: false, status: 400, text: async () => 'bad' };
    };
    const eliza = createElizaClient({ token: 't', _skipProbe: true });
    await assert.rejects(async () => { for await (const _ of eliza.chat('gpt-4.1', [], { system: 'sys' })) {} });
    assert.equal(sentBody.messages[0].role, 'system');
    assert.equal(sentBody.temperature, 0);
  });

  it('no temperature for reasoning model', async () => {
    let sentBody;
    globalThis.fetch = async (url, opts) => {
      sentBody = JSON.parse(opts.body);
      return { ok: false, status: 400, text: async () => 'bad' };
    };
    const eliza = createElizaClient({ token: 't', _skipProbe: true });
    await assert.rejects(async () => { for await (const _ of eliza.chat('o4-mini', [])) {} });
    assert.equal('temperature' in sentBody, false);
  });

  it('chatOnce collects all deltas into string', async () => {
    const sse = 'data: {"choices":[{"delta":{"content":"he"},"finish_reason":null}]}\n\n' +
                'data: {"choices":[{"delta":{"content":"llo"},"finish_reason":"stop"}]}\n\n' +
                'data: [DONE]\n\n';
    globalThis.fetch = async () => ({ ok: true, body: makeStream(sse) });
    const eliza = createElizaClient({ token: 't', _skipProbe: true });
    const { content } = await eliza.chatOnce('gpt-4.1', []);
    assert.equal(content, 'hello');
  });
});

describe('getModels — probe failure notifies onValidated with raw', () => {
  it('calls onValidated with raw models when _runProbe rejects', async () => {
    const rawModels = [
      { id: 'claude-sonnet-4-6', title: 'Claude Sonnet', developer: 'Anthropic', namespace: '', prices: { input: 1 } },
    ];
    globalThis.fetch = async () => ({
      ok: true,
      json: async () => makeModelResponse(rawModels),
    });

    const eliza = createElizaClient({
      token: 'test',
      _skipProbe: false,
      _sleep: async () => {},
      _runProbe: async () => {
        throw new Error('probe boom');
      },
    });

    const { models, validated, onValidated } = await eliza.getModels();
    assert.equal(validated, false);
    const parsed = parseModels({ data: rawModels });
    assert.deepEqual(models, parsed);

    let received = null;
    onValidated((list) => {
      received = list;
    });

    await new Promise((r) => setTimeout(r, 30));
    assert.ok(received);
    assert.deepEqual(received, parsed);
  });
});
