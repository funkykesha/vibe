'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  formatProgressBar,
  formatModelListLines,
  renderProviderGroup,
} = require('../lib/formatting/model-status-formatter');
const StartupDisplayManager = require('../lib/startup-display-manager');

function makeStream() {
  return {
    isTTY: true,
    columns: 40,
    writes: [],
    write(chunk) {
      this.writes.push(chunk);
      return true;
    },
  };
}

test('formatProgressBar uses 8-slot display', () => {
  assert.equal(formatProgressBar(3, 6), '[████░░░░] 3/6');
});

test('formatModelListLines wraps long lists with stable indentation', () => {
  const lines = formatModelListLines([
    { id: 'a-model', status: 'pending' },
    { id: 'b-model', status: 'success' },
    { id: 'c-model', status: 'warning' },
  ], {
    width: 28,
    useAnsi: false,
    indent: '  ',
  });

  assert.ok(lines.length >= 2);
  assert.ok(lines.every((line) => line.startsWith('  ')));
});

test('renderProviderGroup counts warning/error as completed', () => {
  const lines = renderProviderGroup('OpenAI', [
    { id: 'm1', status: 'success' },
    { id: 'm2', status: 'warning' },
    { id: 'm3', status: 'error' },
    { id: 'm4', status: 'pending' },
  ], { width: 90, useAnsi: false });

  assert.equal(lines[0], 'OpenAI [██████░░] 3/4');
});

test('display manager seeds full pending state before updates', () => {
  const stream = makeStream();
  const manager = new StartupDisplayManager({ stream, isTTY: false, width: 80 });

  manager.seedCatalog([
    { provider: 'openai', models: [{ id: 'gpt-4.1', status: 'pending' }, { id: 'gpt-4o', status: 'pending' }] },
  ]);

  const snapshot = manager.getSnapshot();
  assert.equal(snapshot.summary.total, 2);
  assert.equal(snapshot.summary.pending, 2);
});

test('display manager buffers updates before seed and applies after init', () => {
  const stream = makeStream();
  const manager = new StartupDisplayManager({ stream, isTTY: false, width: 80 });

  manager.updateModelStatus('openai', 'gpt-4.1', 'warning');
  manager.seedCatalog([
    { provider: 'openai', models: [{ id: 'gpt-4.1', status: 'pending' }] },
  ]);

  const snapshot = manager.getSnapshot();
  assert.equal(snapshot.providers[0].models[0].status, 'warning');
});

test('display manager keeps provider order stable on later updates', () => {
  const stream = makeStream();
  const manager = new StartupDisplayManager({ stream, isTTY: false, width: 80 });

  manager.seedCatalog([
    { provider: 'anthropic', models: [{ id: 'claude-sonnet', status: 'pending' }] },
    { provider: 'openai', models: [{ id: 'gpt-4.1', status: 'pending' }] },
  ]);

  manager.updateModelStatus('openai', 'gpt-4.1', 'success');

  const snapshot = manager.getSnapshot();
  assert.deepEqual(snapshot.providers.map((p) => p.name), ['anthropic', 'openai']);
});

test('non-TTY mode avoids cursor movement control codes', () => {
  const stream = {
    isTTY: false,
    columns: 40,
    writes: [],
    write(chunk) {
      this.writes.push(chunk);
      return true;
    },
  };

  const manager = new StartupDisplayManager({ stream, isTTY: false, width: 40 });
  manager.seedCatalog([{ provider: 'openai', models: [{ id: 'gpt-4.1', status: 'pending' }] }]);
  manager.updateModelStatus('openai', 'gpt-4.1', 'success');

  const output = stream.writes.join('');
  assert.equal(/\x1b\[[0-9;]*[ABCDJK]/.test(output), false);
});
