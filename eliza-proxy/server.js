'use strict';
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const fs = require('fs');

const { createElizaClient, ElizaError } = require('./lib/eliza-client');
const StartupDisplayManager = require('./lib/startup-display-manager');
const { createProbeState } = require('./lib/probe-state');

const PORT = process.env.PORT || 3100;
const USAGE_LOG_FILE = process.env.USAGE_LOG_FILE || './usage.jsonl';
const LOG_USAGE = process.env.LOG_USAGE !== 'false';
const TOKEN_FILE = '/Users/agaibadulin/.eliza/token';
const FINAL_DISPLAY_DELAY_MS = 100;

function loadToken() {
  let token = process.env.ELIZA_TOKEN;
  if (!token && fs.existsSync(TOKEN_FILE)) {
    token = fs.readFileSync(TOKEN_FILE, 'utf-8').trim();
  }
  return token;
}

function createUsageStats() {
  return {
    total_requests: 0,
    total_input_tokens: 0,
    total_output_tokens: 0,
    total_cost_usd: 0,
    by_model: {},
    period_start: new Date().toISOString(),
  };
}

function recordUsage(usageStats, model, input, output, prices, options = {}) {
  const inputPrice = parseFloat(prices?.input_tokens || 0);
  const outputPrice = parseFloat(prices?.output_tokens || 0);
  const cost = (input * inputPrice) + (output * outputPrice);

  usageStats.total_requests += 1;
  usageStats.total_input_tokens += input;
  usageStats.total_output_tokens += output;
  usageStats.total_cost_usd += cost;

  if (!usageStats.by_model[model]) {
    usageStats.by_model[model] = { requests: 0, input_tokens: 0, output_tokens: 0, cost_usd: 0 };
  }

  usageStats.by_model[model].requests += 1;
  usageStats.by_model[model].input_tokens += input;
  usageStats.by_model[model].output_tokens += output;
  usageStats.by_model[model].cost_usd += cost;

  if (options.logUsage !== false) {
    const entry = JSON.stringify({ ts: new Date().toISOString(), model, input, output, cost_usd: cost });
    fs.appendFile(options.usageLogFile || USAGE_LOG_FILE, `${entry}\n`, () => {});
  }

  return cost;
}

function htmlEscape(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function renderDashboardHtml() {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Model Probe Dashboard</title>
<style>
  :root {
    --bg: #f4f6f8;
    --panel: #ffffff;
    --text: #1e293b;
    --muted: #475569;
    --ok: #0f766e;
    --warn: #a16207;
    --err: #b91c1c;
    --pending: #1d4ed8;
    --line: #e2e8f0;
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: Menlo, Monaco, 'Courier New', monospace; background: radial-gradient(circle at top, #e2e8f0, var(--bg)); color: var(--text); }
  main { max-width: 1100px; margin: 0 auto; padding: 18px; }
  h1 { margin: 0 0 8px; font-size: 20px; letter-spacing: 0.02em; }
  .meta { color: var(--muted); margin-bottom: 16px; }
  .error-box { display: none; margin-bottom: 14px; border: 1px solid #fecaca; background: #fff1f2; color: #9f1239; border-radius: 8px; padding: 10px 12px; }
  .summary { display: grid; grid-template-columns: repeat(5, minmax(120px, 1fr)); gap: 10px; margin-bottom: 16px; }
  .card { border: 1px solid var(--line); background: var(--panel); border-radius: 8px; padding: 10px; }
  .label { color: var(--muted); font-size: 12px; margin-bottom: 4px; }
  .value { font-size: 19px; font-weight: 700; }
  .ok { color: var(--ok); }
  .warn { color: var(--warn); }
  .err { color: var(--err); }
  .pending { color: var(--pending); }
  .group { background: var(--panel); border: 1px solid var(--line); border-radius: 8px; margin-bottom: 12px; }
  .group-header { display: flex; justify-content: space-between; border-bottom: 1px solid var(--line); padding: 10px 12px; font-weight: 700; }
  table { width: 100%; border-collapse: collapse; }
  th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid #f1f5f9; font-size: 13px; }
  th { color: var(--muted); font-weight: 600; }
  tr:last-child td { border-bottom: none; }
  .badge { font-weight: 700; }
</style>
</head>
<body>
<main>
  <h1>Model Probe Dashboard</h1>
  <div class="meta">Read-only status view. No chat controls, no probe controls.</div>
  <div id="startup-error" class="error-box"></div>
  <section class="summary">
    <div class="card"><div class="label">Probe</div><div id="probe" class="value">idle</div></div>
    <div class="card"><div class="label">Success</div><div id="success" class="value ok">0</div></div>
    <div class="card"><div class="label">Warning</div><div id="warning" class="value warn">0</div></div>
    <div class="card"><div class="label">Error</div><div id="error" class="value err">0</div></div>
    <div class="card"><div class="label">Pending</div><div id="pending" class="value pending">0</div></div>
  </section>
  <div id="groups"></div>
</main>
<script>
let pollTimer = null;

function statusClass(status) {
  if (status === 'success') return 'ok';
  if (status === 'warning') return 'warn';
  if (status === 'error') return 'err';
  return 'pending';
}

function safe(value) {
  return String(value ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function render(data) {
  const errorEl = document.getElementById('startup-error');
  if (data.startupError) {
    errorEl.style.display = 'block';
    errorEl.textContent = 'Startup error: ' + data.startupError;
  } else {
    errorEl.style.display = 'none';
    errorEl.textContent = '';
  }

  document.getElementById('probe').textContent = data.probeStatus;
  document.getElementById('success').textContent = data.summary.success;
  document.getElementById('warning').textContent = data.summary.warning;
  document.getElementById('error').textContent = data.summary.error;
  document.getElementById('pending').textContent = data.summary.pending;

  const groupsEl = document.getElementById('groups');
  groupsEl.innerHTML = data.providers.map((group) => {
    const done = group.models.filter((m) => m.status !== 'pending').length;
    const rows = group.models
      .slice()
      .sort((a, b) => a.id.localeCompare(b.id))
      .map((m) => {
        return '\\n<tr>'
          + '\\n<td>' + safe(m.id) + '</td>'
          + '\\n<td class=\"badge ' + statusClass(m.status) + '\">' + safe(m.status) + '</td>'
          + '\\n<td>' + safe(m.kind || '') + '</td>'
          + '\\n<td>' + (m.latencyMs == null ? '' : safe(m.latencyMs)) + '</td>'
          + '\\n<td>' + safe(m.checkedAt || '') + '</td>'
          + '\\n</tr>';
      })
      .join('');

    return '\\n<section class=\"group\">'
      + '\\n<div class=\"group-header\">'
      + '\\n<span>' + safe(group.provider) + '</span>'
      + '\\n<span>' + done + '/' + group.models.length + '</span>'
      + '\\n</div>'
      + '\\n<table>'
      + '\\n<thead><tr><th>Model</th><th>Status</th><th>Kind</th><th>Latency (ms)</th><th>Checked At</th></tr></thead>'
      + '\\n<tbody>' + rows + '</tbody>'
      + '\\n</table>'
      + '\\n</section>';
  }).join('');
}

async function tick() {
  try {
    const res = await fetch('/v1/probe-status');
    const data = await res.json();
    render(data);

    const nextMs = data.probeStatus === 'running' ? 1000 : 5000;
    clearTimeout(pollTimer);
    pollTimer = setTimeout(tick, nextMs);
  } catch {
    clearTimeout(pollTimer);
    pollTimer = setTimeout(tick, 2000);
  }
}

tick();
</script>
</body>
</html>`;
}

function createApp({ eliza, probeState, usageStats, usageLogFile = USAGE_LOG_FILE, logUsage = LOG_USAGE }) {
  const app = express();
  app.use(cors({ origin: '*' }));
  app.use(express.json());

  let seedPromise = null;

  async function ensureProbeStateSeeded() {
    const current = probeState.getSnapshot();
    if (current.seeded || current.startupError) return;
    if (!seedPromise) {
      seedPromise = eliza.getModels()
        .then(({ models }) => {
          if (!probeState.getSnapshot().seeded) {
            probeState.seedCatalog(models);
          }
        })
        .catch((err) => {
          probeState.setStartupError(err.message);
        })
        .finally(() => {
          seedPromise = null;
        });
    }
    await seedPromise;
  }

  app.get('/', (req, res) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(renderDashboardHtml());
  });

  app.get('/v1/probe-status', async (req, res) => {
    await ensureProbeStateSeeded();
    const snapshot = probeState.getSnapshot();
    res.json({
      probeStatus: snapshot.probeStatus,
      summary: snapshot.summary,
      providers: snapshot.providers,
      startupError: snapshot.startupError,
      updatedAt: new Date().toISOString(),
    });
  });

  app.get('/v1/health', async (req, res) => {
    try {
      const { validated } = await eliza.getModels();
      await ensureProbeStateSeeded();
      const snapshot = probeState.getSnapshot();
      res.json({
        status: 'ok',
        version: '1.0.0',
        modelsValidated: validated,
        probeStatus: snapshot.probeStatus,
        probeSummary: snapshot.summary,
      });
    } catch (err) {
      res.status(503).json({ status: 'error', error: err.message });
    }
  });

  app.get('/v1/models', async (req, res) => {
    try {
      const { models, validated } = await eliza.getModels();
      await ensureProbeStateSeeded();
      const withProbe = probeState.withProbeMetadata(models);
      res.json({ models: withProbe, validated, updatedAt: new Date().toISOString() });
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
    res.on('close', () => { clientConnected = false; });
    res.on('error', () => { clientConnected = false; });

    function safeWrite(data) {
      if (!clientConnected || res.destroyed || res.writableEnded) return false;
      try { res.write(data); return true; } catch { clientConnected = false; return false; }
    }

    try {
      const { models } = await eliza.getModels();
      const modelMeta = models.find((item) => item.id === model);
      const prices = modelMeta?.prices || {};

      let usageInput = 0;
      let usageOutput = 0;

      for await (const { delta, done, usage, error } of eliza.chat(model, messages, { system })) {
        if (!clientConnected) break;

        if (error) {
          safeWrite(`data: ${JSON.stringify({ error })}\n\n`);
          break;
        }

        if (usage) {
          usageInput = usage.input ?? usageInput;
          usageOutput = usage.output ?? usageOutput;
        }

        if (done) {
          const costUsd = recordUsage(usageStats, model, usageInput, usageOutput, prices, { usageLogFile, logUsage });
          if (usageInput || usageOutput) {
            safeWrite(`data: ${JSON.stringify({ usage: { input: usageInput, output: usageOutput, model, cost_usd: costUsd } })}\n\n`);
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
      if (!res.writableEnded) {
        try { res.end(); } catch { /* noop */ }
      }
    }
  });

  app.post('/v1/probe', async (req, res) => {
    const { model } = req.body;
    if (!model) {
      res.status(400).json({ error: 'model required' });
      return;
    }
    const t0 = Date.now();
    const available = await eliza.probe(model);
    res.json({ available, latency: Date.now() - t0 });
  });

  app.get('/v1/usage', (req, res) => {
    res.json({ ...usageStats, generated_at: new Date().toISOString() });
  });

  return app;
}

async function startServer(options = {}) {
  const token = options.token || loadToken();
  if (!token) {
    throw new Error(`FATAL: ELIZA_TOKEN not set in .env and not found in ${TOKEN_FILE}`);
  }

  const port = options.port || PORT;
  const shouldExitAfterProbe = Boolean(options.shouldExitAfterProbe);
  const probeState = options.probeState || createProbeState();
  const displayManager = options.displayManager || new StartupDisplayManager();
  const usageStats = options.usageStats || createUsageStats();

  let serverRef = null;
  let exitScheduled = false;

  async function maybeExit() {
    if (!shouldExitAfterProbe || exitScheduled) return;
    const snapshot = probeState.getSnapshot();
    if (!snapshot.seeded || snapshot.probeStatus !== 'complete') return;

    exitScheduled = true;
    setTimeout(async () => {
      console.log('\nProbe complete. Exiting due to --exit-after-probe flag.');
      if (serverRef && serverRef.listening) {
        await new Promise((resolve) => serverRef.close(resolve));
      }
      process.exit(0);
    }, FINAL_DISPLAY_DELAY_MS);
  }

  const eliza = createElizaClient({
    token,
    onModelProbed: (provider, model) => {
      probeState.applyProbeEvent(provider, model);
      void maybeExit();
    },
  });

  eliza.onModelUpdate((provider, modelId, status) => {
    displayManager.updateModelStatus(provider, modelId, status);
  });

  const app = createApp({
    eliza,
    probeState,
    usageStats,
    usageLogFile: options.usageLogFile || USAGE_LOG_FILE,
    logUsage: options.logUsage ?? LOG_USAGE,
  });

  await new Promise((resolve) => {
    serverRef = app.listen(port, resolve);
  });

  console.log(`eliza-proxy: http://localhost:${port}`);
  console.log('ELIZA_TOKEN: OK');

  try {
    const { models } = await eliza.getModels();
    probeState.seedCatalog(models);
    displayManager.seedCatalog(probeState.getProviderGroups());
    await maybeExit();
  } catch (err) {
    probeState.setStartupError(err.message);
    console.error('Failed to fetch models:', err.message);
  }

  return {
    app,
    server: serverRef,
    eliza,
    probeState,
    displayManager,
    usageStats,
  };
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const shouldExitAfterProbe = args.includes('--exit-after-probe');

  startServer({ shouldExitAfterProbe }).catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
}

module.exports = {
  createApp,
  createUsageStats,
  recordUsage,
  renderDashboardHtml,
  startServer,
};
