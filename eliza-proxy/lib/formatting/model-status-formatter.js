'use strict';

const ANSI = {
  RESET: '\x1b[0m',
  GREEN: '\x1b[32m',
  RED: '\x1b[31m',
  YELLOW: '\x1b[33m',
  BLUE: '\x1b[34m',
};

const STATUS_STYLE = {
  available: { symbol: 'OK', color: ANSI.GREEN },
  preview: { symbol: 'PREV', color: ANSI.YELLOW },
  success: { symbol: 'OK', color: ANSI.GREEN },
  warning: { symbol: 'WARN', color: ANSI.YELLOW },
  error: { symbol: 'ERR', color: ANSI.RED },
  pending: { symbol: 'PEND', color: ANSI.BLUE },
};

function stripAnsi(text) {
  return (text || '').replace(/\x1b\[[0-9;]*m/g, '');
}

function visibleLength(text) {
  return stripAnsi(text).length;
}

function formatProgressBar(checked, total, width = 8) {
  const safeTotal = Number.isFinite(total) && total > 0 ? total : 0;
  const safeChecked = Number.isFinite(checked) ? Math.max(0, Math.min(checked, safeTotal)) : 0;
  const filled = safeTotal > 0 ? Math.round((safeChecked / safeTotal) * width) : 0;
  const empty = width - filled;
  return `[${'█'.repeat(filled)}${'░'.repeat(empty)}] ${safeChecked}/${safeTotal}`;
}

function formatModelToken(model, useAnsi = true) {
  const status = STATUS_STYLE[model.status] ? model.status : 'pending';
  const style = STATUS_STYLE[status];
  const token = `${style.symbol} ${model.id}`;
  if (!useAnsi) return token;
  return `${style.color}${token}${ANSI.RESET}`;
}

function wrapTokens(tokens, width, indent = '  ') {
  const lines = [];
  const maxWidth = Math.max(20, width || 100);
  let current = indent;

  for (let i = 0; i < tokens.length; i += 1) {
    const token = tokens[i];
    const prefix = current === indent ? '' : ', ';
    const next = `${current}${prefix}${token}`;

    if (visibleLength(next) <= maxWidth || current === indent) {
      current = next;
    } else {
      lines.push(current);
      current = `${indent}${token}`;
    }
  }

  if (current.trim()) {
    lines.push(current);
  }

  return lines;
}

function formatModelListLines(models, options = {}) {
  const width = options.width || 100;
  const useAnsi = options.useAnsi !== false;
  const indent = options.indent || '  ';

  const sorted = [...(models || [])].sort((a, b) => a.id.localeCompare(b.id));
  const tokens = sorted.map((model) => formatModelToken(model, useAnsi));
  if (tokens.length === 0) return [indent];

  return wrapTokens(tokens, width, indent);
}

function renderProviderGroup(providerName, models, options = {}) {
  const total = (models || []).length;
  const checked = (models || []).filter((model) => model.status !== 'pending').length;
  const header = `${providerName} ${formatProgressBar(checked, total)}`;
  const lines = formatModelListLines(models, options);
  return [header, ...lines];
}

function formatSummaryLine(summary) {
  const s = summary || { pending: 0, success: 0, warning: 0, error: 0, final: 0, total: 0 };
  const bar = formatProgressBar(s.final, s.total);
  return `overall ${bar} available=${s.available || 0} preview=${s.preview || 0} success=${s.success} warning=${s.warning} error=${s.error} pending=${s.pending}`;
}

module.exports = {
  ANSI,
  stripAnsi,
  visibleLength,
  formatProgressBar,
  formatModelListLines,
  renderProviderGroup,
  formatSummaryLine,
};
