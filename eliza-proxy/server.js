'use strict';
require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const fs      = require('fs');
const { createElizaClient, ElizaError } = require('./lib/eliza-client');
const { formatGroup, groupByProvider } = require('./lib/format-startup');

const ELIZA_TOKEN    = process.env.ELIZA_TOKEN;
const PORT           = process.env.PORT || 3100;
const USAGE_LOG_FILE = process.env.USAGE_LOG_FILE || './usage.jsonl';
const LOG_USAGE      = process.env.LOG_USAGE !== 'false';

if (!ELIZA_TOKEN) {
  console.error('FATAL: ELIZA_TOKEN не задан в .env');
  process.exit(1);
}

const displayedGroups = new Set();
let modelsByProvider = {};
let modelsByProviderReady = false;
let pendingProbeEvents = [];
const probedCount = {};

function processProbeEvent(provider, model) {
  if (displayedGroups.has(provider)) return;
  if (!modelsByProvider[provider]) return;

  const idx = modelsByProvider[provider].findIndex(m => m.id === model.id);
  if (idx !== -1) {
    modelsByProvider[provider][idx] = { ...modelsByProvider[provider][idx], probe: model.probe };
  }

  probedCount[provider] = (probedCount[provider] || 0) + 1;
  const totalInProvider = modelsByProvider[provider].length;

  if (probedCount[provider] === totalInProvider) {
    displayedGroups.add(provider);
    const output = formatGroup(provider, modelsByProvider[provider]);
    console.log('\n' + output);
  }
}

const eliza = createElizaClient({
  token: ELIZA_TOKEN,
  onModelProbed: (provider, model) => {
    if (!modelsByProviderReady) {
      pendingProbeEvents.push({ provider, model });
      return;
    }
    processProbeEvent(provider, model);
  },
});

const usageStats = {
  total_requests: 0,
  total_input_tokens: 0,
  total_output_tokens: 0,
  total_cost_usd: 0,
  by_model: {},
  period_start: new Date().toISOString(),
};

function recordUsage(model, input, output, prices) {
  const input_price  = parseFloat(prices?.input_tokens  || 0);
  const output_price = parseFloat(prices?.output_tokens || 0);
  const cost = (input * input_price) + (output * output_price);

  usageStats.total_requests      += 1;
  usageStats.total_input_tokens  += input;
  usageStats.total_output_tokens += output;
  usageStats.total_cost_usd      += cost;

  if (!usageStats.by_model[model]) {
    usageStats.by_model[model] = { requests: 0, input_tokens: 0, output_tokens: 0, cost_usd: 0 };
  }
  usageStats.by_model[model].requests      += 1;
  usageStats.by_model[model].input_tokens  += input;
  usageStats.by_model[model].output_tokens += output;
  usageStats.by_model[model].cost_usd      += cost;

  if (LOG_USAGE) {
    const entry = JSON.stringify({ ts: new Date().toISOString(), model, input, output, cost_usd: cost });
    fs.appendFile(USAGE_LOG_FILE, entry + '\n', () => {});
  }

  return cost;
}

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());

app.get('/v1/health', async (req, res) => {
  try {
    const { validated } = await eliza.getModels();
    res.json({ status: 'ok', version: '1.0.0', modelsValidated: validated });
  } catch (err) {
    res.status(503).json({ status: 'error', error: err.message });
  }
});

app.get('/v1/models', async (req, res) => {
  try {
    const { models, validated } = await eliza.getModels();
    res.json({ models, validated, updatedAt: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/v1/chat', async (req, res) => {
  const { model, messages, system } = req.body;

  if (!model || !Array.isArray(messages)) {
    res.status(400).json({ error: 'model and messages required' });
    return;
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  let clientConnected = true;
  res.on('close',  () => { clientConnected = false; });
  res.on('error',  () => { clientConnected = false; });

  function safeWrite(data) {
    if (!clientConnected || res.destroyed || res.writableEnded) return false;
    try { res.write(data); return true; } catch { clientConnected = false; return false; }
  }

  try {
    const { models } = await eliza.getModels();
    const modelMeta = models.find(m => m.id === model);
    const prices = modelMeta?.prices || {};

    let usageInput = 0, usageOutput = 0;

    for await (const { delta, done, usage, error } of eliza.chat(model, messages, { system })) {
      if (!clientConnected) break;

      if (error) {
        safeWrite(`data: ${JSON.stringify({ error })}\n\n`);
        break;
      }

      if (usage) {
        usageInput  = usage.input  ?? usageInput;
        usageOutput = usage.output ?? usageOutput;
      }

      if (done) {
        const cost_usd = recordUsage(model, usageInput, usageOutput, prices);
        if (usageInput || usageOutput) {
          safeWrite(`data: ${JSON.stringify({ usage: { input: usageInput, output: usageOutput, model, cost_usd } })}\n\n`);
        }
        safeWrite('data: [DONE]\n\n');
        break;
      }

      if (delta) {
        safeWrite(`data: ${JSON.stringify({ text: delta })}\n\n`);
      }
    }
  } catch (err) {
    if (err instanceof ElizaError && err.status === 429) {
      safeWrite(`data: ${JSON.stringify({ error: 'Rate limit exceeded' })}\n\n`);
    } else if (err instanceof ElizaError && err.status === 501) {
      safeWrite(`data: ${JSON.stringify({ error: `Model ${model} does not support streaming` })}\n\n`);
    } else {
      safeWrite(`data: ${JSON.stringify({ error: err.message })}\n\n`);
    }
  } finally {
    if (!res.writableEnded) try { res.end(); } catch { /* closed */ }
  }
});

app.post('/v1/probe', async (req, res) => {
  const { model } = req.body;
  if (!model) { res.status(400).json({ error: 'model required' }); return; }
  const t0 = Date.now();
  const available = await eliza.probe(model);
  res.json({ available, latency: Date.now() - t0 });
});

app.get('/v1/usage', (req, res) => {
  res.json({ ...usageStats, generated_at: new Date().toISOString() });
});

app.listen(PORT, async () => {
  console.log(`eliza-proxy: http://localhost:${PORT}`);
  console.log(`ELIZA_TOKEN: OK`);

  try {
    const { models } = await eliza.getModels();
    modelsByProvider = groupByProvider(models);

    for (const [provider, providerModels] of Object.entries(modelsByProvider)) {
      console.log('\n' + formatGroup(provider, providerModels));
    }

    modelsByProviderReady = true;

    for (const { provider, model } of pendingProbeEvents) {
      processProbeEvent(provider, model);
    }
    pendingProbeEvents = [];
  } catch (err) {
    console.error('Failed to fetch models:', err.message);
  }
});
