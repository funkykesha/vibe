# Startup Model Status Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a real-time model status display during startup that shows probing progress with visual progress bars and color-coded model statuses

**Architecture:** Create a modular system with formatting utilities, event-driven updates, and terminal-based rendering using ANSI escape codes for dynamic updates

**Tech Stack:** Node.js, ANSI escape codes, existing eliza-proxy codebase

---

### Task 1: Create Model Status Formatter Utility

**Files:**
- Create: `lib/formatting/model-status-formatter.js`

- [ ] **Step 1: Write the progress bar formatting function**

```javascript
function formatProgressBar(checked, total) {
  const barLength = 20;
  const progress = total > 0 ? Math.floor((checked / total) * barLength) : 0;
  const filledBar = '█'.repeat(progress);
  const emptyBar = '░'.repeat(barLength - progress);
  return `[${filledBar}${emptyBar}] ${checked}/${total}`;
}
```

- [ ] **Step 2: Write the model list formatting function**

```javascript
function formatModelList(models) {
  // Sort models alphabetically
  const sortedModels = [...models].sort((a, b) => a.id.localeCompare(b.id));
  
  // Map models to colored status strings
  const modelStrings = sortedModels.map(model => {
    switch (model.status) {
      case 'success':
        return `\x1b[32m✅ ${model.id}\x1b[0m`; // Green
      case 'error':
        return `\x1b[31m❌ ${model.id}\x1b[0m`; // Red
      case 'pending':
        return `\x1b[33m⏳ ${model.id}\x1b[0m`; // Yellow
      default:
        return `\x1b[33m⏳ ${model.id}\x1b[0m`; // Default to pending
    }
  });
  
  // Join with commas and handle line wrapping (simplified for now)
  return modelStrings.join(', ');
}
```

- [ ] **Step 3: Write the provider group rendering function**

```javascript
function renderProviderGroup(providerName, models) {
  const total = models.length;
  const checked = models.filter(m => m.status === 'success' || m.status === 'error').length;
  
  const progressBar = formatProgressBar(checked, total);
  const modelList = formatModelList(models);
  
  return [
    `${providerName} ${progressBar}`,
    `  ${modelList}`
  ];
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/formatting/model-status-formatter.js
git commit -m "feat: add model status formatter utility"
```

### Task 2: Enhance Eliza Client with Model Status Tracking

**Files:**
- Modify: `lib/eliza-client/index.js`

- [ ] **Step 1: Add model status tracking to the client**

```javascript
// Add to the ElizaClient class
constructor() {
  // ... existing code ...
  this.modelStatuses = new Map(); // provider -> Map<modelId, status>
  this.statusListeners = [];
}

// Add method to subscribe to status updates
onModelUpdate(listener) {
  this.statusListeners.push(listener);
}

// Add method to update model status
updateModelStatus(provider, modelId, status) {
  if (!this.modelStatuses.has(provider)) {
    this.modelStatuses.set(provider, new Map());
  }
  this.modelStatuses.get(provider).set(modelId, status);
  
  // Notify listeners
  this.statusListeners.forEach(listener => {
    listener(provider, modelId, status);
  });
}
```

- [ ] **Step 2: Integrate status updates with probing logic**

```javascript
// Modify the probeModel method to update status
async probeModel(model) {
  const provider = model.provider;
  const modelId = model.id;
  
  // Set status to pending
  this.updateModelStatus(provider, modelId, 'pending');
  
  try {
    // ... existing probing logic ...
    const response = await this._makeRequest(model, testMessage);
    
    // Set status to success
    this.updateModelStatus(provider, modelId, 'success');
    return true;
  } catch (error) {
    // Set status to error
    this.updateModelStatus(provider, modelId, 'error');
    return false;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/eliza-client/index.js
git commit -m "feat: enhance eliza client with model status tracking"
```

### Task 3: Create Startup Display Manager

**Files:**
- Create: `lib/startup-display-manager.js`

- [ ] **Step 1: Write the display manager class**

```javascript
const { formatProgressBar, formatModelList, renderProviderGroup } = require('./formatting/model-status-formatter');

class StartupDisplayManager {
  constructor() {
    this.providerData = new Map();
    this.renderedLines = 0;
  }
  
  updateModelStatus(provider, modelId, status) {
    // Initialize provider data if needed
    if (!this.providerData.has(provider)) {
      this.providerData.set(provider, new Map());
    }
    
    // Update model status
    this.providerData.get(provider).set(modelId, { id: modelId, status });
    
    // Re-render display
    this.render();
  }
  
  render() {
    // Clear previous output
    this.clear();
    
    // Get providers with at least one model
    const activeProviders = Array.from(this.providerData.entries())
      .filter(([_, models]) => models.size > 0)
      .map(([provider, models]) => ({
        name: provider,
        models: Array.from(models.values())
      }));
    
    // Render each provider group
    const lines = [];
    for (const provider of activeProviders) {
      const groupLines = renderProviderGroup(provider.name, provider.models);
      lines.push(...groupLines);
    }
    
    // Output to console
    console.log(lines.join('\n'));
    this.renderedLines = lines.length;
  }
  
  clear() {
    // Move cursor up and clear lines
    if (this.renderedLines > 0) {
      process.stdout.write(`\x1b[${this.renderedLines}A`); // Move up
      for (let i = 0; i < this.renderedLines; i++) {
        process.stdout.write('\x1b[K'); // Clear line
        if (i < this.renderedLines - 1) {
          process.stdout.write('\n');
        }
      }
      process.stdout.write(`\x1b[${this.renderedLines}A`); // Move back up
    }
  }
}

module.exports = StartupDisplayManager;
```

- [ ] **Step 2: Commit**

```bash
git add lib/startup-display-manager.js
git commit -m "feat: create startup display manager"
```

### Task 4: Integrate Display Manager with Server Startup

**Files:**
- Modify: `server.js`

- [ ] **Step 1: Import and initialize the display manager**

```javascript
// Add near the top of server.js
const StartupDisplayManager = require('./lib/startup-display-manager');
const displayManager = new StartupDisplayManager();
```

- [ ] **Step 2: Subscribe to model updates during startup**

```javascript
// In the startup sequence, after initializing the eliza client
elizaClient.onModelUpdate((provider, modelId, status) => {
  displayManager.updateModelStatus(provider, modelId, status);
});
```

- [ ] **Step 3: Ensure display updates during model probing**

```javascript
// In the startup function, when probing models
// The event-based system should handle updates automatically
```

- [ ] **Step 4: Commit**

```bash
git add server.js
git commit -m "feat: integrate startup display manager with server"
```

### Task 5: Test the Implementation

**Files:**
- Create: `tests/startup-display.test.js`

- [ ] **Step 1: Write tests for the formatter utility**

```javascript
const { formatProgressBar, formatModelList, renderProviderGroup } = require('../lib/formatting/model-status-formatter');

test('formatProgressBar shows correct progress', () => {
  const result = formatProgressBar(3, 5);
  expect(result).toBe('[████████░░░░░░░░░░░░] 3/5');
});

test('formatModelList sorts models alphabetically', () => {
  const models = [
    { id: 'z-model', status: 'success' },
    { id: 'a-model', status: 'error' },
    { id: 'm-model', status: 'pending' }
  ];
  
  const result = formatModelList(models);
  // Check that a-model comes first, then m-model, then z-model
  expect(result).toMatch(/a-model.*m-model.*z-model/);
});
```

- [ ] **Step 2: Write tests for the display manager**

```javascript
const StartupDisplayManager = require('../lib/startup-display-manager');

test('display manager tracks model statuses', () => {
  const manager = new StartupDisplayManager();
  manager.updateModelStatus('OpenAI', 'gpt-4o', 'success');
  
  // Check that the status was recorded
  expect(manager.providerData.get('OpenAI').get('gpt-4o').status).toBe('success');
});
```

- [ ] **Step 3: Run tests to verify they pass**

```bash
npm test -- tests/startup-display.test.js
```

- [ ] **Step 4: Commit**

```bash
git add tests/startup-display.test.js
git commit -m "test: add tests for startup display functionality"
```