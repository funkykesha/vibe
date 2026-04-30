## Why

Daemon doesn't exit cleanly when user clicks quit. Process hangs or gets respawned by system/launchd after time. Causes unexpected restart behavior and prevents graceful shutdown.

## What Changes

- Fix `shutdown()` to properly terminate the daemon process
- Cancel all running timers and dispatch queue operations
- Add explicit process exit call to ensure clean termination
- Verify runloop stops before exiting

## Capabilities

### New Capabilities
- `clean-process-exit`: Ensure daemon process exits completely when shutdown is called, with all resources released and timers cancelled.

### Modified Capabilities
<!-- No requirement changes to existing specs -->

## Impact

- Daemon/AppDelegate.swift: shutdown() method implementation
- Process lifecycle: affects when daemon terminates
- User experience: fixes unexpected restart behavior
