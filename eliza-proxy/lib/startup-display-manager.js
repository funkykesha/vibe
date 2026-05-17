'use strict';

const {
  renderProviderGroup,
  formatSummaryLine,
  stripAnsi,
  visibleLength,
} = require('./formatting/model-status-formatter');

class StartupDisplayManager {
  constructor(options = {}) {
    this.providerData = new Map();
    this.providerOrder = [];
    this.pendingEvents = [];
    this.seeded = false;
    this.renderedLines = 0;

    this.stream = options.stream || process.stdout;
    this.isTTY = options.isTTY ?? Boolean(this.stream && this.stream.isTTY);
    this.width = options.width || this.stream.columns || 120;
  }

  seedCatalog(groups) {
    this.providerData.clear();
    this.providerOrder = [];

    for (const group of groups || []) {
      const provider = group.provider;
      const map = new Map();
      for (const model of group.models || []) {
        map.set(model.id, {
          id: model.id,
          status: model.status || 'pending',
        });
      }
      this.providerOrder.push(provider);
      this.providerData.set(provider, map);
    }

    this.seeded = true;

    for (const event of this.pendingEvents.splice(0)) {
      this.applyUpdate(event.provider, event.modelId, event.status);
    }

    this.render();
  }

  updateModelStatus(provider, modelId, status) {
    if (!this.seeded) {
      this.pendingEvents.push({ provider, modelId, status });
      return;
    }

    this.applyUpdate(provider, modelId, status);
    this.render();
  }

  applyUpdate(provider, modelId, status) {
    if (!this.providerData.has(provider)) {
      this.providerData.set(provider, new Map());
      this.providerOrder.push(provider);
    }

    const providerModels = this.providerData.get(provider);
    const current = providerModels.get(modelId) || { id: modelId, status: 'pending' };
    providerModels.set(modelId, { ...current, status: status || current.status || 'pending' });
  }

  getSnapshot() {
    const providers = this.providerOrder.map((provider) => ({
      name: provider,
      models: Array.from(this.providerData.get(provider).values()),
    }));

    let total = 0;
    let final = 0;
    let success = 0;
    let warning = 0;
    let error = 0;
    let available = 0;
    let preview = 0;

    for (const provider of providers) {
      for (const model of provider.models) {
        total += 1;
        if (model.status !== 'pending') final += 1;
        if (model.status === 'success') success += 1;
        if (model.status === 'warning') warning += 1;
        if (model.status === 'error') error += 1;
        if (model.status === 'available') available += 1;
        if (model.status === 'preview') preview += 1;
      }
    }

    return {
      summary: {
        total,
        final,
        pending: total - final,
        success,
        warning,
        error,
        available,
        preview,
      },
      providers,
    };
  }

  render() {
    if (!this.seeded) return;

    const snapshot = this.getSnapshot();
    const lines = [formatSummaryLine(snapshot.summary)];

    for (const provider of snapshot.providers) {
      lines.push(...renderProviderGroup(provider.name, provider.models, {
        width: this.width,
        useAnsi: this.isTTY,
        indent: '  ',
      }));
    }

    this.writeLines(lines);
  }

  countWrappedLines(lines) {
    const width = Math.max(20, this.width || 120);
    return lines.reduce((sum, line) => {
      const length = Math.max(1, visibleLength(line));
      return sum + Math.max(1, Math.ceil(length / width));
    }, 0);
  }

  writeLines(lines) {
    const output = lines.join('\n');

    if (!this.isTTY) {
      this.stream.write(`${stripAnsi(output)}\n`);
      return;
    }

    this.clearTTY();
    this.stream.write(`${output}\n`);
    this.renderedLines = this.countWrappedLines(lines);
  }

  clearTTY() {
    if (!this.renderedLines || !this.isTTY) return;

    this.stream.write(`\x1b[${this.renderedLines}A`);
    for (let i = 0; i < this.renderedLines; i += 1) {
      this.stream.write('\x1b[2K\r');
      if (i < this.renderedLines - 1) this.stream.write('\x1b[1B');
    }
    this.stream.write(`\x1b[${this.renderedLines - 1}A`);
  }
}

module.exports = StartupDisplayManager;
