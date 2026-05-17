'use strict';

const FINAL_STATES = new Set(['success', 'warning', 'error']);

function normalizeProvider(provider) {
  return provider || 'unknown';
}

function createEmptySummary() {
  return { pending: 0, success: 0, warning: 0, error: 0, available: 0, preview: 0, total: 0, final: 0 };
}

function createProbeState() {
  const providerOrder = [];
  const providers = new Map();
  const indexByProvider = new Map();
  const bufferedProbeEvents = [];

  let seeded = false;
  let probeStatus = 'idle';
  let catalogReady = false;
  let explicitProbeMode = false;
  let startupError = null;

  function ensureProvider(provider) {
    const normalized = normalizeProvider(provider);
    if (!providers.has(normalized)) {
      providers.set(normalized, []);
      providerOrder.push(normalized);
      indexByProvider.set(normalized, new Map());
    }
    return normalized;
  }

  function ensureModel(provider, model) {
    const normalizedProvider = ensureProvider(provider);
    const list = providers.get(normalizedProvider);
    const index = indexByProvider.get(normalizedProvider);
    const modelId = model.id;

    if (!index.has(modelId)) {
      const entry = {
        id: model.id,
        title: model.title || '',
        provider: normalizedProvider,
        status: model.status || 'available',
        catalogStatus: model.stability === 'preview' ? 'preview' : 'available',
        stability: model.stability || 'stable',
        capabilities: model.capabilities || null,
        observed: model.observed || null,
        kind: null,
        variant: null,
        latencyMs: null,
        checkedAt: null,
        httpStatus: null,
        error: null,
      };
      list.push(entry);
      index.set(modelId, entry);
    }

    return index.get(modelId);
  }

  function statusFromProbe(probe) {
    if (!probe) return 'pending';
    if (probe.status === 'success' || probe.status === 'warning' || probe.status === 'error') {
      return probe.status;
    }
    if (probe.httpStatus === 200 || probe.status === 200) return 'success';
    return 'error';
  }

  function setFromProbe(entry, probe) {
    entry.status = statusFromProbe(probe);
    entry.kind = probe?.kind || null;
    entry.variant = probe?.variant || null;
    entry.latencyMs = Number.isFinite(probe?.latencyMs) ? probe.latencyMs : null;
    entry.checkedAt = probe?.checkedAt || null;
    entry.httpStatus = Number.isFinite(probe?.httpStatus) ? probe.httpStatus : (Number.isFinite(probe?.status) ? probe.status : null);
    entry.error = probe?.error || null;
  }

  function summarize() {
    const summary = createEmptySummary();
    for (const provider of providerOrder) {
      const models = providers.get(provider) || [];
      for (const model of models) {
        summary.total += 1;
        if (model.status === 'available' || model.status === 'preview') {
          summary[model.status] += 1;
        } else if (FINAL_STATES.has(model.status)) {
          summary.final += 1;
          summary[model.status] += 1;
        } else {
          summary.pending += 1;
        }
      }
    }
    return summary;
  }

  function refreshLifecycle() {
    const summary = summarize();

    if (!seeded) {
      probeStatus = 'idle';
      return;
    }

    if (!explicitProbeMode) {
      probeStatus = 'idle';
      return;
    }

    if (summary.total === 0) {
      probeStatus = 'complete';
      return;
    }

    probeStatus = summary.pending === 0 ? 'complete' : 'running';
  }

  function flushBufferedEvents() {
    if (!seeded || bufferedProbeEvents.length === 0) return;
    for (const event of bufferedProbeEvents.splice(0)) {
      applyProbeEvent(event.provider, event.model);
    }
  }

  function seedCatalog(models, options = {}) {
    providerOrder.length = 0;
    providers.clear();
    indexByProvider.clear();

    explicitProbeMode = Boolean(options.probeMode);

    for (const model of models || []) {
      const entry = ensureModel(model.provider, {
        ...model,
        status: explicitProbeMode ? 'pending' : (model.stability === 'preview' ? 'preview' : 'available'),
      });
      entry.catalogStatus = model.stability === 'preview' ? 'preview' : 'available';
      entry.stability = model.stability || 'stable';
      entry.capabilities = model.capabilities || null;
      entry.observed = model.observed || null;
      if (model.probe) setFromProbe(entry, model.probe);
    }

    seeded = true;
    catalogReady = true;
    startupError = null;
    refreshLifecycle();
    flushBufferedEvents();
    refreshLifecycle();
  }

  function setStartupError(message) {
    startupError = message || null;
  }

  function applyProbeEvent(provider, model) {
    explicitProbeMode = true;
    if (!seeded) {
      bufferedProbeEvents.push({ provider, model });
      return;
    }

    const entry = ensureModel(provider || model.provider, model);
    setFromProbe(entry, model.probe || {});
    refreshLifecycle();
  }

  function getModel(provider, modelId) {
    const index = indexByProvider.get(normalizeProvider(provider));
    return index ? index.get(modelId) || null : null;
  }

  function toProbeMetadata(entry) {
    if (!entry) return null;
    if (entry.status === 'available' || entry.status === 'preview') return null;
    const probe = {
      status: entry.status,
    };
    if (entry.kind) probe.kind = entry.kind;
    if (entry.variant) probe.variant = entry.variant;
    if (entry.checkedAt) probe.checkedAt = entry.checkedAt;
    if (Number.isFinite(entry.latencyMs)) probe.latencyMs = entry.latencyMs;
    if (Number.isFinite(entry.httpStatus)) probe.httpStatus = entry.httpStatus;
    if (entry.error) probe.error = entry.error;
    return probe;
  }

  function withProbeMetadata(models) {
    return (models || []).map((model) => {
      const entry = getModel(model.provider, model.id);
      if (!entry) return model;
      const probe = toProbeMetadata(entry);
      if (!probe) return model;
      return {
        ...model,
        probe,
      };
    });
  }

  function getProviderGroups() {
    return providerOrder.map((provider) => ({
      provider,
      models: (providers.get(provider) || []).map((m) => ({ ...m })),
    }));
  }

  function getSnapshot() {
    return {
      probeStatus,
      summary: summarize(),
      providers: getProviderGroups(),
      seeded,
      catalogReady,
      startupError,
    };
  }

  return {
    seedCatalog,
    applyProbeEvent,
    getModel,
    withProbeMetadata,
    getSnapshot,
    getProviderGroups,
    isSeeded: () => seeded,
    setStartupError,
  };
}

module.exports = { createProbeState, FINAL_STATES };
