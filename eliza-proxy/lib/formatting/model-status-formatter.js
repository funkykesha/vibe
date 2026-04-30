/**
 * Format model status display components
 */

/**
 * Create a progress bar with filled and empty segments
 * @param {number} checked - Number of completed items
 * @param {number} total - Total number of items
 * @returns {string} Formatted progress bar string
 */
function formatProgressBar(checked, total) {
  const barLength = 20;
  const progress = total > 0 ? Math.floor((checked / total) * barLength) : 0;
  const filledBar = '█'.repeat(progress);
  const emptyBar = '░'.repeat(barLength - progress);
  return `[${filledBar}${emptyBar}] ${checked}/${total}`;
}

/**
 * Format a list of models with color-coded status emojis
 * @param {Array} models - Array of model objects with id and status properties
 * @returns {string} Formatted model list string
 */
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

/**
 * Render a provider group with progress bar and model list
 * @param {string} providerName - Name of the provider
 * @param {Array} models - Array of model objects
 * @returns {Array} Array of lines for the provider group display
 */
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

module.exports = {
  formatProgressBar,
  formatModelList,
  renderProviderGroup
};