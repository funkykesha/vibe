## 1. Store Timer References

- [x] 1.1 Add menuAgentTimer property to DaemonCoordinator to store repeating timer reference
- [x] 1.2 Update start() to store Timer from scheduledTimer call instead of ignoring return value

## 2. Store Dispatch Work Item References

- [x] 2.1 Add workItems array property to DaemonCoordinator to store pending DispatchWorkItem objects
- [x] 2.2 Update initial check asyncAfter in start() to capture and store DispatchWorkItem
- [x] 2.3 Update service control handlers (onStartService, onStopService, onRestartService) to capture DispatchWorkItem from asyncAfter calls

## 3. Implement Proper Shutdown Cleanup

- [x] 3.1 Update shutdown() to cancel menuAgentTimer before stopping other resources
- [x] 3.2 Update shutdown() to iterate workItems array and call .cancel() on each
- [x] 3.3 Clear workItems array after cancellation
- [x] 3.4 Verify resource cleanup order: services → scheduler → file watcher → ipcServer → dispatch items → timers
- [x] 3.5 Add explicit exit(0) call at end of shutdown() after logging DAEMON_SHUTDOWN_COMPLETE

## 4. Handle Edge Cases

- [x] 4.1 Ensure menuAgentTimer invalidation handles nil case if timer was never created
- [x] 4.2 Verify workItems.removeAll() doesn't cause issues with already-cancelled items
- [x] 4.3 Test that exit(0) is reached even if earlier cleanup steps are slow

## 5. Verify and Test

- [x] 5.1 Build project: `swift build`
- [x] 5.2 Manual test: Start daemon, wait 5+ seconds, click quit, verify no respawn after 30+ seconds
- [x] 5.3 Check logs: Verify DAEMON_SHUTDOWN_COMPLETE appears in events.json
- [x] 5.4 Verify no resource warnings or leaks in Console.app
