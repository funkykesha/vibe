# Startup Model Status Display Proposal

## What

Implement a real-time, visually appealing status display during application startup that shows the progress of model availability probing. This will replace the current verbose logging with a compact, informative dashboard showing progress bars and color-coded status indicators for each model.

## Why

1. **Better User Experience**: The current startup process is verbose and difficult to parse. Users cannot easily tell which models are available or how much progress has been made.

2. **Real-time Feedback**: Users need immediate feedback on model availability without waiting for the entire probing process to complete.

3. **Visual Clarity**: Progress bars and color-coded indicators provide instant recognition of system status without reading through logs.

4. **Professional Presentation**: A clean, organized display during startup creates a more polished impression of the application.

## Success Criteria

- Progress bars show accurate completion percentage for each provider group
- Color-coded status indicators (✅ success, ❌ error, ⏳ pending) update in real-time
- Display updates dynamically without excessive screen flickering
- All models are accounted for in the display, even if they fail
- Minimal performance impact on the startup process