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