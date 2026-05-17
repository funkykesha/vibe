'use strict';

const DEFAULT_VENDOR_CHUNKS = ['openai', 'anthropic', 'google', 'deepseek', 'mistral', 'xai', 'alibaba', 'moonshotai', 'zhipu', 'meta', 'sber'];
const DEFAULT_STATUS_CHUNKS = ['200'];
const DEFAULT_STREAM_CHUNKS = ['true', 'false'];

function normalizeBool(value) {
  const text = String(value ?? '').trim().toLowerCase();
  if (text === 'true' || text === '1' || text === 'yes') return true;
  if (text === 'false' || text === '0' || text === 'no') return false;
  return null;
}

function extractLabels(text) {
  const labels = {};
  const re = /(?:^|[,{\s])([a-zA-Z_][\w.-]*)\s*=\s*"?([^",}\s]+)"?/g;
  let match;
  while ((match = re.exec(text))) {
    labels[match[1]] = match[2];
  }
  return labels;
}

function extractAggregateValue(text) {
  const trimmed = String(text || '').trim();
  const equalsMatch = trimmed.match(/(?:value|count|sum|requests|aggregate)\s*[:=]\s*(-?\d+(?:\.\d+)?)/i);
  if (equalsMatch) return Number.parseFloat(equalsMatch[1]);
  const tailMatch = trimmed.match(/\s(-?\d+(?:\.\d+)?)\s*$/);
  return tailMatch ? Number.parseFloat(tailMatch[1]) : 0;
}

function parseObservedFacts(text, window = {}) {
  const facts = new Map();
  for (const line of String(text || '').split(/\r?\n/)) {
    if (!line.trim()) continue;
    const labels = extractLabels(line);
    const model = labels.model;
    if (!model) continue;

    const aggregateValue = extractAggregateValue(line);
    if (!Number.isFinite(aggregateValue) || aggregateValue <= 0) continue;

    const status = labels.status || labels.code || '';
    const stream = normalizeBool(labels.stream);
    const existing = facts.get(model) || {
      model,
      vendor: labels.vendor || '',
      provider: labels.provider || labels.vendor || '',
      observedStatus200: false,
      observedStreamTrue: false,
      requestScore: 0,
      window,
    };

    existing.vendor = existing.vendor || labels.vendor || '';
    existing.provider = existing.provider || labels.provider || labels.vendor || '';
    existing.observedStatus200 = existing.observedStatus200 || status === '200';
    existing.observedStreamTrue = existing.observedStreamTrue || stream === true;
    existing.requestScore += aggregateValue;
    existing.window = window;
    facts.set(model, existing);
  }
  return facts;
}

function planMoniumQueries({ from, to, vendors = DEFAULT_VENDOR_CHUNKS, statuses = DEFAULT_STATUS_CHUNKS, streams = DEFAULT_STREAM_CHUNKS } = {}) {
  if (!from || !to) {
    throw new Error('absolute UTC from/to required for observed model queries');
  }

  const queries = [];
  for (const vendor of vendors) {
    for (const status of statuses) {
      for (const stream of streams) {
        queries.push({
          sensor: 'chat.status',
          from,
          to,
          selectors: {
            vendor,
            status,
            stream,
          },
        });
      }
    }
  }
  return queries;
}

function findObservedMissingFromCatalog(observedFacts, catalogModels) {
  const catalogIds = new Set((catalogModels || []).map((model) => model.id));
  return Array.from(observedFacts instanceof Map ? observedFacts.values() : Object.values(observedFacts || {}))
    .filter((fact) => fact?.model && !catalogIds.has(fact.model))
    .map((fact) => ({ ...fact }));
}

module.exports = {
  parseObservedFacts,
  planMoniumQueries,
  findObservedMissingFromCatalog,
  extractLabels,
  extractAggregateValue,
};
