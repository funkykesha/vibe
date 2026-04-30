'use strict';

const ANSI = {
  GREEN: '\x1b[32m',
  RED: '\x1b[31m',
  YELLOW: '\x1b[33m',
  RESET: '\x1b[0m',
};

function groupByProvider(models) {
  const groups = {};
  for (const model of models) {
    const provider = model.provider || 'unknown';
    if (!groups[provider]) groups[provider] = [];
    groups[provider].push(model);
  }
  return groups;
}

function getModelStatus(model) {
  if (model.probe) {
    if (model.probe.status === 200) return `${ANSI.GREEN}✅${ANSI.RESET}`;
    return `${ANSI.RED}❌${ANSI.RESET}`;
  }
  return `⏳`;
}

function formatProgressBar(completed, total) {
  const width = 20;
  const filled = Math.round((completed / total) * width);
  const empty = width - filled;
  const bar = '█'.repeat(filled) + '░'.repeat(empty);
  return `[${bar}] ${completed}/${total}`;
}

function formatGroupLine(models, targetWidth = 90) {
  const parts = [];
  for (const model of models) {
    const status = getModelStatus(model);
    parts.push(`${status} ${model.id}`);
  }

  const lines = [];
  let current = '';
  for (const part of parts) {
    if (!current) {
      current = part;
    } else if ((current + ', ' + part).length <= targetWidth) {
      current += ', ' + part;
    } else {
      lines.push(current);
      current = part;
    }
  }
  if (current) lines.push(current);

  return lines.map((line, i) => (i === 0 ? `  ${line}` : `  ${line}`)).join('\n');
}

function formatGroup(provider, models) {
  const completed = models.filter(m => m.probe).length;
  const total = models.length;
  const bar = formatProgressBar(completed, total);
  const sorted = [...models].sort((a, b) => a.id.localeCompare(b.id));
  const modelList = formatGroupLine(sorted);

  return `${provider} ${bar}\n${modelList}`;
}

module.exports = { formatProgressBar, formatGroupLine, formatGroup, getModelStatus, groupByProvider, ANSI };
