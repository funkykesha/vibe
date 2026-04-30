const test = require('node:test');
const assert = require('node:assert');
const { formatProgressBar, formatModelList, renderProviderGroup } = require('../lib/formatting/model-status-formatter');
const StartupDisplayManager = require('../lib/startup-display-manager');

// Mock console.log to capture output
const originalConsoleLog = console.log;
let consoleOutput = [];

test.beforeEach(() => {
  consoleOutput = [];
  console.log = (...args) => {
    consoleOutput.push(args.join(' '));
  };
});

test.afterEach(() => {
  console.log = originalConsoleLog;
});

test('formatProgressBar shows correct progress', async (t) => {
  const result = formatProgressBar(3, 5);
  assert.strictEqual(result, '[████████████░░░░░░░░] 3/5');
});

test('formatProgressBar handles edge cases', async (t) => {
  assert.strictEqual(formatProgressBar(0, 0), '[░░░░░░░░░░░░░░░░░░░░] 0/0');
  assert.strictEqual(formatProgressBar(5, 5), '[████████████████████] 5/5');
});

test('formatModelList sorts models alphabetically', async (t) => {
  const models = [
    { id: 'z-model', status: 'success' },
    { id: 'a-model', status: 'error' },
    { id: 'm-model', status: 'pending' }
  ];
  
  const result = formatModelList(models);
  // Check that a-model comes first, then m-model, then z-model
  const modelOrder = result.replace(/\x1b\[[0-9;]*m/g, ''); // Remove color codes
  assert.match(modelOrder, /a-model.*m-model.*z-model/);
});

test('formatModelList applies correct color codes', async (t) => {
  const models = [
    { id: 'success-model', status: 'success' },
    { id: 'error-model', status: 'error' },
    { id: 'pending-model', status: 'pending' }
  ];
  
  const result = formatModelList(models);
  
  // Check for green color code for success
  assert.ok(result.includes('\x1b[32m✅ success-model\x1b[0m'));
  // Check for red color code for error
  assert.ok(result.includes('\x1b[31m❌ error-model\x1b[0m'));
  // Check for yellow color code for pending
  assert.ok(result.includes('\x1b[33m⏳ pending-model\x1b[0m'));
});

test('renderProviderGroup combines components correctly', async (t) => {
  const models = [
    { id: 'model1', status: 'success' },
    { id: 'model2', status: 'error' }
  ];
  
  const result = renderProviderGroup('OpenAI', models);
  assert.strictEqual(result.length, 2);
  assert.strictEqual(result[0], 'OpenAI [████████████████████] 2/2');
  assert.ok(result[1].includes('model1'));
  assert.ok(result[1].includes('model2'));
});

test('display manager tracks model statuses', async (t) => {
  const manager = new StartupDisplayManager();
  manager.updateModelStatus('OpenAI', 'gpt-4o', 'success');
  
  // Check that the status was recorded
  assert.strictEqual(manager.providerData.get('OpenAI').get('gpt-4o').status, 'success');
});

test('display manager renders output', async (t) => {
  const manager = new StartupDisplayManager();
  manager.updateModelStatus('OpenAI', 'gpt-4o', 'success');
  manager.updateModelStatus('OpenAI', 'gpt-4o-mini', 'pending');
  
  // Check that console.log was called
  assert.ok(consoleOutput.length > 0);
});

test('display manager handles multiple providers', async (t) => {
  const manager = new StartupDisplayManager();
  manager.updateModelStatus('OpenAI', 'gpt-4o', 'success');
  manager.updateModelStatus('Anthropic', 'claude-sonnet', 'error');
  
  // Both providers should be tracked
  assert.ok(manager.providerData.has('OpenAI'));
  assert.ok(manager.providerData.has('Anthropic'));
});