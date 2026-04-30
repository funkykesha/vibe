# Startup Model Status Display Design

## Architecture Overview

The solution consists of three main components:

1. **Model Status Formatter Utility** - Responsible for formatting the visual representation of progress bars and model statuses
2. **Enhanced Eliza Client** - Extended with event-driven model status tracking capabilities
3. **Startup Display Manager** - Manages the terminal display and handles dynamic updates using ANSI escape codes

## Component Details

### Model Status Formatter Utility

Location: `lib/formatting/model-status-formatter.js`

Functions:
- `formatProgressBar(checked, total)`: Creates a 20-character progress bar with filled/unfilled segments
- `formatModelList(models)`: Formats model names with color-coded status emojis and handles line wrapping
- `renderProviderGroup(providerName, models)`: Combines provider name, progress bar, and model list into display-ready lines

### Enhanced Eliza Client

Location: `lib/eliza-client/index.js`

Extensions:
- `modelStatuses`: Map tracking status of all models by provider
- `statusListeners`: Array of callback functions for status updates
- `onModelUpdate(listener)`: Subscribe to model status changes
- `updateModelStatus(provider, modelId, status)`: Update model status and notify listeners

### Startup Display Manager

Location: `lib/startup-display-manager.js`

Responsibilities:
- Track model statuses by provider
- Render formatted display using ANSI escape codes for dynamic updates
- Clear and redraw display efficiently to minimize flickering
- Handle line wrapping and proper terminal cursor positioning

## Data Flow

1. Server initializes Eliza client and Startup Display Manager
2. Display Manager subscribes to model status updates from Eliza client
3. During model probing, Eliza client updates model statuses
4. Status updates trigger Display Manager to re-render the terminal output
5. ANSI escape codes are used to clear previous output and draw updated display

## Visual Specification

Each provider group displays:
```
{ProviderName} [{ProgressBar}] {Checked}/{Total}
  {Emoji} {ModelID}, {Emoji} {ModelID}, ...
```

Where:
- ProgressBar: 20 characters with █ (filled) and ░ (empty)
- Emojis: ✅ (success - green), ❌ (error - red), ⏳ (pending - yellow)
- Models sorted alphabetically within each provider group
- Line wrapping handled with proper indentation maintenance